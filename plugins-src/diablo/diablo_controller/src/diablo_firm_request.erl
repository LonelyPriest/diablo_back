-module(diablo_firm_request).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_request).

-export([action/2, action/3, action/4]).
%%--------------------------------------------------------------------
%% @desc: GET action
%%--------------------------------------------------------------------
action(Session, Req) ->
    ?DEBUG("GET Req ~n~p", [Req]),
    {ok, HTMLOutput} = firm_frame:render(
			 [
			  {navbar, ?menu:navbars(?MODULE, Session)},
			  {basebar, ?menu:w_basebar(Session)},
			  {sidebar, sidebar(Session)},
			  {ngapp, "firmApp"},
			  {ngcontroller, "firmCtrl"}]),
    Req:respond({200, [{"Content-Type", "text/html"}], HTMLOutput}).

%%--------------------------------------------------------------------
%% @desc: GET action
%%--------------------------------------------------------------------
action(Session, Req, {"list_firm"}) ->
    ?DEBUG("list firm with session ~p", [Session]), 
    Merchant = ?session:get(merchant, Session),
    %% batch_responed(fun() -> ?supplier:supplier(w_list, Merchant) end, Req);
    batch_responed(fun() -> ?w_user_profile:get(firm, Merchant) end, Req); 

%%--------------------------------------------------------------------
%% @desc: DELTE action
%%--------------------------------------------------------------------
action(Session, Req, {"delete_frim", FirmId}) ->
    ?DEBUG("delete firm with session ~p, id ~p", [Session, FirmId]),
    ok = ?supplier:supplier(delete, {"id", ?to_integer(FirmId)}),
    ?utils:respond(200, Req, ?succ(delete_supplier, FirmId)).


%%--------------------------------------------------------------------
%% @desc: POST action
%%--------------------------------------------------------------------
action(Session, Req, {"new_firm"}, Payload) ->
    ?DEBUG("new frim with session ~p,  paylaod ~p", [Session, Payload]),

    Merchant = ?session:get(merchant, Session),
    case ?supplier:supplier(w_new, [{<<"merchant">>, Merchant}|Payload]) of
	{ok, FirmId} ->
	    ?utils:respond(200, Req, ?succ(add_supplier, FirmId), {<<"id">>, FirmId});
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"delete_firm"}, Payload) ->
    ?DEBUG("update frim with session ~p,  paylaod ~p", [Session, Payload]),

    Merchant = ?session:get(merchant, Session),
    FirmId  = ?v(<<"firm_id">>, Payload),
    case ?supplier:supplier(w_delete, Merchant, FirmId) of
	{ok, FirmId} ->
	    ?utils:respond(200, Req, ?succ(delete_supplier, FirmId));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"update_firm"}, Payload) ->
    ?DEBUG("update frim with session ~p,  paylaod ~p", [Session, Payload]),

    Merchant = ?session:get(merchant, Session),
    case ?supplier:supplier(w_update, Merchant, Payload) of
	{ok, FirmId} ->
	    ?utils:respond(200, Req, ?succ(update_supplier, FirmId));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end. 

sidebar(Session) ->
    %% firm
    %% S1 = 
    %% 	case ?right_auth:authen(?list_w_firm, Session) of 
    %% 	    {ok, ?list_w_firm} ->
    %% 		[{"firm_detail", "厂商详情", "glyphicon glyphicon-briefcase"}];
    %% 	    _ ->
    %% 		[]
    %% 	end,

    S2 = 
	case ?right_auth:authen(?new_w_firm, Session) of
	    {ok, ?new_w_firm} ->
		[{"new_firm", "新增厂商", "glyphicon glyphicon-plus"},
		 {"firm_detail", "厂商详情", "glyphicon glyphicon-book"}];
	    _ ->
		[{"firm_detail", "厂商详情", "glyphicon glyphicon-book"}]
	end,

    %% level_2_menu,
    %% [{{"firm", "厂商管理", "glyphicon glyphicon-map-marker"}, S1 ++ S2}]).
    
    %% ?menu:sidebar(level_1_menu, S2 ++ S1).
    ?menu:sidebar(level_1_menu, S2).



batch_responed(Fun, Req) ->
    case Fun() of
	{ok, Values} ->
	    ?utils:respond(200, batch, Req, Values);
	{error, _Error} ->
	    ?utils:respond(200, batch, Req, [])
    end.

%% object_responed(Fun, Req) ->
%%     case Fun() of
%% 	{ok, Value} ->
%% 	    ?utils:respond(200, object, Req, {Value});
%% 	{error, Error} ->
%% 	    ?utils:respond(200, Req, Error)
%%     end.

