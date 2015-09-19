%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright SeasunGame(C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 21 Mar 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(forest_step).

-include("forest.hrl").

-include("../../../include/knife.hrl").

-behaviour(gen_server).

%% API
-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-export([process/2, do/5]).

-define(SERVER, ?MODULE). 
-define(AGENT_STEP_TO_PROXY, agent_step_to_proxy).

-record(state, {}).


process(step, {[{<<"method">>, <<"cancel_task">>},
		{<<"task_id">>, TaskId}]}) ->
    gen_server:cast(?SERVER, {cancel_task, TaskId});

process(step, Message) when is_list(Message)->
    gen_server:call(?SERVER, {step_to_agent, Message});

process(step, Message) ->
    ?WARN("Receive unkown Message=~p", [Message]).


    
%%%===================================================================
%%% API
%%%===================================================================
start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

init([]) ->
    ets:new(?AGENT_STEP_TO_PROXY, [set, private, named_table]),
    {ok, #state{}}.

handle_call({step_to_agent, Task}, _From, State) ->
    ?DEBUG("Receive task:~n~p", [Task]),

    %% spawn a process to process every subtask of the task
    process_flag(trap_exit, true),
    lists:foreach(
      fun({[{<<"task_id">>, TaskId},
	    {<<"target">>, Target},
	    {<<"steps">>, Steps}]} = _SubTask) ->
	      case forest_node:lookup(?to_string(Target)) of
		  {ok, [{_, Reader}|_]} ->
		      %% [InitStep|_] = Steps,		      
		      %% start
		      case find_real_steps({TaskId, Target}, Steps) of
			  [] ->
			      %% no next steps, report finished
			      ?DEBUG("no steps found, task ~p finished", [TaskId]),
			      notify(TaskId, Target, true,
				     lists:last(Steps), finished, []);
			  [CurrentStep|_] = NewSteps ->
			      ?DEBUG("spawn a new proc to process target ~p~n"
				     "with steps~p",
				     [Target, get_steps_detail(NewSteps)]),
		      
			      TargetProc = proc_lib:spawn(
					     ?MODULE, do,
					     [TaskId, Target, CurrentStep,
					      NewSteps, list_to_pid(Reader)]),
			      
			      ?DEBUG("success to spawn proc ~p to process "
				     "target ~p~n", [TargetProc, Target]),
			      
			      TargetProc !
				  {start, {TaskId, Target, CurrentStep}},
			      forest_target_proc:new(TaskId, Target, TargetProc)
		      end;
		  {ok, []} ->
		      ?DEBUG("target ~p was not connect to proxy", [Target]),
		      %% {_, _, Failed} =
		      %% 	  knife_utils:step_life_cycle(),
		      {ECode, EInfo} =
			  forest_error:error(target_not_connect, Target),

		      CurrentStep = 
			  case find_real_steps({TaskId, Target}, Steps) of
			      [] -> [H|_] = Steps, H;
			      [H|_] -> H
			  end,
		      ok = notify(
			     TaskId, Target, true, CurrentStep, failed,
			     [{<<"ecode">>,   ?to_binary(ECode)}, 
			      {<<"einfo">>,   ?to_binary(EInfo)}])
	      end
      end, Task),
    
    {reply, ok, State};
    
handle_call(Request, _From, State) ->
    ?DEBUG("Receive unkown call message ~p", [Request]),
    Reply = ok,
    {reply, Reply, State}.

handle_cast({cancel_task, TaskId}, State) ->
    forest_target_state:delete_steps(TaskId),
    {noreply, State};

handle_cast(Msg, State) ->
    ?DEBUG("Receive unkown cast message ~p", [Msg]),
    {noreply, State}.


handle_info(Info, State) ->
    ?DEBUG("Receive Info message ~p", [Info]),
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.


%% =============================================================================
%% internal interface
%% =============================================================================
do(TaskId, Target, CurrentStep, Steps, Reader) ->
    ?DEBUG("enter loop to process subtask: with parameters~n"
	   "TaskId = ~p, Target = ~p, ~nCurrentStep=~p,~n"
	   "all Steps = ~p,~n Reader=~p",
	   [TaskId, Target,
	    get_steps_detail(CurrentStep), get_steps_detail(Steps), Reader]),
    
    Timeout = action_timeout(),
    %% {Running, Finished, Failed} = knife_utils:step_life_cycle(),

    receive
	{start, {TaskId, Target, InitStep}} ->
	    ?DEBUG("start to process target ~p~nwith step ~p of task ~p",
		   [Target, get_steps_detail(InitStep), TaskId]),
	    Reader ! {to_agent, 
	      [{<<"task_id">>, TaskId},
	       {<<"target">>, Target},
	       {<<"step">>, InitStep}]},
	    
	    do(TaskId, Target, CurrentStep, Steps, Reader);

	%% step process should be exit, and waiting for artificial process
	{ok, {TaskId, Target}, {SN, Name, <<"3">> = Type, artificial}}->
	    ?DEBUG("step ~p[sn=~p] with type ~p, "
		   "on target ~p artificial with task ~p",
		   [Name, Type, SN, Target, TaskId]),
	    ok = notify(TaskId, Target, true, CurrentStep, artificial, []),
	    %% save current state
	    forest_target_state:save_steps(TaskId, Target, CurrentStep),
	    ?DEBUG("receive artificial step ~p, "
		   "proc ~p of target ~p with task ~p will be exit",
		   [Name, self(), Target, TaskId]);

	%% step process should be exit, and waiting for standby
	{ok, {TaskId, Target}, {SN, Name, <<"4">> = Type, waiting}}->
	    ?DEBUG("step ~p[sn=~p] with type ~p, "
		   "on target ~p waiting with task ~p",
		   [Name, Type, SN, Target, TaskId]),
	    ok = notify(TaskId, Target, true, CurrentStep, waiting, []),
	    %% save current state
	    forest_target_state:save_steps(TaskId, Target, CurrentStep),
	    ?DEBUG("receive standby step ~p, "
		   "proc ~p of target ~p with task ~p will be exit",
		   [Name, self(), Target, TaskId]);

	{ok, {TaskId, Target}, {SN, Name, _Type, running}} ->
	    ?DEBUG("step ~p[sn=~p] on target ~p running with task ~p",
		   [Name, SN, Target, TaskId]),
	    %% notify controller I am running
	    ok = notify(TaskId, Target, false, CurrentStep, running, []),
	    do(TaskId, Target, CurrentStep, Steps, Reader);
	
	{ok, {TaskId, Target}, {SN, Name, _Type, finished}}->
	    ?DEBUG("step ~p[sn=~p] on target ~p finished with task ~p",
		   [Name, SN, Target, TaskId]),
	    
	    ok = notify(TaskId, Target, true, CurrentStep, finished, []),

	    case get_next_step(CurrentStep, Steps) of
		[] ->
		    ?DEBUG("task ~p on target finished with last step ~p~n"
			   "exit self ~p as soon",
			   [TaskId, get_steps_detail(CurrentStep), self()]),
		    
		    forest_target_proc:delete(TaskId, Target),
		    forest_target_state:delete_steps(TaskId, Target),
		    exit({task_on_target_finished, TaskId, Target});
		NextStep ->
		    ?DEBUG("target continue with next step ~p", [NextStep]),
		    Reader ! {to_agent, 
			      [{<<"task_id">>, TaskId},
			       {<<"target">>, Target},
			       {<<"step">>, NextStep}]},

		    %% ok = notify(TaskId, Target, true, CurrentStep, Finished, []),
		    do(TaskId, Target, NextStep, Steps, Reader)
	    end;
	
	{ok, {TaskId, Target}, {SN, Name, _, failed, ECode, EInfo}} ->
	    ?DEBUG("step ~p[sn:~p] of task ~p on target ~p failed "
		   "with ECode ~p~n, EInfo ~p and weill exit itself ~p",
		    [Name, SN, TaskId, Target, ECode, EInfo, self()]),

	    %% delete the process
	    forest_target_proc:delete(TaskId, Target),
	    forest_target_state:delete_steps(TaskId, Target),
	    
	    %% notify controller I am completed
	    ok = notify(TaskId, Target, true, CurrentStep, failed, [ECode, EInfo]),
	    exit({task_on_target_failed, TaskId, Target});
	
	Unkown ->
	    ?DEBUG("Receive unkown message ~p, continue...", [Unkown]),
	    do(TaskId, Target, CurrentStep, Steps, Reader)
		
    after Timeout ->
	    ?DEBUG("step ~p on target ~p of task ~p timout and will exit itself ~p",
		    [CurrentStep, Target, TaskId, self()]),
	    
	    forest_target_proc:delete(TaskId, Target),
	    forest_target_state:delete_steps(TaskId, Target),
	    
	    %% notify controller I am timeout
	    {ECode, EInfo} =
		forest_error:error(step_timeout, Target),
	    %% {[{<<"sn">>, SN}|_]} = CurrentStep,
	    ok = notify(TaskId, Target, true,CurrentStep, failed,
			[{<<"ecode">>,   ?to_binary(ECode)},
			 {<<"einfo">>,   ?to_binary(EInfo)}]),
	    exit({action_time_out,{CurrentStep, Target}})
    end.
    
action_timeout() ->
    20000.

get_next_step(_Current, []) ->
    [];
get_next_step({[{<<"sn">>, CurrentSN}|_]},
	      [{[{<<"sn">>, SN}|_]}|NextStep])
  when CurrentSN =:= SN ->
    case NextStep of
	[]    -> [];
	[H|_] -> H
    end;
get_next_step(Current, [_Step0|NextStep]) ->
    get_next_step(Current, NextStep).


get_left_step(_Current, []) ->
    [];
get_left_step({[{<<"sn">>, CurrentSN}|_]},
	      [{[{<<"sn">>, SN}|_]}|NextSteps])
  when CurrentSN =:= SN ->
    NextSteps;
get_left_step(Current, [_Step0|NextSteps]) ->
    get_left_step(Current, NextSteps).



notify(TaskId, Target, Finished,
       {[{<<"sn">>, SN}, {<<"name">>, Name},
	 {<<"stepid">>, Id}, {<<"type">>, Type}|_]} = Step,
       State, ExtraInfo) ->
    ?DEBUG("report step ~n~p with~nstate ~p and extra info~p to contorller",
	   [Step, State, ExtraInfo]),
    forest_fanout_mq_handler:publish(
      direct,
      {[{<<"from">>,     <<"proxy">>},
	{<<"task_id">>,  TaskId},
	{<<"target">>,   Target},
	{<<"step">>,     Name},
	{<<"stepid">>,   Id},
	{<<"sn">>,       SN},
	{<<"type">>,     Type},
	{<<"finished">>, ?to_binary(Finished)},
	{<<"state">>,    ?to_binary(State)}] ++ ExtraInfo}),
    ok.


get_steps_detail(Steps) when is_list(Steps)->
    lists:foldr(
     fun({[SN, Name|_]}, Acc) ->
	     [{[SN, Name]}|Acc]
     end, [], Steps);
get_steps_detail({[SN, Name|_]}) ->
    {[SN, Name]}.
    

find_real_steps({TaskId, Target}, OldSteps) ->
    case forest_target_state:lookup_steps(
	   TaskId, Target) of
	[] ->
	    %% now steps save before, use the old
	    OldSteps;
	[#target_state{steps = LastSteps}] ->
	    %% save steps before, continue the saved steps
	    get_left_step(LastSteps, OldSteps)
    end.
	    
