%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright Seasun Co, Ltd(C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 26 Feb 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(forest_connection_sup).

-behaviour(supervisor_new).

-export([start_link/0, reader/1]).

-export([init/1]).

-include("../../../include/knife.hrl").

start_link() ->
    {ok, SupPid} = supervisor_new:start_link(?MODULE, []),
    {ok, ReaderPid} =
	supervisor_new:start_child(
	  SupPid,
	  {reader, {forest_reader, start_link, []},
	  intrinsic, ?KNIFE_MAX_WAIT, worker, [forest_reader]}
	 ),
    {ok, SupPid, ReaderPid}.

reader(Pid) ->
    hd(supervisor_new:find_child(Pid, reader)).

init([]) ->
    {ok, {{one_for_all, 0, 1}, []}}.

