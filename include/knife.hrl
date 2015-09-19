%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright Seasun Co, Ltd(C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 26 Feb 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------

%% max time to wait for child process start
-define(KNIFE_MAX_WAIT, 16#ffffffff).
-define(INTERVAL_RECONNECT, 3000).

-define(to_string(E),       knife_utils:transfer_to_string(E)).
-define(to_atom(E),         knife_utils:transfer_to_atom(E)).
-define(to_integer(E),      knife_utils:transfer_to_integer(E)).
-define(to_binary(E),       knife_utils:transfer_to_binary(E)).
-define(to_tuplelist(E),    knife_utils:transfer_to_tuple_list(E)).

-define(to_s(E), ?to_string(E)).
-define(to_a(E), ?to_atom(E)).
-define(to_i(E), ?to_integer(E)).
-define(to_f(E), knife_utils:transfer_to_float(E)).
-define(to_b(E), ?to_binary(E)).
-define(to_l(E), knife_utils:transfer_to_list(E)).
%% to tuple list
-define(to_tl(E), ?to_tuplelist(E)).

%% log format
-define(DEBUG(Fmt),
        knife_log:debug("[~p:~p]-> " ++ Fmt ++ "~n", [?MODULE, ?LINE])).
-define(DEBUG(Fmt, Args),
        knife_log:debug("[~p:~p]-> " ++ Fmt ++ "~n", [?MODULE, ?LINE] ++ Args)).

-define(INFO(Fmt),
        knife_log:info("[~p]-> " ++ Fmt ++ "~n", [?MODULE])).
-define(INFO(Fmt, Args),
        knife_log:info("[~p]-> " ++ Fmt ++ "~n", [?MODULE] ++ Args)).

-define(WARN(Fmt),
        knife_log:warning("[~p]-> " ++ Fmt ++ "~n", [?MODULE])).
-define(WARN(Fmt, Args),
        knife_log:warning("[~p]-> " ++ Fmt ++ "~n", [?MODULE] ++ Args)).

-define(ERROR(Fmt),
        knife_log:error("[~p]-> " ++ Fmt ++ "~n", [?MODULE])).
-define(ERROR(Fmt, Args),
        knife_log:error("[~p]-> " ++ Fmt ++ "~n", [?MODULE] ++ Args)).

-define(FORMAT(Fmt),
        io:format("[~p:~p]-> " ++ Fmt ++ "~n", [?MODULE, ?LINE])).
-define(FORMAT(Fmt, Args),
        io:format("[~p:~p]-> " ++ Fmt ++ "~n", [?MODULE, ?LINE] ++ Args)).
-define(FORMAT_INFO(Fmt, Args),
       io:format(Fmt ++ "~n", Args)).


%% plugin
-record(knife_plugin, {name,         %% atom ()
			 version,      %% string()
			 description,  %% string() 
			 type,         %% 'ez' or 'dir'
			 dependencies, %% string() 
			 location}).   %% string()
