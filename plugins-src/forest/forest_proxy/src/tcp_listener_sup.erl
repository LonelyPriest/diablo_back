%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright Seasun (C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 26 Feb 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(tcp_listener_sup).

-behaviour(supervisor).

%% API
-export([start_link/7, start_link/8]).

%% Supervisor callbacks
-export([init/1]).

-define(SERVER, ?MODULE).

start_link(IPAddress, Port,SocketOpts, OnStartup, OnShutdown,
	  AcceptCallback, Label) ->
    start_link(IPAddress, Port, SocketOpts, OnStartup, OnShutdown,
	      AcceptCallback, 1, Label).

start_link(IPAddress, Port, SocketOpts, OnStartup, OnShutdown,
	  AcceptCallback, ConcurrentAcceptorCount, Label) ->
    supervisor:start_link(
      ?MODULE, {IPAddress, Port, SocketOpts, OnStartup, OnShutdown,
	       AcceptCallback, ConcurrentAcceptorCount, Label}).

init({IPAddress, Port, SocketOpts, OnStartup, OnShutdown,
     AcceptCallback, ConcurrentAcceptorCount, Label}) ->
    Name = forest_utils:tcp_name(tcp_acceptor_sup, IPAddress, Port),
    {ok, {{one_for_all, 10, 10},
          [{tcp_acceptor_sup, {tcp_acceptor_sup, start_link,
                               [Name, AcceptCallback]},
            transient, infinity, supervisor, [tcp_acceptor_sup]},
           {tcp_listener, {tcp_listener, start_link,
                           [IPAddress, Port, SocketOpts,
                            ConcurrentAcceptorCount, Name,
                            OnStartup, OnShutdown, Label]},
            transient, 16#ffffffff, worker, [tcp_listener]}]}}.
