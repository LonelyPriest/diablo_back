%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright Seasun(C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created :  4 Mar 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(gen_mq_handler).

-include("../../../include/knife.hrl").
%% -include("../../../deps/amqp_client-3.2.4/include/amqp_client.hrl").
-include_lib("../../../deps/amqp_client-3.2.4/include/amqp_client.hrl").

-behaviour(gen_server).

%% API
-export([start_link/3]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-export([send_message/2, amqp_setup_init/1]).

-define(SERVER, ?MODULE). 

-record(state, {amqp_connection=undefined,
		amqp_channel=undefined,
		amqp_queue=undefined,
		amqp_consumer_tag=undefined,
		amqp_consumer_exchange=undefined,
		amqp_publish_channel=undefined,
		amqp_connection_monitor_ref=undefined,
		
		amqp_init_params=undefined,
		amqp_reconnect_times=0,
		
		gen_module=undefined,
		gen_module_state=undefined
		}).
		

-callback init(tuple()) -> any().
-callback handle_message(any()) -> any().
-callback send_queue_info(atom(), any()) -> tuple().
-callback connect() -> ok.
-callback close() -> ok. 
    
%% behaviour_info(callbacks) ->
%%     [
%%      {init, 1},
%%      {handle_message, 1},
%%      {send_queue_info, 2}
%%     ];

%% behaviour_info(_Other) ->
%%     undefined.

start_link(GenMod, GenModParams, GenModState) ->
    gen_server:start_link({local, GenMod}, ?MODULE,
			  [GenMod, GenModParams, GenModState], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
init([GenMod, AmqpParams, GenModState]) ->
	NewAmqpParams = GenMod:init(AmqpParams),
	{ok, #state{
	   amqp_init_params = NewAmqpParams,
	   gen_module = GenMod,
	   gen_module_state = GenModState}}.

connect(AmqpParams, #state{gen_module = GenMod,
			   gen_module_state = GenModState,
			   amqp_reconnect_times = Times} = OldState) ->
    [_Type, AmqpHost|_T] = tuple_to_list(AmqpParams),
    try
	NewState = amqp_setup_init(AmqpParams),
	?DEBUG("success to connect to AMQP ~p with ~p times",
		   [AmqpHost, Times]),
	NewState#state{amqp_init_params = AmqpParams,
		       amqp_reconnect_times=0,
		       gen_module = GenMod,
		       gen_module_state = GenModState}
    catch
	_:{badmatch, {error, Error}} ->
	    ?DEBUG("failed to connect to AMQP host ~p, reason: ~p",
		   [AmqpHost, Error]),
	    %% ?WARN("failed to connect to AMQP host ~p, reason: ~p",
	    %% 	  [AmqpHost, Error]),
	    reconnect(forever, GenMod, Times),
	    OldState#state{amqp_reconnect_times = Times + 1}
    end.

reconnect(forever, GenModServer, Times) ->
    AfterTimes = ?INTERVAL_RECONNECT + Times * 2000,
    ?DEBUG("the ~p times to reconnect AMQP after time ~p", [Times, AfterTimes]),
    erlang:send_after(AfterTimes, GenModServer, {'$gen_cast', connect}).

%% build queue with default exchange, default route
amqp_setup_init({direct, Host, Port, Queue}) ->
    amqp_setup_init(Host, Port, <<>>, <<"direct">>, Queue, <<>>);

amqp_setup_init({fanout, Host, Port, Exchange, Queue})->
    amqp_setup_init(Host, Port, Exchange, <<"fanout">>, Queue, Queue);

%% build queue with certain exchange, 
%% routing key is the same with consume queue
amqp_setup_init({direct, Host, Port, Exchange, Queue})->
    amqp_setup_init(Host, Port, Exchange, <<"direct">>, Queue, Queue).


