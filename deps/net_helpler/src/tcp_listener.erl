%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright Seasun(C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 26 Feb 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(tcp_listener).

-include("../../../include/knife.hrl").

-behaviour(gen_server).

%% API
-export([start_link/8]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-define(SERVER, ?MODULE). 

-record(state, {sock, on_startup, on_shutdown, label}).

start_link(IPAddress, Port, SocketOpts,
	  ConcurrentAcceptorCount, AcceptorSup,
	   OnStartup, OnShutdown, Label) ->
    gen_server:start_link(
      ?MODULE, {IPAddress, Port, SocketOpts,
                ConcurrentAcceptorCount, AcceptorSup,
                OnStartup, OnShutdown, Label}, []).

init({IPAddress, Port, SocketOpts,
      ConcurrentAcceptorCount, AcceptorSup,
      OnStartup, OnShutdown, Label}) ->
    process_flag(trap_exit, true),
    ?DEBUG("Listen with argument SockOpts=~p~n, IPAddress=~p, AcceptorSup=~p~n",
	    [SocketOpts, IPAddress, AcceptorSup]),
    
    case gen_tcp:listen(Port, SocketOpts ++ [{ip, IPAddress},
    					     {active, false}]) of
	{ok, LSock} ->
	    lists:foreach(
	      fun(_) ->
		      {ok, _P} = supervisor:start_child(AcceptorSup, [LSock])
	      end, lists:duplicate(ConcurrentAcceptorCount, dummy)),
	    
	    {ok, {LIPAddress, LPort}} = inet:sockname(LSock),
	    ?INFO("start ~s on ~p on ~p with sock ~p~n",
		  
		    [Label, LIPAddress, LPort, LSock]),
	    {ok, #state{sock = LSock,
			on_startup = OnStartup,
			on_shutdown = OnShutdown,
			label = Label}};
	{error, Reason} ->
	    ?ERROR("failed to start ~s on ~p~n", [Label, IPAddress]),
	    {stop, {cannot_listen, IPAddress, Port, Reason}}
    end.

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

