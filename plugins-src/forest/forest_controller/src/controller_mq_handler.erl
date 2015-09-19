%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright Seasun(C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created :  6 Mar 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(controller_mq_handler).

-include("../../../include/knife.hrl").

-behaviour(gen_mq_handler).

-export([start_link/0, publish/2]).
-export([init/1, handle_message/1, send_queue_info/2,
	 connect/0, close/0]).

-record(gen_mod_state,
	{publish_fanout_exchange=undefined,
	 %% publish_fanout_queue=undefined,
	 publish_fanout_routing_key=undefined,
	 
	 publish_direct_exchange=undefined,
	 %% publish_direct_queue=undefined,
	 publish_direct_routing_key=undefined}).

close() ->
    ok = gen_server:cast(?MODULE, close),
    ok.

connect() ->
    gen_server:cast(?MODULE, connect),
    %% erlang:send_after(?INTERVAL_RECONNECT, ?MODULE, {'$gen_cast', connect}),
    ok.

start_link()->
    {ok, RabbitHost} = application:get_env(controller, rabbit_host),
    {ok, RabbitPort} = application:get_env(controller, rabbit_listen_port),
    {ok, DirectX} = application:get_env(controller, deploy_direct_exchange),
    {ok, FanoutX} = application:get_env(controller, deploy_fanout_exchange),
    {ok, QueueOfController} = application:get_env(controller, queue_for_controller),
    {ok, ProxyFanoutRoute} = application:get_env(controller, route_key_to_proxy_fanout),
    {ok, WebServerRoute} = application:get_env(controller, route_key_to_webserver),
    
    Params = {RabbitHost,
	      RabbitPort,
	      DirectX,
	      QueueOfController},
    State = #gen_mod_state
	{publish_fanout_exchange = FanoutX,
	 publish_fanout_routing_key = ProxyFanoutRoute,
	 publish_direct_exchange = DirectX,
	 publish_direct_routing_key = WebServerRoute},
    
    gen_mq_handler:start_link(?MODULE, Params, State).

init({Host, Port, _Exchange, ConsumeQueue})->
    %% gen_mq_handler:amqp_setup_init(
    %%   direct, Host, Port, Exchange, ConsumeQueue),
    %% gen_mq_handler:amqp_setup_init(
    %%   direct, Host, Port, ConsumeQueue).
    {direct, Host, Port, ConsumeQueue}.

handle_message(Message) ->
    process_flag(trap_exit, true),
    proc_lib:spawn(
      controller_msg_dispatch, dispatch, [Message]).
    %% controller_msg_dispatch:dispatch(Message).

publish(direct, Message) ->
    gen_mq_handler:send_message(?MODULE, {direct, Message});
publish(fanout, Message) ->
    gen_mq_handler:send_message(?MODULE, {fanout, Message}).

send_queue_info(direct,
		#gen_mod_state{publish_direct_exchange = _X,
			       %% publish_direct_queue = Queue,
			       publish_direct_routing_key = RoutingKey}) ->
    {<<>>, RoutingKey};
send_queue_info(fanout,
		#gen_mod_state{publish_fanout_exchange = X,
			       %% publish_fanout_queue = Queue,
			       publish_fanout_routing_key = RoutingKey}) ->
    {X, RoutingKey}.
