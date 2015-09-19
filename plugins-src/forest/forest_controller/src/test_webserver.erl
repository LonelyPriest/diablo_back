%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created :  4 Mar 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(test_webserver).

-behaviour(gen_mq_handler).

%% API
-export([start_link/0]).

-export([init/1, handle_message/1, send_queue_info/2,
	 publish/0]).

-define(SERVER, ?MODULE). 

-record(gen_mod_state,
	{publish_direct_exchange=undefined,
	 publish_direct_routing_key=undefined}).

start_link()->
    Params = {"10.20.96.160",
		  5672,
		  <<"deploy.direct">>,
		  <<"queue.deploy.proxy.recv">>},
    State = #gen_mod_state {
      publish_direct_exchange = <<"deploy.direct">>,
      publish_direct_routing_key = <<"queue.rails.recv">>},
    
    gen_mq_handler:start_link(?MODULE, Params, State).


%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
init({Host, Port, _Exchange, ConsumeQueue})->
    gen_mq_handler:amqp_setup_init(
      direct, Host, Port, ConsumeQueue).
    
publish() ->
    Message = [
	       {[
		 {<<"job_id">>, <<"474778688">>},
		 {<<"status">>, 0},
		 {<<"desc">>,   <<"success">>}
	       ]}],
    
    gen_mq_handler:send_message(?MODULE, {direct, Message}).

send_queue_info(direct, #gen_mod_state{
		  publish_direct_exchange = _X,
		  publish_direct_routing_key = RoutingKey}) ->
    %% use default exchange
    {<<>>, RoutingKey}.

handle_message(Message) ->
    io:format("[~p:~p]:Receive message=~p~n", [?MODULE, ?LINE, Message]),
    publish().
