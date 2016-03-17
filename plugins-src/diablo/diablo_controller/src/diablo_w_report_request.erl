%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2015, buxianhui
%%% @desc: wreport request
%%% Created : 22 Jul 2015 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_w_report_request).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_request).

-export([action/2, action/3, action/4]).

action(Session, Req) ->
    ?DEBUG("req ~p", [Req]),
    {ok, HTMLOutput} = wreport_frame:render(
			 [
			  {navbar, ?menu:navbars(?MODULE, Session)},
			  {basebar, ?menu:w_basebar(Session)},
			  {sidebar, sidebar(Session)},
			  {ngapp, "wreportApp"},
			  {ngcontroller, "wreportCtrl"}]),
    Req:respond({200, [{"Content-Type", "text/html"}], HTMLOutput}).


action(Session, _Req, Action) ->
    ?DEBUG("receive unkown action ~p with session ~p", [Action, Session]).

%% ================================================================================
%% POST
%% ================================================================================
action(Session, Req, {"daily_wreport", Type}, Payload) ->
    ?DEBUG("daily_wrport with session ~p, type ~p, paylaod~n~p",
	   [Session, Type, Payload]), 
    Merchant = ?session:get(merchant, Session),
    %% {struct, C} = ?v(<<"condition">>, Payload),
    
    ?pagination:pagination(
       fun(_Match, Conditions) ->
	       ?w_report:report(total, ?to_a(Type), Merchant, Conditions)
       end,
       
       fun(_Match, CurrentPage, ItemsPerPage, Conditions) ->
	       ?w_report:report(
		  ?to_a(Type), Merchant, CurrentPage, ItemsPerPage, Conditions)
       end, Req, Payload);

