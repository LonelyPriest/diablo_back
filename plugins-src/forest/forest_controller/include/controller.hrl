%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright Seasun(C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created :  7 Mar 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------

-define(STEP_TIMEOUT, 9999).
-define(STEP_RUNNING, 8888).
-define(STEP_FINISH,  3333).
-define(TASK_PROCESSING, 8888).
-define(STEP_TRANSFER, 7777).
-define(TASK_FINISHED, 0).
-define(TASK_FAILED, 1).
-define(TASK_RUNNING, 2).

-define(EXECUTE_TASK, "execute_task").

-define(to_err(Err, Key), controller_error:error(Err, Key)).
-define(to_err_code(Code), controller_error:step_state_to_code(Code)).


-define(record_to_tuplelist(Rec, Ref),
	lists:zip(record_info(fields, Rec),tl(tuple_to_list(Ref)))).

-define(to_iplist(BinaryIpString),
	knife_utils:binary_to_iplist(BinaryIpString, <<>>, [])).
-define(to_binary_ips(BinaryIpList),
	knife_utils:iplist_to_binary(BinaryIpList, <<>>)).

-define(TABLE_INSTANCES,  deploy_instances).
-define(TABLE_STEPS,      deploy_steps).
-define(TABLE_TASKS,      deploy_tasks).
-define(TABLE_SUBTASKS,   deploy_subtasks).
-define(TABLE_EVENTS,     deploy_events).

-define(CONTINUE_TASK, <<"2">>).
-define(FORCE_TASK, <<"3">>).

-record(step_state,
       {
	 state = nothing      :: atom(),            %% running|finished|failed|timeout
	 finished = false     :: true | false,      %% the target is finished or not
	 ecode = -1           :: integer(),         %% the state code
	 einfo = <<>>         :: binary()           %% error information when current state was failed
       }).
-type step_state() :: #step_state{}.

-record(step,
       {
	 sn              = -1        :: integer(),
	 name                        :: string()|binary(),
	 stepid          = -1        :: integer(),
	 type            = -1        :: integer(),
	 source          = undefined :: undefined|string()|binary(),
	 script          = undefined :: undefined|string()|binary(),
	 user            = undefined :: undefined|string()|binary(),
	 wait_ips        = undefiend :: undefined|string()|binary(),
	 state                       :: step_state()
       }).
-type step() :: #step{}.

-record(sub_task,
       {
	 task_id,                                 %% which task belong to
	 target,                                  %% IP address
	 steps           :: [step()]|'_'
       }).
-type sub_task() :: #sub_task{}.

-record(task,
	{
	  task_id,
	  state =  undefined   :: atom(),
	  sub_tasks            :: [sub_task()]|'_'
	}).

-record(task_break,
	{
	  task_id,
	  break,
	  wait_targtes = []
	}).
