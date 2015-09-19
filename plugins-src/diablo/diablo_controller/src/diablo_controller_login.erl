%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright diablo(C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 13 Sep 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_controller_login).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").


-behaviour(gen_server).

%% API
-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-export([get/2, login/2]).

-define(SERVER, ?MODULE).

-define(USERS, users).

-record(state, {}).

%%%===================================================================
%%% API
%%%===================================================================

login(User, Passwd) ->
    gen_server:call(?SERVER, {login, User, Passwd}).


get(max_user, User) ->
    gen_server:call(?SERVER, {max_user, User}).

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).


init([]) ->
    {ok, #state{}}.

handle_call({login, User, Passwd}, _From, State) ->
    ?DEBUG("login with User ~p", [User]),
    
    Sql0 = "select id, name, type from users"
	++ " where name=" ++ "\'" ++ ?to_s(User) ++ "\'"
	++ " and password=" ++ "\'" ++ ?to_s(Passwd) ++ "\'"
	++ " and deleted=" ++ ?to_s(?NO),
    case ?sql_utils:execute(s_read, Sql0) of
	{ok, []} ->
	    {reply, {error, ?err(login_error, none)}, State};
	{ok, User0} ->
	    case ?v(<<"type">>, User0) of
		?SUPER ->
		    {reply, {ok, [{<<"merchant">>, 0}, {<<"mtype">>, -1}|User0]}, State};
		_ ->
		    Sql1 = "select a.id, a.name, a.type, a.merchant"
			", b.type as mtype from users a, merchants b"
			++ " where a.merchant=b.id"
			++ " and a.name=" ++ "\"" ++ ?to_s(User) ++ "\""
			++ " and a.password=" ++ "\"" ++ ?to_s(Passwd) ++ "\""
			++ " and a.deleted=" ++ ?to_string(?NO),
		    case ?mysql:fetch(read, Sql1) of
			{ok, []} ->
			    {reply, {error, ?err(login_error, none)}, State};
			{ok, {User1}} ->
			    {reply, {ok, User1}, State}
		    end
	    end;
	Error ->
	    {reply, Error, State}
    end;

handle_call({max_user, User}, _From, State) ->
    ?DEBUG("max_user with user ~p", [User]),
    Sql0 = "select a.id, a.name, a.type, a.merchant, a.max_create from users a"
	%% ++ " where a.name=\'" ++ ?to_s(User) ++ "\'"
	" where a.merchant=("
	"select merchant from users where name=\'" ++ ?to_s(User) ++ "\'"
	++ " and deleted=" ++ ?to_s(?NO) ++ ")"
	++ " and a.type=" ++ ?to_s(?MERCHANT)
	++ " and a.deleted=0",
    case ?mysql:fetch(read, Sql0) of
	{ok, []} ->
	    {reply, {error, login_invalid_user}, State};
	{ok, {H}} ->
	    {reply, {ok, {?v(<<"merchant">>, H),
			  ?v(<<"max_create">>, H)}}, State};
	{ok, [{H}|_T]} ->
	    {reply, {ok, {?v(<<"merchant">>, H),
			  ?v(<<"max_create">>, H)}}, State}
    end; 
    
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
