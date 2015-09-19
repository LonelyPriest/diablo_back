%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright SeasunGame(C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 18 Jun 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(net_helper_sup).

-behaviour(supervisor).

-export([start_link/0, start_child/1,
	 start_child/2, start_child/3,
	 start_supervisor_child/1,
	 start_supervisor_child/2,
	 start_supervisor_child/3,
	 stop_child/1]).

-export([init/1]).

-include("net.hrl").

-define(SERVER, ?MODULE).


start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

start_child(Mod) -> start_child(Mod, []).

start_child(Mod, Args) -> start_child(Mod, Mod, Args).

start_child(ChildId, Mod, Args) ->
    child_reply(supervisor:start_child(
		  ?SERVER,
		  {ChildId, {Mod, start_link, Args},
		  transient, ?MAX_WAIT, worker, [Mod]})).

start_supervisor_child(Mod) ->
    start_supervisor_child(Mod, []).

start_supervisor_child(Mod, Args) ->
    start_supervisor_child(Mod, Mod, Args).

start_supervisor_child(ChildId, Mod, Args) ->
    child_reply(supervisor:start_child(
		  ?SERVER,
		  {ChildId, {Mod, start_link, Args},
		  transient, infinity, supervisor, [Mod]}
		 )).

stop_child(ChildId) ->
    case supervisor:terminate_child(?SERVER, ChildId) of
        ok ->
	    supervisor:delete_child(?SERVER, ChildId);
	E  -> E
    end.

init([]) ->
    {ok, {{one_for_all, 0, 1}, []}}.

child_reply({ok, _}) -> ok;
child_reply(X)       -> X.
