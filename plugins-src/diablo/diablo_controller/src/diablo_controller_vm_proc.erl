
%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright Seasun(C) 2014, buxianhui
%%% @doc
%%%  Agent information which connect to the forest proxy
%%% @end
%%% Created :  4 Mar 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_controller_vm_proc).

-include("../../../../include/knife.hrl").

-behaviour(gen_server).

%% API
-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-export([insert/2, lookup/1, delete/1]).

-define(SERVER, ?MODULE).
-define(CONTROL_VM_PROC, diablo_vm_proc).

-record(state, {}).


insert(UID, Proc) when is_pid(Proc)->
    gen_server:call(?SERVER, {new_proc, {UID, pid_to_list(Proc)}}).

lookup(all) ->
    gen_server:call(?SERVER, {lookup_all});

lookup(UID) ->
    gen_server:call(?SERVER, {lookup, UID}).

delete(UID) ->
    gen_server:call(?SERVER, {delete, UID}).

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

init([]) ->
    %% TableId = ets:new(?FOREST_NODE, [bag, private, named_table]),
    ets:new(?CONTROL_VM_PROC, [set, private, named_table]),
    {ok, #state{}}.

handle_call({new_proc, {UID, Proc}}, _From, State)->
    ?DEBUG("new_proc with parameters: UID ~p, Proc ~p", [UID, Proc]),
    true = ets:insert(?CONTROL_VM_PROC, {?to_string(UID), Proc}),
    {reply, ok, State};

handle_call({delete, UID}, _From, State) ->
    ?DEBUG("delete with parameters: UID ~p", [UID]),
    true = ets:delete(?CONTROL_VM_PROC, ?to_string(UID)),
    {reply, ok, State};

handle_call({lookup, UID}, _From, State)->
    ?DEBUG("lookup with parameters: UID ~p", [UID]),
    MS = [{{'$1', '$2'},
	   [{'==', '$1', ?to_string(UID)}],
	   ['$2']
	  }],
    Proc = ets:select(?CONTROL_VM_PROC, MS),
    {reply, {ok, Proc}, State};

handle_call({lookup_all}, _From, State)->
    Socks = ets:tab2list(?CONTROL_VM_PROC),
    {reply, {ok, Socks}, State};
    
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
