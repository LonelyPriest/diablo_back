%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright Seasun(C) 2014, buxianhui
%%% @doc
%%%  the task state of certain target
%%% @end
%%% Created :  3 Jun 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(forest_target_state).

-include("../../../include/knife.hrl").
-include("forest.hrl").

-behaviour(gen_server).

%% API
-export([start_link/0]).
-export([save_steps/3, lookup_steps/2, lookup_steps/0,
	 delete_steps/0, delete_steps/1, delete_steps/2]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-define(SERVER, ?MODULE). 

-record(state, {}).

%%%===================================================================
%%% API
%%%===================================================================
save_steps(TaskId, Target, Steps) ->
    gen_server:call(?SERVER, {save_steps, TaskId, Target, Steps}).

lookup_steps() ->
    gen_server:call(?SERVER, lookup_steps).

lookup_steps(TaskId, Target) ->
    gen_server:call(?SERVER, {lookup_steps, TaskId, Target}).

delete_steps() ->
    gen_server:cast(?SERVER, delete_steps).

delete_steps(TaskId) ->
    gen_server:call(?SERVER, {delete_steps, TaskId}).

delete_steps(TaskId, Target) ->
    gen_server:cast(?SERVER, {delete_steps, TaskId, Target}).

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

init([]) ->
    case mnesia:system_info(use_dir) of
	true ->
	    ok = mnesia:start(),
	    ok;
	false ->
	    stopped = mnesia:stop(),
	    ok = mnesia:create_schema([node()]),
	    ok = mnesia:start(),
	    lists:foreach(
	      fun({Tab, TabDef}) ->
		      TabDef1 = proplists:delete(match, TabDef),
		      case mnesia:create_table(Tab, TabDef1) of
			  {atomic, ok} -> ok;
			  {aborted, Reason} ->
			      throw({error, {table_creation_failed,
					     Tab, TabDef1, Reason}})
		      end		      
		      
	      end, table_definitions())
    end,    
    {ok, #state{}}.

handle_call({save_steps, TaskId, Target, Steps}, _From, State)->
    ?DEBUG("save_steps-> TaskId ~p, Target ~p, Steps ~p",
	   [TaskId, Target, Steps]),
    {atomic, ok} = 
	mnesia:transaction(
	  fun() ->
		  mnesia:write(#target_state{
				  target_info={TaskId, Target},
				  steps = Steps})
	  end),
    {reply, ok, State};

handle_call(lookup_steps, _From, State) ->
    MS = [{#target_state{_ = '_'}, [], ['$_']}],
    {atomic, TaskState} = 
	mnesia:transaction(
	  fun() -> mnesia:select(target_state, MS) end),

    {reply, TaskState, State};

handle_call({lookup_steps, TaskId, Target}, _From, State) ->
    ?DEBUG("lookup_steps with TaskId ~p, Target ~p", [TaskId, Target]),
    MS = [{#target_state{target_info={'$1', '$2'}, _ = '_'},
	   [{'==', '$1', TaskId}, {'==', '$2', Target}],
	   ['$_']}],
    {atomic, TaskState} = 
	mnesia:transaction(
	  fun() -> mnesia:select(target_state, MS) end),

    ?DEBUG("lookup_steps get result ~p", [TaskState]),

    {reply, TaskState, State};
    
handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.



handle_cast({delete_steps, TaskId, Target}, State) ->
    D = #target_state{target_info = {TaskId,Target}, _ = '_'},
    {atomic, ok} = mnesia:transaction(
		     fun() ->
			     lists:foreach(
			       fun(E) ->
				       mnesia:delete_object(E)
			       end, mnesia:match_object(D))
		     end),
    {noreply, State};


handle_cast({delete_steps, TaskId}, State) ->
    D = #target_state{ target_info = {TaskId, _='_'}, _ = '_'},
    {atomic, ok} =
	mnesia:transaction(
	  fun() ->
		  lists:foreach(
		    fun(E) ->
			    mnesia:delete_object(E)
		    end, mnesia:match_object(D))
	  end),
    {noreply, State};

handle_cast(delete_steps, State) ->
    D = #target_state{ _ = '_'},
    {atomic, ok} =
	mnesia:transaction(
	  fun() ->
		  lists:foreach(
		    fun(E) ->
			    mnesia:delete_object(E)
		    end, mnesia:match_object(D))
	  end),
    {noreply, State};

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.


terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
table_definitions() ->
    [
     {target_state,
      [{record_name, target_state},
       {attributes, record_info(fields, target_state)},
       {disc_copies, [node()]},
       {match, #target_state{_ = '_'}}]}
    ].
