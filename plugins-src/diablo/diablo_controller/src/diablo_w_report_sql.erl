%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright DaYuTongYong(C) 2015, buxianhui
%%% @Desc   : all sql of report
%%% Created : 23 Jul 2015 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_w_report_sql).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-compile(export_all).

sale(new_by_shop, Merchant, Conditions) ->
    {StartTime, EndTime, NewConditions} = 
	?sql_utils:cut(fields_no_prifix, Conditions), 
    "select shop as shop_id"
	", sum(total) as t_amount"
	", sum(should_pay) as t_spay"
	", sum(has_pay) as t_hpay"
	", sum(has_pay) as t_hpay"
	", sum(cash) as t_cash"
	", sum(card) as t_card"
	", sum(wire) as t_wire"
	", sum(verificate) as t_verificate"
	" from w_sale"
	++ " where " ++ ?utils:to_sqls(proplists, NewConditions)
	++ " and merchant=" ++ ?to_s(Merchant)
	++ " and " ++ ?sql_utils:condition(time_no_prfix, StartTime, EndTime)
	++ " and deleted=" ++ ?to_s(?NO)
	++ " group by shop";

sale(new_by_retailer, Merchant, Conditions) ->
    ?DEBUG("new_by_retailer with merchant ~p, conditions ~p",
	   [Merchant, Conditions]), 
    %% 0: has_pay > 0 
    SortConditions = ?w_sale:sort_condition(
			wsale, Merchant, [{<<"has_pay">>, 0}|Conditions]),
    
    %% {StartTime, EndTime, NewConditions} = 
    %% 	?sql_utils:cut(fields_no_prifix, Conditions), 
    "select a.shop as shop_id"
	", a.employ as employee_id"
	", a.retailer as retailer_id"
	", sum(a.cash) as t_cash"
	", sum(a.card) as t_card"
	", sum(a.wire) as t_wire"
	", sum(a.verificate) as t_verificate"
	", SUM(a.has_pay) as t_hpay"
	" from w_sale a"
	++ " where " ++ SortConditions
	++ " and a.deleted=" ++ ?to_s(?NO)
	++ " group by a.retailer";

sale(new_by_good, Merchant, Conditions) ->
    ?DEBUG("new_by_good with merchant ~p, conditions ~p",
	   [Merchant, Conditions]),

    {DConditions, SConditions}
	= ?w_sale:filter_condition(wsale, Conditions, [], []),

    {_, _, CutDCondtions}
	= ?sql_utils:cut(fields_no_prifix, DConditions),
    {StartTime, EndTime, CutSConditions}
    	= ?sql_utils:cut(fields_no_prifix, SConditions),

    CorrectCutDConditions = ?utils:correct_condition(<<"a.">>, CutDCondtions),
    CorrectCutSConditions = ?utils:correct_condition(<<"b.">>, CutSConditions),

    "select a.id, a.rsn, a.style_number, a.brand as brand_id, d.name as brand"
	", sum(a.total) as t_sell"

	", b.shop as shop_id"
	", b.type as sell_type"
	", c.amount as t_stock"
	
	" from w_sale_detail a, w_sale b, w_inventory c, brands d"
	" where "
	++ ?sql_utils:condition(proplists_suffix, CorrectCutDConditions)
	++ "a.rsn=b.rsn"

	++ ?sql_utils:condition(proplists, CorrectCutSConditions)
    	++ " and b.merchant=" ++ ?to_s(Merchant)
    	++ " and " ++ ?sql_utils:condition(time_with_prfix, StartTime, EndTime) 
	++ " and a.style_number=c.style_number"
	++ " and a.brand=c.brand"
	++ " and b.merchant=c.merchant"
	++ " and b.shop=c.shop"
	++ " and a.brand=d.id"
	++ " group by a.style_number, a.brand, b.merchant, b.shop".

sale(new_by_shop_with_pagination,
     Merchant, Conditions, CurrentPage, ItemsPerPage) ->
    sale(new_by_shop, Merchant, Conditions)
	++ ?sql_utils:condition(page_desc, CurrentPage, ItemsPerPage);

sale(new_by_retailer_with_pagination,
     Merchant, Conditions, CurrentPage, ItemsPerPage) ->
    sale(new_by_retailer, Merchant, Conditions)
	++ ?sql_utils:condition(page_desc, CurrentPage, ItemsPerPage);

sale(new_by_good_with_pagination,
     Merchant, Conditions, CurrentPage, ItemsPerPage) ->
    sale(new_by_good, Merchant, Conditions)
	++ ?sql_utils:condition(page_desc, CurrentPage, ItemsPerPage).

