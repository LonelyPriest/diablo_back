%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright Seasun (C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 27 Feb 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(forest_reader).

-include("../../../include/knife.hrl").

-export([start_link/0, init/1]).
-export([start_connection/3]).

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
	    ?ERROR("error on forest connection ~p:~n~n", [self(), Reason]),
	    exit(normal)
    end.
	    
init(Parent)->
    receive
	{go, Sock, SockTransform}->
	    start_connection(Parent, Sock, SockTransform);
	Any ->
	    ?DEBUG("init: receive unkown message ~p, continue...", [Any]),
	    init(Parent)
    end.

start_connection(Parent, Sock, SockTransform)->
    process_flag(trap_exit, true),
    
    ClientSock = sock_op(Sock, SockTransform),
    State = #state{parent = Parent, sock = ClientSock},
    
    forest_net:send(Sock, <<"handshake">>),

    {ok, {PeerHost, _PeerPort, _Host, Port}}
	= forest_net:socket_ends(ClientSock, inbound),
    ?DEBUG("start_connection:start to "
	   "accept a new agent ~p on port ~p", [PeerHost, Port]),
    ?INFO("proxy start to "
	  "accept a new agent ~p on port ~p", [PeerHost, Port]),

    %% relationship of current socket and remote IP,
    %% when a message comes from certain IP, can find the valid socket by IP address
    ok = forest_node:insert(PeerHost, erlang:pid_to_list(self())),

    
    try
	%% peer port is format {192,168,0,1}, bu I want to "192.168.0.1",
	%% so, use ntoa to transfer
	recvloop(State, ?to_binary(inet_parse:ntoa(PeerHost)))
    catch
	Ex -> 
	    case Ex of
		connection_closed_abruptly ->
		    ?WARN("closing forest connection ~p:~p~n",[self(), Ex]);
		_ -> ?ERROR("closing forest connection ~p:~p~n",[self(), Ex])
	    end
    after
	?DEBUG("sock of client ~p will be fast close ...", [PeerHost]),
	?WARN("sock of client ~p will be fast close ...", [PeerHost]),
	forest_net:fast_close(ClientSock),

	%% client closed activitily
	forest_node:delete(PeerHost)
    end,
    done.

recvloop(State = #state{sock = Sock}, PeerHost) ->
    ok = forest_net:setopts(Sock, [{active, once}]),
    case forest_net:recv(Sock) of
	{data, Data} ->
	    ?DEBUG("Recv Data ~p from ~p", [Data, PeerHost]),
	    DecodeData = ejson:decode(Data),
	    ?DEBUG("handle decode message = ~p", [DecodeData]),
	    handle_agent_message(DecodeData, PeerHost),
	    recvloop(State, PeerHost);
	closed ->
	    throw(connection_closed_abruptly);
	{error, Reason} ->
	    throw({inet_error, Reason});
	{other, Other} ->
	    ?DEBUG("read receive other message ~n~p", [Other]),
	    handle_other(Other, PeerHost, State),
	    recvloop(State, PeerHost)
    end.

handle_agent_message({[{<<"task_id">>, TaskId},
		       {<<"sn">>, SN},
		       {<<"name">>, Name},
		       {<<"type">>, Type},
		       {<<"action">>, Status}]}  = Message, PeerHost) ->
    ?DEBUG("handle message ~n~p comes from agent ~p", [Message, PeerHost]),
    send_message(step_process,
		 {TaskId, PeerHost}, {SN, Name, Type, ?to_atom(Status)});

handle_agent_message({[{<<"task_id">>, TaskId},
		       {<<"sn">>, SN},
		       {<<"name">>, Name},
		       {<<"type">>, Type},
		       {<<"action">>, Status},
		       ECode, EInfo]} = Message, PeerHost) ->
    ?DEBUG("handle message = ~p comes from agent ~p", [Message, PeerHost]),
    send_message(step_process,
		 {TaskId, PeerHost},
		 {SN, Name, Type, ?to_atom(Status), ECode, EInfo}).
    
handle_other({to_agent, Message}, PeerHost, #state{sock = Sock})->
    ?DEBUG("send message ~n~p to agent ~p", [Message, PeerHost]),
    %% NewMessage = [{<<"from">>, pid_to_list(From)}|Message],
    EncodeMessage = ejson:encode({Message}),
    ?DEBUG("send json message = ~p", [EncodeMessage]),
    forest_net:send(Sock, EncodeMessage).


send_message(step_process, {TaskId, PeerHost}, Message) ->
    ?DEBUG("send_message: with prameters TaskId = ~p, PeerHost = ~p~n, Message = ~p",
	   [TaskId, PeerHost, Message]),
    case forest_target_proc:lookup(TaskId, PeerHost) of
	[] ->
	    ?DEBUG("There is no valid process on proxy to "
		   "assocaite task ~p and agent ~p", [TaskId, PeerHost]);
	[Process] ->
	    StepPid = list_to_pid(Process),
	    case erlang:is_process_alive(StepPid) of
		true ->
		    ?DEBUG("message ~p will send to ~p[~p]",
			   [Message, Process, PeerHost]),
		    StepPid !
			{ok, {TaskId, PeerHost}, Message};
		false ->
		    ?DEBUG("process ~p associate task ~p and agent ~p "
			    "was not alive", [Process, TaskId, PeerHost])
	    end
    end.
		


