%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright SeasunGame(C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 19 Mar 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(controller).

-include("../../../include/knife.hrl").

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1, boot/0]).

boot() ->
    knife_utils:start_it(
      fun() ->
	      ok = knife_utils:ensure_application_loaded(mnesia),
	      ok = knife_utils:start_applications([controller])
      end
     ).

start(_StartType, _StartArgs) ->
    %% mnesia first
    ok = knife_utils:ensure_application_loaded(mnesia),
    ok = knife_utils:start_applications([mnesia]),
    ok = controller_mnesia:init(),
    %% ok = knife_utils:ensure_application_loaded(controller),

    %% start supervisor tree
    case controller_sup:start_link() of
	{ok, Pid} ->
	    true = register(controller, self()),
	    ok = controller_mq_handler:connect(),
	    {ok, Pid};
	Error ->
	    Error
    end.

    
stop(normal) ->
    io:format("Stoping ~p ~n", [?MODULE]),
    ?INFO("Stoping ~p with state normal~n", [?MODULE]),
    controller_mq_handler:close(),
    controller_mnesia:stop_mnesia(),
    ok;
stop(_State) ->
    ok.



%%%===================================================================
%%% Internal functions
%%%===================================================================
