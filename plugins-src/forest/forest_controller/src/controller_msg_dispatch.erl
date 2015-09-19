%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright Seasun(C) 2014, buxianhui
%%% @doc
%%%  dispatch message to corrent module
%%% @end
%%% Created :  6 Mar 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(controller_msg_dispatch).

-include("../../../include/knife.hrl").
-include("controller.hrl").

-compile(export_all).

dispatch({[{<<"task_id">>, TaskId},
	   {<<"method">>, <<"execute_task">> = _Action} = _Method,
	   {<<"job_id">>,  InstanceId}]})->
    ?DEBUG("receive execute job with taskId=~p and InstanceId=~p~n",
	   [TaskId, InstanceId]),
    try controller_tasks:instance_to_task(InstanceId, TaskId) of
	{ok, {AllTargets, Task}} ->
	    {ok, registered} = controller_tasks:register(task, TaskId, Task),
	    Alarms = controller_tasks:alarms_to_task(InstanceId),

	    %% mask alarm first, use task id to replace message id
	    enable_alarm_mask(TaskId, Alarms, AllTargets),
	    
	    ok = controller_mask_alarm:mask_alarm(
		   enable, {TaskId, InstanceId})
    catch
	_:{error, empty_step} ->
	    %% empty step, sucess to finished
	    controller_task_records:report(
	      task_state, sql_record, {TaskId, finished});
	_:{error, no_target_step} ->
	    %% no any target on any step, success to finished
	    controller_task_records:report(
	      task_state, sql_record, {TaskId, finished})
    end;

dispatch({[{<<"method">>, <<"reply_enable">>},
	   {<<"message_id">>, MessageId},
	   {<<"ret_code">>, 0},
	   {<<"id">>, AlarmId}]}) ->
    ?DEBUG("reploy_enable-> success, message_id ~p, AlarmId ~p",
	   [MessageId, AlarmId]),

    case controller_mask_alarm:mask_alarm(lookup, MessageId) of
	{ok, []} ->
	    %% no mask alam ids found
	    controller_task_records:report(
	      task_state, sql_record, {MessageId, failed});

	%% found the task
	{ok, [{TaskId, InstanceId, nothing}]} ->
	    case controller_tasks:lookup(TaskId) of
		{ok, Task} ->
		    Self = self(),
		    {ok, Process} =
			controller_task_monitor_sup:start_child(
			  Self, Task, TaskId),
		    controller_task_proc:new(TaskId, Process)
	    end,
	    ok = controller_mask_alarm:mask_alarm(
		   enable, {TaskId, InstanceId, AlarmId})
    end;

dispatch({[{<<"method">>, <<"reply_enable">>},
	   {<<"message_id">>, MessageId},
	   {<<"ret_code">>, Ret}]}) when Ret =/= 0 ->
    ?DEBUG("reploy_enable-> failed, message_id ~p", [MessageId]),
    controller_task_records:report(
	      task_state, sql_record, {MessageId, failed});

dispatch({[{<<"task_id">>, TaskId},
	   {<<"method">>, <<"continue_task">> = _Action} = _Method,
	   {<<"force">>, ?CONTINUE_TASK}
	  ]})->
    ?DEBUG("receive continue task with taskId ~p", [TaskId]),
    case controller_tasks:lookup(TaskId) of
	{ok, Task} ->
	    Self = self(),
	    {ok, Process} =
		controller_task_monitor_sup:start_child(
		  Self, Task, TaskId),
	    controller_task_proc:new(TaskId, Process)
    end;

dispatch({[{<<"task_id">>, TaskId},
	   {<<"method">>, <<"continue_task">> = _Action} = _Method,
	   {<<"force">>,  ?FORCE_TASK}
	  ]})->
    ?DEBUG("receive force task with taskId ~p", [TaskId]),
    case controller_tasks:lookup(wait_subtask, TaskId) of
	{ok, Task} ->
	    %% force tasks destroy the whole task step relation,
	    %% so, should modify task
	    {modify_ok, TaskId} =
		controller_tasks:modify(caused_by_force_task, TaskId),
	    Self = self(),
	    {ok, Process} =
		controller_task_monitor_sup:start_child(Self, Task, TaskId),
	    controller_task_proc:new(TaskId, Process)
    end;


dispatch({[{<<"task_id">>, TaskId},
	   {<<"method">>, <<"stop_task">> = _Action} = _Method
	  ]})->
    ?DEBUG("receive cancel task with taskId ~p", [TaskId]),
    controller_task_records:report(
      task_state, sql_record, {TaskId, terminate}),
    
    controller_tasks:refresh(task_state, TaskId, terminate),
    
    disable_alarm_mask(TaskId),
    
    controller_mq_handler:publish(
      fanout, {[{<<"method">>, <<"cancel_task">>},
		{<<"task_id">>, TaskId}]});


dispatch({[{<<"task_id">>, TaskId},
	   {<<"method">>, <<"retry_task">> = _Action} = _Method,
	   {<<"ip_list">>, BinaryIps}
	  ]})->
    ?DEBUG("receive retry task with taskId ~p, Ips ~p", [TaskId, BinaryIps]),
    
    RetryIpsList = knife_utils:binary_to_iplist(BinaryIps, <<>>, []),
    case controller_tasks:next_steps_of_failed_subtasks(TaskId, RetryIpsList) of
	{ok, Task} ->
	    {modify_ok, TaskId} =
		controller_tasks:modify(caused_by_retry_task, TaskId, RetryIpsList),
	    Self = self(),
	    {ok, Process} =
		controller_task_monitor_sup:start_child(Self, Task, TaskId),
	    controller_task_proc:new(TaskId, Process)
    end;
    
