%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright Seasun Co, Ltd(C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 26 Feb 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(forest_client_sup).

-behaviour(supervisor_new).

%% API
-export([start_link/1, start_link/2]).

%% Supervisor callbacks
-export([init/1]).

-define(SERVER, ?MODULE).

start_link(Callback) ->
    supervisor_new:start_link(?MODULE, Callback).

start_link(SupName, Callback) ->
    %% callback = [forest_connection_sup, start_link, []]
    supervisor_new:start_link(SupName, ?MODULE, Callback).

init({M, F, A}) ->
    {ok, {{simple_one_for_one_terminate, 0, 1},
          [{client, {M,F,A}, temporary, infinity, supervisor, [M]}]}}.

