%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright Seasun(C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created :  6 Mar 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_controller_mq_handler).

-include("../../../../include/knife.hrl").

-behaviour(gen_mq_handler).

-export([start_link/0, publish/2]).
-export([init/1, handle_message/1, send_queue_info/2,
	 connect/0, close/0]).

-record(gen_mod_state,
	{diablo_proxy_exchange=undefined,
	 diablo_proxy_routing_key=undefined
	 }).

close() ->
    ok = gen_server:cast(?MODULE, close),
    ok.

connect() ->
    gen_server:cast(?MODULE, connect),
    ok.

start_link()->
    {ok, RabbitHost}    = application:get_env(diablo_controller, rabbit_host),
    {ok, RabbitPort}    = application:get_env(diablo_controller, rabbit_listen_port),
    
    {ok, DirectX}       = application:get_env(diablo_controller, direct_exchange),
    {ok, Queue}         = application:get_env(diablo_controller, queue_for_controller),
    {ok, RouteToProxy}  = application:get_env(diablo_controller, route_to_proxy),
    
    Params = {RabbitHost,
	      RabbitPort,
	      DirectX,
	      Queue},
    State = #gen_mod_state
	{
	 diablo_proxy_exchange = DirectX,
	 diablo_proxy_routing_key = RouteToProxy},
    
    gen_mq_handler:start_link(?MODULE, Params, State).

init({Host, Port, Exchange, ConsumeQueue})->
    {direct, Host, Port, Exchange, ConsumeQueue}.

handle_message({Message}) ->
    %% process_flag(trap_exit, true),
    ?DEBUG("receive message ~p", [Message]),
    diablo_controller_vm:process(response, Message);

handle_message(Message) ->
    %% process_flag(trap_exit, true),
    ?DEBUG("receive message ~p", [Message]).

publish(direct, Message) ->
    gen_mq_handler:send_message(?MODULE, {direct, Message}).

send_queue_info(
  direct, #gen_mod_state{diablo_proxy_exchange = X,
			 diablo_proxy_routing_key = RoutingKey}) ->
    {X, RoutingKey}.

