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

sale(new_by_employee, Merchant, Conditions) ->
    {StartTime, EndTime, NewConditions} = 
	?sql_utils:cut(fields_no_prifix, Conditions), 
    "select employ as employee_id"
	", SUM(total) as t_amount"
	", SUM(should_pay) as t_spay"
	", SUM(has_pay) as t_hpay"
	" from w_sale"
	++ " where " ++ ?utils:to_sqls(proplists, NewConditions)
	++ " and merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(time_no_prfix, StartTime, EndTime)
	++ " and deleted=" ++ ?to_s(?NO)
	++ " group by employ";

sale(new_by_retailer, Merchant, Conditions) ->
    {StartTime, EndTime, NewConditions} = 
	?sql_utils:cut(fields_no_prifix, Conditions), 
    "select retailer as retailer_id"
	", SUM(total) as t_amount"
	", SUM(should_pay) as t_spay"
	", SUM(has_pay) as t_hpay"
	" from w_sale"
	++ " where " ++ ?utils:to_sqls(proplists, NewConditions)
	++ " and merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(time_no_prfix, StartTime, EndTime)
	++ " and deleted=" ++ ?to_s(?NO)
	++ " group by retailer".

sale(new_by_shop_with_pagination, Merchant, Conditions, CurrentPage, ItemsPerPage) ->
    sale(new_by_shop, Merchant, Conditions)
	++ ?sql_utils:condition(page_desc, CurrentPage, ItemsPerPage);
sale(new_by_employee_with_pagination, Merchant, Conditions, CurrentPage, ItemsPerPage) ->
    sale(new_by_employee, Merchant, Conditions)
	++ ?sql_utils:condition(page_desc, CurrentPage, ItemsPerPage);
sale(new_by_retailer_with_pagination, Merchant, Conditions, CurrentPage, ItemsPerPage) ->
    sale(new_by_retailer, Merchant, Conditions)
	++ ?sql_utils:condition(page_desc, CurrentPage, ItemsPerPage).

