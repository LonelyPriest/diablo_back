%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2015, buxianhui
%%% @desc: report
%%% Created : 23 Jul 2015 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_w_report).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_server).

%% API
-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

%% daily
-export([report/4, report/5]).

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
    Sql = ?sql_utils:count_table(w_sale, CountSql, Merchant, Conditions), 
    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};

handle_call({total, by_retailer, Merchant, Conditions}, _From, State) ->
    %% 0: has_pay > 0
    SortConditions = ?w_sale:sort_condition(
			wsale, Merchant, [{<<"has_pay">>, 0}|Conditions]),
    
    CountSql = "select count(distinct shop, merchant, retailer) as total"
    %% ", sum(total) as t_amount"
    %% ", sum(should_pay) as t_spay"
	", sum(cash) as t_cash"
	", sum(card) as t_card"
	", sum(wire) as t_wire"
	", sum(verificate) as t_verificate"
	", sum(has_pay) as t_hpay"
	" from w_sale a"
	" where " ++ SortConditions,
    %% Sql = ?sql_utils:count_table(w_sale, CountSql, Merchant, Conditions), 
    Reply = ?sql_utils:execute(s_read, CountSql),
    {reply, Reply, State};


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
	%% ", sum(c.amount) as t_stock"
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


handle_call({by_shop, Merchant, CurrentPage, ItemsPerPage, Conditions},
	    _From, State) ->
    Sql = ?w_report_sql:sale(
	     new_by_shop_with_pagination,
	     Merchant, Conditions, CurrentPage, ItemsPerPage),
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({by_retailer, Merchant, CurrentPage, ItemsPerPage, Conditions},
	    _From, State) ->
    Sql = ?w_report_sql:sale(
	     new_by_retailer_with_pagination,
	     Merchant, Conditions, CurrentPage, ItemsPerPage),
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({by_good, Merchant, CurrentPage, ItemsPerPage, Conditions},
	    _From, State) ->
    Sql = ?w_report_sql:sale(
	     new_by_good_with_pagination,
	     Merchant, Conditions, CurrentPage, ItemsPerPage),
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};
    
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

