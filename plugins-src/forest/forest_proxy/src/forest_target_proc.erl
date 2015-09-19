%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright SeasunGame(C) 2014, buxianhui
%%% @doc
%%%  A target state of tasks, a task finished only when all target
%%%  finished
%%% @end
%%% Created :  8 Apr 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(forest_target_proc).

-include("../../../include/knife.hrl").

-behaviour(gen_server).

%% API
-export([start_link/0]).

-export([new/3, lookup/2, lookup/1, lookup/0,
	 delete/1, delete/2]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-define(SERVER, ?MODULE).
-define(TARGET_STEP_PROC, target_step_proc).
%% -define(TARGET_STEP_STATE, target_step_state).

-record(state, {}).


%%% =============================================================================
%%% Interface
%%% =============================================================================
new(TaskId, Target, Proc) when is_pid(Proc) ->
    gen_server:call(?SERVER,
		    {new_proc, TaskId, Target, pid_to_list(Proc)}).

lookup(TaskId, Target) -> 
    gen_server:call(?SERVER, {lookup_proc, TaskId, Target}).
lookup(TaskId) ->
    gen_server:call(?SERVER, {lookup_proc, TaskId}).
lookup() ->
    gen_server:call(?SERVER, {lookup_proc}).

delete(TaskId, Target) ->
    gen_server:call(?SERVER, {delete_proc, TaskId, Target}).
delete(TaskId) ->
    gen_server:call(?SERVER, {delete_proc, TaskId}).

%%%===================================================================
%%% API
%%%===================================================================

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

init([]) ->
    ets:new(?TARGET_STEP_PROC, [private, set, named_table]),
    %% ets:new(?TARGET_STEP_STATE, [private, set, named_table]),
    {ok, #state{}}.

handle_call({new_proc, TaskId, Target, Proc}, _From, State)->
    ?DEBUG("new process: task ~p, target ~p, proc ~p", [TaskId, Target, Proc]),
    true = ets:insert(?TARGET_STEP_PROC, {{TaskId, Target}, Proc}),
    {reply, ok, State};

handle_call({lookup_proc, TaskId, Target}, _From, State) ->
    %% Proc = ets:lookup(?TARGET_STEP_PROC, {TaskId, Target}),
    MS =  [
	   {{{'$1', '$2'}, '$3'},
	    [{'==', '$1', TaskId}, {'==', '$2', Target}],
	    ['$3']
	   }],
    Proc = ets:select(?TARGET_STEP_PROC, MS),
    {reply, Proc, State};

handle_call({lookup_proc, TaskId}, _From, State) ->
    MS =  [
	   {{{'$1', '_'}, '$3'},
	    [{'==', '$1', TaskId}],
	    ['$3']
	   }],
    Detail = ets:select(?TARGET_STEP_PROC, MS),
    {reply, Detail, State};

handle_call({lookup_proc}, _From, State) ->
    {reply, {ets:tab2list(?TARGET_STEP_PROC)}, State};

handle_call({delete_proc, TaskId}, _From, State) ->
    MS =  [
	   {{{'$1', '_'}, '_'},
	    [{'==', '$1', TaskId}],
	    [true]
	   }],
    N = ets:select_delete(?TARGET_STEP_PROC, MS),
    {reply, N, State};

handle_call({delete_proc, TaskId, Target}, _From, State) ->
    MS =  [
	   {{{'$1', '$2'}, '_'},
	    [{'==', '$1', TaskId}, {'==', '$2', Target}],
	    [true]
	   }],
    N = ets:select_delete(?TARGET_STEP_PROC, MS),
    {reply, N, State};
    
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
