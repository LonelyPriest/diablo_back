-module(diablo_wechat_request).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-export([action/1]).

action(Req) ->
    ?INFO("receive req ~p", [Req]).

