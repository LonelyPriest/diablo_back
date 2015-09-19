%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright Seasungame(C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 20 Jun 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_controller).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

%%%===================================================================
%%% Application callbacks
%%%===================================================================
start(normal, _StartArgs) ->
    case diablo_controller_sup:start_link() of
	{ok, Pid} ->
	    true = register(diablo_controller, self()),
	    %% ok = diablo_controller_mq_handler:connect(),
	    ok = diablo_controller_http_server:start(),

	    %% init right data
	    %% ok = diablo_controller_right_init:init(),
	    {ok, Pid};
	Error ->
	    Error
		end.


stop(_State) ->
    ok.

%%%===================================================================
%%% Internal functions
%%%===================================================================
