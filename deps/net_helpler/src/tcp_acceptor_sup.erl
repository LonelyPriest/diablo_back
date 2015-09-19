%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright Seasun(C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 26 Feb 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(tcp_acceptor_sup).

-behaviour(supervisor).

-export([start_link/2]).

-export([init/1]).

start_link(Name, Callback) ->
    %% callback = {net_working, start_client, []}
    supervisor:start_link({local, Name}, ?MODULE, Callback).

init(Callback) ->
    {ok, {{simple_one_for_one, 10, 10},
          [{tcp_acceptor, {tcp_acceptor, start_link, [Callback]},
            transient, brutal_kill, worker, [tcp_acceptor]}]}}.

