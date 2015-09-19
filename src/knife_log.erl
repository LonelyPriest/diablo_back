%%%-------------------------------------------------------------------
%%% @author buxianhui
%%% @copyright (C) 2013, buxianhui
%%% @doc
%%%  Logger server
%%% Created : 11 Oct 2013 by buxianhui
%%%-------------------------------------------------------------------
-module(knife_log).

-behaviour(gen_server).

%% API
-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-export([log/3, log/4,
	 debug/1, debug/2,
	 info/1, info/2,
	 warning/1, warning/2,
	 error/1, error/2]).


-export([debug_on/0, debug_off/0, get_level/0]).

-define(SERVER, ?MODULE). 

%% =============================================================================
%% open or close debug flag
%% =============================================================================
debug_on() ->
    gen_server:call(?SERVER, debug_on).

debug_off() ->
    gen_server:call(?SERVER, debug_off).

get_level()->
    gen_server:call(?SERVER, get_level).

%% =============================================================================
%% log format
%% =============================================================================
info(Fmt)          -> log(default, info,    Fmt).
info(Fmt, Args)    -> log(default, info,    Fmt, Args).
warning(Fmt)       -> log(default, warning, Fmt).
warning(Fmt, Args) -> log(default, warning, Fmt, Args).
error(Fmt)         -> log(default, error,   Fmt).
error(Fmt, Args)   -> log(default, error,   Fmt, Args).
debug(Fmt)         -> log(default, debug,   Fmt).
debug(Fmt, Args)   -> log(default, debug,   Fmt, Args).
	
start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

log(Category, Level, Fmt) -> log(Category, Level, Fmt, []).

log(Category, Level, Fmt, Args) when is_list(Args) ->
    gen_server:cast(?SERVER, {log, Category, Level, Fmt, Args}).


%% =============================================================================
%% call backs
%% =============================================================================
init([]) ->
    {ok, CatLevelList} = application:get_env(knife, log_levels),
    CatLevels = [{Cat, level(Level)} || {Cat, Level} <- CatLevelList],
    {ok, orddict:from_list(CatLevels)}.


handle_call(debug_on, _From, CatLevels) ->
    New = [{Cat, level(debug)} || {Cat, _} <- CatLevels],
    {reply, ok, orddict:from_list(New)};

handle_call(debug_off, _From, CatLevels) ->
    New = [{Cat, level(info)} || {Cat, _} <- CatLevels],
    {reply, ok, orddict:from_list(New)};

handle_call(get_level, _From, CatLevels) ->
    Level = [level(Level) || {_Cat, Level} <- CatLevels],
    {reply, Level, CatLevels};

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

handle_cast({log, Category, Level, Fmt, Args}, CatLevels) ->
    CatLevel = case orddict:find(Category, CatLevels) of
                   {ok, L} -> L;
                   error   -> level(info)
               end,
    
    case level(Level) =< CatLevel of
        false -> ok;
        true  -> (case Level of
		      debug   -> fun error_logger:info_msg/2;
                      info    -> fun error_logger:info_msg/2;
                      warning -> fun error_logger:warning_msg/2;
                      error   -> fun error_logger:error_msg/2
                  end)(Fmt, Args)
    end,
    {noreply, CatLevels};

handle_cast(_Msg, State) ->
    {noreply, State}.


handle_info(_Info, State) ->
    {noreply, State}.


terminate(_Reason, _State) ->
    ok.


code_change(_OldVsn, State, _Extra) ->
    {ok, State}.


%%%===================================================================
%%% Internal functions
%%%===================================================================
level(debug)   -> 4;
level(info)    -> 3;
level(warning) -> 2;
level(error)   -> 1;
level(none)    -> 0;
level(4)       -> debug;
level(3)       -> info;
level(2)       -> warning;
level(1)       -> error;
level(0)       -> none.
