%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright Seasun(C) 2014, buxianhui
%%% @doc
%%%  Dispatch message 
%%% @end
%%% Created :  5 Mar 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(forest_msg_dispatch).

-include("../../../include/knife.hrl").

-behaviour(gen_server).

-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-export([dispatch_message/1]).

-define(SERVER, ?MODULE). 

-record(state, {}).

%% API
dispatch_message(Payload)->
    ?FORMAT("dispatch message=~p~n", [Payload]),
    gen_server:call(?SERVER, Payload).

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

init([]) ->
    {ok, #state{}}.

handle_call({Target, Action}, _From, State) ->
    NewTarget = binary_to_term(Target),
    ?FORMAT("Receive Target=~p, Action=~p~n", [NewTarget, Action]),
    case forest_node:lookup(NewTarget) of
	{ok, [{_, Reader}|_]} ->
	    erlang:list_to_pid(Reader) ! {'$gen_call', {self(), Action}},
	    {reply, ok, State};
	{ok, []} ->
	    {reply, {target_not_exit, NewTarget}, State};
	{ok, Any} ->
	    {reply, Any, State}
    end;
    
handle_call(Request, _From, State) ->
    ?FORMAT("Receive unkown message = ~p~n", [Request]),
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

