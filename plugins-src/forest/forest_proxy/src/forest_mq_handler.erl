%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright Seasun(C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created :  6 Mar 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(forest_mq_handler).

-include("../../../include/knife.hrl").

-behaviour(gen_mq_handler).

-export([start_link/0, init/1, handle_message/1, send_queue_info/2,
	 publish/2]).

-record(gen_mod_state,
	{
	  publish_direct_exchange=undefined,
	  publish_direct_routing_key=undefined}).

start_link()->
    AmqpParams = {"10.20.96.160",
		  5672,
		  <<"deploy.direct">>,
		  <<"deploy.proxy.direct">>},

    State = #gen_mod_state{
      publish_direct_exchange = <<"deploy.direct">>,
      publish_direct_routing_key = <<"deploy.control.direct">>
     },
    
    gen_mq_handler:start_link(?MODULE, AmqpParams, State).

init({Host, Port, Exchange, Queue})->
    gen_mq_handler:amqp_setup_init(direct, Host, Port, Exchange, Queue).    

handle_message(Message) ->
    ?FORMAT("Receive Message=~p~n", [Message]).
    %%Result = forest_msg_dispatch:dispatch_message(Message),
    %%?FORMAT("dispatch result = ~p~n", [Result]).

send_queue_info(direct, #gen_mod_state{
		  publish_direct_exchange = X, 
		  publish_direct_routing_key = RoutingKey}) ->
    {X, RoutingKey}.

publish(direct, Message) ->
    gen_mq_handler:send_message(?MODULE, {direct, Message}).
