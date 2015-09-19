%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright Seasun(C) 2014, buxianhui
%%% @doc
%%%  A gen for connection to forest proxy
%%% @end
%%% Created :  3 Mar 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(forest_gen_connection).

-include("../../../include/knife.hrl").

-behaviour(gen_server).

-export([start_link/1, info/2]).

-export([init/1, handle_call/3, handle_cast/2, terminate/2,
	handle_info/2, code_change/3]).

-record(state, {closing = false,
		module,
		module_state,
		forest_params}).

%% -----------------------------------------------------------------------------
%% Behaviour
%% -----------------------------------------------------------------------------
-callback init(list()) -> tuple().
-callback terminate(any(), any()) -> ok.
-callback handle_message(any(), any()) -> tuple().
-callback connect(tuple(), any()) -> {ok, tuple()} .
-callback connect() -> ok .
-callback close() -> ok. 

%% -----------------------------------------------------------------------------
%% Interface
%% -----------------------------------------------------------------------------
start_link(Mod) ->
    gen_server:start_link({local, Mod}, ?MODULE, [Mod], []).

info(Pid, Items)->
    gen_server:call(Pid, {info, Items}, infinity).



%% behaviour_info(callbacks)->
%%     [
%%      {init, 1},
%%      {terminate, 2},
%%      {handle_message, 2},
%%      {connect, 2}
%%     ];


%% behaviour_info(_Other) ->
%%     undefined.


init([Mod])->
    process_flag(trap_exit, true),
    {ok, MState, ForestParams} = Mod:init([]),
    {ok, #state{module = Mod,
		module_state = MState,
		forest_params = ForestParams}}.

handle_call(connect, _From,
	    State0 = #state{module = Mod,
			    module_state = MState,
			    forest_params = ForestParams}) ->
    case Mod:connect(ForestParams, MState) of
	{ok, NewMState} ->
	    {reply, {ok, self()}, State0#state{module_state = NewMState}};
	{error, _} = Error ->
	    {stop, {shutdown, Error}, Error, State0}
    end;

handle_call(Request, _From, State) ->
    {reply, Request, State}.

handle_cast(connect, State0 =
		#state{module = Mod,
		       module_state = MState,
		       forest_params = ForestParams}) ->
    case Mod:connect(ForestParams, MState) of
	{ok, NewMState} ->
	    {noreply, State0#state{module_state = NewMState}};
	{error, _} = Error ->
	    {stop, {shutdown, Error}, State0}
    end;

handle_cast(Request, #state{module = Mod,
			    module_state = MState} = State)->
    ?DEBUG("receive cast msg ~p", [Request]),
    {ok, NewMState} = Mod:handle_message(Request, MState),
    {noreply, State#state{module_state = NewMState}}.


handle_info(Info, State)->
    ?DEBUG("receive unkown info msg ~p", [Info]),
    ?WARN("receive unkown info msg ~p", [Info]),
    {noreply, State}.

terminate(Reason, #state{module = Mod, module_state = MState})->
    Mod:terminate(Reason, MState).

code_change(_OldVsn, State, _Extra)->
    {ok, State}.
