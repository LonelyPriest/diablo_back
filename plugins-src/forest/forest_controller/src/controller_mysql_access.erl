%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@huawei.com>
%%% @copyright (C) 2013, buxianhui
%%% @doc
%%%
%%% @end
%%% Created :  9 Jan 2013 by buxianhui <buxianhui@huawei.com>
%%%-------------------------------------------------------------------
-module(controller_mysql_access).

-include("../../../deps/erlang-mysql-driver-master/include/mysql.hrl").
-include("../../../include/knife.hrl").

-behaviour(gen_server).

%% API
-export([start_link/0]).

-export([fetch/2, get_connection/0, sql_result/3, row_result/3]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-define(SERVER, ?MODULE).

-record(state, {conn_pool = undefined}).

fetch(read, SQL)->
    gen_server:call(?MODULE, {fetch_read, SQL});
fetch(write, SQL) ->
    gen_server:call(?MODULE, {fetch_write, SQL}).

get_connection() ->
    gen_server:call(?MODULE, get_connection).
    
start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).


init([]) ->
    {ok, DB} = application:get_env(controller, powerking_db_name),
    {ok, User} = application:get_env(controller, powerking_db_user),
    {ok, Passwd} = application:get_env(controller, powerking_db_passwd),
    {ok, Host} = application:get_env(controller, powerking_db_host),
    
    mysql:start_link(conn, Host, User, Passwd, DB),
    
    lists:foreach(
      fun(_) ->
	      mysql:connect(conn, Host, undefined, User, Passwd, DB, true)
      end, lists:duplicate(3, dummy)),
    
    {ok, #state{conn_pool = conn}}.

handle_call({fetch_read, SQL}, _From,
            #state{conn_pool = Read} = State) when is_binary(SQL)->
    Result =
        case mysql:fetch(Read, SQL) of
            {data, #mysql_result{rows=[]}} ->
		{ok, []};
	    
	    {data, #mysql_result{fieldinfo=FieldInfo, rows=Rows}} ->
                Fields = [Field || {_, Field, _, _} <- FieldInfo],
                ?DEBUG("fields ~p~nRows ~p", [Fields, Rows]),
                {ok, sql_result(Fields, Rows, [])};
	    
            {error, #mysql_result{error=Error, errcode=ErrCode}} ->
                {error, {Error, ErrCode}}
        end,

    ?DEBUG("sql=~p~nsql result ~p", [SQL, Result]),
    {reply, Result, State};


handle_call({fetch_write, SQL}, _From,
	    #state{conn_pool = Write} = State) when is_binary(SQL)->
    Result = 
	case mysql:fetch(Write, SQL) of
	    {updated, #mysql_result{affectedrows=AffectedRows}} ->
		{ok, {write, AffectedRows}};
	    {error, #mysql_result{error=Error, errcode=ErrCode}} ->
		{error, {ErrCode, Error}}
	end,
    ?DEBUG("fetch_write with sql=~p~nresult ~p", [SQL, Result]),
    
    {reply, Result, State};
    
handle_call(get_connection, _From,
	    #state{conn_pool = Conn} = State) ->
    {reply, Conn, State};

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.


handle_cast(_Msg, State) ->
    {noreply, State}.


handle_info(_Info, State) ->
    {noreply, State}.


terminate(Reason, _State) ->
    ?ERROR("terminate with reason=~p~n", [Reason]),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.


sql_result(_, [], Values) ->
    lists:reverse(Values);
sql_result(Fields, [RowValue|T], Values) ->
    sql_result(Fields, T, [row_result(Fields, RowValue, [])|Values]).

row_result([], [], KV) ->
    lists:reverse(KV);
row_result([Field|RestFields], [Value|RestValues], KV) ->
    FormatValue =
        case Value of
            {date, {Y, M, D}}->
                list_to_binary(
                  lists:flatten(
                    io_lib:format("~4..0w-~2..0w-~2..0w", [Y, M, D])));
            Value ->
                Value
        end,
    row_result(RestFields, RestValues, [{Field, FormatValue}|KV]).
