%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright Seasun(C) 2014, buxianhui
%%% @doc
%%%  Some utils functions
%%% @end
%%% Created : 26 Feb 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(forest_utils).

-export([tcp_name/3]).

tcp_name(Prefix, IPAddress, Port)
  when is_atom(Prefix) andalso is_number(Port) ->    
    list_to_atom(
      format("~w_~s:~w", [Prefix, inet_parse:ntoa(IPAddress), Port])).
format(Fmt, Args) ->
     lists:flatten(io_lib:format(Fmt, Args)).


