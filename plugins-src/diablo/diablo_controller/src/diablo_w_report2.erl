%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2015, buxianhui
%%% @desc: report
%%% Created : 23 Jul 2015 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_w_report2).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_server).

%% API
-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

%% daily
-export([report/4, report/5, stastic/3, stastic/4, stock/4]).
-export([daily_report/3, daily_report/5, month_report/3]).
-export([switch_shift_report/3, switch_shift_report/5]).

-define(SERVER, ?MODULE). 

-record(state, {}).

%%%===================================================================
%%% API
%%%===================================================================

report(total, by_shop, Merchant, Conditions) ->
    gen_server:call(?SERVER, {total, by_shop, Merchant, Conditions}); 
report(total, by_retailer, Merchant, Conditions) ->
    gen_server:call(?SERVER, {total, by_retailer, Merchant, Conditions});
report(total, by_good, Merchant, Conditions) ->
    gen_server:call(?SERVER, {total, by_good, Merchant, Conditions}).

report(by_shop, Merchant, CurrentPage, ItemsPerPage, Conditions) ->
    gen_server:call(
      ?SERVER, {by_shop, Merchant, CurrentPage, ItemsPerPage, Conditions}); 
report(by_retailer, Merchant, CurrentPage, ItemsPerPage, Conditions) ->
    gen_server:call(
      ?SERVER, {by_retailer, Merchant, CurrentPage, ItemsPerPage, Conditions});
report(by_good, Merchant, CurrentPage, ItemsPerPage, Conditions) ->
    gen_server:call(
      ?SERVER, {by_good, Merchant, CurrentPage, ItemsPerPage, Conditions}).

daily_report(total, Merchant, Conditions) ->
    gen_server:call(?SERVER, {total_of_daily, Merchant, Conditions}).
daily_report(detail, Merchant, CurrentPage, ItemsPerPage, Conditions) ->
    gen_server:call(
      ?SERVER, {detail_of_daily, Merchant, CurrentPage, ItemsPerPage, Conditions}).

month_report(by_shop, Merchant, Conditions) ->
    gen_server:call(?SERVER, {month_report_by_shop, Merchant, Conditions}).

switch_shift_report(total, Merchant, Conditions) ->
    gen_server:call(?SERVER, {total_of_shift, Merchant, Conditions}).
switch_shift_report(detail, Merchant, CurrentPage, ItemsPerPage, Conditions) ->
    gen_server:call(
      ?SERVER, {detail_of_shift, Merchant, CurrentPage, ItemsPerPage, Conditions}).

stastic(stock_sale_detail, Merchant, Conditions) ->
    gen_server:call(?SERVER, {stock_sale_detail, Merchant, Conditions});
stastic(stock_sale, Merchant, Conditions)->
    gen_server:call(?SERVER, {stock_sale, Merchant, Conditions});
stastic(stock_profit, Merchant, Conditions)->
    gen_server:call(?SERVER, {stock_profit, Merchant, Conditions});
stastic(stock_in, Merchant, Conditions)->
    gen_server:call(?SERVER, {stock_in, Merchant, Conditions});
stastic(stock_out, Merchant, Conditions)->
    gen_server:call(?SERVER, {stock_out, Merchant, Conditions});
stastic(stock_transfer_in, Merchant, Conditions)->
    gen_server:call(?SERVER, {stock_transfer_in, Merchant, Conditions});
stastic(stock_transfer_out, Merchant, Conditions)->
    gen_server:call(?SERVER, {stock_transfer_out, Merchant, Conditions});
stastic(stock_fix, Merchant, Conditions)->
    gen_server:call(?SERVER, {stock_fix, Merchant, Conditions});
stastic(stock_real, Merchant, Conditions) ->
    gen_server:call(?SERVER, {stock_real, Merchant, Conditions});
stastic(recharge, Merchant, Conditions) ->
    gen_server:call(?SERVER, {recharge, Merchant, Conditions}).


stastic(current_stock_of_shop, Merchant, ShopId, CurrentDay) when is_number(ShopId) ->
    gen_server:call(?SERVER, {current_stock_of_shop, Merchant, [ShopId], CurrentDay});
stastic(current_stock_of_shop, Merchant, ShopIds, CurrentDay)->
    gen_server:call(?SERVER, {current_stock_of_shop, Merchant, ShopIds, CurrentDay});

stastic(last_stock_of_shop, Merchant, ShopId, CurrentDay) when is_number(ShopId) ->
    gen_server:call(?SERVER, {last_stock_of_shop, Merchant, [ShopId], CurrentDay});
