%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 27 Feb 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(knife).

-include("knife.hrl").

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1, stop/0, stop_and_halt/0, status/0]).

-export([boot/0, rotate_logs/1, ensure_working_log_handlers/0]).

boot()->
    knife_utils:start_it(
      fun()->
	      %% knife frame loaded first
	      ok = knife_utils:ensure_application_loaded(knife),

	      
	      %% log intilise
	      ok = ensure_working_log_handlers(),

	      %% plugins setup
	      Plugins = knife_plugins:setup(),
	      io:format("plugins=~p~n", [Plugins]),

	      %% knife frame must be started first
	      StartApps = [knife] ++ Plugins,
	      io:format("StartApps=~p~n", [StartApps]),

	      %% start all applications
	      ok = knife_utils:start_applications(StartApps),
	      ok = print_plugin_info(Plugins)
      end).

print_plugin_info([]) ->
    ok;
print_plugin_info(Plugins) ->
    with_local_io(
      fun() ->
	      
              io:format("~n-- plugins running~n"),
              [print_plugin_info(
                 AppName, element(2, application:get_key(AppName, vsn)))
               || AppName <- Plugins],
              ok
      end).

print_plugin_info(Plugin, Vsn) ->    
    Len = 76 - length(Vsn),
    io:format("~-" ++ integer_to_list(Len) ++ "s ~s~n", [Plugin, Vsn]).

with_local_io(Fun) ->
    GL = group_leader(),
    group_leader(whereis(user), self()),    try
        Fun()
    after
        group_leader(GL, self())
    end.

%%%===================================================================
%%% Application callbacks
%%%===================================================================
start(_StartType, _StartArgs) ->
    case knife_sup:start_link() of
	{ok, Pid} ->
	    %% register self
	    true = register(knife, self()),
	    {ok, Pid};
	Error ->
	    Error
		end.

stop(_State) ->
    ok.

%%%===================================================================
%%% Log
%%%===================================================================
rotate_logs(BinarySuffix) ->
    Suffix = binary_to_list(BinarySuffix),
    io:format("Rotating logs with suffix '~s'~n", [Suffix]),
    log_rotation_result(rotate_logs(log_location(kernel),
                                    Suffix,
                                    knife_error_logger_file_h),
                        rotate_logs(log_location(sasl),
                                    Suffix,
                                    knife_sasl_report_file_h)).


ensure_working_log_handlers() ->
    ?FORMAT("ensure_working_log_handlers", []),
    Handlers = gen_event:which_handlers(error_logger),
    ok = ensure_working_log_handler(error_logger_tty_h,
                                    knife_error_logger_file_h,
                                    error_logger_tty_h,
                                    log_location(kernel),
                                    Handlers),

    ok = ensure_working_log_handler(sasl_report_tty_h,
                                    knife_sasl_report_file_h,
                                    sasl_report_tty_h,
                                    log_location(sasl),
                                    Handlers),
    ok.

ensure_working_log_handler(OldHandler, NewHandler,
			   TTYHandler, LogLocation, Handlers) ->
    ?FORMAT("ensure_working_log_handlers oldh ~p, newh ~p, "
	    "ttyh ~p, logloaction ~p, handlers ~p",
	    [OldHandler, NewHandler, TTYHandler, LogLocation, Handlers]),
    case LogLocation of
        undefined -> ok;
        tty       -> case lists:member(TTYHandler, Handlers) of
                         true  -> ok;
                         false ->
                             throw({error, {cannot_log_to_tty,
                                            TTYHandler, not_installed}})
                     end;
        _         -> case lists:member(NewHandler, Handlers) of
                         true  -> ok;
                         false -> case rotate_logs(
					 LogLocation, "", OldHandler, NewHandler) of
                                      ok -> ok;
                                      {error, Reason} ->
                                          throw(
					    {error, {cannot_log_to_file,
						     LogLocation, Reason}})
                                  end
                     end
    end.


log_location(Type) ->
    case
	application:get_env(knife,
			    case Type of
				kernel -> error_logger;
				sasl   -> sasl_error_logger
			    end) of
        {ok, {file, File}} -> File;
        {ok, false}        -> undefined;
        {ok, tty}          -> tty;
        {ok, silent}       -> undefined;
        {ok, Bad}          -> throw({error, {cannot_log_to_file, Bad}});
        _                  -> undefined
    end.

rotate_logs(File, Suffix, Handler) ->
    rotate_logs(File, Suffix, Handler, Handler).


rotate_logs(undefined, _Suffix, _OldHandler, _NewHandler) -> ok;
rotate_logs(tty,       _Suffix, _OldHandler, _NewHandler) -> ok;
rotate_logs(File,       Suffix,  OldHandler,  NewHandler) ->
    ?FORMAT("rotate_logs file ~p, Suffix ~p", [File, Suffix]),
    gen_event:swap_handler(error_logger,
                           {OldHandler, swap},
                           {NewHandler, {File, Suffix}}).

log_rotation_result({error, MainLogError}, {error, SaslLogError}) ->
    {error, {{cannot_rotate_main_logs, MainLogError},
             {cannot_rotate_sasl_logs, SaslLogError}}};
log_rotation_result({error, MainLogError}, ok) ->
    {error, {cannot_rotate_main_logs, MainLogError}};
log_rotation_result(ok, {error, SaslLogError}) ->
    {error, {cannot_rotate_sasl_logs, SaslLogError}};
log_rotation_result(ok, ok) ->
    ok.


stop() ->
    io:format("Begin to stopping knife ...~n"),
    ?INFO("Begin to stopping knife ...", []),
    Plugins = knife_plugins:setup(),
    ?INFO("Stopping plugins ~p", [Plugins]),
    io:format("Stopping plugins ~p~n", [Plugins]),
    
    %% plugins stop first
    %% clear
    lists:foreach(
      fun(App) ->
    	      App:stop(normal)
      end, Plugins),

    ok = knife_utils:stop_applications(Plugins),
    ok = knife_utils:stop_applications([knife]),
	
    io:format("Success to stopping knife ...~n"),
    ?INFO("Success to stopping knife ...", []),
    ok.

stop_and_halt() ->
    try
	stop()
    after
	io:format("Halting... ~n"),
	init:stop()
    end,
    ok.

status() ->
    Status = 
	lists:foldl(
	  fun(App, Acc) ->
		  [{App, {running, is_process_alive(whereis(App))}}|Acc]
	  end, [], knife_plugins:setup()),
    [{knife, {running, is_process_alive(whereis(knife))}}] ++ Status .
