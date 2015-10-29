%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@huawei.com>
%%% @copyright (C) 2013, buxianhui
%%% @doc
%%%
%%% @end
%%% Created :  9 Jan 2013 by buxianhui <buxianhui@huawei.com>
%%%-------------------------------------------------------------------
-module(diablo_controller_mysql).

-include("../../../../deps/erlang-mysql-driver-master/include/mysql.hrl").
-include("../../../../include/knife.hrl").

-behaviour(gen_server).

%% API
-export([start_link/0]).

-export([fetch/2, get_connection/0, sql_result/3, row_result/3, wait/3]).
-export([start/2]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-export([trans/1]).
-define(SERVER, ?MODULE).

-record(state, {conn_pool = undefined}).

fetch(read, Sql)->
    %% gen_server:call(?MODULE, {fetch_read, ?to_b(SQL)}), 
    %% start(read, ?to_b(Sql));
    read(conn, ?to_b(Sql));
    
fetch(write, Sql) ->
    %% gen_server:call(?MODULE, {fetch_write, ?to_b(SQL)});
    %% start(write, ?to_b(Sql));
    write(conn, ?to_b(Sql));

fetch(insert, Sql) ->
    %% gen_server:call(?MODULE, {fetch_insert, ?to_b(SQL)});
    %% start(insert, ?to_b(Sql));
    insert(conn, ?to_b(Sql));
fetch(transaction, Sqls) when is_list(Sqls)-> 
    %% gen_server:call(?MODULE, {transaction, SQLS}).
    %% start(transaction, Sqls).
    transaction(conn, Sqls).


trans(SQLS) ->
    gen_server:call(?MODULE, {test_trans, SQLS}).

get_connection() ->
    gen_server:call(?MODULE, get_connection).
    
start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).


