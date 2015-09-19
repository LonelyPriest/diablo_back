%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright Seasun(C) 2014, buxianhui
%%% @doc
%%%  Knife plugins management
%%% @end
%%% Created : 28 Feb 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(knife_plugins).

-include("knife.hrl").

-compile(export_all).

setup() ->
    {ok, PluginDir} = application:get_env(knife, plugins_dir),
    {ok, ExpandDir} = application:get_env(knife, plugins_expand_dir),
    {ok, EnabledFile} = application:get_env(knife, enabled_plugins_file),

    Plugins = prepare_plugins(EnabledFile, PluginDir, ExpandDir),
    io:format("plugins ~p will be loaded... ~n", [Plugins]),
    Plugins.

active() ->
    {ok, ExpandDir} = application:get_env(knife, plugins_expand_dir),
    InstalledPlugins = [ P#knife_plugin.name || P <- list(ExpandDir) ],
    [App || {App, _, _} <- application:which_applications(),
	    lists:member(App, InstalledPlugins)].

prepare_plugins(EnabledFile, PluginDistDir, ExpandDir) ->
    %% io:format("EnabledFile ~p~n", [EnabledFile]),
    AllPlugins = list(PluginDistDir),
    Enabled = read_enabled(EnabledFile),
    %%Enabled = lists:foldl(
	%%	fun(P, Acc) ->
	%%		[P#knife_plugin.name|Acc]
	%%	end, [], AllPlugins),
    ToUnpack = dependencies(false, Enabled, AllPlugins),
    ToUnpackPlugins = lookup_plugins(ToUnpack, AllPlugins),

    case Enabled -- plugin_names(ToUnpackPlugins) of
	[]      -> ok;
	Missing -> io:format("Warning: the following enabled plugins were "
			     "not found: ~p~n", [Missing])
    end,

    case delete_recursively(ExpandDir) of
	ok          -> ok;
	{error, E1} -> throw({error, {cannot_delete_plugins_expand_dir,
				      [ExpandDir, E1]}})
    end,

    case filelib:ensure_dir(ExpandDir ++ "/") of
        ok          -> ok;
	{error, E2} -> throw({error, {cannot_create_plugins_expand_dir,
                                      [ExpandDir, E2]}})
    end,

    [prepare_plugin(Plugin, ExpandDir) || Plugin <- ToUnpackPlugins],

    %% ez plugin
    EzPlugins =
	[prepare_dir_plugin(PluginAppDescPath) ||
	    PluginAppDescPath <- filelib:wildcard(ExpandDir ++ "/*/ebin/*.app")],

    %% dir plugin
    %% io:format("pluginDistDir ~p~n", [PluginDistDir]),
    DirPlugins =
	[prepare_dir_plugin(Dir) ||
	    Dir <- filelib:wildcard(PluginDistDir ++ "/*/ebin/*.app")],
    %% io:format("DistPlugins ~p~n", [DirPlugins]),

    %% only loaded ennabled plugins
    %% [ P || P <- EzPlugins ++ DirPlugins, lists:member(P, Enabled)],
    [ P || P <- EzPlugins ++ DirPlugins].

list(PluginsDir) ->
    EZs = [{ez, EZ} || EZ <- filelib:wildcard("*.ez", PluginsDir)],
    FreeApps = [{app, App} ||
		   App <- filelib:wildcard("*/ebin/*.app", PluginsDir)],
    {Plugins, Problems} =
        lists:foldl(
	  fun ({error, EZ, Reason}, {Plugins1, Problems1}) ->
		  {Plugins1, [{EZ, Reason} | Problems1]};
	      (Plugin = #knife_plugin{}, {Plugins1, Problems1}) ->
		  {[Plugin|Plugins1], Problems1}
	  end, {[], []},
	  [plugin_info(PluginsDir, Plug) || Plug <- EZs ++ FreeApps]),
    
    case Problems of
        [] -> ok;
        _  -> io:format("Warning: Problem reading some plugins: ~p~n",
                        [Problems])
    end,
    Plugins.

read_enabled(PluginsFile) ->
    case knife_file:read_term_file(PluginsFile) of
        {ok, [Plugins]} ->
	    Plugins;
	{ok, []}        -> [];
        {ok, [_|_]}     -> throw({error, {malformed_enabled_plugins_file,
                                          PluginsFile}});
        {error, enoent} -> [];
        {error, Reason} -> throw({error, {cannot_read_enabled_plugins_file,
                                          PluginsFile, Reason}})
    end.

dependencies(Reverse, Sources, AllPlugins) ->
    {ok, G} = build_acyclic_graph(
                fun (App, _Deps) ->
			[{App, App}] end,
                fun (App,  Deps) ->
			[{App, Dep} || Dep <- Deps] end,
                lists:ukeysort(
                  1, [{Name, Deps} ||
                         #knife_plugin{name         = Name,
                                 dependencies = Deps} <- AllPlugins] ++
                      [{Dep,   []} ||
                          #knife_plugin{dependencies = Deps} <- AllPlugins,
                          Dep                          <- Deps])),
    
    Dests = case Reverse of
		false ->
		    digraph_utils:reachable(Sources, G);
		true  -> digraph_utils:reaching(Sources, G)
            end,
    true = digraph:delete(G),
    Dests.


build_acyclic_graph(VertexFun, EdgeFun, Graph) ->
    G = digraph:new([acyclic]),    try
        [case digraph:vertex(G, Vertex) of
             false ->
		 digraph:add_vertex(G, Vertex, Label);
	                  _     -> ok = throw({graph_error, {vertex, duplicate, Vertex}})
         end || {Module, Atts}  <- Graph,
                {Vertex, Label} <- VertexFun(Module, Atts)],
        [case digraph:add_edge(G, From, To) of
             {error, E} -> throw({graph_error, {edge, E, From, To}});
             _          -> ok
         end || {Module, Atts} <- Graph,
                {From, To}     <- EdgeFun(Module, Atts)],
        {ok, G}
    catch {graph_error, Reason} ->
            true = digraph:delete(G),
            {error, Reason}
    end.


delete_recursively(Fn) ->
    case knife_file:recursive_delete([Fn]) of
        ok                 ->
	    ok;
	        {error, {Path, E}} -> {error, {cannot_delete, Path, E}};
        Error              -> Error
    end.

prepare_plugin(#knife_plugin{type = ez, location = Location}, ExpandDir) ->
    zip:unzip(Location, [{cwd, ExpandDir}]);
prepare_plugin(#knife_plugin{type = _dir, name = _Name, location = _Location},
               _ExpandDir) ->
    %% unpacked plugin, nothing to do
    ok.
    %% knife_file:recursive_copy(Location, filename:join([ExpandDir, Name])).

plugin_info(Base, {ez, EZ0}) ->
    EZ = filename:join([Base, EZ0]),
    case read_app_file(EZ) of
        {application, Name, Props} -> mkplugin(Name, Props, ez, EZ);
        {error, Reason}            -> {error, EZ, Reason}
    end;
plugin_info(Base, {app, App0}) ->
    App = filename:join([Base, App0]),
    case knife_file:read_term_file(App) of
        {ok, [{application, Name, Props}]} ->
            mkplugin(Name, Props, dir,
                     filename:absname(
                       filename:dirname(filename:dirname(App))));
        {error, Reason} ->
            {error, App, {invalid_app, Reason}}
    end.

mkplugin(Name, Props, Type, Location) ->
    Version = proplists:get_value(vsn, Props, "0"),
    Description = proplists:get_value(description, Props, ""),
    Dependencies =
        filter_applications(proplists:get_value(applications, Props, [])),
    #knife_plugin{name = Name, version = Version, description = Description,
            dependencies = Dependencies, location = Location, type = Type}.

read_app_file(EZ) ->
    case zip:list_dir(EZ) of
        {ok, [_|ZippedFiles]} ->
            case find_app_files(ZippedFiles) of
                [AppPath|_] ->
                    {ok, [{AppPath, AppFile}]} =
                        zip:extract(EZ, [{file_list, [AppPath]}, memory]),
                    parse_binary(AppFile);
		[] ->                    {error, no_app_file}
            end;
        {error, Reason} ->
            {error, {invalid_ez, Reason}}
    end.

find_app_files(ZippedFiles) ->
    {ok, RE} = re:compile("^.*/ebin/.*.app$"),
    [Path || {zip_file, Path, _, _, _, _} <- ZippedFiles,
             re:run(Path, RE, [{capture, none}]) =:= match].

parse_binary(Bin) ->
    try
        {ok, Ts, _} = erl_scan:string(binary_to_list(Bin)),
        {ok, Term} = erl_parse:parse_term(Ts),
	Term
    catch
        Err ->
	     {error, {invalid_app, Err}}
    end.

filter_applications(Applications) ->
    [Application || Application <- Applications,
		    not is_available_app(Application)].


is_available_app(Application) ->
        case application:load(Application) of
        {error, {already_loaded, _}} ->
		true;
	    ok -> application:unload(Application),
		  true;
	    _  -> false
    end.


prepare_dir_plugin(PluginAppDescPath) ->
    %% io:format("code:add_path ~p~n", [filename:dirname(PluginAppDescPath)]),
    code:add_path(filename:dirname(PluginAppDescPath)),
    list_to_atom(filename:basename(PluginAppDescPath, ".app")).


plugin_names(Plugins) ->    
    [Name || #knife_plugin{name = Name} <- Plugins].

lookup_plugins(Names, AllPlugins) ->
    [P || P = #knife_plugin{name = Name} <- AllPlugins, lists:member(Name, Names)].

