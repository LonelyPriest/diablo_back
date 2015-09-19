%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright Seasun(C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created :  6 Mar 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(forest_fanout_mq_handler).

-include("../../../include/knife.hrl").

-behaviour(gen_mq_handler).

-export([start_link/0, init/1, handle_message/1, send_queue_info/2,
	 publish/2, connect/0, close/0]).

-record(gen_mod_state,
	{
	  publish_direct_exchange=undefined,
	  publish_direct_routing_key=undefined
	}).


close() ->
    ok = gen_server:cast(?MODULE, close),
    ok.

connect() ->
    gen_server:cast(?MODULE, connect),
    %% erlang:send_after(?INTERVAL_RECONNECT, ?MODULE, {'$gen_cast', connect}),
    ok.

start_link()->
    {ok, RabbitHost} = application:get_env(forest, rabbit_host),
    {ok, RabbitPort} = application:get_env(forest, rabbit_listen_port),
    {ok, DirectX} = application:get_env(forest, deploy_direct_exchange),
    {ok, FanoutX} = application:get_env(forest, deploy_fanout_exchange),
    {ok, QueueOfProxy} = application:get_env(forest, queue_for_proxy),
    {ok, RouteToController} = application:get_env(forest, route_key_to_controller),
    
    AmqpParams = {RabbitHost,
		  RabbitPort,
		  FanoutX,
		  QueueOfProxy},

    State = #gen_mod_state{
      publish_direct_exchange = DirectX,
      publish_direct_routing_key = RouteToController
     },
    
    gen_mq_handler:start_link(?MODULE, AmqpParams, State).

init({Host, Port, Exchange, Queue})->
    ?DEBUG("init: with pramters-> Host=~p, Port=~p, Exchange=~p, Queue=~p",
	  [Host, Port, Exchange, Queue]),
    %% gen_mq_handler:amqp_setup_init(fanout, Host, Port, Exchange, Queue).
    {fanout, Host, Port, Exchange, Queue}.

handle_message(Message) ->
    ?DEBUG("Receive Message ~n ~p", [Message]),
    ok = forest_step:process(step, Message),
    ok.

%% handle_message(Message) ->
%%     ?FORMAT("Receive unkown Message=~p", [Message]).

send_queue_info(direct, #gen_mod_state{
		  publish_direct_exchange = _X, 
		  publish_direct_routing_key = RoutingKey}) ->
    %% use default exchange
    {<<>>, RoutingKey}.

publish(direct, Message) ->
    gen_mq_handler:send_message(?MODULE, {direct, Message}).

%% =============================================================================
%% internal interface
%% =============================================================================
