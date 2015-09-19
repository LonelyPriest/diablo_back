%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright Seasun(C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created :  5 Mar 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(forest_agent_sup).

-behaviour(supervisor).

%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).
-export([start_child/2]).

-define(SERVER, ?MODULE).


start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

start_child(Child, Params) ->
    supervisor:start_child(?SERVER,
			   {Child, {Child, start_link, [Params]},
			    permanent, 2000, worker, [Child]}).

init([]) ->
    RestartStrategy = one_for_one,
    MaxRestarts = 1000,
    MaxSecondsBetweenRestarts = 3600,

    SupFlags = {RestartStrategy, MaxRestarts, MaxSecondsBetweenRestarts},

    Restart = permanent,
    Shutdown = 2000,
    Type = worker,

    Connection = {forest_connection, {forest_connection, start_link, []},
	      Restart, Shutdown, Type, [forest_connection]},
    
    %% Action = {forest_action, {forest_action, start_link, []},
    %% 	     Restart, Shutdown, Type, [forest_action]},

    {ok, {SupFlags, [Connection]}}.

