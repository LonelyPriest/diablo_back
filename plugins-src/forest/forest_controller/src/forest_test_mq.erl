%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created :  4 Mar 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(forest_test_mq).

-behaviour(gen_mq_handler).

%% API
-export([start_link/0]).

-export([init/1, handle_message/1, send_queue_info/2,
	 publish/0, execute_batch/0, execute_single/0,
	 modify/0, delete/0, get_info/0, connect/0]).

-export([execute_new/0, continue/0]).

-define(SERVER, ?MODULE). 

-record(gen_mod_state,
	{publish_direct_exchange=undefined,
	 publish_direct_routing_key=undefined}).


connect() ->
    whereis(?MODULE) ! {'$gen_cast', connect}.

start_link()->
    Params = {"10.20.96.197",
		  5672,
		  <<"deploy.direct">>,
		  <<"queue.rails.recv">>},
    State = #gen_mod_state {
      %% publish_direct_exchange = <<"deploy.direct">>,
      publish_direct_exchange = <<>>,
      publish_direct_routing_key = <<"queue.deploy.proxy.recv">>},
    
    gen_mq_handler:start_link(?MODULE, Params, State).


%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
init({Host, Port, _Exchange, ConsumeQueue})->
    %% gen_mq_handler:amqp_setup_init(
    %%   direct, Host, Port, Exchange, ConsumeQueue).
    {direct, Host, Port, ConsumeQueue}.
    
publish() ->
    Message =
	       {[
		 {<<"job_id">>,     <<"474778688">>},
		 {<<"method">>,     <<"make_job">>},
		 {<<"date">>,       <<"2014/02/14">>},
		 {<<"maker">>,      <<"buxianhui">>},
		 {<<"subscribe">>, ["zhangshan", "lishi"]},
		 {<<"upgrade_file">>,<<"jx_online_3.tar.gz">>},
		 {<<"file_path">>,  <<"ftp://10.20.96.160/download_test">>},
		 {<<"name">>,       <<"buxianhui">>},
		 {<<"password">>,   <<"wli">>},
		 %%{<<"target">>,        ["10.20.96.160", "10.20.96.161"]},
		 {<<"target">>,        ["10.20.96.160", "10.20.96.160"]},
		 {<<"steps">>,         [download, stop, unzip, restart]},
		 %%{<<"steps">>,         ["download"]},
		 {<<"script">>,    <<"/home/buxianhui/download_test/jx_online_3.sh">>}
	       ]},
    
    gen_mq_handler:send_message(?MODULE, {direct, Message}).

modify() ->
    Message =
	{[
	  {<<"job_id">>,     <<"474778688">>},
	  {<<"method">>,     <<"modify_job">>},
	  {<<"date">>,       <<"2014/02/14">>},
	  {<<"maker">>,      <<"buxianhui">>},
	  {<<"subscribe">>, ["zhangshan", "lishi"]},
	  {<<"upgrade_file">>,<<"jx_online_3.tar.gz">>},
	  {<<"file_path">>,  <<"ftp://10.20.96.16/download_test">>},
	  {<<"name">>,       <<"buxianhui">>},
	  {<<"password">>,   <<"wli">>},
	  %%{<<"target">>,        ["10.20.96.160", "10.20.96.161"]},
	  {<<"target">>,        ["10.20.96.160"]},
	  {<<"steps">>,         ["download", "stop", "unzip", "restart"]},
	  %%{<<"steps">>,         ["download"]},
	  {<<"script">>,    <<"/home/buxianhui/download_test/jx_online_3.sh">>}
	 ]},
    
    gen_mq_handler:send_message(?MODULE, {direct, Message}).


delete() ->
    Message =
	{[
	  {<<"job_id">>,     <<"474778688">>},
	  {<<"method">>,     <<"delete_job">>}]},
    
    gen_mq_handler:send_message(?MODULE, {direct, Message}).

get_info() ->
    Message =
	{[
	  {<<"task_id">>,     <<"12345678">>},
	  {<<"method">>,     <<"get_task_status">>}]},
    
    gen_mq_handler:send_message(?MODULE, {direct, Message}).

execute_batch() ->
    Message = [
	       {[{<<"task_id">>, <<"12345678">>},
		 {<<"date">>, <<"2004/02/14">>}]},
	       {[{<<"method">>, <<"execute_task">>},
		 {<<"job_id">>, [<<"474778688">>]}]}
	      ],
    gen_mq_handler:send_message(?MODULE, {direct, Message}).

execute_single() ->
    Message =
	       {[{<<"task_id">>, <<"12345678">>},
		 {<<"method">>, <<"execute_task">>},
		 {<<"date">>, <<"2004/02/14">>},
		 {<<"job_id">>, <<"474778688">>}]},
    gen_mq_handler:send_message(?MODULE, {direct, Message}).


execute_new() ->
    Message =
	       {[{<<"task_id">>, <<"2">>},
		 {<<"method">>, <<"execute_task">>},
		 {<<"job_id">>, <<"1">>}]},
    gen_mq_handler:send_message(?MODULE, {direct, Message}).

continue() ->
    Message =
	       {[{<<"task_id">>, <<"2">>},
		 {<<"method">>, <<"continue_task">>}]},
    gen_mq_handler:send_message(?MODULE, {direct, Message}).

send_queue_info(direct, #gen_mod_state{
		  publish_direct_exchange = X,
		  publish_direct_routing_key = RoutingKey}) ->
    {X, RoutingKey}.

handle_message(Message) ->
    io:format("[~p:~p]:Receive message=~p~n", [?MODULE, ?LINE, Message]).
