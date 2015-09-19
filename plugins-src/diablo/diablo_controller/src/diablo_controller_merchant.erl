%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 17 Sep 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_controller_merchant).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_server).

%% API
-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-export([merchant/2, merchant/3, lookup/0, lookup/1]).

-define(SERVER, ?MODULE). 
-define(tbl_merchant, "merchants").


-record(state, {}).

%%%===================================================================
%%% API
%%%===================================================================
merchant(new, Props) ->
    gen_server:call(?MODULE, {new_merchant, Props});
merchant(delete, Condition) ->
    gen_server:call(?MODULE, {delete_merchant, Condition});

merchant(get, Merchant) ->
    gen_server:call(?MODULE, {get_merchant, Merchant}).

merchant(update, Condition, Fields) ->
    gen_server:call(?MODULE, {update_merchant, Condition, Fields}).


lookup() ->
    gen_server:call(?MODULE, lookup).
lookup(Condition) ->
    gen_server:call(?MODULE, {lookup, Condition}).



start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
init([]) ->
    {ok, #state{}}.

handle_call({new_merchant, Props}, _From, State)->
    ?DEBUG("new merchant with props ~p", [Props]),
    Name    = ?v(<<"name">>, Props),
    Type    = ?v(<<"type">>, Props),
    Owner   = ?v(<<"owner">>, Props),
    Mobile  = ?v(<<"mobile">>, Props),
    Address = ?v(<<"address">>, Props),

    %% name can not be same
    Sql = "select " ++ fields()
	++ " from " ++ ?tbl_merchant
	++ " where "
	++ " name=" ++ "\"" ++ ?to_s(Name) ++ "\""
	%% ++ " and type=" ++ ?to_s(Type)
	%% ++ " and mobile="   ++ "\"" ++ ?to_s(Mobile) ++ "\""
	%% ++ " and owner="    ++ "\"" ++ ?to_s(Owner) ++ "\""
	++ " and deleted="  ++ ?to_s(?NO),
    
    case ?sql_utils:execute(s_read, Sql) of
	{ok, []} -> 
	    Sql1 = "insert into " ++ ?tbl_merchant
		++ "(name, type, owner, mobile, address, entry_date)"
		++ " values ("
		++ "\""  ++ ?to_s(Name) ++ "\""
		++ ","   ++ ?to_s(Type)
		++ ",\"" ++ ?to_s(Owner) ++ "\""
		++ ",\"" ++ ?to_s(Mobile) ++ "\""
		++ ",\"" ++ ?to_s(Address) ++ "\""
		++ ",\"" ++ ?utils:current_time(localdate) ++ "\");", 
		
	    %% ?DEBUG("sql to merchant ~p", [Sql1]),
	    case ?sql_utils:execute(insert, Sql1) of
		{ok, InsertId} -> 
		    %% user profile
		    case ?w_user_profile:set_default(InsertId) of
			{ok, _} -> 
			    ok = ?inventory_sn:init(merchant, InsertId),
			    {reply, {ok, Name}, State}; 
			Error ->
			    %% rollback
			    Rollback = "delete from " ++ ?tbl_merchant
				++ " where id=" ++ ?to_s(InsertId) ++ ";",
			    case ?sql_utils:execute(write, Rollback, Name) of
				{ok, Name} ->
				    {reply, Error, State};
				_RollbackError ->
				    {reply, ?err(merchant_rollback_failed, Name), State}
			    end
			end;
		Error ->
		    {reply, Error, State}
	    end;
	{ok, _Any} ->
	    ?DEBUG("merchant ~p has been exist", [Name]),
	    {reply, {error, ?err(merchant_exist, Name)}, State};
	Error ->
	    {reply, Error, State}
    end;

handle_call({delete_merchant, Condition}, _From, State) ->
    ?DEBUG("delete merchant with condtion ~p", [Condition]),
    C = ?utils:to_sqls(proplists, Condition),
    Sql = "update " ++ ?tbl_merchant
	++ " set deleted = " ++ ?to_s(?YES)
	++ " where " ++ C ++ ";",
    {ok, _} = ?mysql:fetch(write, Sql),
    {reply, ok, State};

handle_call({update_merchant, Condition, Fields}, _From, State) ->
    ?DEBUG("Update merchant with condtion: condition ~p, fields ~p", [Condition, Fields]),
    C = ?utils:to_sqls(proplists, Condition),
    ?DEBUG("C ~p", [C]),

    Values = ?utils:to_sqls(proplists, Fields),
    ?DEBUG("U ~p", [Values]),
    
    Sql = "update " ++ ?tbl_merchant ++ " set " ++ Values ++ " where " ++ C ++ ";",    
    ?DEBUG("sql ~p", [Sql]),
    {ok, _} = ?mysql:fetch(write, Sql),
    {reply, ok, State};

handle_call(lookup, _From, State) ->
    ?DEBUG("lookup merchant all", []),
    Sql = "select " ++ fields()
	++ " from " ++ ?tbl_merchant ++ ";",
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({lookup, Condition}, _From, State) ->
    ?DEBUG("lookup merchant with condition ~p", [Condition]),
    Sql = "select " ++ fields()
	++ " from " ++ ?tbl_merchant
	++ " where " ++ ?utils:to_sqls(proplists, Condition) ++ ";",
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State}; 

handle_call({get_merchant, Merchant}, _From, State) ->
    ?DEBUG("get_merchant merchant with Merchant ~p", [Merchant]),
    Sql = "select " ++ fields()
	++ " from " ++ ?tbl_merchant
	++ " where id=" ++  ?to_s(Merchant) ++";",
    {ok, Detail} = ?sql_utils:execute(s_read, Sql),
    {reply, {ok, Detail}, State};
    
handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.


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
fields() ->
    "id, name, owner, mobile, address, type, entry_date".
