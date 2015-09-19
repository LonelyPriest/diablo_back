-module(diablo_controller_sale_request).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_request).

-export([action/2, action/3, action/4]).

action(Session, Req) ->
    {ok, HTMLOutput} = sale_frame:render(
			 [
			  {navbar, ?menu:navbars(?MODULE, Session)},
			  {sidebar, sidebar(Session)},
			  {ngapp, "saleApp"},
			  {ngcontroller, "saleCtrl"}]),
    Req:respond({200, [{"Content-Type", "text/html"}], HTMLOutput}).

action(Session, Req, Method) ->
    ?DEBUG("receive unkown method ~p, session ~p", [Method, Session]),
    ?utils:respond(200, Req, ?err(unkown_operation, Method)).


%% ================================================================================
%% POST
%% ================================================================================
action(Session, Req, {"payment"}, Payload) ->
    ?DEBUG("payment with session ~p~n, paylaod ~tp",
	   [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    
    case ?sale:payment([{<<"merchant">>, Merchant}] ++ Payload) of
	{ok, Reply, RunningNo} ->
	    %% generate a running number
	    %% RunningNo = ?inventory_sn:sn(running_no, Merchant),
	    ?utils:respond(200, Req, Reply,
			   {<<"running_no">>, ?to_binary(RunningNo)});
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

%% sale info
action(Session, Req, {"list_sale_info"}, Payload) ->
    ?DEBUG("list_sale_info with session ~p, payload ~p", [Session, Payload]),
    Merchant     = ?session:get(merchant, Session),
    Shops        = ?value(<<"shop">>, Payload),
    CurrentPage  = ?value(<<"page">>, Payload),
    CountPerPage = ?value(<<"count">>, Payload),

    Total = case CurrentPage of
		1 -> ?sale:lookup(
			total_with_pagination,
			[{<<"merchant">>, Merchant}, {<<"shop">>, Shops}]);
		_ -> 0
	    end,
    
    Condition = [{<<"merchant">>, Merchant},
		 {<<"shop">>, Shops}],
    {ok, Sales} = ?sale:lookup(pagination, CurrentPage, CountPerPage, Condition),
    ?utils:respond(200, object, Req, {[{<<"ecode">>, 0},
				       {<<"total">>, Total},
				       {<<"data">>, Sales}]});


action(Session, Req, {"filter_sale_info"}, Payload) ->
    ?DEBUG("filter_sale_info with session ~p, payload ~p", [Session, Payload]),
    Merchant     = ?session:get(merchant, Session),
    Pattern            = ?value(<<"pattern">>, Payload),
    {struct, Fields}   = ?value(<<"fields">>, Payload),
    CurrentPage        = ?value(<<"page">>, Payload),
    CountPerPage       = ?value(<<"count">>, Payload),

    NewFields = [{<<"merchant">>, Merchant}|Fields],
    
    Total = case CurrentPage of
		1 -> ?sale:do_filter(total, ?to_a(Pattern), NewFields);
		_ -> 0
	    end,

    {ok, Sales} =
	?sale:do_filter(
	   pagination, CurrentPage, CountPerPage, ?to_a(Pattern), NewFields),
    
    ?utils:respond(200, object, Req, {[{<<"ecode">>, 0},
				       {<<"total">>, Total},
				       {<<"data">>, Sales}]});

action(Session, Req, {"list_sale_info_with_running"}, Payload) ->
    ?DEBUG("list_sale_info_with_running with session ~p, payload ~p",
	   [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    RunningNo = ?value(<<"running_no">>, Payload),
    {ok, SaleInfo} =
	case ?session:get(type, Session) of
	    ?MERCHANT ->
		?sale:lookup(condition,
			     [{<<"running_no">>, RunningNo},
			      {<<"merchant">>, Merchant}]);
	    ?USER ->
		Shop = ?value(<<"shops">>, Payload),
		?sale:lookup(condition,
			     [{<<"merchant">>, Merchant},
			      {<<"shop">>, Shop},
			      {<<"running_no">>, ?to_integer(RunningNo)}])
	end,
    
    ?utils:respond(200, batch, Req, SaleInfo);

action(Session, Req, {"reject_and_exchange"}, Payload) ->
    ?DEBUG("reject_and_exchange with session ~p, payload ~p",
	   [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    case 
	?sale:reject([{<<"merchant">>, Merchant}|Payload]) of
	{ok, RunningNo} ->
	    ?utils:respond(200, Req, ?succ(reject, RunningNo));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;


action(Session, Req, {"list_reject_info"}, Payload) ->
    ?DEBUG("list_sale_info with session ~p, payload ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    {ok, RejectInfo} = 
	?sale:lookup(reject, [{<<"merchant">>, Merchant},
			      {<<"shop">>, ?value(<<"shops">>, Payload)}]), 
    ?utils:respond(200, batch, Req, RejectInfo).


sidebar(Session) ->
    Cashier =
	case ?right_auth:authen(?perment, Session) of
	    {ok, ?perment} ->
		[{"cashier", "前台收银", "glyphicon glyphicon-usd"}];
	    _ -> []
	end,

    Reject =
	case ?right_auth:authen(?reject_and_exchange, Session) of
	    {ok, ?reject_and_exchange} ->
		[{"reject_exchange", "退换货", "glyphicon glyphicon-transfer"}];
	    _ -> []
	end,

    L1 = ?menu:sidebar(level_1_menu, Cashier ++ Reject),

    Shops = ?inventory_request:get_shops(Session),

    SaleDetail =
	[{{"sale_detail", "销售详情", "glyphicon glyphicon-map-marker"},
	  lists:foldr(fun({Id, Name, _}, Acc) ->
			      S = {?to_string(Id), ?to_string(Name)},
			      case lists:member(S, Acc) of
				  true -> Acc;
				  false -> [S|Acc]
			      end
		      end, [], Shops)}],

    RejectDetail =
	[{{"reject_detail", "退货详情", "glyphicon glyphicon-map-marker"},
	  lists:foldr(fun({Id, Name, _}, Acc) ->
			      S = {?to_string(Id), ?to_string(Name)},
			      case lists:member(S, Acc) of
				  true -> Acc;
				  false -> [S|Acc]
			      end
		      end, [], Shops)}],

    L2 = ?menu:sidebar(level_2_menu, SaleDetail ++ RejectDetail),
    
    %% L2 = ?menu:sidebar(level_2_menu,
    %% 		  [
    %% 		   {{"sale", "销售详情"},
    %% 		    [
    %% 		     %% {"cashier", "收银"},
    %% 		     {"detail", "销售详情"},
    %% 		     %% {"reject_exchange", "退换货"},
    %% 		     {"reject_detail", "退货详情"}]
    %% 		   }
    %% 		  ]),
    L1 ++ L2.


