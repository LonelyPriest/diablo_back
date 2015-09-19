%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright Seasun(C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created :  5 Mar 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(forest_agent).

-include("../../../include/knife.hrl").

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

-export([boot/0]).

boot()->
    knife_utils:start_it(
      fun()->
	      ok = knife_utils:ensure_application_loaded(forest_agent),
	      ok = knife_utils:start_applications([forest_agent])
      end).

start(_StartType, _StartArgs) ->
    case forest_agent_sup:start_link() of
	{ok, Pid} ->
	    true = register(forest_agent, self()),
	    forest_connection:connect(),
	    {ok, Pid};
	Error ->
	    Error
		end.


stop(normal) ->
    io:format("Stoping ~p ~n", [?MODULE]),
    ?INFO("Stoping ~p with state normal~n", [?MODULE]),
    forest_connection:close(),
    ok;

stop(_State) ->
    ok.

%%%===================================================================
%%% Internal functions
%%%===================================================================
