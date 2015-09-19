%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright SeasunGame(C) 2014, buxianhui
%%% @doc
%%%  Plugin management
%%% @end
%%% Created : 19 Mar 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(knife_plugins_main).

-include("knife.hrl").

-export([start/0, stop/0]).

-define(VERBOSE_OPT, "-v").
-define(MINIMAL_OPT, "-m").
-define(ENABLED_OPT, "-E").
-define(ENABLED_ALL_OPT, "-e").

-define(VERBOSE_DEF, {?VERBOSE_OPT, flag}).
-define(MINIMAL_DEF, {?MINIMAL_OPT, flag}).
-define(ENABLED_DEF, {?ENABLED_OPT, flag}).
-define(ENABLED_ALL_DEF, {?ENABLED_ALL_OPT, flag}).

-define(GLOBAL_DEFS, []).

-define(COMMANDS,
        [{list, [?VERBOSE_DEF, ?MINIMAL_DEF, ?ENABLED_DEF, ?ENABLED_ALL_DEF]},
         enable,
         disable]).

-spec start() -> no_return(). 
start() ->
    {ok, [[PluginsFile|_]|_]} =
        init:get_argument(enabled_plugins_file),
    {ok, [[PluginsDir|_]|_]} = init:get_argument(plugins_dist_dir),
    {Command, Opts, Args} =
        case parse_arguments(?COMMANDS, ?GLOBAL_DEFS,
			     init:get_plain_arguments())
        of
            {ok, Res}  -> Res;
            no_command -> print_error("could not recognise command", []),
                          usage()
        end,

    %% io:format("Command=~p Opts=~p Args=~p~n", [Command, Opts, Args]),
    %% io:format("PluginsFile=~p, PluginsDir=~p~n", [PluginsFile, PluginsDir]),

    PrintInvalidCommandError =
        fun () ->
                print_error("invalid command '~s'",
                            [string:join([atom_to_list(Command) | Args], " ")])
        end,

    case catch action(Command, Args, Opts, PluginsFile, PluginsDir) of
        ok ->
            quit(0);
        {'EXIT', {function_clause, [{?MODULE, action, _} | _]}} ->
            PrintInvalidCommandError(),
            usage();
        {'EXIT', {function_clause, [{?MODULE, action, _, _} | _]}} ->
            PrintInvalidCommandError(),
            usage();
        {error, Reason} ->
            print_error("~p", [Reason]),
            quit(2);
        {error_string, Reason} ->
            print_error("~s", [Reason]),
            quit(2);
        Other ->
            print_error("~p", [Other]),
            quit(2)
    end.

stop() ->
    ok.

%%----------------------------------------------------------------------------

action(list, [], Opts, PluginsFile, PluginsDir) ->
    action(list, [".*"], Opts, PluginsFile, PluginsDir);
action(list, [Pat], Opts, PluginsFile, PluginsDir) ->
    format_plugins(Pat, Opts, PluginsFile, PluginsDir);

action(enable, ToEnable0, _Opts, PluginsFile, PluginsDir) ->
    case ToEnable0 of
        [] -> throw({error_string, "Not enough arguments for 'enable'"});
        _  -> ok
    end,
    AllPlugins = knife_plugins:list(PluginsDir),
    Enabled = knife_plugins:read_enabled(PluginsFile),
    ImplicitlyEnabled = knife_plugins:dependencies(false,
                                                    Enabled, AllPlugins),
    ToEnable = [list_to_atom(Name) || Name <- ToEnable0],
    Missing = ToEnable -- plugin_names(AllPlugins),
    NewEnabled = lists:usort(Enabled ++ ToEnable),
    NewImplicitlyEnabled = knife_plugins:dependencies(false,
                                                       NewEnabled, AllPlugins),
    MissingDeps = (NewImplicitlyEnabled -- plugin_names(AllPlugins)) -- Missing,
    case {Missing, MissingDeps} of
        {[],   []} -> ok;
        {Miss, []} -> throw({error_string, fmt_missing("plugins",      Miss)});
        {[], Miss} -> throw({error_string, fmt_missing("dependencies", Miss)});
        {_,     _} -> throw({error_string,
                             fmt_missing("plugins", Missing) ++
                                 fmt_missing("dependencies", MissingDeps)})
    end,
    write_enabled_plugins(PluginsFile, NewEnabled),
    case NewEnabled -- ImplicitlyEnabled of
        [] -> io:format("Plugin configuration unchanged.~n");
        _  -> print_list("The following plugins have been enabled:",
                         NewImplicitlyEnabled -- ImplicitlyEnabled),
              report_change()
    end;

