%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright Seasun(C) 2014, buxianhui
%%% @doc
%%%  Mnesia to store JOB details
%%% @end
%%% Created :  7 Mar 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(controller_mnesia).

-compile(export_all).


init() ->
    ensure_mnesia_running(),
    ensure_mnesia_dir(),
    init_db_and_upgrade([node()], disc, false),
    ok.

init_db_and_upgrade(ClusterNodes, NodeType, CheckOtherNodes) ->
    ok = init_db(ClusterNodes, NodeType, CheckOtherNodes),

    case NodeType of
	ram -> start_mnesia(),
	       change_extra_db_nodes(ClusterNodes, false);
	disc -> ok
    end,
    ok = global:sync(),
    ok.


mnesia_dir() ->
    mnesia:system_info(directory). 

ensure_mnesia_dir()->
    MnesiaDir = mnesia_dir() ++ "/",
    case filelib:ensure_dir(MnesiaDir) of
	{error, Reason} ->
	    throw({error, {cannot_create_mnesia_dir, MnesiaDir, Reason}});
	ok ->
	    ok
    end.

ensure_mnesia_running() ->
    case mnesia:system_info(is_running) of
	yes ->
	    ok;
	starting ->
	    wait_for(mnesia_running),
	    ensure_mnesia_running();
	Reason when Reason =:= no; Reason =:= stopping ->
	    throw({error, mnesia_not_running})
    end.

ensure_mnesia_not_running()->
    case mnesia:system_info(is_running) of
	no ->
	    ok;
	stopping ->
	    wait_for(mnesia_not_running),
	    ensure_mnesia_not_running();
	Reason when Reason =:= yes; Reason =:= starting ->
	    throw({error, mnesia_unexpectedly_running})
    end.

wait_for(Condition) ->
    error_logger:info_msg("Waiting for ~p...~n", [Condition]),
    timer:sleep(1000).

-spec create_schema() -> no_return(). 
create_schema() ->
    stop_mnesia(),
    ensure_ok(mnesia:create_schema([node()]), cannot_create_schema),
    start_mnesia(),
    ok = controller_table:create(),
    ensure_schema_integrity().


-spec ensure_schema_integrity() -> no_return(). 
ensure_schema_integrity() ->
    case controller_table:check_schema_integrity() of
	ok -> 
	    ok;
	{error, Reason} ->
	    throw({error, {schema_integrity_check_failed, Reason}})
    end.

stop_mnesia() ->
    stopped = mnesia:stop(),
    ensure_mnesia_not_running().

start_mnesia() ->
    ensure_ok(mnesia:start(), cannot_start_mnesia),
    ensure_mnesia_running().


ensure_ok(ok, _) -> ok;
ensure_ok({error, Reason}, ErrorTag) -> 
    throw({error, {ErrorTag, Reason}}).

nodes_excl_me(Nodes) -> Nodes -- [node()].

change_extra_db_nodes(ClusterNodes0, CheckOtherNodes) ->
    ClusterNodes = nodes_excl_me(ClusterNodes0),
    case {mnesia:change_config(extra_db_nodes, ClusterNodes), ClusterNodes} of
	{{ok, []}, [_|_]} when CheckOtherNodes ->
	    throw({error, {failed_to_cluster_with, ClusterNodes,
			   "Mnesia could not connect to any nodes."}});
	{{ok, Nodes}, _} ->
	    Nodes
    end.

init_db(ClusterNodes, NodeType, CheckOtherNodes) ->
    Nodes = change_extra_db_nodes(ClusterNodes, CheckOtherNodes),
    WasDiscNode = mnesia:system_info(use_dir),

    case {Nodes, WasDiscNode, NodeType} of
	{[], _, ram } ->
	    throw({error, cannot_create_standalone_ram_node});
	{[], false, disc} ->
	    ok = create_schema();
	{[], true, disc} ->
	    ok;
	{[_AnotherNode|_], _, _} ->
	    throw({error, cluster_not_supported_now})
    end,
    ok.
