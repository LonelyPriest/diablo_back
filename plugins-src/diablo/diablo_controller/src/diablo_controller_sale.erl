%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 17 Sep 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_controller_sale).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_server).

%% API
-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-export([payment/1, reject/1]).
-export([lookup/2, lookup/4, do_filter/3, do_filter/5]).

-define(SERVER, ?MODULE). 
-define(tbl_shop, "shops").


-record(state, {}).

%%%===================================================================
%%% API
%%%===================================================================
payment(Attrs) ->
    gen_server:call(?MODULE, {payment, Attrs}).

reject(Attrs) ->
    gen_server:call(?MODULE, {reject, Attrs}).

lookup(pagination, CurrentPage, CountPerPage, Condition) ->
    gen_server:call(
      ?MODULE, {lookup_pagination, CurrentPage, CountPerPage, Condition}).

lookup(total_with_pagination, Condition) ->
    gen_server:call(?MODULE, {total_with_pagination, Condition});

lookup(condition, Condition) ->
    gen_server:call(?MODULE, {lookup_with_condition, Condition});

lookup(reject, Condition) ->
    gen_server:call(?MODULE, {lookup_reject_with_condition, Condition}).

do_filter(total, 'and', Condition) ->
    gen_server:call(?MODULE, {total_with_pagination, Condition}).
do_filter(pagination, CurrentPage, CountPerPage, 'and', Condition) ->
    gen_server:call(?MODULE, {pagination_with_filter,
			      CurrentPage, CountPerPage, Condition}).


