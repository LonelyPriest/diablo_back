%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright Seasun(C) 2014, buxianhui
%%% @doc
%%%  the task state of certain target
%%% @end
%%% Created :  3 Jun 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_controller_vm_mnesia).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_server).

%% API
-export([start_link/0]).
-export([new/2, update/2, lookup/1, current_time/1]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-define(SERVER, ?MODULE). 

-record(state, {}).

%%%===================================================================
%%% API
%%%===================================================================
new(vm, VMAttrs) ->
    gen_server:call(?SERVER, {new_vm, VMAttrs}).

update(state, {SN, VMState}) ->
    gen_server:call(?SERVER, {update_state, SN, VMState}).

lookup(vms) ->
    gen_server:call(?SERVER, lookup_vms);
lookup(state) ->
    gen_server:call(?SERVER, lookup_vm_state).
    
start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

init([]) ->
    case mnesia:system_info(use_dir) of
	true ->
	    ok = mnesia:start(),
	    ok;
	false ->
	    stopped = mnesia:stop(),
	    ok = mnesia:create_schema([node()]),
	    ok = mnesia:start(),
	    lists:foreach(
	      fun({Tab, TabDef}) ->
		      TabDef1 = proplists:delete(match, TabDef),
		      case mnesia:create_table(Tab, TabDef1) of
			  {atomic, ok} -> ok;
			  {aborted, Reason} ->
			      throw({error, {table_creation_failed,
					     Tab, TabDef1, Reason}})
		      end		      
		      
	      end, table_definitions())
    end,    
    {ok, #state{}}.

%% handle_call({new_vm, VMAttrs}, _From, State)->
%%     ?DEBUG("insert with paramters: \nVMAttrs ~p", [VMAttrs]),
    
%%     SN        = proplists:get_value(<<"sn">>, VMAttrs),
%%     Name      = proplists:get_value(<<"name">>, VMAttrs),
%%     Cpu       = proplists:get_value(<<"cpu">>, VMAttrs),
%%     Memory    = proplists:get_value(<<"memory">>, VMAttrs),
%%     Disk1     = proplists:get_value(<<"disk1">>, VMAttrs),
%%     Disk2     = proplists:get_value(<<"disk2">>, VMAttrs),
%%     Location  = proplists:get_value(<<"location">>, VMAttrs),
%%     OutIp     = proplists:get_value(<<"outIp">>, VMAttrs),
%%     OutIpMask = proplists:get_value(<<"outIpMask">>, VMAttrs),
%%     InIp      = proplists:get_value(<<"inip">>, VMAttrs),
%%     InIpMask  = proplists:get_value(<<"inIpMask">>, VMAttrs),
%%     Gateway   = proplists:get_value(<<"gateway">>, VMAttrs),
%%     Os        = proplists:get_value(<<"os">>, VMAttrs),

%%     ?DEBUG("get vm attrs: sn ~p, name ~p, cpu ~p, memory ~p, disk1 ~p"
%% 	   "disk2 ~p, location ~p, outIp ~p, outIpMask ~p, InIp ~p, InOpMask ~p, "
%% 	   "gateway ~p, os ~p",
%% 	   [SN, Name, Cpu, Memory, Disk1, Disk2,
%% 	    Location, OutIp, OutIpMask, InIp, InIpMask, Gateway, Os]),
    
%%     {atomic, ok} = 
%% 	mnesia:transaction(
%% 	  fun() ->
%% 		  mnesia:write(
%% 		    #vm{sn          = ?to_string(SN),
%% 			name        = ?to_string(Name),
%% 			cpu         = ?to_string(Cpu),
%% 			memory      = ?to_string(Memory),
%% 			disk1       = ?to_string(Disk1),
%% 			disk2       = ?to_string(Disk2),
%% 			location    = ?to_string(Location),
%% 			os          = ?to_string(Os),
%% 			out_ip      = ?to_string(OutIp),
%% 			out_ip_mask = ?to_string(OutIpMask),
%% 			in_ip       = ?to_string(InIp),
%% 			in_ip_mask  = ?to_string(InIpMask),
%% 			gateway     = ?to_string(Gateway)
%% 		       }),
%% 		  mnesia:write(
%% 		    #vm_op_state{sn         = ?to_string(SN),
%% 				 start_time = current_time(localtime),
%% 				 end_time   = current_time(localtime),
%% 				 operator   = ?to_string(new_vm),
%% 				 name       = ?to_string(Name),
%% 				 state      = creating})
%% 	  end),
%%     {reply, ok, State};


