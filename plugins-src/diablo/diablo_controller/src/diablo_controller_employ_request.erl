-module(diablo_controller_employ_request).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_request).

-export([action/2, action/3, action/4]).
%%--------------------------------------------------------------------
%% @desc: GET action
%%--------------------------------------------------------------------
action(Session, Req) ->
    ?DEBUG("GET Req ~n~p", [Req]),
    {ok, HTMLOutput} = employ_frame:render(
			 [
			  {navbar, ?menu:navbars(?MODULE, Session)},
			  {basebar, ?menu:w_basebar(Session)},
			  {sidebar, sidebar(Session)},
			  {ngapp, "employApp"},
			  {ngcontroller, "employCtrl"}]),
    Req:respond({200, [{"Content-Type", "text/html"}], HTMLOutput}).
     
%%--------------------------------------------------------------------
%% @desc: GET action
%%--------------------------------------------------------------------
action(Session, Req, {"list_employe"}) ->
    ?DEBUG("list employ with session ~p", [Session]),
    Merchant = ?session:get(merchant, Session),       
    case ?w_user_profile:get(employee, Merchant) of
	{ok, Employees} ->
	    ?utils:respond(200, batch, Req, Employees);
	{error, _Error} ->
	    ?utils:respond(200, batch, Req, [])
    end;

%%--------------------------------------------------------------------
%% @desc: DELTE action
%%--------------------------------------------------------------------
action(Session, Req, {"delete_employe", EmployId}) ->
    ?DEBUG("delete employ with session ~p, id ~p", [Session, EmployId]),
    Merchant = ?session:get(merchant, Session),
    case ?employ:employ(delete, Merchant, EmployId) of
	{ok, EmployId} ->
	    ?utils:respond(200, Req, ?succ(delete_employ, EmployId));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end.


%%--------------------------------------------------------------------
%% @desc: POST action
%%--------------------------------------------------------------------
action(Session, Req, {"new_employe"}, Payload) ->
    ?DEBUG("new employ with session ~p,  paylaod ~p", [Session, Payload]),

    Merchant = ?session:get(merchant, Session),
    case ?employ:employ(new, [{<<"merchant">>, Merchant}|Payload]) of
	{ok, Name} ->
	    ?utils:respond(200, Req, ?succ(add_employ, Name));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"update_employe", Id}, Payload) ->
    ?DEBUG("update a employ with Session ~p~npaylaod ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    case ?employ:employ(update, Merchant, Id, Payload) of
	{ok, EmployId} ->
	    ?utils:respond(200, Req, ?succ(update_employ, EmployId));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end.

sidebar(Session) ->
    S1 = 
	case ?right_auth:authen(?list_employe, Session) of
	    {ok, ?list_employe} ->
		[{"employ_detail", "员工详情", "glyphicon glyphicon-book"}];
	    _ ->
		[]
	end,

    S2 = 
	case ?right_auth:authen(?new_employe, Session) of
	    {ok, ?new_employe} ->
		[{"employ_new", "新增员工", "glyphicon glyphicon-plus"}];
	    _ ->
		[]
	end,

    case S2 ++ S1 of
	[] -> "";
	Sidebar ->
	    ?menu:sidebar(level_1_menu, Sidebar)
	    %% ?menu:sidebar(level_2_menu,
	    %% 		  [{{"employ", "员工管理", "glyphicon glyphicon-map-marker"}, Sidebar}])
    end.


