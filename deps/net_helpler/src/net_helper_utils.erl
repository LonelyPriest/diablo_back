%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 19 Jun 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(net_helper_utils).

-compile(export_all).

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
    [inet, inet6].
