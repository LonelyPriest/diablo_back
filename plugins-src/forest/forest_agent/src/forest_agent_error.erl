%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 14 Apr 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------

-module(forest_agent_error).

-include("../../../include/knife.hrl").

-export([error/2]).


%% protocal
error(protocal_not_support, Protocal) ->
    {9101, ?to_binary("protocal path [" ++ ?to_string(Protocal) ++ "] does not support")};

%% connection
error(connect_epath, Path) ->
    {9102, ?to_binary("path [" ++ ?to_string(Path) ++ "] "
		      "to connect to download server does not exist")};
error(connect_euser, User) ->
    {9103, ?to_binary("user [" ++ ?to_string(User) ++ "] "
		      "to connect to download server does not exist")};
error(connect_ehost, Host) ->
    {9104, ?to_binary("download server [" ++ ?to_string(Host) ++ "] does not exist")};

error(connect_econn, User) ->
    {9105, ?to_binary("failed to connect to download server with user [" ++ ?to_string(User) ++ "]")};

error(connect_eclosed, Host) ->
    {9106, ?to_binary("donlowed server [" ++ ?to_string(Host) ++ "] has been closed")};
error(connect_unkown_reason, Reason) ->
    {9107, ?to_binary("failed to connect to downloaed server "
		      "with unkown reason: " ++ ?to_string(Reason))};

%% download
error(download_epath, Path) ->
    {9201, ?to_binary("path [" ++ ?to_string(Path) ++ "] to downloading file does not exist")};
error(download_eclosed, Path) ->
    {9202, ?to_binary("ftp with path [" ++ ?to_string(Path) ++ "] was closed")};
error(download_unkown_reason, Reason) ->
    {9203, ?to_binary("failed to download with reason: [" ++ ?to_string(Reason) ++ "]")};
error(not_enough_space, Path)->
    {9204, ?to_binary("local path [" ++ ?to_string(Path) ++ "] "
		      "is not enough space to download file")};

%% execute script
error(exe_script_enoent, File) ->
    {9301, ?to_binary("script file [" ++ ?to_string(File) ++ "] does not exit")};
error(exe_script_unkown_reason, Reason) ->
    {9302, ?to_binary("failed to execute script with unkown reason: " ++ ?to_string(Reason))};


%% step
error(step_not_support, Step)->
    {9401, ?to_binary("step [" ++ ?to_string(Step) ++ "] not support now")}.









