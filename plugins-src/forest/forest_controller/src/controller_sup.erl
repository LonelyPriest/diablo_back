%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright SeasunGame(C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 19 Mar 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(controller_sup).

-behaviour(supervisor).

%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).

-define(SERVER, ?MODULE).

%%%===================================================================
%%% API functions
%%%===================================================================

start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

%%%===================================================================
%%% Supervisor callbacks
%%%===================================================================

init([]) ->
    RestartStrategy = one_for_one,
    MaxRestarts = 1000,
    MaxSecondsBetweenRestarts = 3600,

    SupFlags = {RestartStrategy, MaxRestarts, MaxSecondsBetweenRestarts},

    Restart = permanent,
    Shutdown = 2000,
    Type = worker,

    MQHandler = {controller_mq, {controller_mq_handler, start_link, []},
		 Restart, Shutdown, Type, [controller_mq_haneler]},    
    
    TaskHandler = {controller_task, {controller_tasks, start_link, []},
		   Restart, Shutdown, Type, [controller_tasks]},
    
    TaskProc = {controller_task_proc, {controller_task_proc, start_link, []},
     			  Restart, Shutdown, Type, [controller_task_proc]},

    TaskMonitor = {controller_task_monitor, {controller_task_monitor_sup, start_link, []},
		   Restart, Shutdown, supervisor, [controller_task_monitor_sup]},

    MySqlHandler = {controller_mysql_access, {controller_mysql_access, start_link, []},
		    Restart, Shutdown, Type, [controller_mysql_access]},

    TableHandler = {controller_mysql_table, {controller_mysql_table, start_link, []},
		   Restart, Shutdown, Type, [controller_mysql_table]},

    TaskRecords = {controller_task_records, {controller_task_records, start_link, []},
		    Restart, Shutdown, Type, [controller_task_records]},


    TaskState = {controller_task_state, {controller_task_state, start_link, []},
		    Restart, Shutdown, Type, [controller_task_state]},

    MaskAlarm = {controller_mask_alarm, {controller_mask_alarm, start_link, []},
		    Restart, Shutdown, Type, [controller_mask_alarm]},

    

    {ok, {SupFlags, [MQHandler, TaskHandler, TaskMonitor, TaskProc,
		     MySqlHandler, TableHandler, TaskRecords, TaskState,
		     MaskAlarm]}}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
