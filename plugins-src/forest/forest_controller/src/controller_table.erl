%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright Seasun(C) 2014, buxianhui
%%% @doc
%%%  Tables operation
%%% @end
%%% Created :  7 Mar 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(controller_table).

-include("controller.hrl").

-export([create/0, table_definitions/1, check_schema_integrity/0,
	 table_names/0, wait/1]).


%% -----------------------------------------------------------------------------
%% Create tables
%% -----------------------------------------------------------------------------
-spec create() -> no_return(). 
create() ->
    lists:foreach(fun({Tab, TabDef}) ->
			  TabDef1 = proplists:delete(match, TabDef),
			  case mnesia:create_table(Tab, TabDef1) of
			      {atomic, ok} -> ok;
			      {aborted, Reason} ->
				  throw({error, {table_creation_failed,
						Tab, TabDef1, Reason}})
			  end
		  end, table_definitions()),
    ok.

-spec table_definitions(disc|ram) -> no_return(). 
table_definitions(disc) ->
    table_definitions();
table_definitions(ram) ->
    [{Tab, [{disc_copies, []}, {ram_copies, [node()]} |
	    proplists:delete(
	      ram_copies, proplists:delete(disc_copies, TabDef))]} ||
	 {Tab, TabDef} <- table_definitions()].

-spec table_definitions() -> no_return(). 
table_definitions() ->
    [
     {task, [{record_name, task},
	     {attributes, record_info(fields, task)},
	     {disc_copies, [node()]},
	     {match, #task{_ = '_'}}]},
     
     {task_break, [{record_name, task_break},
		   {attributes, record_info(fields, task_break)},
		   {disc_copies, [node()]},
		   {match, #task{_ = '_'}}]}
    ].

-spec check_schema_integrity() -> no_return(). 
check_schema_integrity() ->
    Tables = mnesia:system_info(tables),
    case check(fun(Tab, TabDef) ->
		       case lists:member(Tab, Tables) of
			   false -> {error, {table_missing, Tab}};
			   true  -> check_attributes(Tab, TabDef)
		       end
	       end) of
	ok    ->
	    ok = wait(table_names()),
	    check(fun check_content/2);
	[]    -> ok;
	Other -> Other
    end.

-spec table_names() -> no_return(). 
table_names()->
    [ Name || {Name, _} <- table_definitions()].


check_content(Tab, TabDef) ->
    {_, Match} = proplists:lookup(match, TabDef),

    %% The table that was not empty should check it's content
    case mnesia:dirty_first(Tab) of
	'$end_of_table' ->
	    ok;
	Key ->
	    ObjList = mnesia:dirty_read(Tab, Key),
	    MatchComp = ets:match_spec_compile([{Match, [], ['$_']}]),
	    case ets:match_spec_run(ObjList, MatchComp) of
		ObjList -> ok;
		_ -> {error, {table_contend_invalid, Tab, Match, ObjList}}
	    end
    end.	    

-spec check(fun()) -> no_return().
check(FunCheck)->
    lists:foldl(
      fun({Tab, TabDef}, Acc) ->
	      case FunCheck(Tab, TabDef) of
		  ok -> Acc ++ [];
		  {error, Error} -> Acc ++ [Error]
	      end
      end, [], table_definitions()).

%% -----------------------------------------------------------------------------
%% Check the table's attributes, comparing with mnesia and table definition
%% -----------------------------------------------------------------------------
check_attributes(Tab, TabDef) ->
    {_, ExpAttrs} = proplists:lookup(attributes, TabDef),
    case mnesia:table_info(Tab, attributes) of
	ExpAttrs -> ok;
	Attrs -> {error, {table_attributes_mismatch, Tab, ExpAttrs, Attrs}}
    end.

%% -----------------------------------------------------------------------------
%% Wait all table is ready
%% -----------------------------------------------------------------------------
-spec wait(string()|atom()) -> no_return().
wait(TableNames) ->
    case mnesia:wait_for_tables(TableNames, 30000) of
	ok ->
	    ok;
	{timeout, BadTabs} ->
	    throw({error, {timeout_waiting_for_tables, BadTabs}});
	{error, Reason} ->
	    throw({error, {failed_waiting_for_tables, Reason}})
    end.