amqp_setup_init(Host, Port, Exchange, ExchangeType, Queue, RoutingKey)->
    %% start network connection
    {ok, Connection} =
	amqp_connection:start(#amqp_params_network{
				 host = Host,
				 port = Port}),
    ?DEBUG("success to connec to AMQP host ~p on port ~p", [Host, Port]),
    ?INFO("success to connec to AMQP host ~p on port ~p", [Host, Port]),
    
    %% channel to receive message
    {ok, Channel} = amqp_connection:open_channel(Connection),
    
    %% declare exchange
    case Exchange =:= <<>> of
	true -> ok; %% use default exchange
	false ->
	    #'exchange.declare_ok'{}
		= amqp_channel:call(
		    Channel,
		    #'exchange.declare'{
		      exchange = Exchange, type = ExchangeType})
    end,

    %% queue to receive message
    #'queue.declare_ok'{} =
	amqp_channel:call(Channel, #'queue.declare'{queue = Queue}),

    %% bind exchange and queue
    case RoutingKey =:= <<>> of
	true  -> ok; %% use default binding
	false ->
	    Binding = #'queue.bind'{queue = Queue,
				    exchange = Exchange,
				    routing_key = RoutingKey},
	    #'queue.bind_ok'{} = amqp_channel:call(Channel, Binding)
    end,

    %% subscribe message
    Subscribe = #'basic.consume'{queue = Queue},
    #'basic.consume_ok'{consumer_tag = Tag} =
	amqp_channel:subscribe(Channel, Subscribe, self()),

    %% register return handler 
    amqp_channel:register_return_handler(Channel, self()),

    %% monitor connction
    Ref = erlang:monitor(process, Connection),

    #state{amqp_connection=Connection,
	   amqp_channel=Channel,
	   amqp_queue=Queue,
	   amqp_consumer_tag=Tag,
	   amqp_connection_monitor_ref=Ref}.
    
%% publish message with default direct exchange,
%% so the queue name and the routing key are the same
%% publish(Pid, Message, Queue)->
%%     publish(Pid, Message, <<>>, Queue, Queue).

%% pubish message with certain direct exchange,
%% so, the routing key and queue are the same
%% publish(Pid, Message, Exchange, Queue)->
%%     publish(Pid, Message, Exchange, Queue, Queue).

%% publis message use internal publis queue
send_message(Name, Message) ->
    gen_server:cast(Name, Message).

handle_call(gen_mq_handler, _From, #state{gen_module = GenMod} = State) ->
    {reply, GenMod, State};

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

handle_cast({Style, Message},
	    #state{amqp_connection = Connection,
		   amqp_publish_channel = undefined,
		   gen_module = GenMod,
		   gen_module_state = GenModState} = State)->
    ?DEBUG("will send message=~p with Style=~p", [Message, Style]),
    
    {ok, Channel} = amqp_connection:open_channel(Connection),
    
    %% register return handler 
    amqp_channel:register_return_handler(Channel, self()),
    
    {Exchange, RoutingKey} = GenMod:send_queue_info(Style, GenModState), 
    ok = cast_message(Message, Channel, Exchange, Style, RoutingKey),
    {noreply, State#state{amqp_publish_channel=Channel}};

handle_cast({MsgType, Message},
	    #state{amqp_publish_channel = Channel,
		   gen_module = GenMod,
		   gen_module_state = GenModState} = State)->
    ?DEBUG("send message~n~p with Style=~p", [Message, MsgType]),
    
    {Exchange, RoutingKey} = GenMod:send_queue_info(MsgType, GenModState),
    ok = cast_message(Message, Channel, Exchange, MsgType, RoutingKey),
    {noreply, State};


