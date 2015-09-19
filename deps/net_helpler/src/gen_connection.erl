%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright Seasun(C) 2014, buxianhui
%%% @doc
%%%  A generation connection
%%% @end
%%% Created :  3 Mar 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(gen_connection).

-include("../../../include/knife.hrl").

-behaviour(gen_server).

-export([start_link/1]).
-export([reconnect/2, reconnect/3]).

-export([init/1, handle_call/3, handle_cast/2, terminate/2,
	handle_info/2, code_change/3]).

-record(state, {closing = false,
		callback_module,
		callback_module_state,
		net_params,
		reconnect_times}).

%% -----------------------------------------------------------------------------
%% Behaviour
%% -----------------------------------------------------------------------------
-callback init(list()) -> tuple().
-callback handle_cast(any(), any()) -> tuple().
-callback handle_info(any(), any()) -> tuple().
-callback terminate(any(), any()) -> ok.
-callback after_connect(any) -> ok. 

%% -----------------------------------------------------------------------------
%% Interface
%% -----------------------------------------------------------------------------
start_link(Mod) ->
    gen_server:start_link({local, Mod}, ?MODULE, [Mod], []).

init([Mod])->
    ok = timer:start(),
    
    {ok, CallbackModState, NetParams} = Mod:init([]),
    {ok, #state{callback_module = Mod,
		callback_module_state = CallbackModState,
		net_params = NetParams,
		reconnect_times = 0}}.

handle_call(connect, _From,
	    State0 = #state{callback_module = Mod,
			    net_params = NetParams}) ->
    {_, NewState0} = do_connect(Mod, NetParams, State0),
    {reply, ok, NewState0};


handle_call(Request, _From, State) ->
    {reply, Request, State}.

handle_cast(connect, State0 =
		#state{callback_module = Mod,
		       net_params = NetParams}) ->
    {_, NewState0} = do_connect(Mod, NetParams, State0),
    {noreply, NewState0};

handle_cast(Request,
	    #state{callback_module = Mod,
		   callback_module_state = CallbackModState} = State0)->
    ?DEBUG("receive cast msg ~p", [Request]),
    {ok, CallbackNewState} = Mod:handle_cast(Request, CallbackModState),
    {noreply, State0#state{callback_module_state = CallbackNewState}}.


handle_info({tcp, Socket, <<"handshake">>}, State0) ->
    {ok, {PeerHost, Port}} = inet:peername(Socket),
    ?INFO("congratulations, receive handshake from proxy ~p "
	  "on port ~p, Success to connected" , [PeerHost, Port]),
    {noreply, State0};

handle_info({tcp_closed, Socket}, #state{callback_module = Mod} = State0) ->
    ?WARN("tcp closed on socket ~p" , [Socket]),
    reconnect(interval, Mod),
    {noreply, State0};
    
handle_info({tcp, Socket, Message}, #state{callback_module = Mod,
			 callback_module_state = CallbackModState} = State0)->
    ?DEBUG("receive info msg ~p from socket ~p", [Message, Socket]),
    {ok, CallbackNewState} = Mod:handle_info(Message, CallbackModState),
    {noreply, State0#state{callback_module_state = CallbackNewState}}.

terminate(Reason, #state{callback_module = Mod,
			 callback_module_state = CallbackModState})->
    Mod:terminate(Reason, CallbackModState).

code_change(_OldVsn, State, _Extra)->
    {ok, State}.


%% =============================================================================
%% Internal functions
%% =============================================================================
do_connect(CallbackMod, {IPAddr, Port, Family, Timeout, TCPOptions},
	   #state{callback_module = CallbackMod,
		  reconnect_times = Times} = State0)->
    case gen_tcp:connect(IPAddr, Port, [Family|TCPOptions], Timeout) of
	{ok, Sock} ->
	    ?DEBUG("success to connect to server ~p with ~p times",
		   [IPAddr, Times]),
	    CallbackModState = CallbackMod:after_connect(Sock),
	    {ok, State0#state{
		   callback_module_state = CallbackModState,
		   reconnect_times = 0}};
	
	{error, _} = E ->
	    ?DEBUG("fail to connect Remote host ~p, error:~p", [IPAddr, E]),
	    reconnect(forever, Times, CallbackMod),
	    {error, State0#state{reconnect_times = Times + 1}}
	
    end.

reconnect(forever, Times, CallbackMod) ->
    ?WARN("the ~p times to reconnect after 3 seconds", [Times]),
    AfterTimes = ?INTERVAL_RECONNECT + Times * 2000,
    erlang:send_after(AfterTimes, CallbackMod, {'$gen_cast', connect}).

reconnect(interval, CallbackMod)->
    %% reconnect after 3 seconds
    ?WARN("reconnect after 3 seconds", []),
    erlang:send_after(?INTERVAL_RECONNECT, CallbackMod, {'$gen_cast', connect}).