stastic(last_stock_of_shop, Merchant, ShopIds, CurrentDay)->
    gen_server:call(?SERVER, {last_stock_of_shop, Merchant, ShopIds, CurrentDay}).


stock(of_day, Merchant, ShopIds, Day) ->
    gen_server:call(?SERVER, {stock_of_day, Merchant, ShopIds, Day}).

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

init([]) ->
    {ok, #state{}}.

handle_call({total, by_shop, Merchant, Conditions}, _From, State) ->
    CountSql = "count(distinct shop, merchant) as total"
	", sum(total) as t_amount"
	", sum(should_pay) as t_spay"
	", sum(has_pay) as t_hpay"
	", sum(cash) as t_cash"
	", sum(card) as t_card"
	", sum(wire) as t_wire"
	", sum(verificate) as t_verificate",
	%% ", sum(withdraw) as t_withdraw"
	%% ", sum(ticket) as t_ticket",
    Sql = ?sql_utils:count_table(w_sale, CountSql, Merchant, Conditions), 
    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};

%% handle_call({total, by_retailer, Merchant, Conditions}, _From, State) ->
%%     SortConditions = ?w_sale:sort_condition(wsale, Merchant, Conditions), 
%%     CountSql = "select count(distinct shop, merchant, retailer) as total"
%% 	", sum(should_pay) as t_spay"
%% 	", sum(cash) as t_cash"
%% 	", sum(card) as t_card"
%% 	", sum(withdraw) as t_withdraw"
%% 	" from w_sale a"
%% 	" where " ++ SortConditions,
%%     Reply = ?sql_utils:execute(s_read, CountSql),
%%     {reply, Reply, State};

handle_call({total, by_good, Merchant, Conditions}, _From, State) ->
    {DConditions, SConditions}
	= ?w_sale:filter_condition(wsale, Conditions, [], []),

    {_, _, CutDCondtions}
	= ?sql_utils:cut(fields_no_prifix, DConditions),
    {StartTime, EndTime, CutSConditions}
    	= ?sql_utils:cut(fields_no_prifix, SConditions),

    CorrectCutDConditions = ?utils:correct_condition(<<"a.">>, CutDCondtions),
    CorrectCutSConditions = ?utils:correct_condition(<<"b.">>, CutSConditions),

    Sql =
	"select count(distinct a.style_number, a.brand, b.shop, b.merchant)"
	" as total"
	", sum(a.total) as t_sell"
	" from w_sale_detail a, w_sale b"
	" where "
	++ ?sql_utils:condition(proplists_suffix, CorrectCutDConditions)
	++ "a.rsn=b.rsn"

	++ ?sql_utils:condition(proplists, CorrectCutSConditions)
    	++ " and b.merchant=" ++ ?to_s(Merchant)
    	++ " and " ++ ?sql_utils:condition(time_with_prfix, StartTime, EndTime),
	%% ++ " and b.merchant=c.merchant"
	%% ++ " and b.shop=c.shop"
	
	%% ++ " and a.style_number=c.style_number"
	%% ++ " and a.brand=c.brand",
    
    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};

handle_call({total_of_daily, Merchant, Conditions}, _From, State) ->
    {StartTime, EndTime, NewConditions} = ?sql_utils:cut(fields_no_prifix, Conditions),

    Sql = "select count(*) as total"
	", sum(sell) as sell"
	", sum(sell_cost) as sell_cost"
	", sum(should_pay) as should_pay"
	", sum(has_pay) as has_pay"
	", sum(cash) as cash"
	", sum(card) as card"
	", sum(wire) as wire"
    %% ", sum(draw) as draw" 
    %% ", sum(ticket) as ticket" 
	", sum(veri) as veri"
	
    %% ", sum(stock) as stock"
    %% ", sum(stock_cost) as stockCost"
	
	", sum(stock_in) as stock_in"
	", sum(stock_in_cost) as stock_in_cost"
	", sum(stock_out) as stock_out"
	", sum(stock_out_cost) as stock_out_cost"

	", sum(t_stock_in) as tstock_in"
	", sum(t_stock_out) as tstock_out"
	", sum(t_stock_in_cost) as tstock_in_cost"
	", sum(t_stock_out_cost) as tstock_out_cost"

	", sum(stock_fix) as stock_fix"
	", sum(stock_fix_cost) as stock_fix_cost"
	" from w_daily_report"
	" where merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, NewConditions)
	++ " and " ++ ?w_report2_sql:day_condition(StartTime, EndTime),
	%% ++ case ?sql_utils:condition(time_no_prfix, StartTime, EndTime) of
	%%        [] -> [];
	%%        TimeSql ->
	%% 	   " and " ++ TimeSql
	%%    end,

    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};
    
