%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright Seasun(C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created :  4 Mar 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(forest_node_sup).

-behaviour(supervisor).

%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).

-define(SERVER, ?MODULE).

start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

init([]) ->
    RestartStrategy = one_for_one,
    MaxRestarts = 1000,
    MaxSecondsBetweenRestarts = 3600,

    SupFlags = {RestartStrategy, MaxRestarts, MaxSecondsBetweenRestarts},

    Restart = permanent,
    Shutdown = 2000,
    Type = worker,

    ForestNode = {forest_node, {forest_node, start_link, []},
		  Restart, Shutdown, Type, [forest_node]},
    
    %% MQHandler = {direct_mq_handler, {forest_mq_handler, start_link, []},
    %% 		 Restart, Shutdown, Type, [forest_mq_handler]},

    MsgDispatcher = {msg_dispatcher, {forest_msg_dispatch, start_link, []},
		     Restart, Shutdown, Type, [forest_msg_dispatch]},

    FanoutMQHandler = {fanout_mq_handler,
		       {forest_fanout_mq_handler, start_link, []},
		       Restart, Shutdown, Type, [forest_fanout_mq_handler]},
    
    ForestStep = {forest_step, {forest_step, start_link, []},
		      Restart, Shutdown, Type, [forest_step]},

    ForestTargetProc = {forest_target_proc, {forest_target_proc, start_link, []},
    			  Restart, Shutdown, Type, [forest_target_proc]},

    ForestTargetState = {forest_target_state, {forest_target_state, start_link, []},
    			  Restart, Shutdown, Type, [forest_target_state]},

    {ok, {SupFlags, [ForestNode, FanoutMQHandler,
		     MsgDispatcher, ForestStep,
		     ForestTargetProc, ForestTargetState]}}.
