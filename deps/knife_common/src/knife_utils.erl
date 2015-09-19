%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright SeasunGame(C) 2014, buxianhui
%%% @doc
%%%  public utilies
%%% @end
%%% Created : 19 Mar 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(knife_utils).

-include("../../../include/knife.hrl").

-compile(export_all).

-define(FIRST_TEST_BIND_PORT, 10000).

%% =============================================================================
%% application utils
%% =============================================================================
start_it(StartFun) ->
    try
        StartFun()
    catch
        throw:{could_not_start, _App, _Reason}=Err ->
            throw({Err, not_available});
         _:Reason ->
            throw({Reason, erlang:get_stacktrace()})
    after
        timer:sleep(100)
    end.

ensure_application_loaded(App) ->
    case application:load(App) of
        ok                             -> ok;
        {error, {already_loaded, App}} -> ok
    end.

stop_applications(Apps) ->
    stop_applications(
      Apps, fun (App, Reason) ->
                    throw({error, {cannot_stop_application, App, Reason}})
            end).

stop_applications(Apps, ErrorHandler) ->
    manage_applications(fun lists:foldr/3,
                        fun application:stop/1,
                        fun application:start/1,
                        not_started,
                        ErrorHandler,
                        Apps).

start_applications(Apps) ->
    manage_applications(fun lists:foldl/3,
                        fun application:start/1,
                        fun application:stop/1,
                        already_started,
                        fun handle_app_error/2,
                        Apps).

manage_applications(Iterate, Do, Undo, SkipError, ErrorHandler, Apps) ->
    Iterate(fun (App, Acc) ->
                    case Do(App) of
                        ok -> [App | Acc];
                        {error, {SkipError, _}} -> Acc;
                        {error, Reason} ->
                            lists:foreach(Undo, Acc),
                            ErrorHandler(App, Reason)
                    end
            end, [], Apps),
    ok.

handle_app_error(App, {bad_return, {_MFA, {'EXIT', {Reason, _}}}}) ->
    throw({could_not_start, App, Reason});

handle_app_error(App, Reason) ->
    throw({could_not_start, App, Reason}).


%% =============================================================================
%% Network utils
%% =============================================================================
port_to_family(Port) ->
    IPv4 = {"0.0.0.0", Port, inet},
    %% [IPv4].
    IPv6 = {"::",      Port, inet6},
    case ipv6_status(?FIRST_TEST_BIND_PORT) of
        single_stack -> [IPv4];
    	ipv6_only    -> [IPv6];
        dual_stack   -> [IPv6, IPv4];
        ipv4_only    -> [IPv4]
    end.

ipv6_status(TestPort) ->
    IPv4 = [inet, {ip, {0,0,0,0}}],
    IPv6 = [inet6, {ip, {0,0,0,0,0,0,0,0}}],
    case gen_tcp:listen(TestPort, IPv6) of
        {ok, LSock6} ->
            case gen_tcp:listen(TestPort, IPv4) of
                {ok, LSock4} ->
                    %% Dual stack
                    gen_tcp:close(LSock6),
		    gen_tcp:close(LSock4),
		    dual_stack;
		%% Checking the error here would only let us
                %% distinguish single stack IPv6 / IPv4 vs IPv6 only,
                %% which we figure out below anyway.
                {error, _} ->
                    gen_tcp:close(LSock6),
                    case gen_tcp:listen(TestPort, IPv4) of
                        %% Single stack
                        {ok, LSock4}            -> gen_tcp:close(LSock4),
                                                   single_stack;
                        %% IPv6-only machine. Welcome to the future.
                        {error, eafnosupport}   -> ipv6_only; %% Linux
                        {error, eprotonosupport}-> ipv6_only; %% FreeBSD
                        %% Dual stack machine with something already
                        %% on IPv4.
                        {error, _}              -> ipv6_status(TestPort + 1)
                    end
            end;
        %% IPv4-only machine. Welcome to the 90s.
        {error, eafnosupport} -> %% Linux
            ipv4_only;
	{error, eprotonosuport} -> %% BSD
	    ipv4_only;
	{error, _} ->
	    ipv6_status(TestPort + 1)
    end.

%% =============================================================================
%% shell utils
%% =============================================================================

%% =============================================================================
%% @desc: execute a excutable script with absolute path
%% @param: script -> sting with absolute path, such as "/home/jx/jx.sh"
%% @param: args   -> string with list, such as ["stop"]
%% @param: successStatus -> the status with successfully exit,
%%                          on linux/unix, usally it is 0
%% @return: {ok, output}|{error, status, output}
%% =============================================================================
execute({script, Script}, SuccessStatus) when is_integer(SuccessStatus) ->
    [Path|_Action] = string:tokens(transfer_to_string(Script), " "),
    S = transfer_to_string(Script) ++ ">" ++ Path ++ ".out 2>&1",
    ?DEBUG("start to execute script ~p with success status ~p",
	   [S, SuccessStatus]),
    Port = open_port({spawn, S},
		    [stream,
		     %% {cd, Dir},
		     %% {args, A},
		     exit_status,
		     use_stdio,
		     in,
		     binary
		     %% eof  %% only care the result but not content
		     ]),
    loop_read(port, Port, SuccessStatus, <<>>);

execute(command, Command) ->
    ?DEBUG("start to execute command ~p", [Command]),
    Port = open_port({spawn, Command},
		    [stream,
		     %% {cd, Dir},
		     %% {args, A},
		     exit_status,
		     use_stdio,
		     in,
		     binary
		     %% eof  %% only care the result but not content
		     ]),
    loop_read(port, Port, 0, <<>>).