handle_call({detail_of_daily, Merchant, CurrentPage, ItemsPerPage, Conditions},
	    _From, State) ->
    Sql = ?w_report2_sql:daily(
	     daily_with_pagination,
	     Merchant, Conditions, CurrentPage, ItemsPerPage),
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({stock_of_day, Merchant, ShopIds, Day}, _From, State) ->
    Sql = "select a.day, a.merchant, a.shop as shop_id, a.stockc, a.stock_cost"
    	" from w_daily_report a "
    	"inner join (select max(day) as day, merchant, shop from w_daily_report"
    	" where merchant=" ++ ?to_s(Merchant)
    	++ " and "++ ?utils:to_sqls(proplists, {<<"shop">>, ShopIds})
    	++ " and day<=\'"  ++ ?to_s(Day) ++ "\'"
    	++ " group by merchant, shop) b on "
	"a.merchant=b.merchant and a.shop=b.shop and a.day=b.day", 
    R = ?sql_utils:execute(read, Sql),
    {reply, R, State}; 

%% handle_call({total_of_shift, Merchant, Conditions}, _From, State) ->
%%     {StartTime, EndTime, NewConditions} = ?sql_utils:cut(fields_no_prifix, Conditions),

%%     Sql = "select count(*) as total"
%% 	", sum(total) as sell"
%% 	", sum(balance) as balance"
%% 	", sum(cash) as cash"
%% 	", sum(card) as card"
%% 	", sum(wxin) as wxin"

%% 	%% ", sum(stock_in) as stockIn"
%% 	%% ", sum(stock_out) as stockOut"
	
%% 	%% ", sum(t_stock_in) as tstockIn"
%% 	%% ", sum(t_stock_out) as tstockOut" 

%% 	%% ", sum(stock_fix) as stockFix"
	
%% 	" from w_change_shift"
%% 	" where merchant=" ++ ?to_s(Merchant)
%% 	++ ?sql_utils:condition(proplists, NewConditions) 
%% 	++ case ?sql_utils:condition(time_no_prfix, StartTime, EndTime) of
%% 	       [] -> [];
%% 	       TimeSql ->
%% 		   " and " ++ TimeSql
%% 	   end,

%%     Reply = ?sql_utils:execute(s_read, Sql),
%%     {reply, Reply, State};

%% handle_call({detail_of_shift, Merchant, CurrentPage, ItemsPerPage, Conditions},
%% 	    _From, State) ->
%%     Sql = ?w_report2_sql:shift(
%% 	     shift_with_pagination,
%% 	     Merchant, Conditions, CurrentPage, ItemsPerPage),
%%     Reply = ?sql_utils:execute(read, Sql),
%%     {reply, Reply, State};


handle_call({by_shop, Merchant, CurrentPage, ItemsPerPage, Conditions},
	    _From, State) ->
    Sql = ?w_report2_sql:sale(
	     new_by_shop_with_pagination,
	     Merchant, Conditions, CurrentPage, ItemsPerPage),
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({by_retailer, Merchant, CurrentPage, ItemsPerPage, Conditions},
	    _From, State) ->
    Sql = ?w_report2_sql:sale(
	     new_by_retailer_with_pagination,
	     Merchant, Conditions, CurrentPage, ItemsPerPage),
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({by_good, Merchant, CurrentPage, ItemsPerPage, Conditions},
	    _From, State) ->
    Sql = ?w_report2_sql:sale(
	     new_by_good_with_pagination,
	     Merchant, Conditions, CurrentPage, ItemsPerPage),
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({stock_sale_detail, Merchant, Conditions}, _From, State)->
    ?DEBUG("stock_sale_detail: merchant ~p, Conditions ~p", [Merchant, Conditions]),
    {StartTime, EndTime, NewConditions} = ?sql_utils:cut(non_prefix, Conditions),
    Sql = "select style_number, brand as brand_id, merchant, shop as shop_id, firm as firm_id"
	", sum(total) as total"
	" from w_sale_detail"
	" where merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, NewConditions)
	++ " and " ++ ?sql_utils:condition(time_no_prfix, StartTime, EndTime)
	++ " group by style_number, brand, merchant, shop",
    R = ?sql_utils:execute(read, Sql),
    {reply, R, State};
	
    
