%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2015, buxianhui
%%% @doc 
%%%
%%% @end
%%% Created : 25 Oct 2015 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_work_pool_sup).

-include("../../../../include/knife.hrl").
%% -include("diablo_controller.hrl").

-behaviour(supervisor).

%% API
-export([start_link/1, get/2]).

%% Supervisor callbacks
-export([init/1]).

-define(SERVER, ?MODULE).

%%%===================================================================
%%% API functions
%%%===================================================================
start_link(M) ->
    Name = ?to_a(?to_s(M) ++ "_sup"),
    supervisor:start_link({local, Name}, ?MODULE, [M]).

get(M, Merchant) ->
    %% RegisterName = ?to_a(?to_s(Module) ++ ?to_s(Name)),
    %% Spec = child_spec(Module, RegisterName),
    RModule = ?to_a(?to_s(M) ++ "-" ++ ?to_s(Merchant)),
    
    case is_module_alive(RModule) of
	[] ->
	    Sup = ?to_a(?to_s(M) ++ "_sup"),
	    ?DEBUG("start new child ~p with supervisor ~p", [RModule, Sup]),
	    {ok, _PId} = supervisor:start_child(Sup, [RModule]),
	    RModule;
	_PId ->
	    RModule
    end.

%%%===================================================================
%%% Supervisor callbacks
%%%===================================================================

init([M]) ->
    %% ?DEBUG("M ~p", [M]),
    %% RestartStrategy = simple_one_for_one,
    %% MaxRestarts = 1000,
    %% MaxSecondsBetweenRestarts = 3600,

    %% SupFlags = {RestartStrategy, MaxRestarts, MaxSecondsBetweenRestarts},

    %% Restart = permanent,
    %% Shutdown = 2000,
    %% Type = worker,

    %% AChild = {'AName', {'AModule', start_link, []},
    %% 	      Restart, Shutdown, Type, ['AModule']},

    Spec = {M, {M, start_link, []}, temporary, 2000, worker, [M]},

    {ok, {{simple_one_for_one, 0, 1}, [Spec]}}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
%% child_spec(?w_inventory, Name) ->
%%     {diablo_purchaser,
%%      {diablo_purchaser, start_link, [Name]},
%%      permanent, 2000, work, [diablo_purchaser]};
%% child_spec(?w_sale, Name) ->
%%     {diablo_w_sale,
%%      {diablo_w_sale, start_link, [Name]},
%%      permanent, 2000, work, [diablo_w_sale]}.

is_module_alive(Module) ->
    case erlang:whereis(Module) of
	undefined -> [];
	PId ->
	    case erlang:is_process_alive(PId) of
		true -> PId;
		false -> []
	    end 
    end.