action(disable, ToDisable0, _Opts, PluginsFile, PluginsDir) ->
    case ToDisable0 of
        [] -> throw({error_string, "Not enough arguments for 'disable'"});
        _  -> ok
    end,
    ToDisable = [list_to_atom(Name) || Name <- ToDisable0],
    Enabled = knife_plugins:read_enabled(PluginsFile),
    AllPlugins = knife_plugins:list(PluginsDir),
    Missing = ToDisable -- plugin_names(AllPlugins),
    case Missing of
        [] -> ok;
        _  -> print_list("Warning: the following plugins could not be found:",
                         Missing)
    end,
    ToDisableDeps = knife_plugins:dependencies(true, ToDisable, AllPlugins),
    NewEnabled = Enabled -- ToDisableDeps,
    case length(Enabled) =:= length(NewEnabled) of
        true  -> io:format("Plugin configuration unchanged.~n");
        false -> ImplicitlyEnabled =
                     knife_plugins:dependencies(false, Enabled, AllPlugins),
                 NewImplicitlyEnabled =
                     knife_plugins:dependencies(false,
                                                 NewEnabled, AllPlugins),
                 print_list("The following plugins have been disabled:",
                            ImplicitlyEnabled -- NewImplicitlyEnabled),
                 write_enabled_plugins(PluginsFile, NewEnabled),
                 report_change()
    end.

%%----------------------------------------------------------------------------

print_error(Format, Args) ->
    ?FORMAT("Error: " ++ Format ++ "~n", [Args]).

-spec usage() -> no_return(). 
usage() ->
    quit(1).