%% handle_call({update_state, SN, VMState}, _From, State) ->
%%     ?DEBUG("update_state with prameters: SN ~p, VMState ~p", [SN, VMState]),
    
%%     {atomic, ok} = 
%% 	mnesia:transaction(
%% 	  fun() -> 
%% 		  [VMOp] = mnesia:read(vm_op_state, ?to_string(SN), write),
%% 		  mnesia:write(
%% 		    VMOp#vm_op_state{sn         = ?to_string(SN),
%% 				     %% start_time = current_time(localtime),
%% 				     end_time   = current_time(localtime),
%% 				     %% name       = VMOp#vm.name,
%% 				     state      = ?to_atom(VMState)})
%% 	  end),
%%     {reply, ok, State};


%% handle_call(lookup_vms, _From, State) ->
%%     MS = [{#vm{_ = '_'}, [], ['$_']}],
%%     {atomic, VMs} = 
%% 	mnesia:transaction(
%% 	  fun() -> mnesia:select(vm, MS) end),

%%     {reply, VMs, State};

%% handle_call(lookup_vm_state, _From, State) ->
%%     MS = [{#vm_op_state{_ = '_'}, [], ['$_']}],
%%     {atomic, VMs} = 
%% 	mnesia:transaction(
%% 	  fun() -> mnesia:select(vm_op_state, MS) end),

%%     {reply, VMs, State};

%% handle_call({lookup_steps, TaskId, Target}, _From, State) ->
%%     ?DEBUG("lookup_steps with TaskId ~p, Target ~p", [TaskId, Target]),
%%     MS = [{#target_state{target_info={'$1', '$2'}, _ = '_'},
%% 	   [{'==', '$1', TaskId}, {'==', '$2', Target}],
%% 	   ['$_']}],
%%     {atomic, TaskState} = 
%% 	mnesia:transaction(
%% 	  fun() -> mnesia:select(target_state, MS) end),

%%     ?DEBUG("lookup_steps get result ~p", [TaskState]),

%%     {reply, TaskState, State};
    
handle_call(Request, _From, State) ->
    ?DEBUG("receive unkown Request ~p", [Request]),
    Reply = ok,
    {reply, Reply, State}.



%% handle_cast({delete_steps, TaskId, Target}, State) ->
%%     D = #target_state{target_info = {TaskId,Target}, _ = '_'},
%%     {atomic, ok} = mnesia:transaction(
%% 		     fun() ->
%% 			     lists:foreach(
%% 			       fun(E) ->
%% 				       mnesia:delete_object(E)
%% 			       end, mnesia:match_object(D))
%% 		     end),
%%     {noreply, State};


%% handle_cast({delete_steps, TaskId}, State) ->
%%     D = #target_state{ target_info = {TaskId, _='_'}, _ = '_'},
%%     {atomic, ok} =
%% 	mnesia:transaction(
%% 	  fun() ->
%% 		  lists:foreach(
%% 		    fun(E) ->
%% 			    mnesia:delete_object(E)
%% 		    end, mnesia:match_object(D))
%% 	  end),
%%     {noreply, State};

%% handle_cast(delete_steps, State) ->
%%     D = #target_state{ _ = '_'},
%%     {atomic, ok} =
%% 	mnesia:transaction(
%% 	  fun() ->
%% 		  lists:foreach(
%% 		    fun(E) ->
%% 			    mnesia:delete_object(E)
%% 		    end, mnesia:match_object(D))
%% 	  end),
%%     {noreply, State};

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
table_definitions() ->
    [
     %% {vm,
     %%  [{record_name, vm},
     %%   {attributes, record_info(fields, vm)},
     %%   {disc_copies, [node()]},
     %%   {match, #vm{_ = '_'}}]},
     %% {vm_op_state,
     %%  [{record_name, vm_op_state},
     %%   {attributes, record_info(fields, vm_op_state)},
     %%   {disc_copies, [node()]},
     %%   {match, #vm_op_state{_ = '_'}}]}
    ].


%%--------------------------------------------------------------------
%% @desc : get current time
%% @return: format yyyymmddhhmmsss
%%--------------------------------------------------------------------
current_time(localtime) ->
    {{Year, Month, Date}, {Hour, Minute, Second}} =
	calendar:now_to_local_time(erlang:now()),
    
    lists:flatten(
      io_lib:format("~4..0w-~2..0w-~2..0w:~2..0w-~2..0w-~2..0w",
		    [Year, Month, Date, Hour, Minute, Second])).