handle_call({stock_sale, Merchant, Conditions}, _From, State)->
    ?DEBUG("stock_sale: merchant ~p, Conditions ~p", [Merchant, Conditions]),
    {StartTime, EndTime, NewConditions} = ?sql_utils:cut(non_prefix, Conditions),
    
    Sql = "select SUM(total) as total"
	", SUM(should_pay) as spay"
	", SUM(has_pay) as hpay"
	
	", SUM(cash) as cash"
	", SUM(card) as card"
	", SUM(wire) as wire"
    %% ", SUM(withdraw) as draw"
    %% ", SUM(ticket) as ticket"
	", SUM(verificate) as veri" 
	", shop as shop_id"
	" from w_sale "
	" where merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, NewConditions)
	++ " and " ++ ?sql_utils:condition(time_no_prfix, StartTime, EndTime)
	++ " group by shop",

    R = ?sql_utils:execute(read, Sql),
    {reply, R, State};

handle_call({stock_profit, Merchant, Conditions}, _From, State)->
    {StartTime, EndTime, NewConditions} = ?sql_utils:cut(fields_no_prifix, Conditions),

    Sql = "select SUM(total) as total"
	", SUM(org_price * total) as cost"
	", SUM(fprice * fdiscount * total) as balance"
	", shop as shop_id"
	" from w_sale_detail "
	" where merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, NewConditions)
	++ " and " ++ ?sql_utils:condition(time_no_prfix, StartTime, EndTime)
	++ " group by shop",

    R = ?sql_utils:execute(read, Sql),
    {reply, R, State};

handle_call({stock_in, Merchant, Conditions}, _From, State)->
    {StartTime, EndTime, NewConditions} = ?sql_utils:cut(fields_no_prifix, Conditions),

    Sql = "select SUM(total) as total"
	", SUM(should_pay) as cost"
	", shop as shop_id"
	" from w_inventory_new"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and type=" ++ ?to_s(?NEW_INVENTORY)
	++ " and state in(0,1)"
	++ ?sql_utils:condition(proplists, NewConditions)
	++ " and " ++ ?sql_utils:condition(time_no_prfix, StartTime, EndTime)
	++ " group by shop",

    R = ?sql_utils:execute(read, Sql),
    {reply, R, State};

handle_call({stock_out, Merchant, Conditions}, _From, State)->
    {StartTime, EndTime, NewConditions} = ?sql_utils:cut(fields_no_prifix, Conditions),

    Sql = "select SUM(total) as total"
	", SUM(should_pay) as cost"
	", shop as shop_id"
	" from w_inventory_new "
	" where merchant=" ++ ?to_s(Merchant)
	++ " and type=" ++ ?to_s(?REJECT_INVENTORY)
	++ " and state in(0,1)"
	++ ?sql_utils:condition(proplists, NewConditions)
	++ " and " ++ ?sql_utils:condition(time_no_prfix, StartTime, EndTime)
	++ " group by shop",

    R = ?sql_utils:execute(read, Sql),
    {reply, R, State};

handle_call({stock_transfer_in, Merchant, Conditions}, _From, State)->
    {StartTime, EndTime, NewConditions} = ?sql_utils:cut(fields_no_prifix, Conditions),

    CutConditions = lists:foldr(
		      fun({<<"shop">>, V}, Acc) ->
			      [{<<"tshop">>, V}|Acc];
			 (C, Acc) ->
			      [C|Acc] 
		      end, [], NewConditions),
    
    Sql = "select SUM(total) as total"
	", SUM(cost) as cost"
	", tshop as tshop_id"
	" from w_inventory_transfer"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and state=1"
	++ ?sql_utils:condition(proplists, CutConditions)
	++ " and " ++ ?sql_utils:condition(time_no_prfix, StartTime, EndTime)
	++ " group by tshop",

    R = ?sql_utils:execute(read, Sql),
    {reply, R, State};

handle_call({stock_transfer_out, Merchant, Conditions}, _From, State)->
    {StartTime, EndTime, NewConditions} = ?sql_utils:cut(fields_no_prifix, Conditions),

    CutConditions = lists:foldr(
		      fun({<<"shop">>, V}, Acc) ->
			      [{<<"fshop">>, V}|Acc];
			 (C, Acc) ->
			      [C|Acc] 
		      end, [], NewConditions),
    
    Sql = "select SUM(total) as total"
	", SUM(cost) as cost"
	", fshop as fshop_id"
	
	" from w_inventory_transfer"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and state=1"
	++ ?sql_utils:condition(proplists, CutConditions)
	++ " and " ++ ?sql_utils:condition(time_no_prfix, StartTime, EndTime)
	++ " group by fshop",

    R = ?sql_utils:execute(read, Sql),
    {reply, R, State};

