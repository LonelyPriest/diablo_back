%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright SeasunGame(C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 24 May 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(controller_task_records).

-include("../../../include/knife.hrl").
-include("../include/controller.hrl").

-behaviour(gen_server).

%% API
-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

%% interface
-export([report/3, current_time/1]).

-define(SERVER, ?MODULE).

-record(state, {}).

%%%===================================================================
%%% API
%%%===================================================================

report(subtask, sql_record,
       {TaskId, SubtaskState, Target, StepId}) ->
    gen_server:cast(?SERVER, {record_subtask_to_sql_table,
			      {TaskId, SubtaskState, Target, StepId}});

report(task_detail, sql_record,
       {TaskId, Event, StepId, Target, TaskState}) ->
    gen_server:cast(?SERVER,
		    {record_task_detail_to_sql_table,
		     {TaskId, Event, StepId, Target, TaskState}});

report(task_state, sql_record, {TaskId, TaskState}) ->
    gen_server:cast(?SERVER,
		    {record_task_state_to_sql_table, TaskId, TaskState}).

%% =============================================================================
%% Callbacks
%% =============================================================================
start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).


init([]) ->
    {ok, #state{}}.

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.


handle_cast({record_subtask_to_sql_table,
	     {TaskId, SubtaskState, Target, StepId}}, State) ->
    %% subtask state is a character, transfer to number
    NumberState = knife_utils:step_life_cycle(?to_atom(SubtaskState)),
    
    %% record subtask, add a new record when target of the task does not exit,
    %% orelse update it
    Sql1 = "select id, ip from " ++ ?to_string(?TABLE_SUBTASKS)
	++ " where "
	++ "ip = \'" ++ ?to_string(Target) ++ "\'"
	++ " and "
	++ "deploy_task_id = " ++ ?to_string(TaskId) ++ ";",

    Sql2 = 
	case controller_mysql_access:fetch(read, ?to_binary(Sql1)) of
	    {ok, []} ->
		"insert into " ++ ?to_string(?TABLE_SUBTASKS)
		    ++
		    " (deploy_task_id, status, ip, current_step,"
		    " created_at, updated_at)"
		    ++ " values "
		    ++ " ("
		    ++ ?to_string(TaskId)         ++ ","
		    ++ ?to_string(NumberState)    ++ ","
		    ++ "\'" ++ ?to_string(Target) ++ "\',"
		    ++ ?to_string(StepId)         ++ ","
		    ++ ?to_string(current_time(db))    ++ ","
		    ++ ?to_string(current_time(db))
		    ++ ");";
	    {ok, _} ->
		"update " ++ ?to_string(?TABLE_SUBTASKS)
		    ++ " set "
		    ++ " status = " ++ ?to_string(NumberState) ++ ","
		    ++ " current_step = " ++ ?to_string(StepId) ++ ","
		    ++ " updated_at =" ++ ?to_string(current_time(db))
		    ++ " where "
		    ++ " ip = \'" ++ ?to_string(Target) ++ "\'"
		    ++ " and "
		    ++ " deploy_task_id = " ++ ?to_string(TaskId) ++ ";"
	end,

    case controller_mysql_access:fetch(write, ?to_binary(Sql2)) of
	{ok, {write, _}} ->
	    {noreply, State};
	{error, {ECode, EInfo}} ->
	    ?WARN("failed to refresh table ~p~n, code ~p, erro ~p",
		  [?to_string(?TABLE_SUBTASKS), ECode, EInfo]),
	    {noreply, State}
    end;

handle_cast({record_task_detail_to_sql_table,
	     {TaskId, Event, StepId, Target, Taskstate}}, State) ->
    Sql1 = "select id as subtask_id, ip from " ++ ?to_string(?TABLE_SUBTASKS)
	++ " where "
	++ "ip = \'" ++ ?to_string(Target) ++ "\'"
	++ " and "
	++ "deploy_task_id = " ++ ?to_string(TaskId) ++ ";",

    Sql2 = 
	case controller_mysql_access:fetch(read, ?to_binary(Sql1)) of
	    {ok, [[{<<"subtask_id">>, SubtaskId}, {<<"ip">>, _Ip}]]} ->
		
		"insert into " ++ ?to_string(?TABLE_EVENTS)
		    ++ " (deploy_task_id, ts, event, deploy_step_id, "
		    "deploy_subtask_id, status, created_at, updated_at)"
		    ++ " values "
		    ++ " ("
		    ++ ?to_string(TaskId)                          ++ ","
		    ++ ?to_string(current_time(db_unix_timestamp)) ++ ","
		    ++ "\'" ++ ?to_string(Event)                   ++ "\',"
		    ++ ?to_string(StepId)                          ++ ","
		    ++ ?to_string(SubtaskId)                       ++ ","
		    ++ ?to_string(
			  knife_utils:step_life_cycle(?to_atom(Taskstate))) ++ ","
		    ++ ?to_string(current_time(db))    ++ ","
		    ++ ?to_string(current_time(db))
		    ++ ");"
	end,

    case controller_mysql_access:fetch(write, ?to_binary(Sql2)) of
	{ok, {write, _}} ->
	    {noreply, State};
	{error, {ECode, EInfo}} ->
	    ?WARN("failed to refresh table ~p~n, code ~p, erro ~p",
		  [?to_string(?TABLE_EVENTS), ECode, EInfo]),
	    {noreply, State}
    end;

handle_cast({record_task_state_to_sql_table, TaskId, TaskState}, State) ->
    Sql = "update " ++ ?to_string(?TABLE_TASKS)
	++ " set "
	++ " status = "
	++ ?to_string(knife_utils:task_life_cycle(?to_atom(TaskState))) ++ ","
	++ " updated_at =" ++ ?to_string(current_time(db))
	++ " where "
	++ " id = "  ++ ?to_string(TaskId) ++ ";",
    case controller_mysql_access:fetch(write, ?to_binary(Sql)) of
	{ok, {write, _}} ->
	    {noreply, State};
	{error, {ECode, EInfo}} ->
	    ?WARN("failed to refresh table ~p~n, code ~p, erro ~p",
		  [?to_string(?TABLE_EVENTS), ECode, EInfo]),
	    {noreply, State}
    end;
	

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

%%--------------------------------------------------------------------
%% @desc : get current time
%% @return: format yyyymmddhhmmsss
%%--------------------------------------------------------------------
current_time(localtime) ->
    {{Year, Month, Date}, {Hour, Minute, Second}} =
	calendar:now_to_local_time(erlang:now()),
    
    lists:flatten(
      io_lib:format("~4..0w~2..0w~2..0w~2..0w~2..0w~2..0w",
		    [Year, Month, Date, Hour, Minute, Second]));

current_time(timestamp) ->
    {M, S, _} = erlang:now(),
    
    M * 1000000 + S;

current_time(db) ->
    "CURRENT_TIMESTAMP()";

current_time(db_unix_timestamp) ->
    "UNIX_TIMESTAMP()".

