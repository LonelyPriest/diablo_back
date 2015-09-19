%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 20 May 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(controller_mysql_table).

-include("../../../include/knife.hrl").
-include("../include/controller.hrl").

-behaviour(gen_server).

%% API
-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-export([steps_of_instance/1, alarms_of_instance/1]).

-export([fill_special_step/3]).

-define(SERVER, ?MODULE). 

-record(state, {}).

steps_of_instance({instance_id, Instance}) ->
    gen_server:call(?SERVER, {steps_of_instance, {instance_id, Instance}}).

alarms_of_instance({instance_id, Instance}) ->
    gen_server:call(?SERVER, {alarms_of_instance, {instance_id, Instance}}).

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
init([]) ->
    {ok, #state{}}.

handle_call({alarms_of_instance, {instance_id, Instance}}, _From, State) ->
    Sql1 = "select alarm_ids from deploy_instances"
	++ " where id = " 
	++ ?to_string(Instance),
    
    case controller_mysql_access:fetch(read, list_to_binary(Sql1)) of
	    {ok, [[{<<"alarm_ids">>, <<>>}]]} ->
		{reply, empty, State};
	    {ok, [[{<<"alarm_ids">>, Alarms}]]} ->
	    {reply, Alarms, State}
    end;
    
handle_call({steps_of_instance, {instance_id, Instance}}, _From, State) ->
    Sql1 = "select steps from deploy_instances"
	++ " where id = " 
	++ ?to_string(Instance),

    StepsInfo =
	case controller_mysql_access:fetch(read, list_to_binary(Sql1)) of
	    {ok, [[{<<"steps">>, <<>>}]]} ->
		[];
	    {ok, [[{<<"steps">>, Steps}]]} ->
		Sql2 = "select target, sn as sn, name, "
		    "id as stepid, step_type as type, "
		    "source, script_exe as script, "
		    "user_exe as user from deploy_steps"
		    ++ " where id in "
		    ++ "(" ++ ?to_string(Steps) ++ ")"
		    ++ " order by sn;",
		{ok, Info} =
		    controller_mysql_access:fetch(read, list_to_binary(Sql2)),
		Info
	end,
    
    NameIds = 
	lists:foldr(
	  fun(S, Acc) ->
		  ParamsNameIds = 
		      lists:foldr(
			fun({_k, undefined}, Acc2) ->
				Acc2;
			   ({<<"stepid">>, _}, Acc2) ->
				Acc2;
			   ({<<"sn">>, _}, Acc2) ->
				Acc2;
			   ({<<"type">>, _}, Acc2) ->
				Acc2;
			   ({_, Id}, Acc2) when is_integer(Id) ->
				[?to_string(Id)|Acc2];
			   ({_k, _v}, Acc2) ->
				Acc2
			end, [], S),
		  ParamsNameIds ++ Acc
	  end, [], StepsInfo),


    case NameIds of
	[] ->
	    {reply, empty_step, State};
	_ ->
	    Sql3 = "select deploy_param_id, value "
		"from deploy_param_values where deploy_param_id in ("
		++ string:join(lists:usort(NameIds), ",")
		++ ") and deploy_instance_id = "
		++ ?to_string(Instance),

	    {ok, ParamValues} =
		controller_mysql_access:fetch(read, list_to_binary(Sql3)),
	    
	    Task = 
		lists:foldr(
		  fun(S, Acc) ->
			  StepDetail = 
			      lists:foldr(
				fun({_k, undefined}, Acc2) ->
					Acc2;
				   ({<<"stepid">>, Id}, Acc2) ->
					[{<<"stepid">>, ?to_binary(Id)}|Acc2];
				   ({<<"sn">>, SN}, Acc2) ->
					[{<<"sn">>, ?to_binary(SN)}|Acc2];
				   ({<<"name">>, _Name}, Acc2) ->
					[{<<"name">>, ?to_binary(no_use)}|Acc2];
				   ({<<"type">>, Type}, Acc2) ->
					[{<<"type">>, ?to_binary(Type)}|Acc2];
				   ({K, Id}, Acc2) when is_integer(Id) ->
					V = value(Id, ParamValues),
					[{K, V}|Acc2];
				   ({K, V}, Acc2) ->
					[{K, V}|Acc2]
				end, [], S),
			  [StepDetail] ++ Acc
		  end, [], StepsInfo),

	    ?DEBUG("step on target ~n~p", [Task]),
	    %% steps such "wait" have not target field, should fill it
	    try fill_special_step(Task, [], []) of
		FilledTask ->
		    ?DEBUG("filled step on target ~n~p", [FilledTask]),
		    {reply, FilledTask, State}
	    catch
		_:Error ->
		    {reply, Error, State}
	    end
    end;    
       
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
value(_, []) ->
    <<>>;
value(ParamId, [ [{<<"deploy_param_id">>, Id}, {<<"value">>, V}]|_T ])
  when Id =:= ParamId ->
    V;
value(ParamId, [ _H|T ]) ->    
    value(ParamId, T).


fill_special_step([], _, NewSteps) ->
    NewSteps;
%% dba-check
fill_special_step([ [_, _, _, {<<"type">>, <<"3">>}|_T] = Step|Next ],
		  Ips, NewSteps) ->
    ?DEBUG("Step ~p", [Step]),
    
    case ?to_binary_ips(
	    lists:usort(
	      Ips ++ find_target(backward_until_next_break, Next, []))) of
	[]     -> throw(no_target_step);
	NewIps ->
	    fill_special_step(
	      Next, Ips, NewSteps
	      ++ [ [{<<"target">>, NewIps} ]
		   ++  Step ++ [{<<"wait_ips">>, NewIps}] ])
    end;
%% standby
fill_special_step([ [_, _, _, {<<"type">>, <<"4">>}|_T] = Step|Next ],
		  Ips, NewSteps) ->
    ?DEBUG("Step ~p", [Step]),
    case ?to_binary_ips(
	    lists:usort(
	      Ips ++ find_target(backward_until_next_break, Next, []))) of
	[] -> throw(no_target_step);
	NewIps ->
	    fill_special_step(
	      Next, Ips, NewSteps
	      ++ [ [{<<"target">>, NewIps}]
		   ++  Step ++ [{<<"wait_ips">>, NewIps}]
		 ])
    end;
    
fill_special_step([ [{<<"target">>, Target}|_T] = Step|Next ],
		  Ips, NewSteps) ->
    ?DEBUG("Step ~p", [Step]),
    fill_special_step(Next,
		      case lists:member(Target, Ips) of
			  true -> Ips;
			  false -> [Target|Ips] end,
		      NewSteps ++ [Step]).


find_target(backward_until_next_break, [], Ips) ->
    Ips;
find_target(backward_until_next_break,
	    [ [_, _, _, {<<"type">>, <<"3">>}|_T] | _Next ], Ips) ->
    Ips;
find_target(backward_until_next_break,
	    [ [_, _, _, {<<"type">>, <<"4">>}|_T] | _Next ], Ips) ->
    Ips;
find_target(backward_until_next_break,
	    [ [{<<"target">>, Target}|_T] | Next ], Ips) ->
    find_target(backward_until_next_break, Next,
		case lists:member(Target, Ips) of
		    true -> Ips;
		    false -> [Target|Ips]
		end).