handle_call({stock_fix, Merchant, Conditions}, _From, State)->
    {StartTime, EndTime, NewConditions} = ?sql_utils:cut(fields_no_prifix, Conditions),

    Sql = "select SUM(metric) as total"
	", SUM(cost) as cost"
	", shop as shop_id"
	" from w_inventory_fix"
	" where merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, NewConditions)
	++ " and " ++ ?sql_utils:condition(time_no_prfix, StartTime, EndTime)
	++ " group by shop",

    R = ?sql_utils:execute(read, Sql),
    {reply, R, State};

handle_call({stock_real, Merchant, Conditions}, _From, State)->
    {StartTime, EndTime, NewConditions} = ?sql_utils:cut(fields_no_prifix, Conditions),

    Sql = "select SUM(amount) as total"
	", SUM(org_price * amount) as cost"
	", shop as shop_id"
	" from w_inventory"
	" where merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, NewConditions)
	++ " and " ++ ?sql_utils:condition(time_no_prfix, StartTime, EndTime)
	++ " group by shop",

    R = ?sql_utils:execute(read, Sql),
    {reply, R, State};

handle_call({last_stock_of_shop, Merchant, ShopIds, CurrentDay}, _From, State) ->

    Sql = "select a.id, a.day, a.merchant, a.shop as shop_id, stock as total"
    	" from w_daily_report a "
    	"inner join (select max(day) as day, merchant, shop from w_daily_report"
    	" where merchant=" ++ ?to_s(Merchant)
    	++ " and "++ ?utils:to_sqls(proplists, {<<"shop">>, ShopIds})
    	++ " and day<\'"  ++ ?to_s(CurrentDay) ++ "\'"
    	++ " group by merchant, shop) b on "
	"a.merchant=b.merchant and a.shop=b.shop and a.day=b.day", 
    R = ?sql_utils:execute(read, Sql),
    {reply, R, State};

handle_call({current_stock_of_shop, Merchant, ShopIds, CurrentDay}, _From, State) ->
    Sql = "select id, merchant, shop as shop_id, stock as total"
	" from w_daily_report "
	" where merchant=" ++ ?to_s(Merchant)
	++ " and "++ ?utils:to_sqls(proplists, {<<"shop">>, ShopIds})
	++ " and day='"  ++ ?to_s(CurrentDay) ++ "\'"
	++ " group by merchant, shop", 
    R = ?sql_utils:execute(read, Sql),
    {reply, R, State};

%% handle_call({recharge, Merchant, Conditions}, _From, State) ->
%%     {StartTime, EndTime, NewConditions} = ?sql_utils:cut(fields_no_prifix, Conditions),

%%     Sql = "select SUM(cbalance) as cbalance"
%% 	", sum(cash) as tcash"
%% 	", sum(card) as tcard"
%% 	", sum(wxin) as twxin"
%% 	", shop as shop_id"
%% 	" from w_charge_detail "
%% 	" where merchant=" ++ ?to_s(Merchant)
%% 	++ ?sql_utils:condition(proplists, NewConditions)
%% 	++ " and " ++ ?sql_utils:condition(time_no_prfix, StartTime, EndTime)
%% 	++ " group by shop",

%%     R = ?sql_utils:execute(read, Sql),
%%     {reply, R, State};

handle_call({month_report_by_shop, Merchant, Conditions}, _From, State) ->
    {StartTime, EndTime, NewConditions} = ?sql_utils:cut(fields_no_prifix, Conditions),

    Sql = "select merchant, shop as shop_id"
	", SUM(sell) as sell"
	", SUM(sell_cost) as sell_cost"
	", SUM(balance) as balance"
	", SUM(cash) as cash"
	", SUM(card) as card"
	", SUM(wire) as wire"
	", SUM(veri) as veri"
    %% ", SUM(draw) as draw"
    %% ", SUM(ticket) as ticket"
	
	", SUM(stock_in) as stock_in"
	", SUM(stock_out) as stock_out"
	", SUM(stock_in_cost) as stock_in_cost"
	", SUM(stock_out_cost) as stock_out_cost"

	", SUM(t_stock_in) as tstock_in"
	", SUM(t_stock_out) as tstock_out"
	", SUM(t_stock_in_cost) as tstock_in_cost"
	", SUM(t_stock_out_cost) as tstock_out_cost"

	", SUM(stock_fix) as stock_fix"
	", SUM(stock_fix_cost) as stock_fix_cost"

	" from w_daily_report"
	" where merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, NewConditions)
	++ " and " ++ ?w_report2_sql:day_condition(StartTime, EndTime)
	++ " group by merchant, shop",
    R = ?sql_utils:execute(read, Sql),
    {reply, R, State};
	

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================	
    
    
