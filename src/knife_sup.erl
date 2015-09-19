%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright Seasun(C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 28 Feb 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(knife_sup).

-behaviour(supervisor).

%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).

-define(SERVER, ?MODULE).

start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

init([]) ->
    {ok, {{one_for_one, 3, 3},
	  [
	   {knife_log, {knife_log, start_link, []},
	     transient, 2000, worker, [knife]}
	  ]
	 }
    }.