handle_cast(connect, #state{amqp_init_params = AmqpParams} = State) ->
    ?DEBUG("connect to AMQP with params:~nAmqpParams ~p", [AmqpParams]),
    NewState = connect(AmqpParams, State),
    {noreply, NewState};

handle_cast(close, #state{amqp_connection = undefined} = State) ->
    ?INFO("no AMQP connect, discard close message", []),
    {noreply, State};

handle_cast(close, #state{
	      amqp_connection = Connection,
	      amqp_channel = Channel,
	      amqp_publish_channel = PublishChannel,
	      amqp_connection_monitor_ref = Ref} = State) ->
    ?INFO("Start to disconnect to AMQP", []),

    amqp_channel:unregister_return_handler(Channel),
    amqp_channel:close(Channel),
    case PublishChannel of
	undefined  -> ok;
	PublishChannel ->
	    amqp_channel:unregister_return_handler(PublishChannel),
	    amqp_channel:close(PublishChannel)
    end,
    
    erlang:demonitor(Ref),
    amqp_connection:close(Connection),
    {noreply, State};

handle_cast(_Msg, State) ->
    {noreply, State}.


handle_info(#'basic.consume_ok'{consumer_tag = Tag}, State)->
    ?INFO("success to connect to AMQP with tag ~p", [Tag]),
    {noreply, State};

handle_info({#'basic.deliver'{delivery_tag = DTag, consumer_tag = Tag}, Content},
	    #state{amqp_channel = Channel, gen_module = GenMod} = State)
  when Tag =:= State#state.amqp_consumer_tag->
    ?DEBUG("Receive message ~p from MQ", [Content]),

    %% avoid message block
    amqp_channel:cast(Channel, #'basic.ack'{delivery_tag = DTag}),        
    
    %% dispatch message
    #amqp_msg{props = _Props, payload = Payload} = Content,
    
    GenMod:handle_message(ejson:decode(Payload)),
    
    {noreply, State};

%% handle_info({#'basic.return'{reply_text = <<'unroutable'>>}, Content}, State)->
%%     ?FORMAT("Message ~p unrouteable", [Content]),
%%     ?WARN("Message ~p unreouteable", [Content]),
%%     {noreply, State};

handle_info({#'basic.return'{reply_code = 312,
			     reply_text = Text,
			     routing_key = Key},
	     #amqp_msg{payload = Payload} = _Content}, State) ->
    ?DEBUG("received error=~p on routing key ~p with payload~p~n",
	    [Text, Key, Payload]),
    {noreply, State};

handle_info({'DOWN', Ref, process, _Process, socket_closed_unexpectedly = Error},
	    #state{amqp_connection_monitor_ref = MRef,
		   gen_module = GenMod} = State)
  when Ref =:= MRef->
    ?DEBUG("AMQP closed with reason: ~p, reconnect after 3 seconds", [Error]),
    erlang:send_after(?INTERVAL_RECONNECT, GenMod, {'$gen_cast', connect}),
    {noreply, State};
    
handle_info(UnkownMessage, State) ->
    ?WARN("handle_info: Receive unkown message ~p", [UnkownMessage]),
    %% amqp_channel:cast(Channel, #'basic.ack'{delivery_tag = Tag}),
    {noreply, State}.

terminate(_Reason, _State) ->
    ?DEBUG("terminate reason=~p~n", [_Reason]),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

cast_message(Message, Channel, Exchange, MsgType, RoutingKey) ->
    ?DEBUG("cast message with exchange=~p, routingkey=~p~n",
	    [Exchange, RoutingKey]),
    Type = 
	case MsgType of
	    fanout   -> <<"fanout">>;
	    _Default -> <<"direct">>
	end,
    
    Publish = 
	case Exchange =:= <<>> of
	    true ->
		#'basic.publish'{routing_key = RoutingKey,
				  mandatory = true};
	    
	false ->		
		amqp_channel:call(
		  Channel,
		  #'exchange.declare'{exchange = Exchange, type = Type}),
		
		#'basic.publish'{exchange = Exchange,
				 routing_key = RoutingKey,
				 mandatory = true}
    end,
    
    
    %% amqp_channel:call(Channel, #'queue.declare'{queue = _Queue}),
    %% Publish = 
    %% 	case Exchange =:= <<>> of
    %% 	    true  ->
    %% 		#'basic.publish'{routing_key = RoutingKey,
    %% 				 mandatory = true};
    %% 	    false ->
    %% 		#'basic.publish'{exchange = Exchange,
    %% 				 routing_key = RoutingKey,
    %% 				 mandatory = true}
    %% 	end,
    
    JsonMessage = ejson:encode(Message),
    
    ?DEBUG("will send json message~p~n", [JsonMessage]),
    amqp_channel:cast(Channel, Publish, #amqp_msg{payload = JsonMessage}),
    ok.