action(Session, Req, {"print_wreport", Type}, Payload) ->
    ?DEBUG("print_wreport with session ~p, type ~p, payload~n~p",
	  [Session, Type, Payload]),
    Merchant = ?session:get(merchant, Session),
    {struct, Content}  = ?v(<<"content">>, Payload),
    
    ShopId   = ?v(<<"shop">>, Content, []),
    Datetime = ?v(<<"datetime">>, Content),
    %% SPay     = ?v(<<"spay">>, Payload),
    
    HPay     = ?v(<<"hpay">>, Content, 0),
    Cash     = ?v(<<"cash">>, Content, 0),
    Card     = ?v(<<"card">>, Content, 0),
    Wire     = ?v(<<"wire">>, Content, 0),
    VPay     = ?v(<<"vpay">>, Content, 0) ,

    ResponseFun =
	fun(PCode, PInfo) ->
		?utils:respond(200, Req, ?succ(print_wreport, ShopId),
			       [{<<"pcode">>, PCode},
				{<<"pinfo">>, PInfo}])
	end,

    {VPrinters, ShopInfo} = ?wifi_print:get_printer(Merchant, ShopId),

    case VPrinters of
	[] ->
	    {error, ?err(shop_not_printer, ShopId)};
	_  -> 
	    ShopName = ?to_s(?v(<<"name">>, ShopInfo)) ++ "（日报表）", 

	    PrintInfo = 
		lists:foldr(
		  fun(P, Acc) ->
			  SN     = ?v(<<"sn">>, P),
			  Key    = ?v(<<"code">>, P),
			  Path   = ?v(<<"server_path">>, P),

			  Brand  = ?v(<<"brand">>, P),
			  Model  = ?v(<<"model">>, P),

			  Column = ?v(<<"pcolumn">>, P),
			  Height = ?v(<<"pheight">>, P),
			  
			  %% ?DEBUG("P ~p", [P]),
			  Server = ?wifi_print:server(?v(<<"server_id">>, P)), 

			  Head = ?wifi_print:title(Brand, Model, Column, ShopName),

			  Body = 
			      "日期：" ++ ?to_s(Datetime) ++ ?f_print:br(Brand)
			      ++ ?f_print:br(Brand)
			      %% ++ ?f_print:decorate_data(bwh)
			      ++ "备用金：" ++ ?f_print:br(Brand)
			      ++ ?f_print:br(Brand)
			      ++ "营业额：" ++ ?to_s(HPay) ++ ?f_print:br(Brand)
			      ++ ?f_print:br(Brand)
			      ++ "现金：" ++ ?to_s(Cash) ++ ?f_print:br(Brand)
			      ++ ?f_print:br(Brand)
			      ++ "刷卡：" ++ ?to_s(Card) ++ ?f_print:br(Brand)
			      ++ ?f_print:br(Brand)
			      ++ "汇款：" ++ ?to_s(Wire) ++ ?f_print:br(Brand)
			      ++ ?f_print:br(Brand)
			      ++ "核销：" ++ ?to_s(VPay) ++ ?f_print:br(Brand)
			      ++ ?f_print:br(Brand)
			      ++ "开支：" ++ ?f_print:br(Brand)
			      ++ ?f_print:br(Brand)
			      ++ "余额：" ++ ?f_print:br(Brand),
			      %% ++ ?f_print:decorate_data(cancel_bwh),
			  
			  PrintContent = Head ++ Body, 
			  NoUpgradeDevices = ["1004", "1001", "1002", "1003", "1023"],

			  DBody = 
			      case lists:member(
				     ?to_s(SN), NoUpgradeDevices) of
			  	  true ->
				      %% auto page
			  	      ?f_print:pagination(
			  		 auto, Height * 10, PrintContent);
			  	  false ->
				      %% no page
				      ?f_print:pagination(
					 just_size, Height * 10, PrintContent)
			      end, 
			  ?DEBUG("server ~p", [Server]),
			  [{SN, fun() when Server =:= rcloud ->
					?wifi_print:start_print(
					   rcloud, Brand, Model, Height,
					   SN, Key, Path, DBody);
				   () when Server =:= fcloud ->
					?wifi_print:start_print(
					  fcloud, SN, Key, Path, PrintContent) 
				end}|Acc] 
		  end, [], VPrinters),
	    
	    case ?wifi_print:multi_print(PrintInfo) of
		{Success, []} ->
		    ResponseFun(0, Success); 
		{[], Failed} ->
		    PInfo = [{[{<<"device">>, DeviceId}, {<<"ecode">>, ECode}]}
			     || {DeviceId, ECode} <- Failed],
		    ResponseFun(1, PInfo); 
		{_Success, Failed} when is_list(Failed)->
		    PInfo = [{[{<<"device">>, DeviceId}, {<<"ecode">>, ECode}]}
			     || {DeviceId, ECode} <- Failed],
		    ResponseFun(2, PInfo);
		{error, {ECode, _EInfo}} ->
		    ResponseFun(ECode, [])
	    end
    end.

sidebar(Session) ->
    AuthenFun =
	fun(Actions) ->
		lists:foldr(
		  fun({Action, Detail}, Acc) ->
			  case ?right_auth:authen(Action, Session) of
			      {ok, Action} -> [Detail|Acc];
			      _ -> Acc
			  end 
		  end, [], Actions)

	end,

    ReportAuthen = AuthenFun(
		   [{?daily_wreport,
		     {"wreport_daily", "日报表", "wi wi-moon-new"}}
		    %% {?weekly_wreport,
		    %%  {"wreport_weekly", "周报表", "wi wi-moon-waxing-cresent-1"}}, 
		    %% {?monthly_wreport,
		    %%  {"wreport_montyly", "月报表", "wi wi-moon-waxing-cresent-3"}},
		    %% {?quarter_wreport,
		    %%  {"wreport_quarter", "季度报表", "wi wi-moon-waxing-cresent-6"}},
		    %% {?half_wreport,
		    %%  {"wreport_half", "年中报表", "wi wi-moon-first-quarter"}},
		    %% {?year_wreport,
		    %%  {"wreport_year", "年报表", "wi wi-moon-full"}}
		   ]),

    

    case ReportAuthen of
	[]   -> [];
	R -> 
	    ?menu:sidebar(level_1_menu, R) 
    end.

    