start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
init([]) ->
    {ok, #state{}}.

handle_call({payment, Attrs}, _From, State)->
    ?DEBUG("payment with attrs ~p", [Attrs]),
    Inventories = ?value(<<"inventories">>, Attrs),
    Member      = ?value(<<"member">>, Attrs, -1),
    Employ      = ?value(<<"employ">>, Attrs),
    Balance     = ?value(<<"total_price">>, Attrs),
    Shop        = ?value(<<"shop">>, Attrs, -1),
    Merchant    = ?value(<<"merchant">>, Attrs),

    %% first, modify inventory,
    %% then, add the score of the member if member
    %% last, add the sale record
    case sale(modify_inventory, Inventories) of
	{check_amount_error, Sn} ->
	    {reply, {error, ?err(failed_to_check_amount, Sn)}, State};
	{error, Error} ->
	    {reply, {error, ?err(failed_to_payment, Error)}, State};
	{ok, _} ->
	    RunningNo = lists:concat(["M-",  Merchant, "-S",
				      ?to_integer(Shop), "-",
				      ?inventory_sn:sn(running_no, Merchant)]),
	    case sale(record,
		      {Employ, Member, Merchant, Shop}, RunningNo, Inventories) of
		{error, Error} ->
		    {reply, {error, ?err(failed_to_record, Error)}, State};
		{ok, _} ->
		    case Member of
			-1   -> %% no member
			    {reply, {ok,
				     ?succ(sale, Employ), RunningNo}, State}; 
			Member ->
			    case sale(acc_score, Member, Balance) of
				{error, Error} ->
				    {reply,
				     {error,
				      ?err(failed_to_add_score, Error)}, State};
				{ok, _} ->
				    {reply,
				     {ok, ?succ(sale, Employ), RunningNo}, State}
			    end
		    end
	    end
    end;

handle_call({reject, Attrs}, _From, State) ->
    ?DEBUG("reject with attrs", [Attrs]),

    RunningNO   = ?value(<<"running_no">>, Attrs),
    StyleNumber = ?value(<<"style_number">>, Attrs),
    Sn          = ?value(<<"sn">>, Attrs),
    Employ      = ?value(<<"employ">>, Attrs),
    Member      = ?value(<<"member">>, Attrs, -1),
    Merchant    = ?value(<<"merchant">>, Attrs),
    Shop        = ?value(<<"shop">>, Attrs),
    Amount      = ?value(<<"amount">>, Attrs),
    
    %% add to inventory
    Sql1 = "update inventory_to_shop set amount "
	++ " = amount + " ++ ?to_string(Amount)
	++ " where sn=" ++ "\"" ++ ?to_string(Sn) ++ "\";",

    Sql2 = "insert into sale_reject("
	++ "running_no, sn, style_number, employ, member,"
	++ " merchant, shop, amount, reject_date) values("
	++ "\"" ++?to_string(RunningNO) ++ "\","
	++ "\"" ++ ?to_string(Sn) ++ "\","
	++ "\"" ++?to_string(StyleNumber) ++ "\","
	++ "\"" ++ ?to_string(Employ) ++ "\","
	++ "\"" ++ ?to_string(Member) ++ "\","
	++ ?to_string(Merchant) ++ ","
	++ ?to_string(Shop) ++ ","
	++ ?to_string(Amount) ++ ","
	++ "\"" ++ ?utils:current_time(localtime) ++ "\");",

    case ?mysql:fetch(transaction, [Sql1,Sql2]) of
	{error, Error} ->
	    {reply, Error, State};
	{ok, _} ->
	    {reply, {ok, RunningNO}, State}
    end;

handle_call({total_with_pagination, Condition}, _From, State) ->
    StartTime    = ?value(<<"start_time">>, Condition),
    EndTime      = ?value(<<"end_time">>, Condition),
    CutCondition = proplists:delete(<<"end_time">>,
				 proplists:delete(<<"start_time">>, Condition)),

    %% Sql = "select count(*) from sales a"
    %% 	++ " where " ++ ?utils:to_sqls(
    %% 			   proplists, CutCondition),
    Sql = sql(sale_count, CutCondition),

    Time0 = time_condition(StartTime, "a.sale_date", ge),
    Time1   = time_condition(EndTime, "a.sale_date", le),

    {ok, {Detail}} = ?mysql:fetch(read, Sql ++ Time0 ++ Time1),
    ?DEBUG("count(*) ~p", [Detail]),
    {reply, ?value(<<"count(*)">>, Detail), State};
    
handle_call({lookup_pagination, CurrentPage, CountPerPage, Condition},
	    _From, State) ->
    Sql = sql(sale_detail, Condition),
    %% add pagination
    Pagination
	= " limit " ++ ?to_string((CurrentPage-1)*CountPerPage) ++ ", "
	++ ?to_string(CountPerPage),
    
    SqlOfPagination = Sql ++ Pagination,
    ?DEBUG("sql of pagination ~ts", [SqlOfPagination]),
    {ok, Sales} = ?mysql:fetch(read, SqlOfPagination),
    {reply, {ok, Sales}, State};
    
handle_call({pagination_with_filter, CurrentPage, CountPerPage, Condition},
	   _From, State) ->
    StartTime    = ?value(<<"start_time">>, Condition),
    EndTime      = ?value(<<"end_time">>, Condition),
    CutCondition = proplists:delete(<<"end_time">>,
				    proplists:delete(<<"start_time">>, Condition)),
    
    Sql = sql(sale_detail, CutCondition),
    Time0   = time_condition(StartTime, "a.sale_date", ge),
    Time1   = time_condition(EndTime, "a.sale_date", le),

    %% add pagination
    Pagination
	= " limit " ++ ?to_string((CurrentPage-1)*CountPerPage) ++ ", "
	++ ?to_string(CountPerPage),


    {ok, Sales} = ?mysql:fetch(read, Sql ++ Time0 ++ Time1 ++ Pagination),
    {reply, {ok, ?to_tl(Sales)}, State};

handle_call({lookup_with_condition, Conditioin}, _From, State) ->
    Sql = sql(sale_detail, Conditioin),
    {ok, Sales} = ?mysql:fetch(read, Sql),
    {reply, {ok, Sales}, State};

handle_call({lookup_reject_with_condition, Conditioin}, _From, State) ->
    ?DEBUG("lookup_reject_with_condition condition~p", [Conditioin]),
    CorrectCondition = ?utils:correct_condition(<<"a.">>, Conditioin),
    Merchant = ?value(<<"merchant">>, Conditioin),
    Sql = "select a.id, a.running_no, a.sn, a.style_number"
	++ ", a.shop, a.amount, a.reject_date"
	++ ", g.name as employe"
	++ ", x.name as member"
	++ ", y.name as shop_name"
	++ ", z.plan_price, z.discount"
	++ ", z.sex, z.size, z.entry_date as year, z.season"
	++ ", c.name as brand"
	++ ", d.name as color"
	++ ", e.name as supplier"
	++ ", f.name as type"
	++ " from sale_reject a"
	++ " left join employees g on a.employ = g.number"
	++ " and g.merchant=" ++ ?to_string(Merchant)
	++ " left join members x on a.member = x.number"
	++ " and x.merchant=" ++ ?to_string(Merchant)
	++ " left join shops y on a.shop = y.id"
	%% ++ " left join inventory_service b on a.style_number=b.style_number"
	%% ++ " and b.merchant=" ++ ?to_string(Merchant)
	++ " left join inventory_to_shop z on a.sn=z.sn"
	++ " and z.merchant="++ ?to_string(Merchant)
	++ " left join brands c on z.brand = c.id"
	++ " left join colors d on z.color = d.id"
	++ " left join suppliers e on z.supplier = e.id"
	++ " left join inv_types f on z.type = f.id"
	++ " where a.deleted = " ++ ?to_string(?NO)
	++ " and " ++ ?utils:to_sqls(proplists, CorrectCondition) ++ ";",

    {ok, Sales} = ?mysql:fetch(read, Sql),
    {reply, {ok, Sales}, State};
    
	
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
sale(modify_inventory, Inventories) ->
    sale(modify_inventory, Inventories, []).

sale(modify_inventory, [], Sqls) ->
    ?mysql:fetch(transaction, Sqls);
sale(modify_inventory, [Inventory|T], Sqls) ->
    {struct, Record} = Inventory,
    Sn = ?value(<<"inventory">>, Record),
    Amount = ?value(<<"buy_amount">>, Record),
    case check_buy_amount(inventory, Record) of
	true ->
	    Sql1 = "update inventory_to_shop set amount "
		++ " = amount - " ++ ?to_string(Amount)
		++ " where sn=" ++ "\"" ++ ?to_string(Sn) ++ "\";",
	    sale(modify_inventory, T, [Sql1|Sqls]);
	{false, _ExistAmount} ->
	    {check_amount_error, Sn}
    end;

sale(acc_score, Member, Balance) ->
    ?member:exchange(money_to_score, {<<"number">>, Member}, Balance).

sale(record, {Employ, Member, Merchant, Shop}, RunningNo, Inventories) ->
    sale(record, {Employ, Member, Merchant, Shop}, RunningNo, Inventories, []).

sale(record, {_Employ, _Mmember, _Merchant, _Shop}, _RunningNo, [], Sqls) ->
    ?mysql:fetch(transaction, Sqls);
sale(record, {Employ, Member, Merchant, Shop}, RunningNo, [Inventory|T], Sqls) ->
    {struct, Record} = Inventory,
    Sn          = ?value(<<"inventory">>, Record),
    StyleNumber = ?value(<<"style_number">>, Record),
    Amount      = ?value(<<"buy_amount">>, Record),
    Sql = "insert into sales("
	++ "running_no, sn, style_number, employ"
	++ ", member, merchant, shop, amount, sale_date)"
	++ " values ("
	++ "\"" ++ ?to_string(RunningNo) ++ "\","
	++ "\"" ++ ?to_string(Sn) ++ "\","
	++ "\"" ++ ?to_string(StyleNumber) ++ "\","
	++ "\"" ++ ?to_string(Employ) ++ "\","
	++ "\"" ++ ?to_string(Member) ++ "\","
	++ ?to_string(Merchant) ++ "," 
	++ ?to_string(Shop) ++ ","
	++ ?to_string(Amount) ++ ","
	++ "\"" ++ ?utils:current_time(localtime) ++ "\");",
    sale(record, {Employ, Member, Merchant, Shop}, RunningNo, T, [Sql|Sqls]).

    
check_buy_amount(inventory, Inventory) ->
    Sn = ?value(<<"inventory">>, Inventory),
    BuyAmount = ?value(<<"buy_amount">>, Inventory),
    %% should non negative
    Sql = "select amount from inventory_to_shop "
	++ "where sn="++ "\"" ++ ?to_string(Sn) ++ "\";",
    {ok, {Amount}} = ?mysql:fetch(read, Sql),
    ?DEBUG("check amount of sn ~p, amount ~p, buyAmount ~p",
	   [Sn, Amount, BuyAmount]),
    
    case  ?value(<<"amount">>, Amount) - BuyAmount >= 0 of
	true ->
	    true;
	false ->
	    ?DEBUG("failed to check amount, amount ~p, buyAmount ~p",
		   [Amount, BuyAmount]),
	    {false, ?value(<<"amount">>, Amount)}
    end.

sql(sale_count, Condition) ->
    Merchant = ?value(<<"merchant">>, Condition),
    Brand    = ?value(<<"brand">>, Condition),
    Color    = ?value(<<"color">>, Condition),
    Size     = ?value(<<"size">>, Condition),

    CutCondition = proplists:delete(
		     <<"color">>,
		     proplists:delete(
		       <<"brand">>,
		       proplists:delete(
			 <<"size">>, Condition))),
    
    CorrectCondition = ?utils:correct_condition (<<"a.">>, CutCondition),
    
    Sql = "select count(*)"
	++ " from sales a"
	++ " left join employees g on a.employ = g.number"
	++ " and g.merchant=" ++ ?to_string(Merchant)
	++ " left join members x on a.member = x.number"
	++ " and x.merchant=" ++ ?to_string(Merchant)
	++ " left join shops y on a.shop = y.id"
	++ " left join inventory_to_shop z on a.sn=z.sn"
	++ " and z.merchant=" ++ ?to_string(Merchant)
	++ " left join brands c on z.brand = c.id"
    %% ++ extra_jion_condition("z.brand", Brand)
	++ " left join colors d on z.color = d.id"
    %% ++ extra_jion_condition("z.color", Color)
    %% ++ " left join suppliers e on z.supplier = e.id"
    %% ++ " left join inv_types f on z.type = f.id"
	++ " where a.deleted = " ++ ?to_string(?NO)
	++ " and " ++ ?utils:to_sqls(proplists, CorrectCondition)
	++ extra_jion_condition("z.brand", Brand)
	++ extra_jion_condition("z.color", Color)
	++ extra_jion_condition("z.size", Size),
    Sql;

sql(sale_detail, Condition) ->
    Merchant = ?value(<<"merchant">>, Condition),
    Brand    = ?value(<<"brand">>, Condition),
    Color    = ?value(<<"color">>, Condition),
    Size     = ?value(<<"size">>, Condition),

    CutCondition = proplists:delete(
		     <<"color">>,
		     proplists:delete(
		       <<"brand">>,
		       proplists:delete(
			 <<"size">>, Condition))),
    
    CorrectCondition = ?utils:correct_condition(<<"a.">>, CutCondition),
    
    Sql = "select a.id, a.running_no, a.sn, a.style_number"
	++ ", a.shop, a.amount, a.sale_date"
	++ ", g.name as employe"
	++ ", x.name as member"
	++ ", y.name as shop_name"
	++ ", z.plan_price, z.discount"
	++ ", z.sex, z.size, z.season, z.entry_date as year"
	++ ", c.name as brand"
	++ ", d.name as color"
	++ ", e.name as supplier"
	++ ", f.name as type"
	++ " from sales a"
	++ " left join employees g on a.employ = g.number"
	++ " and g.merchant=" ++ ?to_string(Merchant)
	++ " left join members x on a.member = x.number"
	++ " and x.merchant=" ++ ?to_string(Merchant)
	++ " left join shops y on a.shop = y.id"
    %% ++ " left join inventory_service b on a.style_number=b.style_number"
    %% ++ " and b.merchant=" ++ ?to_string(Merchant)
	++ " left join inventory_to_shop z on a.sn=z.sn"
	++ " and z.merchant="++ ?to_string(Merchant)
	++ " left join brands c on z.brand = c.id"
    %% ++ extra_jion_condition("z.brand", Brand)
	++ " left join colors d on z.color = d.id"
    %% ++ extra_jion_condition("z.color", Color)
	++ " left join suppliers e on z.supplier = e.id"
	++ " left join inv_types f on z.type = f.id"
	++ " where a.deleted = " ++ ?to_string(?NO)
	++ " and " ++ ?utils:to_sqls(proplists, CorrectCondition)
	++ extra_jion_condition("z.brand", Brand)
	++ extra_jion_condition("z.color", Color)
	++ extra_jion_condition("z.size", Size),
    
    Sql.


time_condition(Time, TimeField, ge) ->
    case Time of
	undefined -> "";
	Time ->
	    " and " ++ ?to_s(TimeField) ++ ">=\"" ++ ?to_s(Time) ++ "\""
    end;
time_condition(Time, TimeField, le) ->
    case Time of
	undefined -> "";
	Time ->
	    " and " ++ ?to_s(TimeField) ++ "<=\"" ++ ?to_s(Time) ++ "\""
    end.

extra_jion_condition(Filed, Value) ->
    case Value of
	undefined -> "";
	Value when is_integer(Value) ->
	    " and " ++ Filed ++ "=" ++ ?to_s(Value);
	Value when is_binary(Value) ->
	    " and " ++ Filed ++ "=" ++ "\"" ++ ?to_s(Value) ++ "\""
    end.
	
