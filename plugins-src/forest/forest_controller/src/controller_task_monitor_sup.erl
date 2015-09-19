%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright SeasunGame(C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 19 Mar 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(controller_task_monitor_sup).

-behaviour(supervisor).

%% API
-export([start_link/0, start_child/3]).

%% Supervisor callbacks
-export([init/1]).

-define(SERVER, ?MODULE).

start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

start_child(Parent, Task, TaskId) ->
    supervisor:start_child(?SERVER, [Parent, Task, TaskId]).

init([]) ->
    {ok, {{simple_one_for_one, 0, 1},
	  [
	   {controller_task_monitor, {controller_task_monitor, start_link, []},
	    temporary, brutal_kill, worker,  [controller_task_monitor]}
	  ]}}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
