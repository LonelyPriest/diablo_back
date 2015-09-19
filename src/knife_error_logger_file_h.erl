%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2014, buxianhui
%%% @doc
%%%  Logger file handler to replace sysem file handler
%%% @end
%%% Created : 27 Feb 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(knife_error_logger_file_h).

-include("knife.hrl").

-behaviour(gen_event).

-export([init/1, handle_event/2, handle_call/2, handle_info/2, terminate/2,
         code_change/3]).

%% Used only when swapping handlers in log rotation
init({{File, Suffix}, []}) ->
    ?FORMAT("file ~p, suffix ~p~n", [File, Suffix]),
    case knife_file:append_file(File, Suffix) of
        ok -> file:delete(File),
              ok;
        {error, Error} ->
            knife_log:error("Failed to append contents of "
			      "log file '~s' to '~s':~n~p~n",
			      [File, [File, Suffix], Error])
    end,
    init(File);

%% Used only when swapping handlers and the original handler
%% failed to terminate or was never installed
init({{File, _}, error}) ->
    ?FORMAT("file ~p", [File]),
    init(File);

%% Used only when swapping handlers without performing
%% log rotation
init({File, []}) ->
    ?FORMAT("file ~p", [File]),
    init(File);
%% Used only when taking over from the tty handler
init({{File, []}, _}) ->
    ?FORMAT("file ~p", [File]),
    init(File);
init({File, {error_logger, Buf}}) ->
    %% knife_file:ensure_parent_dirs_exist(File),
    init_file(File, {error_logger, Buf});
init(File) ->
    knife_file:ensure_parent_dirs_exist(File),
    init_file(File, []).

init_file(File, {error_logger, Buf}) ->
    case init_file(File, error_logger) of
        {ok, {Fd, File, PrevHandler}} ->
            [handle_event(Event, {Fd, File, PrevHandler}) ||
                {_, Event} <- lists:reverse(Buf)],
            {ok, {Fd, File, PrevHandler}};
        Error ->
            Error
    end;
init_file(File, PrevHandler) ->
    ?FORMAT("init_file file  ~p, PrevHandler ~p", [File, PrevHandler]),
    process_flag(trap_exit, true),
    case file:open(File, [append]) of
        {ok,Fd} ->
	    {ok, {Fd, File, PrevHandler}};
        Error   ->
	    Error
    end.

handle_event(Event, State) ->
    error_logger_file_h:handle_event(Event, State).

handle_info(Event, State) ->
    error_logger_file_h:handle_info(Event, State).

handle_call(Event, State) ->
    error_logger_file_h:handle_call(Event, State).

terminate(Reason, State) ->
    error_logger_file_h:terminate(Reason, State).

code_change(OldVsn, State, Extra) ->
    error_logger_file_h:code_change(OldVsn, State, Extra).