loop_read(port, Port, SuccessStatus, Acc) ->
    receive
	{Port, {data, Data}} ->
	    loop_read(port, Port, SuccessStatus, <<Acc/binary, Data/binary>>);
	{Port, {exit_status, SuccessStatus}}->
	    ?DEBUG("success to execute script with info ~p", [Acc]),
	    {ok, Acc};
	{Port, {exit_status, FailedStatus}} ->
	    ?ERROR("failed to execute with status ~p, errinfo ~p",
		    [FailedStatus, Acc]),
	    {error, {FailedStatus, Acc}}
    end.


-spec transfer_to_atom(binary()|string()|atom()) -> atom().
transfer_to_atom(E) when is_binary(E) ->
    try erlang:binary_to_existing_atom(E, latin1) of
	Atom -> Atom
    catch
	error:badarg ->
	    erlang:binary_to_atom(E, latin1)
    end;
transfer_to_atom(E) when is_list(E) ->
    try erlang:list_to_existing_atom(E) of
	Atom -> Atom
    catch
	error:badarg ->
	    erlang:list_to_atom(E)
    end;
transfer_to_atom(E) ->
    E.

-spec transfer_to_binary(string()|atom()|integer()|binary()) -> binary().
transfer_to_binary(E) when is_list(E) ->
    list_to_binary(E);
transfer_to_binary(E) when is_atom(E) ->
    atom_to_binary(E, latin1);
transfer_to_binary(E) when is_integer(E)->
    %% compatible R15, R14
    %% R15 has the direct function integer_to_binary/1
    list_to_binary(integer_to_list(E));
transfer_to_binary(E) when is_float(E) ->
    float_to_binary(E, [{decimals, 2}]);
transfer_to_binary(E) when is_binary(E) ->
    E.

-spec transfer_to_string(atom()|integer()|binary()|string()) -> string().
transfer_to_string(E) when is_atom(E) ->
    atom_to_list(E);
transfer_to_string(E) when is_integer(E) ->
    integer_to_list(E);
transfer_to_string(E) when is_float(E) ->
    float_to_list(E, [{decimals, 2}]);
transfer_to_string(E) when is_binary(E)->
    case E of
	<<>> -> "";
	E -> binary_to_list(E)
    end;
transfer_to_string(E) ->
    E.

-spec transfer_to_float(integer()|binary()|string()) -> float().
transfer_to_float(E) when is_integer(E) ->
    erlang:float(E);
transfer_to_float(E) when is_binary(E) ->
    try
	erlang:binary_to_float(E)
    catch
	error:badarg ->
	    erlang:binary_to_integer(E)
    end;
transfer_to_float(E) when is_list(E)->
    erlang:list_to_float(E);
transfer_to_float(E) ->
    E.


transfer_to_tuple_list(E) when is_tuple(E) ->
    [E];
transfer_to_tuple_list(E) when is_list(E)->
    E;
transfer_to_tuple_list(E) ->
    E.

-spec transfer_to_integer(binary()|string()|integer()) -> integer(). 
transfer_to_integer(E) when is_binary(E) ->
    binary_to_integer(E);
transfer_to_integer(E) when is_list(E) ->
    list_to_integer(E);
transfer_to_integer(E) ->
    E.

-spec transfer_to_list(binary()|string()|integer()|list()) -> integer(). 
transfer_to_list(E) when is_list(E) ->
    E;
transfer_to_list(E) ->
    [E].

%%--------------------------------------------------------------------
%% @desc : parse a binary ips seperator by comma to a binyar ip list
%% @param: Ips -> binary separator by comma <<"192.168.0.1", <<"192.168.0.2">>>>
%% @param: IpBinary -> a ip format with binary
%% @param: Ips -> return param, [<<"192.168.0.1">>, <<"192.168.0.2">>]
%% @return: Ips
%%--------------------------------------------------------------------    
binary_to_iplist(<<>>, IpBinary, Ips) ->
    lists:reverse([IpBinary|Ips]);
binary_to_iplist(<<",", T/binary>>, IpBinary, Ips) ->
    binary_to_iplist(T, <<>>, [IpBinary|Ips]);
binary_to_iplist(<<H, T/binary>>, IpBinary, Ips) ->
    binary_to_iplist(T, <<IpBinary/binary, H>>, Ips).


iplist_to_binary([], Binary) ->
    Binary;
iplist_to_binary([Ip], Binary)->
    iplist_to_binary([], <<Binary/binary, Ip/binary>>);
iplist_to_binary([Ip|Next], Binary) ->
    iplist_to_binary(Next, <<Binary/binary, Ip/binary, ",">>).
    

-spec step_life_cycle(atom()) -> integer().
step_life_cycle(finished) ->
    4;
step_life_cycle(running) ->
    2;
step_life_cycle(failed) ->
    5;
step_life_cycle(timeout) ->
    5;
step_life_cycle(ready) ->
    1;
step_life_cycle(waiting) ->
    3;
step_life_cycle(artificial) ->
    3.

-spec task_life_cycle(atom()) -> integer().
task_life_cycle(finished) ->
    4;
task_life_cycle(running) ->
    2;
task_life_cycle(party_failed) ->
    5;
task_life_cycle(failed) ->
    5;
task_life_cycle(waiting) ->
    3;
task_life_cycle(timeout) ->
    5;
task_life_cycle(terminate) ->
    6.

    
