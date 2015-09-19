%%%-------------------------------------------------------------------
%%% @author buxianhui
%%% @copyright (C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 27 Feb 2014 by buxianhui
%%%-------------------------------------------------------------------
-module(forest).

-include("../../../include/knife.hrl").

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

-export([boot/0]).


boot()->
    knife_utils:start_it(
      fun()->
	      ok = knife_utils:ensure_application_loaded(forest),
	      ok = knife_utils:start_applications([forest])
      end).

%%%===================================================================
%%% Application callbacks
%%%===================================================================

start(_StartType, _StartArgs) ->
    ok = knife_utils:ensure_application_loaded(forest),
    case forest_sup:start_link() of
	{ok, Pid} ->
	    %% register self
	    true = register(forest, self()),

	    %% start networking
	    forest_networking:boot(),

	    %% connect to amqp
	    forest_fanout_mq_handler:connect(),
	    
	    {ok, Pid};
	Error ->
	    Error
		end.


stop(normal) ->
    io:format("Stoping ~p ~n", [?MODULE]),
    ?INFO("Stoping ~p with state normal~n", [?MODULE]),
    forest_fanout_mq_handler:close(),
    ok;

stop(_State) ->
    ok.