init([]) ->
    {ok, DB} = application:get_env(diablo_controller, diablo_db_name),
    {ok, User} = application:get_env(diablo_controller, diablo_db_user),
    {ok, Passwd} = application:get_env(diablo_controller, diablo_db_passwd),
    {ok, Host} = application:get_env(diablo_controller, diablo_db_host),

    LogFun =
	fun(Module, Line, _Level, FormatFun) ->
		{Fmt, Args} = FormatFun(),
		knife_log:debug("[~p:~p]-> " ++ Fmt ++ "~n",
				[Module, Line] ++ Args)
	end,
    
    mysql:start_link(conn, Host, undefined, User, Passwd, DB, LogFun),

    %% mysql:connect(conn, Host, undefined, User, Passwd, DB, true),
    lists:foreach(
      fun(_) ->
    	      mysql:connect(conn, Host, undefined, User, Passwd, DB, true)
      end, lists:duplicate(10, dummy)),
    
    {ok, #state{conn_pool = conn}}.

handle_call({fetch_read, SQL}, _From,
            #state{conn_pool = Read} = State) when is_binary(SQL)->
    Result =
        case mysql:fetch(Read, SQL) of
            {data, #mysql_result{rows=[]}} ->
		{ok, []};
	    
	    {data, #mysql_result{fieldinfo=FieldInfo, rows=Rows}} ->
                Fields = [Field || {_, Field, _, _} <- FieldInfo],
                %% ?DEBUG("fields ~p~nRows ~p", [Fields, Rows]),
                {ok, sql_result(Fields, Rows, [])};
	    
            {error, #mysql_result{error=Error, errcode=ErrCode}} ->
                {error, {ErrCode, Error}}
        end,

    %% ?DEBUG("sql=~ts~nsql result ~p", [SQL, Result]),
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
    ?DEBUG("fetch_write with sql=~ts~nresult ~p", [SQL, Result]),
    
    {reply, Result, State};


handle_call({fetch_insert, SQL}, _From,
	    #state{conn_pool = Insert} = State) when is_binary(SQL)->
    Result = 
	case mysql:fetch(Insert, SQL) of
	    {updated, #mysql_result{insertid=InsertId}} ->
		?DEBUG("insert id=~p", [InsertId]),
		{ok, InsertId};
	    {error, #mysql_result{error=Error, errcode=ErrCode}} ->
		{error, {ErrCode, Error}}
	end,
    ?DEBUG("fetch_write with sql=~ts~nresult ~p", [SQL, Result]),

    {reply, Result, State};

handle_call({transaction, SQLS}, _From,
	    #state{conn_pool = Write} = State) ->
    %% [?DEBUG("transaction with sql=~ts", [?to_b(SQL)]) || SQL <- SQLS],
    
    Funs = 
    	lists:foldr(
    	  fun(SQL, Acc) ->
    		  [fun() -> mysql:fetch(?to_b(SQL)) end|Acc]
    	  end, [], SQLS),

    
    %% TransFun = fun() -> [F() || F <- Funs] end,
    TransFun = fun() -> exec_funs(Funs, []) end,
    
    Reply = 
	case mysql:transaction(Write, TransFun) of
	    {atomic, Result} ->
		{ok, Result};
	    {aborted, {{error, Error}, RollbackResult}} ->
		?DEBUG("transaction failed: ~nerror ~p, rollback result ~p",
		       [Error, RollbackResult]),
		{error, Error#mysql_result.error}
	end,
    ?DEBUG("transaction Reply ~p", [Reply]),
    {reply, Reply, State};



handle_call({test_trans, SQLS}, _From,
	    #state{conn_pool = Write} = State)->

    ?DEBUG("SQLS ~p", [SQLS]),
    %% [S1|S2] = SQLS,
    %% Result = 
    %% 	mysql:transaction(
    %% 	  Write,
    %% 	  fun() -> mysql:fetch(?to_binary(S1)),
    %% 		   mysql:fetch(?to_binary(S2))
    %% 	  end),
    R = 
	mysql:transaction(
	  Write,
	  fun() -> mysql:fetch(<<"INSERT INTO inv_types(nam1) VALUES "
				 "('duan')">>),
		   mysql:fetch(<<"INSERT INTO colors(name) VALUES "
				 "('zishe')">>)

	  end),
    
    ?DEBUG("fetch_write with result ~p", [R]),

    {reply, R, State};
    
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


sql_result(_, [], [Values]) ->
    Values;
sql_result(_, [], Values) ->
    lists:reverse(Values);
sql_result(Fields, [RowValue|T], Values) ->
    sql_result(Fields, T, [{row_result(Fields, RowValue, [])}|Values]).

row_result([], [], KV) ->
    lists:reverse(KV);
row_result([Field|RestFields], [Value|RestValues], KV) ->
    %% ?DEBUG("value ~p", [Value]),
    FormatValue =
        case Value of
            {date, {Y, M, D}}->
                ?to_binary(
                  lists:flatten(
		    io_lib:format("~4..0w-~2..0w-~2..0w", [Y, M, D])));
	    {datetime, {{Y, M, D}, {H, Mi, S}}} ->
		?to_binary(
		   lists:flatten(
		     io_lib:format("~4..0w-~2..0w-~2..0w ~2..0w:~2..0w:~2..0w",
				   [Y, M, D, H, Mi, S])));
            undefined ->
                <<>>;
	    <<>> ->
		<<>>;
	    Value ->
		Value
        end,
    row_result(RestFields, RestValues, [{Field, FormatValue}|KV]).


exec_funs([], Res) ->
    Res;
exec_funs(_Funs, {error, Error}) ->
    throw({error,Error});
exec_funs([F|T], _Res)->
    exec_funs(T, F()).

start(Action, Sql) ->
    ?DEBUG("action ~p~nsql ~p", [Action, Sql]),
    Self = self(),
    spawn(?MODULE, wait, [conn, Self, {Action, Sql}]),
    receive
    	{Self, R} -> R
    after 5000 ->
    	    ?WARN("==== Sql timeout ======~n~p", [Sql]),
    	    {error, timeout}
    end.

wait(Pool, Parent, {Action, Sql}) ->
    ?DEBUG("wait with pool ~p, Action ~p", [Pool, Action]),
    case Action of
	read ->
	    R = read(Pool, ?to_b(Sql)),
	    %% timer:sleep(6000),
	    Parent ! {Parent, R};
	write ->
	    R = write(Pool, ?to_b(Sql)),
	    Parent ! {Parent, R};
	insert ->
	    R = insert(Pool, ?to_b(Sql)),
	    Parent ! {Parent, R};
	transaction  when is_list(Sql) ->
	    R = transaction(Pool, Sql),
	    Parent ! {Parent, R} 
    end.

read(Pool, Sql) ->
    Result =
        case mysql:fetch(Pool, Sql) of
            {data, #mysql_result{rows=[]}} ->
		{ok, []};

	    {data, #mysql_result{fieldinfo=FieldInfo, rows=Rows}} ->
                Fields = [Field || {_, Field, _, _} <- FieldInfo],
                %% ?DEBUG("fields ~p~nRows ~p", [Fields, Rows]),
                {ok, sql_result(Fields, Rows, [])};

            {error, #mysql_result{error=Error, errcode=ErrCode}} ->
                {error, {ErrCode, Error}}
        end,
    Result.

write(Pool, Sql) ->
    Result = 
	case mysql:fetch(Pool, Sql) of
	    {updated, #mysql_result{affectedrows=AffectedRows}} ->
		{ok, {write, AffectedRows}};
	    {error, #mysql_result{error=Error, errcode=ErrCode}} ->
		{error, {ErrCode, Error}}
	end,
    ?DEBUG("write with sql=~ts~nresult ~p", [Sql, Result]),

    Result.

insert(Pool, Sql) ->
    Result = 
	case mysql:fetch(Pool, Sql) of
	    {updated, #mysql_result{insertid=InsertId}} ->
		?DEBUG("insert id=~p", [InsertId]),
		{ok, InsertId};
	    {error, #mysql_result{error=Error, errcode=ErrCode}} ->
		{error, {ErrCode, Error}}
	end,
    ?DEBUG("fetch_write with sql=~ts~nresult ~p", [Sql, Result]),

    Result.


transaction(Pool, Sqls) ->
    Funs = 
    	lists:foldr(
    	  fun(Sql, Acc) ->
    		  [fun() -> mysql:fetch(?to_b(Sql)) end|Acc]
    	  end, [], Sqls),


    %% TransFun = fun() -> [F() || F <- Funs] end,
    TransFun = fun() -> exec_funs(Funs, []) end,

    Reply = 
	case mysql:transaction(Pool, TransFun) of
	    {atomic, Result} ->
		{ok, Result};
	    {aborted, {{error, Error}, RollbackResult}} ->
		?DEBUG("transaction failed: ~nerror ~p, rollback result ~p",
		       [Error, RollbackResult]),
		{error, Error#mysql_result.error}
	end,
    ?DEBUG("transaction Reply ~p", [Reply]),
    Reply.
