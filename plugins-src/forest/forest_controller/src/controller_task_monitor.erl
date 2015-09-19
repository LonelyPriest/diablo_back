%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright SeasunGame(C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 19 Mar 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(controller_task_monitor).

-include("../../../include/knife.hrl").
-include("controller.hrl").

-export([start_link/3, init/3]).

-export([rebuild_task/3]).

start_link(Parent, Task, TaskId) ->
    {ok, proc_lib:spawn_link(?MODULE, init, [Parent, Task, TaskId])}.

init(Parent, Task, TaskId) ->
    ?DEBUG("Start a new proc=~p to process task ~p", [self(), TaskId]),

    %% fanout task to all proxy
    ok = fanout({to_proxy, Parent},  Task),

    %% begin to execute, task in running state
    controller_task_records:report(
	      task_state, sql_record, {TaskId, running}),
    
    %% then, wait for this task done
    wait_for_task_done(Parent, TaskId, Task).
    

%% =============================================================================
%% wait for the whole task done, the conditions are:
%% 1: all the steps have been executed
%% 2: one of the steps of the task was timeout
%% =============================================================================
-spec wait_for_task_done(pid(), string(), list()) -> no_return(). 
wait_for_task_done(Parent, TaskId, Task) ->
    ?DEBUG("wait_for_task_done with parameter: Parent ~p, TaskId ~p~n",
	   [Parent, TaskId]),
    
    receive
	{TaskId, Target, Step, SN, <<"3">> = Type, StepState} ->
	    ?DEBUG("wait_for_task_done: step ~p, sequenced ~p, type ~p, "
		   "with state ~p of target ~p " "in task ~p ",
		   [Step, SN, Type, StepState, Target, TaskId]),
	    NowWaits  = now_wait_targets(TaskId, Type, Target, SN),
	    routine(wait_for_artificial,
		    {NowWaits, Target, Type}, {Parent, TaskId, Task});

	{TaskId, Target, Step, SN, <<"4">> = Type, StepState} ->
	    ?DEBUG("wait_for_task_done: step ~p, sequenced ~p, type ~p, "
		   "with state ~p of target ~p " "in task ~p ",
		   [Step, SN, Type, StepState, Target, TaskId]),
	    NowWaits  = now_wait_targets(TaskId, Type, Target, SN),
	    routine(wait_for_standby,
		    {NowWaits, Target, Type}, {Parent, TaskId, Task});
			    
	{TaskId, Target, Step, SN, _, StepState} ->
	    ?DEBUG("wait_for_task_done: step ~p sequenced ~p "
		   "with state ~p of target ~p " "in task ~p ",
		   [Step, SN, StepState, Target, TaskId]),
	    
	    task_routine(Parent, TaskId, Task);
	
	{TaskId, Target, Step, SN, _, StepState, ECode, EInfo} ->
	    ?DEBUG("wait_for_task_done: step ~p sequenced ~p "
		   "with state ~p of target ~p "
		   "in task ~p~n ecode ~p, einfo ~p",
		   [Step, SN, StepState, Target, TaskId, ECode, EInfo]),
	    task_routine(Parent, TaskId, Task);
	Any ->
	    ?DEBUG("receive unkown message ~p, continue...", [Any]),
	    ?WARN("receive unkown message ~p, continue...", [Any]),
	    wait_for_task_done(Parent, TaskId, Task)
		
    after 30000 ->
	    ?DEBUG("wait_for_task_done: Task ~p timeout, will be exit process ~p",
		   [TaskId, self()]),

	    controller_task_records:report(
	      task_state, sql_record, {TaskId, timeout}),
	    
	    controller_tasks:refresh(task_state, TaskId, timeout),
	    %% controller_tasks:delete(task, TaskId),
	    
	    timer:sleep(100),
	    exit({task_timeout, TaskId})
    end.


%% =============================================================================
%% @desc: check task, finished, timeout or begin to do next step
%% =============================================================================
-spec task_routine(pid(), string(), list()) -> no_return(). 
task_routine(Parent, TaskId, Task) ->
    ?DEBUG("task ~p routine...", [TaskId]),
    %% Task = controller_tasks:lookup(task, TaskId),
    RoutineFun =
	fun() ->
		controller_tasks:refresh(task_state, TaskId, running),
		wait_for_task_done(Parent, TaskId, Task)
	end,

    is_task_finished(TaskId, RoutineFun).

routine(wait_for_artificial, {Waits, Me, Type}, {Parent, TaskId, Task}) ->
    ?DEBUG("rotine wait_for_artificial-> waits ~p, Me ~p", [Waits, Me]),
    
    {_, _, FailedNodes} = controller_tasks:task_detail(TaskId),
    ?DEBUG("wait_for_artificial -> FailedNodes ~p", [FailedNodes]),
    ExcludeMeWaits = [Ip || Ip <- Waits -- FailedNodes, Ip =/= Me],
    ?DEBUG("wait_for_artificial, ExcludeMeWaits = ~p", [ExcludeMeWaits]),
    
    RoutineFun =
	fun() ->
		case ExcludeMeWaits of
		    [] ->
			?DEBUG("no target to wait, exit process ~p "
			       "and wait for artificial process", [self()]),
			%% shoudle delete this artificial step
			controller_task_state:delete(TaskId, Type),
			wait_exit(wait_for_artificial, TaskId, Type);
		    _ ->
			?DEBUG("artificial waiting targets ~p",
			       [ExcludeMeWaits]),
			wait_routine(
			  Parent, TaskId, Task, Type, ExcludeMeWaits)
		end
	end,
    
    is_task_finished(TaskId, RoutineFun);

routine(wait_for_standby, {Waits, Me, Type}, {Parent, TaskId, Task}) ->
    ?DEBUG("rotine wait_for_standby-> waits ~p, Me ~p", [Waits, Me]),
    
    {Finished, _, FailedNodes} = controller_tasks:task_detail(TaskId),
    ?DEBUG("wait_for_artificial -> FailedNodes ~p", [FailedNodes]),
    ExcludeMeWaits = [Ip || Ip <- Waits -- FailedNodes, Ip =/= Me],
    ?DEBUG("wait_for_standy, ExcludeMeWaits = ~p", [ExcludeMeWaits]),

    RoutineFun =
	fun() ->
		case ExcludeMeWaits of
		    [] ->
			?DEBUG("all standby target was arrived, "
			       "wait for next process"),
			case FailedNodes of
			    [] ->
				%% no standby nodes, continue task
				?DEBUG("no target to wait, "
				       "continue the task ~p", [TaskId]),
				%% exclude finished node
				case rebuild_task(
				       delete_target, Task, Finished) of
				    [] ->
					?DEBUG("no steps found, "
					       "task ~p finished", [TaskId]),
					exit_task(TaskId, finished);
				    RebuildTask ->
					ok = fanout(
					       {to_proxy, Parent},  RebuildTask)
				end,
		    
				%% shoudle delete this standby step
				controller_task_state:delete(TaskId, Type),
				%% rewait the task done
				wait_for_task_done(Parent, TaskId, Task);
			    _ ->
				wait_exit(wait_for_standby, TaskId, Type)
			end;
		    _ ->
			?DEBUG("standby waiting targets ~p" , [ExcludeMeWaits]),
			wait_routine(Parent, TaskId, Task, Type, ExcludeMeWaits)
		end end,
    
    is_task_finished(TaskId, RoutineFun).

%% =============================================================================
%% @desc: fanout a task to proxy
%% =============================================================================
fanout({to_proxy, _To}, Body) ->
    controller_mq_handler:publish(fanout, Body),
    ok.
    %% To ! {'$gen_cast',
    %% 	  {fanout, Body}},
    %% ok.

wait_exit(ExitType, TaskId, StepType) ->
    %% controller_task_records:report(
    %%   task_state, sql_record, {TaskId, waiting}),
    
    controller_task_state:delete(TaskId, StepType),
    
    exit({ExitType, TaskId}).

wait_routine(Parent, TaskId, Task, StepType, ExcludeMeWaits) ->
    controller_task_state:save_task(TaskId, StepType, ExcludeMeWaits),
    wait_for_task_done(Parent, TaskId, Task).


%% =============================================================================
%% @desc: get current wait targets in a running task
%% =============================================================================
now_wait_targets(TaskId, Type, Target, SN) ->
    case controller_task_state:wait_targets(TaskId, Type) of
	{ok, no_target} ->
	    wait_for_targets(TaskId, Target, SN);
	{ok, Waits} ->
	    Waits
    end.

%% =============================================================================
%% @desc: get the wait targets with a target
%% =============================================================================
wait_for_targets(TaskId, SelfTarget, SN) ->
    #step{wait_ips = Waits} =
	controller_tasks:lookup_step(subtask, TaskId, SelfTarget, SN),
    knife_utils:binary_to_iplist(Waits, <<>>, []).


%% step_type(<<"3">>) ->
%%     wait_for_artificial;
%% step_type(<<"4">>) ->
%%     wait_for_standby.

rebuild_task(delete_target, Task, Targets) ->
    ?DEBUG("rebuild_task-> Targets ~p", [Targets]),
    RebuildTask = 
	lists:foldr(
	  fun({[{<<"task_id">>, _}, {<<"target">>, Node}|_]} = Subtask, Acc) ->
		  case lists:member(Node, Targets) of
		      true  -> Acc;
		      false -> [Subtask|Acc]
		  end
	  end, [], Task),
    ?DEBUG("rebuild task ~p", [RebuildTask]),
    RebuildTask.


exit_task(failed, TaskId) ->
    exit_task(TaskId, failed);
exit_task(finished, TaskId) ->
    exit_task(TaskId, finished);
exit_task(TaskId, Status) ->
    controller_task_records:report(task_state, sql_record, {TaskId, Status}),
    controller_tasks:refresh(task_state, TaskId, Status),
    controller_task_proc:delete(TaskId),
    controller_msg_dispatch:disable_alarm_mask(TaskId),

    %% wait for all the message was send
    timer:sleep(100),
    exit({task_finished, Status, TaskId}).


is_task_finished(TaskId, RoutineFun) ->
    case controller_tasks:is_task_finished(TaskId) of
    	{true, success, _Finished} ->
    	    ?DEBUG("task ~p completely finished", [TaskId]),
    	    ?DEBUG("task ~p finished, will be exit process ~p", [TaskId, self()]),
	    exit_task(finished, TaskId);
	
    	{true, failed, Failed} ->
    	    ?DEBUG("task ~p finished, but failed on targets ~p", [TaskId, Failed]),	    
    	    ?DEBUG("task ~p finished, will be exit process ~p", [TaskId, self()]),
	    exit_task(TaskId, failed);
	
    	{false, _, _} ->
	    ?DEBUG("task ~p not finished, continue...", [TaskId]),
	    RoutineFun()
    end.
