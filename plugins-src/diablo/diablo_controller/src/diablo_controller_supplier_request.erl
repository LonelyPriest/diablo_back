-module(diablo_controller_supplier_request).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_request).

-export([action/2, action/3, action/4]).
%%--------------------------------------------------------------------
%% @desc: GET action
%%--------------------------------------------------------------------
action(Session, Req) ->
    ?DEBUG("GET Req ~n~p", [Req]),
    {ok, HTMLOutput} = supplier_frame:render(
			 [
			  {navbar, ?menu:navbars(?MODULE, Session)},
			  {sidebar, sidebar(Session)},
			  {ngapp, "supplierApp"},
			  {ngcontroller, "supplierCtrl"}]),
    Req:respond({200, [{"Content-Type", "text/html"}], HTMLOutput}).
     
%%--------------------------------------------------------------------
%% @desc: GET action
%%--------------------------------------------------------------------
action(Session, Req, {"list_supplier"}) ->
    ?DEBUG("list supplier with session ~p", [Session]),
    
    Merchant = ?session:get(merchant, Session),
    Suppliers = ?supplier:lookup([{<<"merchant">>, Merchant}]),
    ?utils:respond(200, batch, Req, Suppliers);

%% action(Session, Req, {"list_brand"}) ->
%%     ?DEBUG("list brand with session ~p", [Session]),

%%     Merchant = ?session:get(merchant, Session),
%%     Brands = ?supplier:lookup(brand, [{<<"merchant">>, Merchant}]),
%%     ?utils:respond(200, batch, Req, Brands);


%% action(Session, Req, {"list_unconnect_brand"}) ->
%%     ?DEBUG("list_unconnect_brand with session ~p", [Session]),

%%     Merchant = ?session:get(merchant, Session),
%%     Brands = ?supplier:lookup(unconnect_brand, [{<<"merchant">>, Merchant}]),
%%     ?utils:respond(200, batch, Req, Brands);

%%--------------------------------------------------------------------
%% @desc: DELTE action
%%--------------------------------------------------------------------
action(Session, Req, {"delete_supplier", SupplierId}) ->
    ?DEBUG("delete supplier with session ~p, id ~p", [Session, SupplierId]),
    ok = ?supplier:supplier(delete, {"id", ?to_integer(SupplierId)}),
    ?utils:respond(200, Req, ?succ(delete_supplier, SupplierId)).


%%--------------------------------------------------------------------
%% @desc: POST action
%%--------------------------------------------------------------------
action(Session, Req, {"new_supplier"}, Payload) ->
    ?DEBUG("new supplier with session ~p,  paylaod ~p", [Session, Payload]),

    Merchant = ?session:get(merchant, Session),
    MType    = ?session:get(mtype, Session),

    CreateFun = 
	case MType of
	    ?SALER ->
		fun(Arg) -> ?supplier:supplier(new, Arg) end ;
	    ?WHOLESALER ->
		fun(Arg) -> ?supplier:supplier(w_new, Arg) end
		%% case ?supplier:supplier(w_new, [{<<"merchant">>, Merchant}|Payload]) of
		%%     {ok, Name} ->
		%% 	?succ(add_supplier, Name);
		%%     {error, Error} ->
		%% 	Error
	end,

    case CreateFun([{<<"merchant">>, Merchant}|Payload]) of
	{ok, Name} ->
	    ?utils:respond(200, Req, ?succ(add_supplier, Name));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"update_supplier", Id}, Payload) ->
    ?DEBUG("update supplier with Session ~p, paylaod ~p", [Session, Payload]),
    ok =  ?supplier:supplier(update, {<<"id">>, ?to_integer(Id)}, Payload),
    ?utils:respond(200, Req, ?succ(update_supplier, Id));

%% brand
action(Session, Req, {"connect_brand"}, Payload) ->
    ?DEBUG("new brand with session ~p, payload ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    case ?supplier:supplier(connect_brand, [{<<"merchant">>, Merchant}|Payload]) of
	{ok, Name} ->
	    ?utils:respond(200, Req, ?succ(connect_brand, Name));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end.


sidebar(Session) ->
    %% supplier
    S1 = 
	case ?right_auth:authen(?list_supplier, Session) of
	    {ok, ?list_supplier} ->
		[{"supplier_detail", "供应商详情"}];
	    _ ->
		[]
	end,

    S2 = 
	case ?right_auth:authen(?new_supplier, Session) of
	    {ok, ?new_supplier} ->
		[{"supplier_new", "新增供应商"}];
	    _ ->
		[]
	end,

    %% brand
    S3 =
	case ?right_auth:authen(?list_brand, Session) of
	    {ok, ?list_brand} ->
		[{"brand_detail", "品牌详情"}];
	    _ ->
		[]
	end,

    S4 =
	case ?right_auth:authen(?connect_brand, Session) of
	    {ok, ?connect_brand} ->
		[{"brand_new", "关联品牌"}];
	    _ ->
		[]
	end,

    case S1 ++ S2 of
	[]      -> "";
	Sidebar ->
	    case S3 ++ S4 of
		[] ->
		    ?menu:sidebar(
		       level_2_menu,
		       [{{"supplier", "供应商管理", "glyphicon glyphicon-map-marker"}, Sidebar}]);
		Sidebar2 ->
		    ?menu:sidebar(
		       level_2_menu,
		       [{{"supplier", "供应商管理", "glyphicon glyphicon-map-marker"}, Sidebar},
			{{"brand", "品牌管理", "glyphicon glyphicon-map-marker"}, Sidebar2}])
	    end
    end.
	    


