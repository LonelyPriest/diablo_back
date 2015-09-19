-module(diablo_controller_merchant_request).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_request).

-export([action/2, action/3, action/4]).

%%--------------------------------------------------------------------
%% @desc: GET action
%%--------------------------------------------------------------------
action(Session, Req) ->
    %% ?DEBUG("GET Req ~n~p", [Req]),
    {ok, HTMLOutput} = merchant_frame:render(
			 [
			  {navbar, ?menu:navbars(?MODULE, Session)},
			  {basebar, ?menu:w_basebar(Session)},
			  {sidebar, sidebar()},
			  {ngapp, "merchantApp"},
			  {ngcontroller, "merchantCtrl"}]),
    Req:respond({200, [{"Content-Type", "text/html"}], HTMLOutput}).
     
%%--------------------------------------------------------------------
%% @desc: GET action
%%--------------------------------------------------------------------
action(Session, Req, {"list_merchant"}) ->
    ?DEBUG("list_merchant with session ~p", [Session]),
    case ?merchant:lookup() of
	{ok, Merchants} ->
	    ?utils:respond(200, batch, Req, Merchants);
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"list_w_merchant"}) ->
    ?DEBUG("list_w_merchant with session ~p", [Session]),
    case ?merchant:lookup({<<"type">>, ?WHOLESALER}) of
	{ok, Merchants} ->
	    ?utils:respond(200, batch, Req, Merchants);
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

%%--------------------------------------------------------------------
%% @desc: DELTE action
%%--------------------------------------------------------------------
action(Session, Req, {"delete_merchant", MerchantId}) ->
    ?DEBUG("delete_merchant with session ~p, merchantId ~p",
	   [Session, MerchantId]),
    %% user of the merchant should be deleted first
    case  ?right:lookup_account({<<"merchant">>, ?to_integer(MerchantId)}) of
	[] ->
	    ok = ?merchant:merchant(delete, {"id", ?to_integer(MerchantId)}),
	    ?utils:respond(200, Req, ?succ(delete_merchant, MerchantId));
	_ ->
	    ?utils:respond(200, Req, ?err(account_of_merchant_not_empty, MerchantId))
    end.

%%--------------------------------------------------------------------
%% @desc: POST action
%%--------------------------------------------------------------------
action(Session, Req, {"new_merchant"}, Payload) ->
    ?DEBUG("new_merchant with session ~p, paylaod ~p", [Session, Payload]),
    case ?merchant:merchant(new, Payload) of
	{ok, Name} ->
	    ?utils:respond(200, Req, ?succ(add_merchant, Name));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"update_merchant", Id}, Payload) ->
    ?DEBUG("update_merchant with session ~p, paylaod ~p", [Session, Payload]),
    ok =  ?merchant:merchant(update, {<<"id">>, ?to_integer(Id)}, Payload),
    ?utils:respond(200, Req, ?succ(update_merchant, Id)).

sidebar() ->
    ?menu:sidebar(
       level_1_menu, 
       [{"merchant_new", "新增商家", "glyphicon glyphicon-plus"},
	{"merchant_detail", "商家详情", "glyphicon glyphicon-briefcase"}
       ]).


