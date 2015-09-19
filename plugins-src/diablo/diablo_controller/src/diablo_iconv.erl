
-module(diablo_iconv).

-behaviour(gen_server).

-export([start/0, start_link/0, convert/3]).

%% Internal exports, call-back functions.
-export([init/1,
	 handle_call/3,
	 handle_cast/2,
	 handle_info/2,
	 code_change/3,
	 terminate/2]).

start() ->
    gen_server:start({local, ?MODULE}, ?MODULE, [], []).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
    case erl_ddll:load_driver(get_so_path(), iconv_drv) of
	ok -> ok;
	{error, already_loaded} -> ok
    end,
    Port = open_port({spawn, "iconv_drv"}, []),
    ets:new(iconv_table, [set, public, named_table]),
    ets:insert(iconv_table, {port, Port}),
    {ok, Port}.

get_so_path() ->
	case code:priv_dir(iconv) of 
	{error, _} -> "./priv"; 
	Path -> Path
	end. 

%%% --------------------------------------------------------
%%% The call-back functions.
%%% --------------------------------------------------------

handle_call(_, _, State) ->
    {noreply, State}.

handle_cast(_, State) ->
    {noreply, State}.

handle_info({'EXIT', Port, Reason}, Port) ->
    {stop, {port_died, Reason}, Port};
handle_info({'EXIT', _Pid, _Reason}, Port) ->
    {noreply, Port};
handle_info(_, State) ->
    {noreply, State}.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

terminate(_Reason, Port) ->
    Port ! {self, close},
    ok.

convert(From, To, String) ->
    [{port, Port} | _] = ets:lookup(iconv_table, port),
    Bin = term_to_binary({From, To, String}),
    BRes = port_control(Port, 1, Bin),
    binary_to_list(BRes).

