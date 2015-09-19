%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright Seasun (C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 27 Feb 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(tcp_reader).

-include("../../../include/knife.hrl").

-export([start_link/0, init/1]).
-export([start_connection/4]).

-record(state, {
	  parent,
	  sock
	 }).

start_link()->
    ?DEBUG("start a new reader to accept agent...", []),
    {ok, proc_lib:spawn_link(?MODULE, init, [self()])}.

sock_op(Sock, Fun)->
    case Fun(Sock) of
	{ok, Res} -> Res;
	{error, Reason} ->
	    ?ERROR("error on tcp connection ~p:~n~n", [self(), Reason]),
	    exit(normal)
    end.
	    
init(Parent)->
    receive
	{go, Sock, SockTransform, CallbackApp}->
	    start_connection(Parent, Sock, SockTransform, CallbackApp);
	Any ->
	    ?DEBUG("init: receive unkown message ~p, continue...", [Any]),
	    init(Parent)
    end.

start_connection(Parent, Sock, SockTransform, CallbackApp)->
    process_flag(trap_exit, true),
    
    ClientSock = sock_op(Sock, SockTransform),
    State = #state{parent = Parent, sock = ClientSock},
    
    {ok, {PeerHost, _PeerPort, _Host, Port}}
	= net_receiver:socket_ends(ClientSock, inbound),
    
    ?INFO("start to accept a new agent ~p on port ~p", [PeerHost, Port]),
    
    {ok, CallbackReader} =
	application:get_env(CallbackApp, callback_reader),
    try
	%% some callbacks require the relation of current process and remote host,
	%% so that the self application can use it
	?DEBUG("start to enter loop to receive message", []),
	apply(CallbackReader, handle_reader, [PeerHost, self()]),
	
	net_receiver:send(Sock, <<"handshake">>),
	%% peer port is format {192,168,0,1}, bu I want to "192.168.0.1",
	%% so, use ntoa to transfer
	recvloop(State, ?to_binary(inet_parse:ntoa(PeerHost)), CallbackReader)
    catch
	Ex -> 
	    case Ex of
		connection_closed_abruptly ->
		    ?WARN("closing TCP connection ~p:~p~n",[self(), Ex]);
		_ -> ?ERROR("closing TCP connection ~p:~p~n",[self(), Ex])
	    end
    after
	?DEBUG("sock of client ~p will be fast close ...", [PeerHost]),
	?WARN("sock of client ~p will be fast close ...", [PeerHost]),
	net_receiver:fast_close(ClientSock),

	%% client closed activitily
	apply(CallbackReader, handle_close, [PeerHost])
    end,
    done.

recvloop(State = #state{sock = Sock}, PeerHost, CallbackReader) ->
    ok = net_receiver:setopts(Sock, [{active, once}]),
    case net_receiver:recv(Sock) of
	{data, Data} ->
	    ?DEBUG("Recv Data ~p from ~p", [Data, PeerHost]),
	    DecodeData = ejson:decode(Data),
	    ?DEBUG("handle decode message = ~p", [DecodeData]),
	    handle_message(DecodeData, PeerHost, CallbackReader),
	    
	    recvloop(State, PeerHost, CallbackReader);
	closed ->
	    throw(connection_closed_abruptly);
	{error, Reason} ->
	    throw({inet_error, Reason});
	{other, Other} ->
	    ?DEBUG("read receive other message ~n~p", [Other]),
	    handle_other(Other, PeerHost, State, CallbackReader),
	    recvloop(State, PeerHost, CallbackReader)
    end.

handle_message(Message, PeerHost, CallbackReader) ->
    ?DEBUG("~p handle message ~n~p comes from ~p",
	   [CallbackReader, Message, PeerHost]),

    %% call the callback to handler message
    apply(CallbackReader, handle_message, [Message, PeerHost]).
    
handle_other(Message, PeerHost, #state{sock = Sock}, CallbackReader)->
    ?DEBUG("send message ~n~p to agent ~p", [Message, PeerHost]),
    CallbackReader:handle_nontcp_message(
      Message, Sock, fun net_receiver:send/2).
		


