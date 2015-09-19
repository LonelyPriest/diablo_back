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
report(total, by_employee, Merchant, Conditions) ->
    gen_server:call(?SERVER, {total, by_employee, Merchant, Conditions});
report(total, by_retailer, Merchant, Conditions) ->
    gen_server:call(?SERVER, {total, by_retailer, Merchant, Conditions}).

report(by_shop, Merchant, CurrentPage, ItemsPerPage, Conditions) ->
    gen_server:call(?SERVER, {by_shop, Merchant, CurrentPage, ItemsPerPage, Conditions});
report(by_employee, Merchant, CurrentPage, ItemsPerPage, Conditions) ->
    gen_server:call(?SERVER, {by_employee, Merchant, CurrentPage, ItemsPerPage, Conditions});
report(by_retailer, Merchant, CurrentPage, ItemsPerPage, Conditions) ->
    gen_server:call(?SERVER, {by_retailer, Merchant, CurrentPage, ItemsPerPage, Conditions}).


start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

init([]) ->
    {ok, #state{}}.

handle_call({total, by_shop, Merchant, Conditions}, _From, State) ->
    CountSql = "count(distinct shop) as total"
	", sum(total) as t_amount"
	", sum(should_pay) as t_spay"
	", sum(has_pay) as t_hpay",
    Sql = ?sql_utils:count_table(w_sale, CountSql, Merchant, Conditions), 
    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};

handle_call({total, by_employee, Merchant, Conditions}, _From, State) ->
    CountSql = "count(distinct employ) as total"
	", sum(total) as t_amount"
	", sum(should_pay) as t_spay"
	", sum(has_pay) as t_hpay",
    Sql = ?sql_utils:count_table(w_sale, CountSql, Merchant, Conditions), 
    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};

handle_call({total, by_retailer, Merchant, Conditions}, _From, State) ->
    CountSql = "count(distinct retailer) as total"
	", sum(total) as t_amount"
	", sum(should_pay) as t_spay"
	", sum(has_pay) as t_hpay",
    Sql = ?sql_utils:count_table(w_sale, CountSql, Merchant, Conditions), 
    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};

handle_call({by_shop, Merchant, CurrentPage, ItemsPerPage, Conditions}, _From, State) ->
    Sql = ?w_report_sql:sale(
	     new_by_shop_with_pagination, Merchant, Conditions, CurrentPage, ItemsPerPage),
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({by_employee, Merchant, CurrentPage, ItemsPerPage, Conditions}, _From, State) ->
    Sql = ?w_report_sql:sale(
	     new_by_employee_with_pagination, Merchant, Conditions, CurrentPage, ItemsPerPage),
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({by_retailer, Merchant, CurrentPage, ItemsPerPage, Conditions}, _From, State) ->
    Sql = ?w_report_sql:sale(
	     new_by_retailer_with_pagination, Merchant, Conditions, CurrentPage, ItemsPerPage),
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

