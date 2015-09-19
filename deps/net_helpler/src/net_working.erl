%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright Seasun(C) 2014, buxianhui
%%% @doc
%%%  

%%% @end
%%% Created : 26 Feb 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(net_working).

-compile(export_all).

boot(CallbackApp) ->
    ok = start(),
    ok = boot_tcp(CallbackApp).

boot_tcp(CallbackApp) ->
    {ok, TcpListeners} = application:get_env(CallbackApp, tcp_listener),
    [ok = start_tcp_listener(CallbackApp, Listener) || Listener <- TcpListeners],
    ok.

start() ->
    %% tcp_client_sup
    net_helper_sup:start_supervisor_child(
      net_tcp_client_sup, net_client_sup,
      [{local, net_tcp_client_sup},
       {net_connection_sup, start_link, []}]).

start_tcp_listener(CallbackApp, Listener) ->
    start_listener(CallbackApp, Listener, net_helper, "TCP Listener",
		   {?MODULE, start_client, [CallbackApp]}).

start_listener(CallbackApp, Listener, Protocol, Label, OnConnect) ->
    [start_listener0(CallbackApp, Address, Protocol, Label, OnConnect) ||
	Address <- tcp_listener_addresses(Listener)],
    ok.

start_listener0(CallbackApp, Address, Protocol, Label, OnConnect) ->
    Spec = tcp_listener_spec(net_tcp_listener_sup,
			     Address, tcp_opts(CallbackApp),
			     Protocol, Label, OnConnect),
    case supervisor:start_child(net_helper_sup, Spec) of
	{ok, _} -> ok;
	{error, {shutdown, _}} ->
	    {_IPAddress, _Port, _Family} = Address,
	    exit({could_not_start_tcp_listener})
    end.

tcp_listener_spec(NamePrefix, {IPAddress, Port, Family}, SocketOpts,
		 Protocol, Label, OnConnect) ->
    {tcp_name(NamePrefix, IPAddress, Port),
     {tcp_listener_sup, start_link,
     [IPAddress, Port, [Family | SocketOpts],
      {?MODULE, tcp_listener_started, [Protocol]},
      {?MODULE, tcp_listener_stopped, [Protocol]},
      OnConnect, Label]},
     transient, infinity, supervisor, [tcp_listener_sup]}.

tcp_listener_started(_Protocol, _IPAddress, _Port) ->
    ok.
tcp_listener_stopped(_Protocol, _IPAddress, _Port) ->
    ok.

tcp_opts(CallbackApp)->
    {ok, Opts} = application:get_env(CallbackApp, tcp_listen_options),
    Opts.

start_client(CallbackApp, Sock, SockTransform) ->
    {ok, _Child, Reader} = supervisor:start_child(net_tcp_client_sup, []),
    
    %% transfer new process Reader to accept sock
    ok = net_receiver:controlling_process(Sock, Reader),
    Reader ! {go, Sock, SockTransform, CallbackApp},
    
    Reader.

start_client(CallbackApp, Sock) ->
    start_client(CallbackApp, Sock, fun(S) -> {ok, S} end).

tcp_listener_addresses(Port) when is_integer(Port) ->
    tcp_listener_addresses_auto(Port);
tcp_listener_addresses({"auto", Port}) ->
    %% Variant to prevent lots of hacking around in bash and batch files
    tcp_listener_addresses_auto(Port);
tcp_listener_addresses({Host, Port}) ->
    %% auto: determine family IPv4 / IPv6 after converting to IP address
    tcp_listener_addresses({Host, Port, auto});
tcp_listener_addresses({Host, Port, Family0})
  when is_integer(Port) andalso (Port >= 0) andalso (Port =< 65535) ->
    [{IPAddress, Port, Family} ||
        {IPAddress, Family} <- getaddr(Host, Family0)];
tcp_listener_addresses({_Host, Port, _Family0}) ->
    error_logger:error_msg("invalid port ~p - not 0..65535~n", [Port]),
    throw({error, {invalid_port, Port}}).

tcp_listener_addresses_auto(Port) ->
    lists:append([tcp_listener_addresses(Listener) ||
                     Listener <- knife_utils:port_to_family(Port)]).

getaddr(Host, Family) ->
    case inet_parse:address(Host) of
        {ok, IPAddress} ->
	    [{IPAddress, resolve_family(IPAddress, Family)}];
	{error, _}      -> gethostaddr(Host, Family)
    end.

gethostaddr(Host, auto) ->
    Lookups = [{Family, inet:getaddr(Host, Family)} || Family <- [inet, inet6]],
        case [{IP, Family} || {Family, {ok, IP}} <- Lookups] of
        []  ->
		host_lookup_error(Host, Lookups);
	    IPs -> IPs
    end;

gethostaddr(Host, Family) ->
    case inet:getaddr(Host, Family) of
        {ok, IPAddress} -> [{IPAddress, Family}];
        {error, Reason} -> host_lookup_error(Host, Reason)
    end.

host_lookup_error(Host, Reason) ->    
    error_logger:error_msg("invalid host ~p - ~p~n", [Host, Reason]),
        throw({error, {invalid_host, Host, Reason}}).


resolve_family({_,_,_,_},         auto) -> inet;
resolve_family({_,_,_,_,_,_,_,_}, auto) -> inet6;
resolve_family(IP,                auto) -> throw({error, {strange_family, IP}});
resolve_family(_,                 F)    -> F.

tcp_name(Prefix, IPAddress, Port)
  when is_atom(Prefix) andalso is_number(Port) ->    
    list_to_atom(
      lists:flatten(
	io_lib:format("~w_~s:~w", [Prefix, inet_parse:ntoa(IPAddress), Port]))).