%% Pretty print a list of plugins.
format_plugins(Pattern, Opts, PluginsFile, PluginsDir) ->
    Verbose = proplists:get_bool(?VERBOSE_OPT, Opts),
    Minimal = proplists:get_bool(?MINIMAL_OPT, Opts),
    Format = case {Verbose, Minimal} of
                 {false, false} -> normal;
                 {true,  false} -> verbose;
                 {false, true}  -> minimal;
                 {true,  true}  -> throw({error_string,
                                          "Cannot specify -m and -v together"})
             end,
    OnlyEnabled    = proplists:get_bool(?ENABLED_OPT,     Opts),
    OnlyEnabledAll = proplists:get_bool(?ENABLED_ALL_OPT, Opts),

    AvailablePlugins = knife_plugins:list(PluginsDir),
    EnabledExplicitly = knife_plugins:read_enabled(PluginsFile),
    EnabledImplicitly =
        knife_plugins:dependencies(false, EnabledExplicitly,
                                    AvailablePlugins) -- EnabledExplicitly,
    Missing = [#knife_plugin{name = Name, dependencies = []} ||
                  Name <- ((EnabledExplicitly ++ EnabledImplicitly) --
                               plugin_names(AvailablePlugins))],
    {ok, RE} = re:compile(Pattern),
    Plugins = [ Plugin ||
                  Plugin = #knife_plugin{name = Name} <- AvailablePlugins ++ Missing,
                  re:run(atom_to_list(Name), RE, [{capture, none}]) =:= match,
                  if OnlyEnabled    ->  lists:member(Name, EnabledExplicitly);
                     OnlyEnabledAll -> (lists:member(Name,
                                                     EnabledExplicitly) or
                                        lists:member(Name, EnabledImplicitly));
                     true           -> true
                  end],
    Plugins1 = usort_plugins(Plugins),
    MaxWidth = lists:max([length(atom_to_list(Name)) ||
                             #knife_plugin{name = Name} <- Plugins1] ++ [0]),
    [format_plugin(P, EnabledExplicitly, EnabledImplicitly,
                   plugin_names(Missing), Format, MaxWidth) || P <- Plugins1],
    ok.

format_plugin(#knife_plugin{name = Name, version = Version,
                      description = Description, dependencies = Deps},
              EnabledExplicitly, EnabledImplicitly, Missing,
              Format, MaxWidth) ->
    Glyph = case {lists:member(Name, EnabledExplicitly),
                  lists:member(Name, EnabledImplicitly),
                  lists:member(Name, Missing)} of
                {true, false, false} -> "[E]";
                {false, true, false} -> "[e]";
                {_,        _,  true} -> "[!]";
                _                    -> "[ ]"
            end,
    Opt = fun (_F, A, A) -> ok;
              ( F, A, _) -> io:format(F, [A])
          end,
    case Format of
        minimal -> io:format("~s~n", [Name]);
        normal  -> io:format("~s ~-" ++ integer_to_list(MaxWidth) ++ "w ",
                             [Glyph, Name]),
                   Opt("~s", Version, undefined),
                   io:format("~n");
        verbose -> io:format("~s ~w~n", [Glyph, Name]),
                   Opt("    Version:     \t~s~n", Version,     undefined),
                   Opt("    Dependencies:\t~p~n", Deps,        []),
                   Opt("    Description: \t~s~n", Description, undefined),
                   io:format("~n")
    end.

print_list(Header, Plugins) ->
    io:format(fmt_list(Header, Plugins)).

fmt_list(Header, Plugins) ->
    lists:flatten(
      [Header, $\n, [io_lib:format("  ~s~n", [P]) || P <- Plugins]]).

fmt_missing(Desc, Missing) ->
    fmt_list("The following " ++ Desc ++ " could not be found:", Missing).

usort_plugins(Plugins) ->
    lists:usort(fun plugins_cmp/2, Plugins).

plugins_cmp(#knife_plugin{name = N1, version = V1},
            #knife_plugin{name = N2, version = V2}) ->
    {N1, V1} =< {N2, V2}.

%% Return the names of the given plugins.
plugin_names(Plugins) ->
    [Name || #knife_plugin{name = Name} <- Plugins].

%% Write the enabled plugin names on disk.
write_enabled_plugins(PluginsFile, Plugins) ->
    case knife_file:write_term_file(PluginsFile, [Plugins]) of
        ok              -> ok;
        {error, Reason} -> throw({error, {cannot_write_enabled_plugins_file,
                                          PluginsFile, Reason}})
    end.

report_change() ->
    io:format("Plugin configuration has changed. "
              "Restart Knife for changes to take effect.~n").


parse_arguments(Commands, GlobalDefs, As) ->
    lists:foldl(maybe_process_opts(GlobalDefs, As), no_command, Commands).

maybe_process_opts(GDefs, As) ->    
    fun({C, Os}, no_command) ->	    
            process_opts(atom_to_list(C), dict:from_list(GDefs ++ Os), As);
       (C, no_command) ->
            (maybe_process_opts(GDefs, As))({C, []}, no_command);
       (_, {ok, Res}) ->
            {ok, Res}
    end.

process_opts(C, Defs, As0) ->
    KVs0 = dict:map(fun (_, flag)        -> false;
                        (_, {option, V}) -> V
                    end, Defs),
    process_opts(Defs, C, As0, not_found, KVs0, []).

process_opts(_Defs, C, [], found, KVs, Outs) ->
    {ok, {list_to_atom(C), dict:to_list(KVs), lists:reverse(Outs)}};
process_opts(_Defs, _C, [], not_found, _, _) ->
    no_command;
process_opts(Defs, C, [A | As], Found, KVs, Outs) ->
    OptType = case dict:find(A, Defs) of
                  error             -> none;
                  {ok, flag}        -> flag;
                  {ok, {option, _}} -> option
              end,
    case {OptType, C, Found} of
        {flag, _, _}     -> process_opts(
                              Defs, C, As, Found, dict:store(A, true, KVs),
                              Outs);
        {option, _, _}   -> case As of
                                []        -> no_command;
                                [V | As1] -> process_opts(
                                               Defs, C, As1, Found,
                                               dict:store(A, V, KVs), Outs)
                            end;
        {none, A, _}     -> process_opts(Defs, C, As, found, KVs, Outs);
        {none, _, found} -> process_opts(Defs, C, As, found, KVs, [A | Outs]);
        {none, _, _}     -> no_command
    end.



-spec quit(any()) -> no_return(). 
quit(Status) ->
    case os:type() of
        {unix,  _} ->
	    halt(Status);
	{win32, _} ->
	    init:stop(Status),
	    receive
	    after infinity -> ok
	    end
    end.
