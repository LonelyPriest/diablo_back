-module(knife_sasl_report_file_h).

-include("knife.hrl").

-behaviour(gen_event).

-export([init/1, handle_event/2, handle_call/2, handle_info/2, terminate/2,
         code_change/3]).

%% Used only when swapping handlers and performing
%% log rotation
init({{File, Suffix}, []}) ->
    ?FORMAT("file ~p, suffix ~p~n", [File, Suffix]),
    case knife_file:append_file(File, Suffix) of
        ok -> file:delete(File),
              ok;
        {error, Error} ->
            ?ERROR("Failed to append contents of "
		   "sasl log file '~s' to '~s':~n~p~n",
		   [File, [File, Suffix], Error])
    end,
    init(File);
%% Used only when swapping handlers and the original handler
%% failed to terminate or was never installed
init({{File, _}, error}) ->
    init(File);
%% Used only when swapping handlers without
%% doing any log rotation
init({File, []}) ->
    init(File);
init({_File, _Type} = FileInfo) ->
    %% knife_file:ensure_parent_dirs_exist(File),
    init_file(FileInfo);
init(File) ->
    knife_file:ensure_parent_dirs_exist(File),
    init_file({File, sasl_error_logger_type()}).

init_file({File, Type}) ->
    process_flag(trap_exit, true),
    case file:open(File, [append]) of
        {ok,Fd} -> {ok, {Fd, File, Type}};
        Error   -> Error
    end.

handle_event(Event, State) ->
    sasl_report_file_h:handle_event(Event, State).

handle_info(Event, State) ->
    sasl_report_file_h:handle_info(Event, State).

handle_call(Event, State) ->
    sasl_report_file_h:handle_call(Event, State).

terminate(Reason, State) ->
    sasl_report_file_h:terminate(Reason, State).

code_change(_OldVsn, State, _Extra) ->
    %% There is no sasl_report_file_h:code_change/3
    {ok, State}.

%%----------------------------------------------------------------------

sasl_error_logger_type() ->
    case application:get_env(sasl, errlog_type) of
        {ok, error}    -> error;
        {ok, progress} -> progress;
        {ok, all}      -> all;
        {ok, Bad}      -> throw({error, {wrong_errlog_type, Bad}});
        _              -> all
    end.
