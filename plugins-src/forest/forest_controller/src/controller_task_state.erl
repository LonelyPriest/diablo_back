%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright Seasun(C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created :  3 Jun 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(controller_task_state).

-include("../../../include/knife.hrl").
-include("controller.hrl").

-behaviour(gen_server).

%% API
-export([start_link/0]).
-export([save_task/3, wait_targets/1,
	 wait_targets/2, lookup/0, delete/0, delete/2]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-define(SERVER, ?MODULE). 

-record(state, {}).

%%%===================================================================
%%% API
%%%===================================================================
save_task(TaskId, BreakType, WaitTargets)->
    gen_server:call(?SERVER, {save_task, TaskId, BreakType, WaitTargets}).

wait_targets(TaskId, BreakType) ->
    gen_server:call(?SERVER, {wait_targets, TaskId, BreakType}).

lookup() ->
    gen_server:call(?SERVER, lookup_all).

wait_targets(TaskId) ->
    gen_server:call(?SERVER, {wait_targets, TaskId}).

delete() ->
    gen_server:call(?SERVER, delete_all).

delete(TaskId, BreakType) ->
    gen_server:call(?SERVER, {delete, TaskId, BreakType}).


start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

init([]) ->
    {ok, #state{}}.

handle_call({save_task, TaskId, BreakType, WaitTargets}, _From, State) ->
    ?DEBUG("save_task-> TaskId ~p, BreakType ~p, WaitTargets ~p",
	   [TaskId, BreakType, WaitTargets]),
    {atomic, ok} =
	mnesia:transaction(
	  fun() ->
		  mnesia:write(
		    #task_break{
		       task_id      = TaskId,
		       break        = BreakType,
		       wait_targtes = WaitTargets})
		      
	  end),

    {reply, {ok, save_task}, State};

handle_call({wait_targets, TaskId, BreakType}, _From, State) ->
    MS = [{#task_break{task_id='$1', break='$2', _='$3'}, 
    	   [{'==', '$1', TaskId}, {'==', '$2', BreakType}],               
    	   ['$3']}],

    Reply = 
	case mnesia:transaction(fun() -> mnesia:select(task_break, MS) end) of
	    {atomic, []} ->
		{ok, no_target};
	    {atomic, [Ips]} ->
		{ok, Ips};
	    {abborted, Reason} ->
		{error, Reason}
	end,

    {reply, Reply, State};


handle_call({wait_targets, TaskId}, _From, State) ->
    MS = [{#task_break{task_id='$1', _ = '_'}, 
    	   [{'==', '$1', TaskId}],               
    	   ['$_']}],

    Reply = 
	case mnesia:transaction(fun() -> mnesia:select(task_break, MS) end) of
	    {atomic, []} ->
		{ok, no_target};
	    {atomic, [#task_break{break = BreakType, wait_targtes = Ips}]} ->
		{ok, {BreakType, Ips}};
	    {abborted, Reason} ->
		{error, Reason}
	end,

    {reply, Reply, State};

handle_call(lookup_all, _From, State) ->
    {atomic, TaskState} =
	mnesia:transaction(
	  fun() ->
		  mnesia:select(task_break, [{#task_break{ _= '_'}, [], ['$_']}])
	  end),
    {reply, TaskState, State};

handle_call(delete_all, _From, State) ->
    D = #task_break{ _ = '_'},
    {atomic, ok} =
	mnesia:transaction(
	  fun() ->
		  lists:foreach(
		    fun(E) ->
			    mnesia:delete_object(E)
		    end, mnesia:match_object(D))
	  end),
    {reply, ok, State};

handle_call({delete, TaskId, BreakType}, _From, State) ->
    D = #task_break{task_id = TaskId, break = BreakType, _ = '_'},
    {atomic, ok} =
	mnesia:transaction(
	  fun() ->
		  lists:foreach(
		    fun(E) ->
			    mnesia:delete_object(E)
		    end, mnesia:match_object(D))
	  end),
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
