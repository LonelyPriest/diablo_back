%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright Seasun(C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created :  3 Mar 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(forest_connection).

-include("../../../include/knife.hrl").
-include("forest_agent.hrl").

-behaviour(forest_gen_connection).

-export([start_link/0, init/1, connect/2, handle_message/2,
	 terminate/2]).

-export([tcp_connector_addr/1, tcp_connector_addr_auto/1,
	 reconnect/0, reconnect/2, close/0, connect/0]).

-define(FOREST_TCP_OPTS, [binary, {packet, raw}, {active,true}, {nodelay, true}]).
-define(SOCKET_CLOSING_TIMEOUT, 1000).
%% -define(INTERVAL_RECONNECT, 3000).

-record(state, {sock,
		closing_reason,
		waitting_socket_close = false,
		reconnect_times = 0}).


close() ->
    gen_server:cast(?MODULE, close).

connect() ->
    gen_server:cast(?MODULE, connect).


start_link()->
    forest_gen_connection:start_link(?MODULE).

init([]) ->
    {ok, TcpConnector} = application:get_env(forest_agent, tcp_connector),
    [{IPAddr, Port, Family}|_] = tcp_connector_addr(TcpConnector),
    ForestParams =
	#forest_params_network{host = IPAddr,
			       port = Port,
			       family = Family},
    ok = timer:start(),
    {ok, #state{}, ForestParams}.


handle_message(close, #state{sock = Sock} = State)->
    ?INFO("start to close socket ~p", [Sock]),
    gen_tcp:close(Sock),
    {ok, State#state{sock = undefined}};

handle_message(Info, State)->
    ?WARN("handle_message: receive unkown message ~p", [Info]),
    {ok, State}.

terminate(_Reason, _State)->
    ok.

reconnect(forever, Times) ->
    ?WARN("the ~p times to reconnect after 3 seconds", [Times]),
    AfterTimes = ?INTERVAL_RECONNECT + Times * 2000,
    erlang:send_after(AfterTimes, ?MODULE, {'$gen_cast', connect}).

reconnect()->
    %% reconnect after 3 seconds
    ?WARN("reconnect after 3 seconds", []),
    erlang:send_after(?INTERVAL_RECONNECT, ?MODULE, {'$gen_cast', connect}).


%% timer_cancle(undefined) ->
%%     ok;
%% timer_cancle(TRef) ->
%%     ?DEBUG("start to cancel timer ~p", [TRef]),
%%     {ok, cancel} = timer:cancel(TRef).

connect(NetworkParams, State) ->
    do_connect(NetworkParams, State).

do_connect(#forest_params_network{
	      host = IPAddr, port = Port, family = Family,
	      connection_timeout = Timeout} = _Params,
	   #state{reconnect_times = Times} = State)->
    %% ?INFO("the ~p times to start to connect to server ~p", [Times, IPAddr]),
    case gen_tcp:connect(IPAddr, Port, [Family|?FOREST_TCP_OPTS], Timeout) of
	{ok, Sock} ->
	    ?DEBUG("success to connect to server ~p with ~p times",
		   [IPAddr, Times]),
	    PidAction = 
		case erlang:whereis(forest_action) of
		    undefined ->
			?DEBUG("forest_action process does not exist, "
			       "new it", []),
			{ok, Child} =
			    forest_agent_sup:start_child(forest_action, Sock),
			Child;
		    Any ->
			%% reconnect, refresh sock
			?DEBUG("reconnect to ~p ok, refresh forest_action "
			       "server with new sock ~p", [IPAddr, Sock]),
			?INFO("reconnect to ~p ok, refresh forest_action "
			      "server with new sock ~p", [IPAddr, Sock]),
			forest_action:refresh_sock(Sock),
			Any
	    end,
	    
	    gen_tcp:controlling_process(Sock, PidAction),
	    {ok, State#state{sock = Sock, reconnect_times = 0}};
	
	{error, econnrefused} ->
	    ?DEBUG("Remote host ~p refused to connect, retry", [IPAddr]),
	    reconnect(forever, Times),
	    {ok, State#state{reconnect_times = Times + 1}};
	
	{error, _} = E ->
	    ?DEBUG("Failed to connect ~p, reason:~p~n", [IPAddr, E]),
	    reconnect(forever, Times),
	    {ok, State#state{reconnect_times = Times + 1}}
    end.

tcp_connector_addr_auto(Port) ->
    %% use first
    [Connector|_] = knife_utils:port_to_family(Port),
    tcp_connector_addr(Connector).

tcp_connector_addr({Host, Port}) ->
    tcp_connector_addr({Host, Port, auto});
tcp_connector_addr({Host, Port, Family0})->
    [{IpAddr, Port, Family}
     || {IpAddr, Family} <- getaddr(Host, Family0)];
tcp_connector_addr(Port) ->
    tcp_connector_addr_auto(Port).

getaddr(Host, Family) ->
    case inet_parse:address(Host) of
        {ok, IPAddress} ->
	    [{IPAddress,
	      case {IPAddress, Family} of
		  {{_,_,_,_}, auto} -> inet;
		  {{_,_,_,_,_,_,_,_}, auto} -> inet6;
		  {IP, auto} -> throw({error, {strange_family, IP}});
		  {_, F} -> F
	      end}];
	{error, _}      ->
	    gethostaddr(Host)
    end.

gethostaddr(Host) ->
    Lookups = [{Family, inet:getaddr(Host, Family)}
               || Family <- inet_address_preference()],
    [{IP, Family} || {Family, {ok, IP}} <- Lookups].



inet_address_preference() ->	    
    case application:get_env(forest_agent, use_ipv6) of
        {ok, true}        -> [inet6, inet];
	{ok, false}       -> [inet, inet6];
	undefined         -> [inet, inet6]
    end.