%% =============================================================================
%% @desc: process message comes form proxy
%% =============================================================================
dispatch({[{<<"from">>, <<"proxy">>},
	   {<<"task_id">>, TaskId},
	   {<<"target">>, Target},
	   {<<"step">>, Step},
	   {<<"stepid">>, StepId},
	   {<<"sn">>, SN},
	   {<<"type">>, Type},
	   {<<"finished">>, Finished},
	   {<<"state">>, State}]} = Message) ->
    ?DEBUG("receive message~n~p of task ~p from proxy", [Message, TaskId]),
    case controller_task_proc:lookup(TaskId) of
	[] ->
	    ?DEBUG("no process to associate task ~p" ,
		   [TaskId]),
	    ok;
	[P] ->
	    ?DEBUG("find prcess=~p to associate task ~p", [P, TaskId]),

	    
	    controller_task_records:report(
	      subtask, sql_record, {TaskId, State, Target, StepId}),
	    
	    controller_task_records:report(
	      task_detail, sql_record, {TaskId, success, StepId, Target, State}),
	    
	    %% refresh target
	    controller_tasks:refresh(
	      task, TaskId, {Target, Finished, Step, SN, State}),

	    %% the process may be exit first when the task is finished,
	    %% so we should notify first
	    %% notify(TaskId, Target, State),
	    
	    Process = list_to_pid(P),
	    case is_process_alive(Process) of
		true ->
		    Process ! {TaskId, Target, Step, SN, Type, State};
		false ->
		    ?DEBUG("target ~p with step ~p find prcess=~p is not alive~n, "
			   "discard message~n~p", [Target, Step, P, Message])
	    end
    end;

dispatch({[{<<"from">>,    <<"proxy">>},
	   {<<"task_id">>, TaskId},
	   {<<"target">>,  Target},
	   {<<"step">>,    Step},
	   {<<"stepid">>,  StepId},
	   {<<"sn">>,      SN},
	   {<<"type">>,    Type},
	   {<<"finished">>, Finished},
	   {<<"state">>, State},
	   {<<"ecode">>, ECode},
	   {<<"einfo">>, EInfo}]} = Message) ->
    ?DEBUG("receive message ~p of task ~p from proxy", [Message, TaskId]),
    case controller_task_proc:lookup(TaskId) of
	[] ->
	    ?DEBUG("no process to associate task ~p, discard message" ,
		   [TaskId]),
	    ok;
	[P] ->
	    ?DEBUG("find prcess=~p to associate task ~p", [P, TaskId]),

	    controller_task_records:report(subtask, sql_record,
					   {TaskId, State, Target, StepId}),

	    controller_task_records:report(
	      task_detail, sql_record, {TaskId, EInfo, StepId, Target, State}),
	    
	    %% refresh target
	    controller_tasks:refresh(
	      task, TaskId, {Target, Finished, Step, SN, State, ECode, EInfo}),

	    %% the process may be exit first when the task is finished,
	    %% so we should notify first
	    %% notify(TaskId, Target, State, ECode, EInfo),
	    
	    Process = list_to_pid(P),
	    case is_process_alive(Process) of
		true ->
		    Process !
			{TaskId, Target, Step, SN, Type, State, ECode, EInfo};
		false ->
		    ?DEBUG("target ~p with step ~p find prcess=~p is not alive, "
			   "discard message~n~p", [Target, Step, P, Message])
	    end	    
    end;




dispatch(Message)->
    ?DEBUG("dispatch unkown message~n ~p~n", [Message]).

%% =============================================================================
%% @desc: notify target state
%% =============================================================================
enable_alarm_mask(MessageId, Alarms, Targets) ->
    ?DEBUG("enable_alarm_mask-> MessageId ~p, Alarms ~p, Targets ~p",
	   [MessageId, Alarms, Targets]),
    {MegaSecs, Secs, MicroSecs} = Now = erlang:now(),
    
    {{Year, Month, Date}, {NowHour, NowMinute, _}} =
	calendar:now_to_local_time(Now),
    
    %% estimate mask alarm 8 hours
    {_, {EstimateHour, EstimateMinute, _}} =
	calendar:now_to_local_time({MegaSecs, Secs + 8 * 3600, MicroSecs}),

	    %% alarm_mask
	    controller_mq_handler:publish(
	      direct,
	      {[{<<"method">>, <<"enable_alarm_mask">>},
		{<<"message_id">>, MessageId},
		{<<"params">>,
		 {[{<<"target_ips">>, ?to_binary_ips(Targets)},
		   {<<"mask_alarms">>, Alarms},
		   {<<"mask_timespan">>,
		    ?to_binary(
		       lists:flatten(
			 io_lib:format(
			   "~2..0w~2..0w~2..0w~2..0w",
			   [NowHour, NowMinute, EstimateHour, EstimateMinute])))},
		   {<<"mask_date">>,
		    ?to_binary(
		       lists:flatten(
			 io_lib:format("~4..0w~2..0w~2..0w",
				       [Year, Month, Date])))}]}
		}]}).

disable_alarm_mask(MessageId) ->
    {ok, [{_, _, AlarmId}]} =
	controller_mask_alarm:mask_alarm(lookup, MessageId),
    Message = {[{<<"method">>, <<"disable_alarm_mask">>},
		{<<"message_id">>, MessageId},
		{<<"params">>,
		 {[{<<"id">>, ?to_binary(AlarmId)}]}
		}]},
    controller_mq_handler:publish(direct, Message).
