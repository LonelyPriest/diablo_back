%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright Seasungame(C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 11 Apr 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(forest_error).

-include("../../../include/knife.hrl").

-compile(export_all).

error(target_not_connect, Target) ->
    {1101, "target " ++ ?to_string(Target) ++ " does not connect to proxy"};
error(step_timeout, Step) ->
    {1102, "step " ++ ?to_string(Step) ++ " timeout, please check agent"}.

