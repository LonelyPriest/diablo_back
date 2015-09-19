%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@kins.com>
%%% @copyright Seasun(C) 2014, buxianhui
%%% @doc
%%%  Net utily function
%%% @end
%%% Created : 26 Feb 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(forest_net).

-include("../../../include/knife.hrl").

-compile(export_all).

%%--------------------------------------------------------------------
%% @doc:  switch pid to receive socket data
%% @spec
%% @end
%%--------------------------------------------------------------------
controlling_process(Sock, Pid) when is_port(Sock) ->
    ?DEBUG("socket ~p transfer to process ~p to receive~n", [Sock,Pid]),
    gen_tcp:controlling_process(Sock, Pid).

recv(Sock) when is_port(Sock)->
    ?DEBUG("start to recv sock no param", []),
    recv(Sock, {tcp, tcp_closed, tcp_error}).

recv(S, {DataTag, ClosedTag, ErrorTag}) ->
    receive
	{DataTag, S, Data}    ->
	    {data, Data};
	{ClosedTag, S}        ->
	    closed;
	{ErrorTag, S, Reason} ->
	    {error, Reason};
	Other                 ->
	    {other, Other}
    end.

send(Sock, Data) when is_port(Sock) ->
    ?DEBUG("start to send data ~p to socket ~p~n", [Sock, Data]),
    gen_tcp:send(Sock, Data).


setopts(Sock, Options) when is_port(Sock) ->
    inet:setopts(Sock, Options).

getopts(Sock, Options) when is_port(Sock) ->
    inet:getopts(Sock, Options).


socket_ends(Sock, Direction) ->
    {From, To} = sock_funs(Direction),
    case {From(Sock), To(Sock)} of
        {{ok, {FromAddress, FromPort}}, {ok, {ToAddress, ToPort}}} ->
            {ok, {FromAddress, FromPort, ToAddress, ToPort}};
	{{error, _Reason} = Error, _} ->
            Error;
        {_, {error, _Reason} = Error} ->
            Error
    end.

maybe_ntoab(Addr) when is_tuple(Addr) -> rabbit_misc:ntoab(Addr);
maybe_ntoab(Host)                     -> Host.

peername(Sock)   when is_port(Sock) ->
     inet:peername(Sock).
sockname(Sock)   when is_port(Sock) ->
     inet:sockname(Sock).

sock_funs(inbound)  -> {fun peername/1, fun sockname/1};
sock_funs(outbound) -> {fun sockname/1, fun peername/1}.


          

close(Sock) when is_port(Sock) ->
    gen_tcp:close(Sock).

fast_close(Sock) when is_port(Sock) ->
    catch port_close(Sock),
    ok.
