%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright SeasunGame(C) 2014, buxianhui
%%% @doc
%%%  A target state of tasks, a task finished only when all target
%%%  finished
%%% @end
%%% Created :  8 Apr 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(controller_task_proc).

-include("../../../include/knife.hrl").

-behaviour(gen_server).

%% API
-export([start_link/0]).

-export([new/2, lookup/1, lookup/0, delete/1]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-define(SERVER, ?MODULE).
-define(TASK_PROCS, task_procs).
%% -define(TARGET_STEP_STATE, target_step_state).

-record(state, {}).


%%% =============================================================================
%%% Interface
%%% =============================================================================
new(TaskId, Proc) when is_pid(Proc) ->
    gen_server:call(?SERVER, {new_proc, TaskId, pid_to_list(Proc)}).

lookup(TaskId) ->
    gen_server:call(?SERVER, {lookup_proc, TaskId}).
lookup() ->
    gen_server:call(?SERVER, {lookup_proc}).

delete(TaskId) ->
    gen_server:call(?SERVER, {delete_proc, ?to_binary(TaskId)}).

%%%===================================================================
%%% API
%%%===================================================================

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

init([]) ->
    ets:new(?TASK_PROCS, [private, set, named_table]),
    %% ets:new(?TARGET_STEP_STATE, [private, set, named_table]),
    {ok, #state{}}.

handle_call({new_proc, TaskId, Proc}, _From, State)->
    ?DEBUG("add new process ~p assocaite task ~p", [Proc, TaskId]),
    true = ets:insert(?TASK_PROCS, {TaskId, Proc}),
    {reply, ok, State};

handle_call({lookup_proc, TaskId}, _From, State) ->
    MS =  [
	   {{'$1', '$2'},
	    [{'==', '$1', TaskId}],
	    ['$2']
	   }],
    Proc = ets:select(?TASK_PROCS, MS),
    {reply, Proc, State};

handle_call({lookup_proc}, _From, State) ->
    {reply, {ets:tab2list(?TASK_PROCS)}, State};

handle_call({delete_proc, TaskId}, _From, State) ->
    ?DEBUG("delete process assocaite task ~p", [TaskId]),
    MS =  [
	   {{'$1', '_'},
	    [{'==', '$1', TaskId}],
	    [true]
	   }],
    _N = ets:select_delete(?TASK_PROCS, MS),
    {reply, ok, State};
    
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

%%%===================================================================
%%% Internal functions
%%%===================================================================
