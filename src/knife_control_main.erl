%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2014, buxianhui
%%% @doc
%%%  applocation controll
%%% @end
%%% Created : 15 Apr 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(knife_control_main).

-export([start/0]).

-define(ALLOWED_COMMAND, [stop,
			  list_tasks,
			  list_jobs,
			  list_servers,
			  debug_on,
			  debug_off,
			  log_info,
			  status,
			  dump
			  ]).

-define(PLUGINS_COMMAND, [{controller, [list_tasks, list_jobs]},
			  {proxy, [list_servers]}]).

-define(PLUGINS, [controller, proxy, agent]).

start() ->
    {ok, [[NodeStr|_]|_]} = init:get_argument(nodename),
    io:format("running node name [~p]~n", [NodeStr]),
    Args = init:get_plain_arguments(),
    Command =
	case parse_arguments(Args) of
	    no_command ->
		print_error("no command input", []),
		usage();
	    Res -> Res
	end,

    case lists:member(Command, ?ALLOWED_COMMAND) of
	false -> 
	    print_error("could not recognize command ~p", [Command]),
	    usage();
	true -> ok
    end,

    [Plugin|_] = string:tokens(NodeStr, "-"),
    case lists:member(list_to_atom(Plugin), ?PLUGINS) of
	false ->
	    print_error("could not recognize plugin ~p", [Plugin]),
	    usage();
	true ->
	    ok
    end,

    %% valid command of valid plugin
    check_command(Plugin, Command),

    try
	{ok, Result} = action(Command, list_to_atom(NodeStr)),
	case Result of
	    none -> ok;
	    Info ->
		io:format("result: ~p~n", [Info])
	end
    catch
	_:{badmatch, {badrpc, nodedown}} ->
	    print_error("node ~p has been down, "
			"make sure you choose the right plugin [controller, proxy, agent]",
			[list_to_atom(NodeStr)]),
	    quit(1);
	_:Error ->
	    print_error("~p", [Error]),
	    %%print_error("~p", [erlang:get_stacktrace()]),
	    usage()
    end,

    quit(0).

	    
action(stop, Node) ->
    io:format("Stopping and halting application on node [~p]~n", [Node]),
    ok = rpc:call(Node, knife, stop_and_halt, []),
    {ok, none};

action(status, Node) ->
    io:format("check status of [~p]~n", [Node]),
    Status = rpc:call(Node, knife, status, []),
    {ok, Status};

action(dump, Node) ->
    io:format("dump mnesia to file ~p~n", [Node]),
    Result = rpc:call(Node, diablo_controller_inventory_sn, dump, []),
    {ok, Result};

action(list_tasks, Node) ->
    io:format("list all tasks on node [~p]~n", [Node]),
    Tasks = rpc:call(Node, controller_tasks, lookup, []),
    {ok, Tasks};

action(list_servers, Node) ->
    io:format("list all server that connected to proxy on node [~p]~n", [Node]),
    Servers = rpc:call(Node, forest_node, lookup, [all]),
    {ok, Servers};

action(debug_on, Node) ->
    io:format("debug on on node [~p]~n", [Node]),
    ok = rpc:call(Node, knife_log, debug_on, []),
    {ok, none};

action(debug_off, Node) ->
    io:format("debug off on node [~p]~n", [Node]),
    ok = rpc:call(Node, knife_log, debug_off, []),
    {ok, none};

action(log_info, Node) ->
    io:format("get log level of node ~p~n", [Node]),
    Level = rpc:call(Node, knife_log, get_level, []),
    {ok, Level}.

%% action(list_task, TaskId, Node) ->
%%     io:format("list all tasks on node [~p]~n", [Node]),
%%     Tasks = rpc:call(Node, controller_tasks, lookup, [TaskId]),
%%     {ok, Tasks}.



parse_arguments([]) ->
    no_command;
parse_arguments(Args) ->
    [H|_T] = Args,
    list_to_atom(H).

print_error(Format, Args) ->
    io:format("error: " ++ Format ++ "~n", Args).


usage()->
    io:format("Usage:
knifectl [controller|proxy|agent] <command>

Notice
    some commands only supported by special moudle,
    such as command 'list_servers' execute only by proxy

Command
stop
    stop knife and plug-in
status
    check the knife's status

debug_on
    switch log to debug status
debug_off
    switch log to info status
log_info
    query current log status

list_tasks
    list all tasks in controller, supported by controller

list_servers
    list all servers that has been connected to proxy, only supported by proxy
~n"),

    quit(1).

quit(Status) ->
    halt(Status).

check_command(_, stop)         -> ok;
check_command(_, status)       -> ok;
check_command(_, debug_on)     -> ok;
check_command(_, debug_off)    -> ok;
check_command(_, log_info)     -> ok;
check_command(_, dump)         -> ok;
check_command(Plugin, Command) ->
    case proplists:get_value(list_to_atom(Plugin), ?PLUGINS_COMMAND) of
	undefined  ->
	    print_error("plugin ~p does not support command ~p",
			[Plugin, Command]),
	    usage();
	PluginCommands ->
	    case {list_to_atom(Plugin), lists:member(Command, PluginCommands)} of
		{_, true} -> ok ;
		{_, false} ->
		    print_error("plugin ~p does not support command ~p",
				[Plugin, Command]),
		    usage()
	    end
    end.
