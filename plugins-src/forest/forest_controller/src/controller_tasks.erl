%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright SeasunGame(C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 13 Mar 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(controller_tasks).

-include("../../../include/knife.hrl").
-include("controller.hrl").

-behaviour(gen_server).

%% API
-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-export([register/3, is_task_finished/1]).
-export([refresh/3, get_task/2]).

-export([lookup/0, lookup/1, lookup/2]).
-export([next_steps_of_failed_subtasks/2]).
-export([lookup_step/4, task_detail/1]).
-export([delete/1, delete/2]).
-export([modify/2, modify/3]).

-export([instance_to_task/2, alarms_to_task/1]).

%% =============================================================================
%% internal export to debug
%% =============================================================================
-export([steps_to_task/2, steps_to_target/2, steps/1, class/1]).

-define(SERVER, ?MODULE).
-define(ASSOCIATE_TASK_PROCESS, associate_task_process).

%% -define(ASSOCIATE_TASK_STEP, associate_task_step).


-record(state, {}).

%% =============================================================================
%% Interface
%% =============================================================================
register(task, TaskId, Task) ->
    gen_server:call(?SERVER, {register, TaskId, Task}, infinity).


refresh(task_state, TaskId, TaskState)->
    gen_server:call(
      ?SERVER, {refresh_task_state, TaskId, TaskState});

refresh(task, TaskId, {Target, Completed, Step, SN, State}) ->
    gen_server:call(
      ?SERVER,
      {refresh_task, TaskId, {Target, Completed, Step, SN, State}});

refresh(task, TaskId, {Target, Completed, Step, SN, State, ECode, EInfo}) ->
    gen_server:call(
      ?SERVER, {refresh_task, TaskId,
		{Target, Completed, Step, SN, State, ECode, EInfo}}).

%% =============================================================================
%% @desc: lookup all the tasks
%% =============================================================================
lookup()->
    gen_server:call(?SERVER, lookup_task).

lookup(task_to_process) ->
    gen_server:call(?SERVER, lookup_task_to_process);

%% =============================================================================
%% @desc: lookup task by cetain task id
%% =============================================================================
lookup(TaskId) ->
    gen_server:call(?SERVER, {lookup_task_by_id, ?to_binary(TaskId)}).

%% =============================================================================
%% @desc: get a task which some subtasks were in wait status
%% =============================================================================
lookup(wait_subtask, TaskId) ->
    gen_server:call(?SERVER, {lookup_wait_subtask, ?to_binary(TaskId)}).

%% =============================================================================
%% @desc:  get a task with special subtasks
%% @param: TaskId -> id of task
%% @param: SubtaskIps -> binary ip list, [<<"192.168.0.1">>, <<"192.168.0.2">>]
%% =============================================================================
next_steps_of_failed_subtasks(TaskId, SubtaskIps) ->
    gen_server:call(
      ?SERVER, {next_steps_of_failed_subtasks, ?to_binary(TaskId), SubtaskIps}).



delete(task) ->
    gen_server:cast(?SERVER, delete_task).
delete(task, TaskId) ->
    gen_server:cast(?SERVER, {delete_task, ?to_binary(TaskId)}).

%% find the step of subtask by SN
lookup_step(subtask, TaskId, Target, SN) ->
    gen_server:call(?SERVER, {lookup_step_of_subtask, TaskId, Target, SN}).


is_task_finished(TaskId) ->
    gen_server:call(?SERVER, {is_task_finished, TaskId}).

task_detail(TaskId) ->
    gen_server:call(?SERVER, {lookup_task_detail, TaskId}).

modify(caused_by_force_task, TaskId) ->
    gen_server:call(?SERVER, {modify_caused_by_force_task, ?to_binary(TaskId)}).


modify(caused_by_retry_task, TaskId, RetryIps) ->
    gen_server:call(?SERVER,
		    {modify_caused_by_retry_task, ?to_binary(TaskId), RetryIps}).

%% =============================================================================
%% Callback
%% =============================================================================
start_link() ->    
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

init([]) ->
    ets:new(?ASSOCIATE_TASK_PROCESS, [set, private, named_table]),
    %% ets:new(?ASSOCIATE_TASK_STEP, [set, private, named_table]),
    {ok, #state{}}.

handle_call({lookup_process_by_task, TaskId}, _From, State)->
    %% select process where taskid =:= TaskId
    MS = [{{'$1', '$2'},           %% head
	   [{'==', '$1', TaskId}], %% condition
	   ['$2']}],               %% result
    Process = ets:select(?ASSOCIATE_TASK_PROCESS, MS),
    {reply, {ok, Process}, State};


handle_call({associate_task_process, {TaskId, Process}}, _From, State) ->
    ?FORMAT("associate task ~p to process ~p", [TaskId, pid_to_list(Process)]),
    true = ets:insert(?ASSOCIATE_TASK_PROCESS,
		      {TaskId, pid_to_list(Process)}),
    {reply, ok, State};

handle_call(lookup_task, _From, State) ->
    {atomic, Tasks} =
	mnesia:transaction(
	  fun() ->
		  mnesia:select(task, [{#task{_ = '_'}, [], ['$_']}])
	  end),    
    {reply, Tasks, State};

handle_call({lookup_step_of_subtask, TaskId, Target, SN}, _From, State) ->
    ?DEBUG("lookup_step_of_subtask, TaskId ~p, Target ~p, SN ~p",
	   [TaskId, Target, SN]),
    Reply =
	action_on_task(lookup_step_of_subtask, {TaskId, {Target, SN}}),
    {reply, Reply, State};

handle_call({lookup_task_by_id, TaskId}, _From, State) ->
    {ok, #task{sub_tasks = Subtasks}} = get_task(by_id, TaskId),
    JsonTask = 
	lists:foldr(
	  fun(#sub_task{target = Target, steps = Steps}, Acc1) ->
		  S = 
		      lists:foldr(
			fun(#step{sn = SN, name = Name, stepid = StepId,
				  type = Type, source = Source,
				  script = Script, user = User,
				  wait_ips = Wait}, Acc2) ->
				[
				 {task_fields(
				    [{<<"sn">>, SN},
				     {<<"name">>, Name},
				     {<<"stepid">>, StepId},
				     {<<"type">>, Type},
				     {<<"source">>, Source},
				     {<<"script">>, Script},
				     {<<"user">>, User},
				     {<<"wait_ips">>, Wait}] , [])}
				 | Acc2]
			end, [], Steps),
		  [
		   {[{<<"task_id">>, TaskId},
		     {<<"target">>, Target},
		     {<<"steps">>, S}]} | Acc1
		  ]
	  end, [], Subtasks),
    {reply, {ok, JsonTask}, State};



handle_call({lookup_wait_subtask, TaskId}, _From, State) ->
    {ok, #task{sub_tasks = Subtasks}} = get_task(by_id, TaskId),
    {_, Unfinished, _} = subtasks_info(Subtasks, [], [], []),
    JsonTask = task_with_subtasks(Subtasks, Unfinished),
    
    {reply, {ok, JsonTask}, State};

handle_call({next_steps_of_failed_subtasks, TaskId, SubtaskIps},
	    _From, State) ->
    ?DEBUG("get_next_step_of_failed_subtasks-> TaskId ~p, SubtaskIps ~p",
	   [TaskId, SubtaskIps]),
    {ok, #task{sub_tasks = Subtasks}} = get_task(by_id, TaskId),
    JsonTask = get_next_steps_of_failed_subtasks(Subtasks, SubtaskIps),
    
    {reply, {ok, JsonTask}, State};

handle_call(lookup_task_to_process, _From, State) ->
    {reply, {ets:tab2list(?ASSOCIATE_TASK_PROCESS)}, State};


handle_call({register, TaskId, Task}, _From, State) ->
    ?DEBUG("start to register tasks=~p", [TaskId]),
    SubTasks = 
	lists:foldr(
	  fun({[{<<"task_id">>, _}, {<<"target">>, Target},
		{<<"steps">>, Steps}]}, Acc0) ->
		  %% ?DEBUG("subtask steps=~p", [Steps]),
		  TargetSteps = 
		      lists:foldr(
			fun({S}, Acc1) ->
				SN     = proplists:get_value(<<"sn">>, S),
				Name   = proplists:get_value(<<"name">>, S),
				Type   = proplists:get_value(<<"type">>, S),
				StepId = proplists:get_value(<<"stepid">>, S),
				Source = proplists:get_value(<<"source">>, S),
				Script = proplists:get_value(<<"script">>, S),
				User   = proplists:get_value(<<"user">>, S),
				Wait   = proplists:get_value(<<"wait_ips">>, S),
				[#step{sn = SN, name = Name, stepid = StepId,
				       type = Type, source = Source,
				       script = Script, user = User,
				       wait_ips = Wait, state = #step_state{}}
				 |Acc1]
			end, [], Steps),

		  [#sub_task{
		      task_id = TaskId, target = Target,
		      steps = TargetSteps}|Acc0]
	  end, [], Task),

    ?DEBUG("build task ~p with subtasks~n~p",[TaskId, SubTasks]),
    {atomic, ok} =
	mnesia:transaction(
	  fun() ->
		  mnesia:write(#task{task_id = TaskId, sub_tasks = SubTasks})
	  end),
    
    {reply, {ok, registered}, State};

handle_call({refresh_task_state, TaskId, TaskState},
	    _From, State) ->
    ?DEBUG("refresh task ~p with state ~p", [TaskId, TaskState]),
    Reply = action_on_task(refresh_task_state,
			   {TaskId, TaskState}),
    {reply, Reply, State};

handle_call({refresh_task, TaskId, {Target, Completed, Step, SN, StepState}},
	    _From, State) ->
    ?DEBUG("refresh target ~p step ~p with stepstate ~p of task ~p",
	   [Target, Step, StepState, TaskId]),
    Reply = action_on_task(refresh_task,
			   {TaskId,
			    {Target, Completed, Step, SN, StepState}}),
    {reply, Reply, State};

handle_call({refresh_task, TaskId,
	     {Target, Completed, Step, SN, StepState,  ECode, EInfo}},
	    _From, State) ->
    ?DEBUG("refresh Target ~p Step ~p with Stepstate ~p of task ~p",
	   [Target, Step, StepState, TaskId]),
    Reply = action_on_task(refresh_task,
			   {TaskId,
			    {Target, Completed, Step, SN, StepState, ECode, EInfo}}),
    {reply, Reply, State};
    
handle_call({is_task_finished, TaskId}, _From, State) ->
    ?DEBUG("is_task_finished, TaskId=~p", [TaskId]),
    
    Reply = action_on_task(is_task_finished, {TaskId, nothing}),
    {reply, Reply, State};

handle_call({lookup_task_detail, TaskId}, _From, State) ->
    ?DEBUG("lookup_task_detail, TaskId=~p", [TaskId]),
    
    Reply = action_on_task(lookup_task_detail, {TaskId, nothing}),
    {reply, Reply, State};

handle_call({modify_caused_by_force_task, TaskId}, _From, State) ->
    ?DEBUG("modify task caused_by_force_task, TaskId=~p", [TaskId]),
    Reply = action_on_task(modify_caused_by_force_task, {TaskId, nothing}),
    {reply, Reply, State};


handle_call({modify_caused_by_retry_task, TaskId, RetryIps}, _From, State) ->
    ?DEBUG("modify task caused_by_retry_task, TaskId ~p, RetryIps ~p",
	   [TaskId, RetryIps]),
    Reply = action_on_task(modify_caused_by_retry_task, {TaskId, RetryIps}),
    {reply, Reply, State};

handle_call(_Request, _From, State) ->
    ?WARN("receive unkown message ~p", [_Request]),
    Reply = ok,
    {reply, Reply, State}.

handle_cast({delete_task, TaskId}, State) ->
    {atomic, ok} = mnesia:transaction(
		     fun() -> mnesia:delete({task, TaskId}) end),
    {noreply, State};

handle_cast(delete_task, State) ->
    Tasks = fun(#task{task_id = TaskId}, _Acc) ->
		    mnesia:delete({task, TaskId})
	    end,
    {atomic, ok} = mnesia:transaction(
		     fun() -> mnesia:foldl(Tasks, [], task) end),
    {noreply, State};

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
    
%% =============================================================================
%% @desc: select * form tasks where taskid=tasks.id
%% @return: record of tasks
%% =============================================================================
-spec get_task(atom(), binary()) -> no_return(). 
get_task(by_id, TaskId) ->
    MS = [{#task{task_id='$1', _ = '_'},         %% head
    	   [{'==', '$1', TaskId}],               %% condition
    	   ['$_']}],                             %% result
    
    case mnesia:transaction(fun() -> mnesia:select(task, MS) end) of
	{atomic, []} ->
	    {error, {task_not_found, TaskId}};
	{atomic, [Task]} ->
	    {ok, Task};
	{aborted, Reason} ->
	    {error, Reason}
    end.

%% =============================================================================
%% @desc: do action on a certain task
%% @param: TaskId -> the task ID
%% @param: State  -> state for current process
%% @param: ActionFun -> a callback function to describe the action on the task
%% =============================================================================
-spec action_on_task(atom(), tuple()) -> no_return(). 
action_on_task(Action, {TaskId, Params}) ->
    case get_task(by_id, TaskId) of
	{error, E} ->
	    E;
	{ok, Task} ->
	    task_action(Action, {Task, Params})
    end.

task_action(modify_caused_by_force_task, {Task, nothing}) ->
    #task{sub_tasks = Subtasks} = Task,
    {_, Unfinished, Failed} = subtasks_info(Subtasks, [], [], []),
    ?DEBUG("unfinished ~p, failed ~p", [Unfinished, Failed]),
    NewSubtasks = 
	lists:foldr(
	  fun(#sub_task{target = Target, steps = Steps} = Subtask, Acc0) ->
		  NewSteps =
		      lists:foldr(
			fun(#step{wait_ips = undefined} = Step, Acc1 ) ->
				[Step|Acc1];
			   (#step{wait_ips = Wait} = Step, Acc1) ->
				case {lists:member(Target, Unfinished),
				      lists:member(Target, Failed)} of
				    {true, false} ->
					[Step#step{
					   wait_ips =
					       binary_delete(Wait, Failed)}
					 |Acc1];
				    {false, true} ->
					[Step#step{
					   wait_ips =
					       binary_delete(Wait, Unfinished)}
					 |Acc1]
				end
			end, [], Steps),	      
		  [Subtask#sub_task{steps = NewSteps}|Acc0]
	  end, [], Subtasks),

    ?DEBUG("NewSubtasks ~p", [NewSubtasks]),
    {atomic, ok} =
    	mnesia:transaction(
    	  fun() ->
    		  mnesia:write(Task#task{sub_tasks = NewSubtasks})
    	  end),
    {modify_ok, Task#task.task_id};

task_action(modify_caused_by_retry_task, {Task, RetryIps}) ->
    #task{sub_tasks = Subtasks} = Task,
    {Finished, _, Failed} = subtasks_info(Subtasks, [], [], []),
    ?DEBUG("Finished = ~p, Failed = ~p, RetryIps = ~p",
	   [Finished, Failed, RetryIps]),    
    UnRetryIps = Failed -- RetryIps ++ Finished,
    ?DEBUG("UnRetryIps = ~p, RetryIps = ~p", [UnRetryIps, RetryIps]),
    NewSubtasks = 
	lists:foldr(
	  fun(#sub_task{target = Target, steps = Steps} = Subtask, Acc0) ->
		  NewSteps =
		      lists:foldr(
			fun(#step{wait_ips = undefined} = Step, Acc1 ) ->
				[Step|Acc1];
			   (#step{wait_ips = Wait} = Step, Acc1) ->
				case lists:member(Target, RetryIps) of
				    true ->
					[Step#step{
					   wait_ips =
					       binary_delete(Wait, UnRetryIps)}
					 |Acc1];
				    false ->
					[Step#step{
					   wait_ips =
					       binary_delete(Wait, RetryIps)}
					 |Acc1]
				end
			end, [], Steps),	      
		  [Subtask#sub_task{steps = NewSteps}|Acc0]
	  end, [], Subtasks),

    %% ?DEBUG("NewSubtasks~n ~p", [NewSubtasks]),
    {atomic, ok} =
    	mnesia:transaction(
    	  fun() ->
    		  mnesia:write(Task#task{sub_tasks = NewSubtasks})
    	  end),
    {modify_ok, Task#task.task_id};

task_action(refresh_task_state, {Task, TaskState}) ->
    {atomic, ok} =
	mnesia:transaction(
	  fun() ->
		  mnesia:write(Task#task{state = ?to_atom(TaskState)})
	  end),
    {refresh_ok, Task#task.task_id};

task_action(refresh_task, {Task,
	    {Target,Completed, Name, SN, StepState}}) ->
    ?DEBUG("refresh_task:~n"
	   "Target ~p, Completed ~p, Step ~p, StepState ~p",
	   [Target, Completed, Name, StepState]),
    task_action(refresh_task,
		{Task, {Target, Completed, Name, SN, StepState, 0, ""}});
    
task_action(refresh_task,
	    {#task{sub_tasks = SubTasks} = Task,
	     {Target, Completed, Name, SN, StepState, ECode, EInfo}}) ->

    ?DEBUG("task_action->refresh_task: Target ~p, "
	   "Completed ~p, Step ~p, SN ~p, StepState ~p, ECode ~p, EInfo ~p",
	   [Target, Completed, Name, SN, StepState, ECode, EInfo]),
    NewSubTasks = 
	lists:foldr(
	  fun(#sub_task{target = Ip, steps = Steps} = SubTask, Acc0)
		when Ip =:= Target ->
		  StepsNew = 
		      lists:foldr(
			fun(Step, Acc1) ->
				case Step#step.sn =:= SN of
				    true ->
					[Step#step{
					   state=#step_state{
					     state = ?to_atom(StepState),
					     finished = ?to_atom(Completed),
					     ecode = ?to_integer(ECode),
					     einfo = ?to_binary(EInfo)}}|Acc1];
				    false ->
					[Step|Acc1]
				end
			end, [], Steps),
		   [SubTask#sub_task{steps = StepsNew}] ++ Acc0;
	     (OldSubTask, Acc0) ->
		  [OldSubTask|Acc0]
	  end, [], SubTasks),

    {atomic, ok} = 
	mnesia:transaction(
	  fun() ->
		  mnesia:write(Task#task{sub_tasks = NewSubTasks})
	  end),
    {refresh_ok, Target};

%% =============================================================================
%% @desc: task was finished or not, 
%%        finished condition: all target stete in Finished state
%% @return true|false
%% =============================================================================
task_action(is_task_finished, {#task{sub_tasks = SubTasks} = _Task, nothing}) ->
    case subtasks_info(SubTasks, [], [], []) of
	{Finished, [], []} ->
	    {true, success, Finished};
	{_, [], Failed} ->
	    {true, failed, Failed};
	{_, Unfinished, _} ->
	    {false, running, Unfinished}
    end;

task_action(lookup_step_of_subtask,
	    {#task{sub_tasks = SubTasks} = _Task, {Target, SN}}) ->
    Steps = lookup_subtask(SubTasks, Target),
    Step  = lookup_step(Steps, SN),
    Step;

task_action(lookup_task_detail,
	    {#task{sub_tasks = SubTasks} = _Task, nothing}) ->
    {Finish, Unfinish, Fail} = subtasks_info(SubTasks, [], [], []),
    {Finish, Unfinish, Fail}.
 
%% =============================================================================
%% @desc: list subtask detail of a task
%% @param: finished   -> finished subtasks
%% @param: unfinished -> unfinished subtasks
%% @param: failed     -> failed subtasks
%% @return 
%% =============================================================================
-spec subtasks_info(list(), list(), list(), list()) -> tuple(). 
subtasks_info([], Finished, Unfinished, Failed) ->
    ?DEBUG("subtasks_info:~nFinished ~p~nUnfinished ~p~nFailed ~p",
    	   [Finished, Unfinished, Failed]),
    {Finished, Unfinished, Failed};

subtasks_info([#sub_task{target = Target, steps = Steps}|Next],
	     Finished, Unfinished, Failed) ->
    case step_info(Steps, [], [], []) of
	{FinishedSteps, [], FailedSteps} -> %% no unfinished steps
	    case {FinishedSteps, FailedSteps} of
		{_, []} -> %% no failed steps, subtasks success
		    subtasks_info(Next, [Target|Finished], Unfinished, Failed);
		{_, _} -> 
		    subtasks_info(Next, Finished, Unfinished, [Target|Failed])
	    end;
	{FinishedSteps, _, FailedSteps} ->
	    case {FinishedSteps, FailedSteps} of
		{_, []} -> %% no failed steps, subtasks running
		    subtasks_info(Next, Finished, [Target|Unfinished], Failed);
		{_, _} ->
		    subtasks_info(Next, Finished, Unfinished, [Target|Failed])
	    end
    end.

%% =============================================================================
%% @desc: get the subtask detial, how many targets was finished, unfinished or failed
%%        condtiion:
%%        1: subtask  in 'running' state,  means the step of the task was in procesing
%%        2: subtask  in 'finish'  state , means finishd or in process
%%        4: subutask in 'timeout' state,  means finished
%%        5: subtask  in 'failed'  state,  means  finished
%% =============================================================================
step_info([], Finished, Unfinished, Failed) ->
    %% ?DEBUG("steps_info: Finished ~p~n, Unfinished ~p~n, Failed ~p",
    %% 	   [Finished, Unfinished, Failed]),
    {Finished, Unfinished, Failed};
step_info([Step|Next], Finished, Unfinished, Failed) ->
    #step{sn = SN,
	  state = #step_state{state=State, finished = Success}} = Step,
    
    %% {Running, Completed, Errored} = knife_utils:step_life_cycle(),
    
    case {State, Success} of
	{running, false} ->
	    step_info(Next, Finished, [SN|Unfinished], Failed);
	{ready, false} ->
	    step_info(Next, Finished, [SN|Unfinished], Failed);
	{artificial, true} ->
	    step_info(Next, [SN|Finished], Unfinished, Failed);
	{finished, true} ->
	    step_info(Next, [SN|Finished], Unfinished, Failed);
	{waiting, true} ->
	    step_info(Next, [SN|Finished], Unfinished, Failed);
	{failed, true} ->
	    step_info(Next, Finished, Unfinished, [SN|Failed]);
	{timeout, true} ->
	    step_info(Next, Finished, Unfinished, [SN|Failed]);
	{nothing, false} ->
	    step_info(Next, Finished, [SN|Unfinished], Failed)
    end.


lookup_subtask([], _) ->
    [];
lookup_subtask([#sub_task{target = Ip, steps = Steps}|_Next],
		       Target)  when Ip =:= Target->
    Steps;
lookup_subtask([_SubTask|Next], Target) ->
    lookup_subtask(Next, Target).

lookup_step([#step{sn = SN} = Step|_Next], InputSN)
  when SN =:= InputSN->
    Step;
lookup_step([_Step|Next], InputSN) ->
    lookup_step(Next, InputSN).

%%--------------------------------------------------------------------
%% @desc : get the task with subtask targets
%% @param: Subtasks ->   whole subtask of the task
%% @param: SubtaskIps -> shoud include in the task
%% @return: a task include the subtask targets
%%--------------------------------------------------------------------
task_with_subtasks(Subtasks, SubtaskIps) ->
    ?DEBUG("task_with_subtasks-> SubtaskIps ~p", [SubtaskIps]),
    lists:foldr(
      fun(#sub_task{target = Target, task_id = TaskId , steps = Steps}, Acc1) ->
	      case lists:member(Target, SubtaskIps) of
		  true ->
		      S = 
			  lists:foldr(
			    fun(#step{sn = SN, name = Name, stepid = StepId,
				      type = Type, source = Source,
				      script = Script, user = User,
				      wait_ips = Wait},
				Acc2) ->
				    [{[{<<"sn">>, SN},
				       {<<"name">>, Name},
				       {<<"stepid">>, StepId},
				       {<<"type">>, Type}]
				      ++ task_fields(
					   [{source, Source}, {script, Script},
					     {user, User}, {wait_ips, Wait}], [])}
				     | Acc2]
			    end, [], Steps),
		      [
		       {[{<<"task_id">>, TaskId},
			 {<<"target">>, Target},
			 {<<"steps">>, S}]}
		       | Acc1];
		  false ->
		      Acc1
	      end
      end, [], Subtasks).


%%--------------------------------------------------------------------
%% @desc : get a subtask failed to execute with the next steps of the failed
%% @param: Subtasks  -> the whole subtasks of a task
%% @param: SubtasIps -> failed target to execute
%% @end
%%--------------------------------------------------------------------
get_next_steps_of_failed_subtasks(Subtasks, FailedIps) ->
    ?DEBUG("get_next_steps_of_failed_subtasks-> SubtaskIps ~p", [FailedIps]),
    lists:foldr(
      fun(#sub_task{target = Target, task_id = TaskId , steps = Steps}, Acc1) ->
	      case lists:member(Target, FailedIps) of
		  true ->
		      [
		       {[{<<"task_id">>, TaskId},
			 {<<"target">>,  Target},
			 {<<"steps">>,   next_steps_of_failed_subtask(Steps)}]}
		       | Acc1];
		  false ->
		      Acc1
	      end
      end, [], Subtasks).

%% --------------------------------------------------------------------
%% @desc : get the steps with json format
%% --------------------------------------------------------------------
next_steps_of_failed_subtask(Steps) ->
    lists:foldr(
      fun(#step{sn = SN, name = Name, stepid = StepId,
		type = Type, source = Source,
		script = Script, user = User,
		wait_ips = Wait,
		state = #step_state{state = State}},
	  Acc1) when State =:= failed; State =:= nothing ->
	      %% assume all failed target are wait for each other
	      [{[
		 {<<"sn">>, SN},
		 {<<"name">>, Name},
		 {<<"stepid">>, StepId},
		 {<<"type">>, Type}]
		++ task_fields(
		     [{source, Source}, {script, Script}, {user, User}], [])
		++ case Wait of
		       undefined ->
			   [];
		       _ ->
			   [{wait_ips, Wait}] end }
	       | Acc1];
	 (_, Acc1) ->
	      Acc1
      end, [], Steps).

task_fields([], Fields) ->
    lists:reverse(Fields);
task_fields([{Name, Value}|Next], Fields) ->
    task_fields(Next, task_field(Name, Value) ++ Fields).
	
task_field(_, undefined) ->
    [];
task_field(Name, Value) ->
    [{?to_binary(Name), Value}].

binary_delete(B1, B2) when is_list(B1) ->
    ?to_binary_ips(B1 -- B2);
binary_delete(B1, B2) when is_binary(B1) ->
    ?to_binary_ips(?to_iplist(B1) -- B2).

    
%% =============================================================================
%% tasks
%% =============================================================================

%%--------------------------------------------------------------------
%% @desc:  build a task by certain instance
%% @param: InstanceId
%% @param: TaskId
%% @return: a tasks with format as follow
%% [{[{<<"task_id">>,<<"12345678">>},
%%     {<<"target">>,<<"10.20.96.160">>},
%%     {<<"steps">>,
%%      [{[{<<"sn">>,<<"0">>},
%%         {<<"name">>,<<"download">>},
%%         {<<"source">>,<<"ftp://10.20.96.160/download_test">>}]},
%%       {[{<<"sn">>,<<"1">>},
%%         {<<"name">>,<<"unzip">>},
%%         {<<"script_exe">>,
%%          <<"/home/buxianhui/download_test/jx_online_3.sh unzip">>}]},
%%       {[{<<"sn">>,<<"2">>},
%%         {<<"name">>,<<"stop">>},
%%         {<<"script_exe">>,
%%          <<"/home/buxianhui/download_test/jx_online_3.sh stop">>}]},
%%       {[{<<"sn">>,<<"3">>},
%%         {<<"name">>,<<"restart">>},
%%         {<<"script_exe">>,
%%          <<"/home/buxianhui/download_test/jx_online_3.sh restart">>}]},
%%    {[{<<"task_id">>, <<"12345678">>},
%%      {<<"target">>, <<"10.20.96.157">>},
%%      {<<"steps">>}, [...]
%%    }]}
%% ]}]}]
%%--------------------------------------------------------------------
alarms_to_task(InstanceId) ->
    case controller_mysql_table:alarms_of_instance({instance_id, InstanceId}) of
	empty ->
	    throw({error, empty_alarm});
	Alarm ->
	    Alarm
    end.


instance_to_task(InstanceId, TaskId) ->
    %% first, we get all the steps of a task by given instance
    case controller_mysql_table:steps_of_instance({instance_id, InstanceId}) of
	empty_step ->
	    throw({error, empty_step});
	no_target_step ->
	    throw({error, no_target_step});
	Steps ->
	    %% second, we build a certain formated task by steps
	    {AllTargets, Task} =
		steps_to_task(steps_to_target(Steps, []), TaskId),
	    ?DEBUG("get task~n~p with taskid ~p of instance ~p",
		   [Task, TaskId, InstanceId]),
	    {ok, {AllTargets, Task}}
    end.


steps_to_task(Targets, TaskId) ->
    AllTargetIps = class(Targets),
    Task = 
	lists:foldl(
	  fun(Ip, Acc) ->
		  [ {[{<<"task_id">>, ?to_binary(TaskId)}]
		     ++ step_to_subtask(Targets, Ip, [])} | Acc]
	  end, [], AllTargetIps),
    {AllTargetIps, Task}.

steps_to_target([], Targets) ->
    lists:reverse(Targets);
steps_to_target([Step|NextStep], Targets) ->
    Steps = steps(Step),
    steps_to_target(NextStep, Steps ++ Targets).

steps([{<<"target">>, Targets}|StepProps])->
    Ips = [ ?to_binary(string:strip(Ip))
	    || Ip <- string:tokens(?to_string(Targets), ",")],
    [ [{<<"target">>, Ip}, {<<"steps">>, {StepProps}} ] || Ip <- Ips].


class(Targets) ->
    Ips = 
	lists:foldr(
	  fun([{<<"target">>, Ip}, _], Acc) ->
		  case lists:member(Ip, Acc) of
		      true  -> Acc;
		      false -> [Ip|Acc]
		  end
	  end, [], Targets),
    Ips.

%%--------------------------------------------------------------------
%% @desc:  get a subtask by certain ip, by the way, give a sequence
%%         to every step of this subtask
%% @param: steps -> tasks's steps, including all target
%% @param: ip    -> certain ip
%% @param: steps -> all steps of subtask
%% @return: subtask with sequenced steps
%%--------------------------------------------------------------------
step_to_subtask([], Ip, Steps) ->
    [{<<"target">>, ?to_binary(Ip)}] ++ [{<<"steps">>, lists:reverse(Steps)}];
step_to_subtask([ [{<<"target">>, T}, {<<"steps">>, {Step}} ]|N], Ip, Steps) ->
    %% ?DEBUG("step_to_subtask-> target ~p, Ip ~p", [T, Ip]),
    case ?to_binary(T) =:= ?to_binary(Ip) of
	true  ->	    
	    step_to_subtask(N, Ip, [{Step}| Steps]);
	false ->
	    step_to_subtask(N, Ip, Steps)
    end.

