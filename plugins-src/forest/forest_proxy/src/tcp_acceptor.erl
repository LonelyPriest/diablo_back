%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright Seasun(C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 26 Feb 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(tcp_acceptor).

-include("../../../include/knife.hrl").

-behaviour(gen_server).

-export([start_link/2]).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-define(SERVER, ?MODULE). 

-record(state, {callback, sock, ref}).

start_link(Callback, LSock) ->
    gen_server:start_link(?MODULE, {Callback, LSock}, []).


init({Callback, LSock}) ->
    gen_server:cast(self(), accept),
    {ok, #state{callback=Callback, sock=LSock}}.


handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

handle_cast(accept, State) ->
    accept(State);

handle_cast(_Msg, State) ->
    {noreply, State}.


handle_info({inet_async, LSock, Ref, {ok, Sock}},
            State = #state{callback={M,F,A}, sock=LSock, ref=Ref}) ->
    ?DEBUG("handle_info:inet_async with lsock=~p, sock=~p", [LSock, Sock]),
    %% patch up the socket so it looks like one we got from
    %% gen_tcp:accept/1
    {ok, Mod} = inet_db:lookup_socket(LSock),
    inet_db:register_socket(Sock, Mod),
    
    %% call forest_networking:start_client() to generater a child process to
    %% accept a new connection
    apply(M, F, A ++ [Sock]),
    
    %% accept more
    accept(State);

handle_info({inet_async, LSock, Ref, {error, closed}},
            State=#state{sock=LSock, ref=Ref}) ->
    %% It would be wrong to attempt to restart the acceptor when we
    %% know this will fail.
    {stop, normal, State};

handle_info({inet_async, LSock, Ref, {error, Reason}},
            State=#state{sock=LSock, ref=Ref}) ->
    {stop, {accept_failed, Reason}, State};

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.


accept(State = #state{sock=LSock}) ->
    io:format("start to accept...~n"),
    case prim_inet:async_accept(LSock, -1) of
	{ok, Ref} ->
	    io:format("accept new connection with sock=~p~n", [LSock]),
	    {noreply, State#state{ref=Ref}};
	Error     ->
	    {stop, {cannot_accept, Error}, State}
    end.
	    
