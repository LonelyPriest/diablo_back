%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright Seasun Game(C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 16 Jun 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(controller_mask_alarm).

-include("../../../include/knife.hrl").

-behaviour(gen_server).

%% API
-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-export([mask_alarm/2]).

-define(SERVER, ?MODULE).

-define(ALARM_MASK, alarm_mask).

-record(state, {}).


%%%===================================================================
%%% API
%%%===================================================================

mask_alarm(enable, {TaskId, InstanceId}) ->
    gen_server:call(?SERVER, {enable_mask_alarm,
			      {TaskId, InstanceId, nothing}});

mask_alarm(enable, {TaskId, InstanceId, AlarmId}) ->
    gen_server:call(?SERVER, {enable_mask_alarm,
			      {TaskId, InstanceId, AlarmId}});

mask_alarm(cancel, TaskId) ->
    gen_server:call(?SERVER, {cancel_mask_alarm, TaskId});

mask_alarm(lookup, TaskId) ->
    gen_server:call(?SERVER, {lookup_mask_alarm, TaskId}).


start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
init([]) ->
    %% new a ets table to store the ralation mask and task,
    %% format {task_id, instance_id}
    ets:new(?ALARM_MASK, [private, set, named_table]),
    {ok, #state{}}.

handle_call({enable_mask_alarm, {TaskId, InstanceId, AlarmId}},
	    _From, State) ->
    ?DEBUG("enable_mask_alarm-> TaskId ~p, InstanceId ~p",
	   [TaskId, InstanceId]),
    true = ets:insert(?ALARM_MASK,
		      {?to_binary(TaskId), InstanceId, AlarmId}),
    {reply, ok, State};

handle_call({cancel_mask_alarm, TaskId}, _From, State) ->
    ?DEBUG("cancel_mask_alarm-> TaskId ~p", [TaskId]),
    true = ets:delete(?ALARM_MASK, ?to_binary(TaskId)),
    {reply, ok, State};

handle_call({lookup_mask_alarm, TaskId}, _From, State) ->
    ?DEBUG("lookup_mask_alarm-> TaskId ~p", [TaskId]),
	AlarmInfo = ets:lookup(?ALARM_MASK, ?to_binary(TaskId)),
    {reply, {ok, AlarmInfo}, State};
    
handle_call(_Request, _From, State) ->
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
