%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright Seasum(C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created :  5 Aug 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_controller_vm).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_server).

%% API
-export([start_link/0]).

-export([process/2, do/3]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-define(SERVER, ?MODULE).
-define(UNINITIAL_UUID, 16#FFFF).

-record(state, {}).

process(new_request, {Properties, HttpReq}) ->
    gen_server:call(?SERVER, {new_request, Properties, HttpReq});
process(response, Message) ->
    gen_server:call(?SERVER, {response, Message}).

%%%===================================================================
%%% API
%%%===================================================================

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

init([]) ->
    {ok, #state{}}.

handle_call({new_request, Properties, HttpReq}, _From, State) ->
    %% process_flag(trap_exit, true),
    ?DEBUG("new_vm_request with parameters: Properties ~p", [Properties]),
    Proc = proc_lib:spawn(?MODULE, do, [new_vm, ?UNINITIAL_UUID, HttpReq]),

    UID = knife_uuid:v4(string),
    ok = diablo_controller_vm_proc:insert(UID, Proc),
    Proc ! {new_vm, [{<<"UID">>, ?to_binary(UID)}] ++ Properties},
    
    {reply, Proc, State};

handle_call({response, Message}, _From, State) ->
    ?DEBUG("response with message ~p", [Message]),
    UID = proplists:get_value(<<"UID">>, Message),
    Reply = 
	case diablo_controller_vm_proc:lookup(UID) of
	    {ok, []} ->
		?WARN("no valid proc to process message ~p, "
		      "discard it", [Message]),
		{error, no_valid_proc};
	    {ok, [Proc]} ->
		Pid = list_to_pid(Proc),
		case erlang:is_process_alive(Pid) of
		    true ->
			?DEBUG("message ~p will send to ~p", [Message, Pid]),
			Pid ! {response, Message},
			ok;
		    false ->
			?DEBUG("proc ~p is not alive, discard message ~p",
			       [Pid, Message]),
			{error, no_alived_proc}
		end
	end,
    {reply, Reply, State};
    
handle_call(Request, _From, State) ->
    ?DEBUG("receive unkown Request ~p", [Request]),
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
do(Action, UID, HttpReq) ->
    ?DEBUG("do -> action ~p with UID ~p", [Action, UID]),
    Timeout = action_timeout(?to_atom(Action)),
    
    receive
	{new_vm, Properties} ->
	    Message = [{<<"method">>, <<"new_vm">>}] ++ Properties,
	    ?DEBUG("send a new vm message ~p", [Message]),

	    ok = diablo_controller_vm_mnesia:new(vm, Properties),
	    
	    diablo_controller_mq_handler:publish(direct, {Message}),
	    do(Action, UID, HttpReq);

	{response, [{<<"method">>, Method}, _UID, {<<"sn">>, SN}|Response]} ->
	    ?DEBUG("response with method ~p, SN ~p, response ~p:",
		   [Method, SN, Response]),
	    do_response(?to_atom(Method), SN, Response, HttpReq),
	    routine(Response, fun() -> do(Action, UID, HttpReq) end);
	
	Unkown ->
	    ?DEBUG("Receive unkown message ~p, continue...", [Unkown]),
	    do(Action, UID, HttpReq)

    after Timeout ->
	    ?DEBUG("vm action ~p with UID ~p timeout and will exit", [Action, UID]),
	    exit({action_timeout, Action})
    end.


do_response(new_vm, SN, Response, _HttpReq) ->
    ?DEBUG("do_response-> new_vm with parameters: "
	   "SN ~p, Response ~p", [SN, Response]),
    ECode = ?to_integer(proplists:get_value(<<"ecode">>, Response)),
    
    State = state(new_vm, ?to_integer(ECode)),
    ok = diablo_controller_vm_mnesia:update(state, {SN, State});

%% =============================================================================
%% @desc: synchronous operation return a HTTP response immediately
%% =============================================================================
do_response(Method, SN, Response, HttpReq) ->
    ?DEBUG("do_response with parameters: "
	   "method ~p, SN ~p, response ~p", [Method, SN, Response]),
    HttpReq:respond({200,
		 [{"Content-Type", "application/json"}],
		 ejson:encode({Response})}).

action_timeout(new_vm) ->
    20000.


routine(Response, DoFun) when is_function(DoFun) ->
    case ?to_integer(proplists:get_value(<<"ecode">>, Response)) of
	8888 ->
	    ?DEBUG("routine continue ...."),
	    DoFun();
	7777 ->
	    ?DEBUG("routine continue ...."),
	    DoFun();
	_ ->
	    ?DEBUG("routine end ...."),
	    none
    end.

state(new_vm, 8888) ->
    creating;
state(new_vm, 7777) ->
    ping;
state(new_vm, 0) ->
    created;
state(new_vm, _) ->
    failed.
