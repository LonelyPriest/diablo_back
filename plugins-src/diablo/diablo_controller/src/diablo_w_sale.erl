%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2015, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 11 Feb 2015 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_w_sale).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_server).

%% API
-export([start_link/1]).
-export([sale/3, sale/4]).
-export([rsn_detail/3]).
-export([filter/4, filter/6, export/3]).
-export([direct/1]).


%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).
-export([sort_condition/3, filter_condition/4]).

-define(SERVER, ?MODULE). 

-record(state, {}).

%%%===================================================================
%%% API
%%%===================================================================
sale(new, Merchant, Inventories, Props) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {new_sale, Merchant, Inventories, Props});
sale(update, Merchant, Inventories, Props) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {update_sale, Merchant, Inventories, Props});    
%% view the sale history of retailer
sale(history_retailer, Merchant, Retailer, Goods) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {history_retailer, Merchant, Retailer, Goods});
sale(reject, Merchant, Inventories, Props) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {reject_sale, Merchant, Inventories, Props}).

sale(check, Merchant, RSN) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {check_new, Merchant, RSN});
sale(list_new, Merchant, Condition) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {list_new, Merchant, Condition});
sale(get_new, Merchant, RSN) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {get_new, Merchant, RSN});
sale(last, Merchant, Condition) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {last_sale, Merchant, Condition});
sale(trans_detail, Merchant, Condition) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {trans_detail, Merchant, Condition});
sale(get_rsn, Merchant, Condition) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {get_sale_rsn, Merchant, Condition}).


%% rsn_group(rsn, Merchant) ->
%%     rsn_group(rsn, Merchant, []).
%% rsn_group(rsn, Merchant, RSN) ->
%%     gen_server:call(?SERVER, {rsn_group, Merchant, RSN}).
rsn_detail(rsn, Merchant, Condition) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {rsn_detail, Merchant, Condition}).


filter(total_news, 'and', Merchant, Fields) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {total_news, Merchant, Fields});
%% filter(total_rejects, 'and', Merchant, Fields) ->
%%     gen_server:call(?SERVER, {total_rejects, Merchant, Fields});
filter(total_rsn_group, 'and', Merchant, Fields) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {total_rsn_group, Merchant, Fields}).

filter(news, 'and', Merchant, CurrentPage, ItemsPerPage, Fields) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(
      Name, {filter_news, Merchant, CurrentPage, ItemsPerPage, Fields});
%% filter(rejects, 'and', Merchant, CurrentPage, ItemsPerPage, Fields) ->
%%     gen_server:call(
%%       ?SERVER, {filter_rejects, Merchant, CurrentPage, ItemsPerPage, Fields});
filter(rsn_group, 'and', Merchant, CurrentPage, ItemsPerPage, Fields) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(
      Name, {filter_rsn_group, Merchant, CurrentPage, ItemsPerPage, Fields}).

export(trans, Merchant, Condition) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {new_trans_export, Merchant, Condition});
export(trans_note, Merchant, Condition) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {new_trans_note_export, Merchant, Condition}).

start_link(Name) ->
    gen_server:start_link({local, Name}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

init([]) ->
    {ok, #state{}}.

handle_call({new_sale, Merchant, Inventories, Props}, _From, State) ->
    ?DEBUG("new_sale with merchant ~p~n~p, props ~p",
	   [Merchant, Inventories, Props]),

    Retailer   = ?v(<<"retailer">>, Props),
    Shop       = ?v(<<"shop">>, Props), 
    DateTime   = ?v(<<"datetime">>, Props, ?utils:current_time(localtime)),
    Employe    = ?v(<<"employee">>, Props),

    Balance    = ?v(<<"balance">>, Props, 0), 
    Cash       = ?v(<<"cash">>, Props, 0),
    Card       = ?v(<<"card">>, Props, 0),
    Wire       = ?v(<<"wire">>, Props, 0),
    VerifyPay  = ?v(<<"verificate">>, Props, 0),
    Comment    = ?v(<<"comment">>, Props, ""),
    %% Action     = ?v(<<"action">>, Props), 
    ShouldPay  = round(?v(<<"should_pay">>, Props, 0)),
    HasPay     = ?v(<<"has_pay">>, Props, 0),

    EPayType   = ?v(<<"e_pay_type">>, Props, -1),
    EPay       = ?v(<<"e_pay">>, Props, 0),

    Total      = ?v(<<"total">>, Props, 0),

    Sql0 = "select id, name, balance from w_retailer"
	" where id=" ++ ?to_s(Retailer)
	++ " and merchant=" ++ ?to_s(Merchant)
	++ " and deleted=" ++ ?to_s(?NO) ++ ";",

    case ?sql_utils:execute(s_read, Sql0) of 
	{ok, Account} -> 
	    SaleSn = lists:concat(
		       ["M-", ?to_i(Merchant),
			"-S-", ?to_i(Shop), "-",
			?inventory_sn:sn(w_sale_new_sn, Merchant)]),
	    RealyShop = realy_shop(Merchant, Shop),
	    Sql1 = 
		lists:foldr(
		  fun({struct, Inv}, Acc0)-> 
			  Amounts = ?v(<<"amounts">>, Inv), 
			  wsale(new, SaleSn, DateTime,
				Merchant, RealyShop, Inv, Amounts) ++ Acc0
		  end, [], Inventories), 

	    CurrentBalance = case ?v(<<"balance">>, Account) of
				 <<>> -> 0;
				 R -> R
			     end,

	    Sql2 = "insert into w_sale(rsn"
		", employ, retailer, shop, merchant, balance"
		", should_pay, has_pay, cash, card, wire"
		", verificate, total, comment, e_pay_type"
		", e_pay, type, entry_date) values("
		++ "\"" ++ ?to_s(SaleSn) ++ "\","
		++ "\"" ++ ?to_s(Employe) ++ "\","
		++ ?to_s(Retailer) ++ ","
		++ ?to_s(Shop) ++ ","
		++ ?to_s(Merchant) ++ ","
		++ case ?to_f(CurrentBalance) =:= ?to_f(Balance) of
		       true  -> ?to_s(Balance) ++ ",";
		       false -> ?to_s(CurrentBalance) ++ ","
		   end
		++ ?to_s(ShouldPay) ++ ","
		++ ?to_s(HasPay) ++ ","
		++ ?to_s(Cash) ++ ","
		++ ?to_s(Card) ++ ","
		++ ?to_s(Wire) ++ ","
		++ ?to_s(VerifyPay) ++ ","
		++ ?to_s(Total) ++ ","
		++ "\"" ++ ?to_s(Comment) ++ "\","
		++ ?to_s(EPayType) ++ ","
		++ ?to_s(EPay) ++ ","
		++ ?to_s(type(new)) ++ ","
		++ "\"" ++ ?to_s(DateTime) ++ "\");",

	    Sql3 = "update w_retailer set balance=balance+"
		++ ?to_s(?to_f(ShouldPay + EPay) -
			     ?to_f(Cash) - ?to_f(Card) - ?to_f(Wire) - ?to_f(VerifyPay))
		++ " where id=" ++ ?to_s(?v(<<"id">>, Account)),

	    AllSql = Sql1 ++ [Sql2] ++ [Sql3],
	    %% ?DEBUG("Sqls ~p", [AllSql]),
	    Reply = ?sql_utils:execute(transaction, AllSql, SaleSn),
	    %% ?w_user_profile:update(retailer, Merchant),
	    {reply, Reply, State};
	%% {reply, {ok, RSn}, State}
	%% case ?mysql:fetch(transaction, AllSql) of
	%% 	{error, Error} ->
	%% 	    ?DEBUG("failed to new good, error: ~p", [Error]),
	%% 	    {reply, {error, ?err(db_error, Error)}, State};
	%% 	{ok, _} ->
	%% 	    {reply, {ok, SaleSn}, State}
	%% end;
	Error ->
	    {reply, Error, State}
    end;


handle_call({update_sale, Merchant, Inventories, Props}, _From, State) ->
    ?DEBUG("update_sale with merchant ~p~n~p, props ~p",
	   [Merchant, Inventories, Props]),

    CurTime    = ?utils:current_time(localtime),

    RSNId      = ?v(<<"id">>, Props),
    RSN        = ?v(<<"rsn">>, Props),
    Retailer   = ?v(<<"retailer">>, Props),
    Shop       = ?v(<<"shop">>, Props), 
    Datetime   = ?v(<<"datetime">>, Props, CurTime),
    Employee   = ?v(<<"employee">>, Props),

    Balance    = ?v(<<"balance">>, Props), 
    Cash       = ?v(<<"cash">>, Props, 0),
    Card       = ?v(<<"card">>, Props, 0),
    Wire       = ?v(<<"wire">>, Props, 0),
    VerifyPay  = ?v(<<"verificate">>, Props, 0),
    EPay       = ?v(<<"e_pay">>, Props, 0),

    Comment    = ?v(<<"comment">>, Props),
    ShouldPay  = ?v(<<"should_pay">>, Props, 0),
    HasPay     = ?v(<<"has_pay">>, Props, 0),

    OldRetailer  = ?v(<<"old_retailer">>, Props),
    OldBalance   = ?v(<<"old_balance">>, Props),
    OldVerifyPay = ?v(<<"old_verify_pay">>, Props, 0),
    OldShouldPay = ?v(<<"old_should_pay">>, Props, 0),
    OldHasPay    = ?v(<<"old_has_pay">>, Props, 0),
    OldDatetime  = ?v(<<"old_datetime">>, Props),

    Total        = ?v(<<"total">>, Props),

    RealyShop    = realy_shop(Merchant, Shop),

    Sql1 = sql(update_wsale,
	       RSN, Merchant, RealyShop, Datetime, OldDatetime, Inventories),

    Updates = ?utils:v(employ, string, Employee)
	++ ?utils:v(retailer, integer, Retailer) 
	++ ?utils:v(shop, integer, Shop)
    %% ++ ?utils:v(balance, float, OldBalance)
	++ ?utils:v(should_pay, float, ShouldPay)
	++ ?utils:v(has_pay, float, HasPay)
	++ ?utils:v(cash, float, Cash)
	++ ?utils:v(card, float, Card)
	++ ?utils:v(wire, float, Wire)
	++ ?utils:v(verificate, float, VerifyPay)
	++ ?utils:v(total, integer, Total)
	++ ?utils:v(comment, string, Comment)
	++ case Datetime =:= OldDatetime of
	       true -> [];
	       false ->
		   ?utils:v(entry_date, string, Datetime)
	   end,

    case Retailer =:= OldRetailer of
	true ->
	    Sql2 = "update w_sale set "
		++ ?utils:to_sqls(
		      proplists, comma,
		      ?utils:v(balance, float, OldBalance) ++ Updates)
		++ " where rsn=" ++ "\'" ++ ?to_s(RSN) ++ "\'",

	    case  (ShouldPay - HasPay - VerifyPay)
		- (OldShouldPay - OldHasPay - OldVerifyPay) of
		0 ->
		    AllSql = Sql1 ++ [Sql2],
		    Reply = ?sql_utils:execute(transaction, AllSql, RSN),
		    {reply, Reply, State};
		Metric ->
		    ?DEBUG("Metric ~p", [Metric]),
		    AllSql = Sql1 ++ [Sql2] ++
			["update w_retailer set balance=balance+"
			 ++ ?to_s(Metric) 
			 ++ ", change_date=" ++ "\"" ++ ?to_s(CurTime) ++ "\""
			 ++ " where id=" ++ ?to_s(Retailer)
			 ++ " and merchant=" ++ ?to_s(Merchant),

			 "update w_sale set balance=balance+" ++ ?to_s(Metric)
			 ++ " where shop=" ++ ?to_s(Shop)
			 ++ " and merchant=" ++ ?to_s(Merchant)
			 ++ " and retailer=" ++ ?to_s(Retailer)
			 ++ " and id>" ++ ?to_s(RSNId)],

		    Reply = ?sql_utils:execute(transaction, AllSql, RSN),
		    ?w_user_profile:update(retailer, Merchant),
		    {reply, Reply, State}
	    end;
	false ->
	    Sql0 = "select id, rsn, retailer, shop, merchant, balance"
		", verificate, should_pay, has_pay, e_pay"
		" from w_sale"
		" where shop=" ++ ?to_s(Shop)
		++ " and merchant=" ++ ?to_s(Merchant)
		++ " and retailer=" ++ ?to_s(Retailer)
		++ " and id<" ++ ?to_s(RSNId)
		++ " order by id desc limit 1",

	    LastBalance = 
		case ?sql_utils:execute(s_read, Sql0) of
		    {ok, []} -> Balance;
		    {ok, R}  ->
			?v(<<"balance">>, R)
			    + ?v(<<"should_pay">>, R, 0)
			    + ?v(<<"e_pay">>, R, 0)
			    - ?v(<<"has_pay">>, R, 0)
			    - ?v(<<"verificate">>, R, 0)
		end,

	    Sql2 = 
		"update w_sale set "
		++ ?utils:to_sqls(
		      proplists, comma,
		      ?utils:v(balance, float, LastBalance) ++ Updates) 
		++ " where rsn=" ++ "\'" ++ ?to_s(RSN) ++ "\'"
		++ " and id=" ++ ?to_s(RSNId),

	    BackBalanceOfOldRetailer
		= OldShouldPay + EPay - OldVerifyPay - OldHasPay,
	    BalanceOfNewRetailer
		= ShouldPay + EPay - HasPay - VerifyPay,

	    AllSql = Sql1 ++ [Sql2] ++ 
		["update w_retailer set balance=balance-"
		 %% ++ ?to_s(OldShouldPay + EPay - OldHasPay)
		 ++ ?to_s(BackBalanceOfOldRetailer)
		 ++ " where id=" ++ ?to_s(OldRetailer),

		 "update w_retailer set balance=balance+"
		 %% ++ ?to_s(ShouldPay + EPay - HasPay)
		 ++ ?to_s(BalanceOfNewRetailer)
		 ++ " where id=" ++ ?to_s(Retailer),

		 "update w_sale set balance=balance-"
		 %% ++ ?to_s(OldShouldPay + EPay - OldHasPay)
		 ++ ?to_s(BackBalanceOfOldRetailer)
		 ++ " where shop=" ++ ?to_s(Shop)
		 ++ " and merchant=" ++ ?to_s(Merchant)
		 ++ " and retailer=" ++ ?to_s(OldRetailer)
		 ++ " and id>" ++ ?to_s(RSNId),

		 "update w_sale set balance=balance+"
		 %% ++ ?to_s(ShouldPay + EPay - HasPay)
		 ++ ?to_s(BalanceOfNewRetailer)
		 ++ " where shop=" ++ ?to_s(Shop)
		 ++ " and merchant=" ++ ?to_s(Merchant)
		 ++ " and retailer=" ++ ?to_s(Retailer)
		 ++ " and id>" ++ ?to_s(RSNId) 
		],

	    Reply = ?sql_utils:execute(transaction, AllSql, RSN),
	    ?w_user_profile:update(retailer, Merchant),

	    {reply, Reply, State}

    end; 

handle_call({check_new, Merchant, RSN}, _From, State) ->
    ?DEBUG("check_new with merchant ~p, RSN ~p", [Merchant, RSN]),
    Sql = "update w_sale set state=" ++ ?to_s(?CHECKED)
	++ ", check_date=\'" ++ ?utils:current_time(localtime) ++ "\'"
	++ " where rsn=\'" ++ ?to_s(RSN) ++ "\'"
	++ " and merchant=" ++ ?to_s(Merchant),

    Reply = ?sql_utils:execute(write, Sql, RSN),
    {reply, Reply, State};

handle_call({list_new, Merchant, Conditions}, _From, State) ->
    ?DEBUG("list_new with merchant ~p, condtions ~p", [Conditions, Merchant]),

    CorrectCondition = ?utils:correct_condition(<<"a.">>, Conditions),
    Sql = "select a.id, a.rsn, a.retailer as retailer_id, a.shop as shop_id"
	", a.balance, a.should_pay, a.has_pay, a.cash, a.card"
	", a.wire, a.verificate, a.total, a.comment, a.rdate, a.entry_date"
	", b.name as employee"
	", c.name as retailer"
	", d.name as shop"
	" from w_sale a"
	++ " left join employees b on a.employ=b.number"
	++ " and b.merchant=" ++ ?to_s(Merchant)
	++ " left join w_retailer c on a.retailer=c.id"
	++ " left join shops d on a.shop=d.id"
	++ " where a.merchant=" ++ ?to_s(Merchant)
	++ " and " ++ ?utils:to_sqls(proplists, CorrectCondition) ++ ";",
    {ok, Records} = ?mysql:fetch(read, Sql),
    {reply, ?to_tl(Records), State};

handle_call({get_new, Merchant, RSN}, _From, State) ->
    ?DEBUG("get_new with merchant ~p, rsn ~p", [Merchant, RSN]),
    Sql = "select id, rsn"
	", employ as employ_id, retailer as retailer_id, shop as shop_id"
	", balance, should_pay, has_pay, cash, card"
	", wire, verificate, total, comment, e_pay_type, e_pay, type, entry_date" 
	" from w_sale" 
	++ " where rsn=\'" ++ ?to_s(RSN) ++ "\'"
	++ " and merchant=" ++ ?to_s(Merchant), 
    Reply =  ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State}; 

handle_call({last_sale, Merchant, Conditions}, _From, State) ->
    ?DEBUG("last_sale with merchant ~p, condtions ~p", [Merchant, Conditions]),
    Retailer = ?v(<<"retailer">>, Conditions),
    Shop     = ?v(<<"shop">>, Conditions),
    C1 = [{<<"a.shop">>, Shop},
	  {<<"a.merchant">>, Merchant},
	  {<<"a.retailer">>, Retailer},
	  {<<"a.type">>, 0}],

    C2 = proplists:delete(<<"retailer">>,
			  proplists:delete(<<"shop">>, Conditions)),
    CorrectC2 = ?utils:correct_condition(<<"b.">>, C2),

    Sql = 
	"select a.rsn, b.id, b.rsn, b.style_number, b.sell_style"
	", b.fdiscount, b.fprice"
	" from w_sale a, w_sale_detail b"
	" where a.rsn=b.rsn" ++ ?sql_utils:condition(proplists, C1)
	++ " and " ++ ?utils:to_sqls(proplists, CorrectC2)
	++ " order by id desc limit 1",

    %% Sql = "select a.id, a.rsn, a.style_number, a.sell_style"
    %% 	", a.fdiscount, a.fprice"
    %% 	" from w_sale_detail a"
    %% 	" inner join "
    %% 	  "(select rsn from w_sale where " ++ ?utils:to_sqls(proplists, C1)
    %% 	++ ") b on a.rsn=b.rsn",
    %% 	%% " where a.rsn in"
    %% 	%% "(select rsn from w_sale where "
    %% 	%% ++ ?utils:to_sqls(proplists, C1) ++ ")"
    %% 	%% ++ ?sql_utils:condition(proplists, C2)
    %% 	++ " where " ++ ?utils:to_sqls(proplists, CorrectC2)
    %% 	++ " order by id desc limit 1",
    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};

handle_call({get_sale_rsn, Merchant, Conditions}, _From, State) ->
    ?DEBUG("get_sale_rsn with merchant=~p, conditions ~p", [Merchant, Conditions]),
    {DetailConditions, SaleConditions} = 
	filter_condition(wsale, Conditions ++ [{<<"merchant">>, Merchant}], [], []),
    ?DEBUG("sale conditions ~p, detail condition ~p", [SaleConditions, DetailConditions]), 

    {StartTime, EndTime, CutSaleConditions}
	= ?sql_utils:cut(fields_with_prifix, SaleConditions),
    %% CorrectDetailConditions = ?utils:correct_condition(<<"a.">>, DetailConditions),

    Sql1 = 
	"select a.rsn from w_sale a"
	" where "
	++ ?sql_utils:condition(proplists_suffix, CutSaleConditions)
	++ ?sql_utils:condition(time_with_prfix, StartTime, EndTime),
    %% ++ case {StartTime, EndTime} of
    %%        {undefined, undefined} -> ?utils:to_sqls(proplists, CutSaleConditions);
    %%        _ -> ?sql_utils:condition(proplists_suffix, CutSaleConditions)
    %%    end 
    %% ++ ?sql_utils:condition(time_no_prfix, StartTime, EndTime),
    Sql = 
	case ?v(<<"rsn">>, SaleConditions, []) of
	    [] ->
		case DetailConditions of
		    [] -> Sql1;
		    _ ->
			"select a.rsn from w_sale a "
			    "inner join (select rsn from w_sale_detail"
			    " where rsn like " ++ "\'M-" ++ ?to_s(Merchant) ++"%\'"
			    ++ ?sql_utils:condition(proplists, DetailConditions) ++ ") b"
			    " on a.rsn=b.rsn"
			    " where "
			    ++ ?sql_utils:condition(proplists_suffix, CutSaleConditions)
			    ++ ?sql_utils:condition(time_with_prfix, StartTime, EndTime) 
		end;
	    _ -> Sql1 
	end,

    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};


handle_call({history_retailer, Merchant, Retailer, Goods}, _From, State) ->
    ?DEBUG("history_retailer with merchant ~p, retailer ~p~n goods ~p",
	   [Merchant, Retailer, Goods]),
    [{S1, B1}|T] = Goods,

    Sql = "select style_number, brand"
	" from w_sale_detail where rsn in"
	"(select rsn from w_sale where retailer="++ ?to_s(Retailer) ++ ")" 
	++ " and (style_number, brand) in("
	++ lists:foldr(
	     fun({StyleNumber, Brand}, Acc)->
		     "(\'" ++ ?to_s(StyleNumber) ++ "\',"
			 ++ ?to_s(Brand) ++ ")," ++ Acc
	     end, [], T)
	++ "(\'" ++ ?to_s(S1) ++ "\'," ++ ?to_s(B1) ++ "))",

    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State}; 


handle_call({rsn_detail, Merchant, Conditions}, _From, State) ->
    ?DEBUG("rsn_detail with merchant ~p, Conditions ~p",
	   [Merchant, Conditions]),
    C = ?utils:to_sqls(proplists, Conditions),
    Sql = "select id, rsn, style_number, brand as brand_id, color as color_id"
	", size, total as amount"
	" from w_sale_detail_amount" 
	" where " ++ C,

    %% "select a.id, a.rsn, a.style_number"
    %% ", a.brand as brand_id, a.color as color_id, a.size, a.total as amount"
    %% ", b.type as type_id, b.s_group, b.free, b.season, b.firm as firm_id"
    %% ", b.hand, b.total, b.sell_style, b.fdiscount, b.fprice"
    %% ", c.name as color"
    %% " from "

    %% "(select id, rsn, style_number, brand, color, size, total"
    %% " from w_sale_detail_amount"
    %% " where " ++ C ++ ") a"

    %% " left join "
    %% "(select rsn, style_number, brand, type"
    %% ", s_group, free, season, firm, hand, total, sell_style"
    %% ", fdiscount, fprice, path, entry_date"
    %% " from w_sale_detail"
    %% " where " ++ C ++ ") b"
    %% " on a.style_number=b.style_number and a.brand=b.brand"

    %% " left join colors c on a.color=c.id",
    %% "(select id, name from colors where merchant="
    %% ++ ?to_s(Merchant) ++ ") c on a.color=c.id",

    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({trans_detail, Merchant, Conditions}, _From, State) ->
    ?DEBUG("trans_detail with merchant ~p, Conditions ~p", [Merchant, Conditions]),
    Sql =
	" select a.id, a.rsn, a.style_number, a.brand_id, a.type_id"
	", a.s_group, a.free, a.season, a.firm_id, a.hand, a.total"
	", a.sell_style, a.fdiscount, a.fprice, a.path"

	", b.color as color_id, b.size, b.total as amount"
	" from "

	"(select id, rsn, style_number, brand as brand_id, type as type_id"
	", s_group, free, season, firm as firm_id, hand, total, sell_style"
	", fdiscount, fprice, path"
	" from w_sale_detail"
	" where " ++ ?utils:to_sqls(proplists, Conditions) ++ ") a"

	" inner join w_sale_detail_amount b on a.rsn=b.rsn"
	" and a.style_number=b.style_number"
	" and a.brand_id=b.brand",

    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};


%% =============================================================================
%% filter with pagination
%% =============================================================================
handle_call({total_news, Merchant, Fields}, _From, State) ->
    CountSql = count_table(w_sale, Merchant, Fields),
    Reply = ?sql_utils:execute(s_read, CountSql),
    {reply, Reply, State}; 

handle_call({filter_news, Merchant, CurrentPage, ItemsPerPage, Fields}, _From, State) ->
    ?DEBUG("filter_new_with_and: "
	   "currentPage ~p, ItemsPerpage ~p, Merchant ~p~n"
	   "fields ~p", [CurrentPage, ItemsPerPage, Merchant, Fields]),
    Sql = filter_table(w_sale_with_page, Merchant, CurrentPage, ItemsPerPage, Fields), 
    Reply =  ?sql_utils:execute(read, Sql),
    {reply, Reply, State}; 

%% =============================================================================
%% reject
%% =============================================================================
handle_call({reject_sale, Merchant, Inventories, Props}, _From, State) ->
    ?DEBUG("reject_sale with merchant ~p~n~p, props ~p",
	   [Merchant, Inventories, Props]),

    Retailer   = ?v(<<"retailer_id">>, Props),
    Shop       = ?v(<<"shop">>, Props), 
    DateTime   = ?v(<<"datetime">>, Props, ?utils:current_time(localtime)),
    Employe    = ?v(<<"employee">>, Props),

    Balance    = ?v(<<"balance">>, Props), 
    Comment    = ?v(<<"comment">>, Props, ""),
    ShouldPay  = ?v(<<"should_pay">>, Props, 0), 
    Total      = ?v(<<"total">>, Props, 0),

    EPayType   = ?v(<<"e_pay_type">>, Props, -1),
    EPay       = ?v(<<"e_pay">>, Props, 0),

    Sql0 = "select id, name, balance from w_retailer"
	" where id=" ++ ?to_s(Retailer)
	++ " and merchant=" ++ ?to_s(Merchant)
	++ " and deleted=" ++ ?to_s(?NO) ++ ";",

    case ?sql_utils:execute(s_read, Sql0) of 
	{ok, Account} -> 
	    Sn = lists:concat(["M-", ?to_i(Merchant),
			       "-S-", ?to_i(Shop), "-R-",
			       ?inventory_sn:sn(w_sale_reject_sn, Merchant)]),
	    {ShopType, RealyShop} = realy_shop(reject, Merchant, Shop),

	    Sql1 =
		case ShopType of
		    ?BAD_REPERTORY ->
			lists:foldr(
			  fun({struct, Inv}, Acc0)->
				  Amounts = ?v(<<"amounts">>, Inv),
				  wsale(reject_badrepo, Sn, DateTime,
					Merchant, {Shop, RealyShop}, Inv, Amounts) ++ Acc0
			  end, [], Inventories);
		    _ ->
			lists:foldr(
			  fun({struct, Inv}, Acc0)->
				  Amounts = ?v(<<"amounts">>, Inv),
				  wsale(reject, Sn, DateTime,
					Merchant, RealyShop, Inv, Amounts) ++ Acc0
			  end, [], Inventories)
		end,

	    CurrentBalance = ?v(<<"balance">>, Account),

	    Sql2 = "insert into w_sale(rsn"
		", employ, retailer, shop, merchant, balance"
		", should_pay, total, comment, e_pay_type"
		", e_pay, type, entry_date) values("
		++ "\"" ++ ?to_s(Sn) ++ "\","
		++ "\"" ++ ?to_s(Employe) ++ "\","
		++ ?to_s(Retailer) ++ ","
		++ ?to_s(Shop) ++ ","
		++ ?to_s(Merchant) ++ ","
		++ case ?to_f(CurrentBalance) =:= ?to_f(Balance) of
		       true -> ?to_s(Balance) ++ ",";
		       false -> ?to_s(CurrentBalance) ++ ","
		   end
		++ ?to_s(-ShouldPay) ++ "," 
		++ ?to_s(-Total) ++ ","
		++ "\"" ++ ?to_s(Comment) ++ "\","
		++ ?to_s(EPayType) ++ ","
		++ ?to_s(-EPay) ++ ","
		++ ?to_s(type(reject)) ++ ","
		++ "\"" ++ ?to_s(DateTime) ++ "\");",

	    Sql3 = "update w_retailer set balance=balance-"
		++ ?to_s(?to_f(ShouldPay + EPay))
		++ " where id=" ++ ?to_s(?v(<<"id">>, Account)),

	    AllSql = Sql1 ++ [Sql2] ++ [Sql3],

	    case ?sql_utils:execute(transaction, AllSql, Sn) of
		{error, _} = Error ->
		    {reply, Error, State};
		OK -> 
		    ?w_user_profile:update(retailer, Merchant),
		    {reply, OK, State}
	    end; 
	Error ->
	    {reply, Error, State}
    end;

%% handle_call({total_rejects, Merchant, Fields}, _From, State) -> 
%%     CountSql = count_table(w_sale, Merchant, Fields),
%%     Reply = ?sql_utils:execute(s_read, CountSql),
%%     {reply, Reply, State}; 

%% handle_call({filter_rejects, Merchant, CurrentPage, ItemsPerPage, Fields}, _From, State) ->
%%     ?DEBUG("filter_rejects_with_and: currentPage ~p, ItemsPerpage ~p, Merchant ~p~n"
%% 	   "fields ~p", [CurrentPage, ItemsPerPage, Merchant, Fields]), 

%%     Sql = filter_table(w_sale, reject, Merchant, CurrentPage, ItemsPerPage, Fields),
%%     Reply =  ?sql_utils:execute(read, Sql),
%%     {reply, Reply, State}; 


handle_call({total_rsn_group, Merchant, Conditions}, _From, State) -> 

    %% Sql = "select count(*) as total"
    %% 	", SUM(total) as t_amount"
    %% 	", SUM(fprice * fdiscount * total) as t_balance"
    %% 	" from w_sale_detail where " ++ ?utils:to_sqls(proplists, Conditions),
    
    {DConditions, SConditions} = filter_condition(wsale, Conditions, [], []),

    {StartTime, EndTime, CutSConditions}
    	= ?sql_utils:cut(fields_with_prifix, SConditions),
    
    {_, _, CutDCondtions}
    	= ?sql_utils:cut(fields_no_prifix, DConditions),

    %% ?DEBUG("CutDCondtions ~p", [CutDCondtions]),
    CorrectCutDConditions = ?utils:correct_condition(<<"b.">>, CutDCondtions),

    Sql = "select count(*) as total"
    	", SUM(b.total) as t_amount"
    	", SUM(b.fprice * b.fdiscount * b.total) as t_balance"
	
    	" from w_sale_detail b, w_sale a"

    	" where "
	++ ?sql_utils:condition(proplists_suffix, CorrectCutDConditions)
	++ "b.rsn=a.rsn"

    	++ ?sql_utils:condition(proplists, CutSConditions)
    	++ " and a.merchant=" ++ ?to_s(Merchant)
    	++ " and " ++ ?sql_utils:condition(time_with_prfix, StartTime, EndTime),
	
    %% Sql = "select count(*) as total"
    %% 	", SUM(total) as t_amount"
    %% 	", SUM(fprice * fdiscount * total) as t_balance"
    %% 	" from ("
    %% 	"select b.id, b.rsn, b.total, b.fprice, b.fdiscount"
    %% 	" from w_sale a, w_sale_detail b"
    %% 	" where a.rsn=b.rsn"
    %% 	++ ?sql_utils:condition(proplists, CutSConditions)
    %% 	++ " and a.merchant=" ++ ?to_s(Merchant)
    %% 	++ " and " ++ ?sql_utils:condition(time_with_prfix, StartTime, EndTime)
    %% 	++ ?sql_utils:condition(proplists, CorrectCutDConditions)
    %% 	++ ") c", 
    
    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State}; 

handle_call({filter_rsn_group, Merchant,
	     CurrentPage, ItemsPerPage, Conditions}, _From, State) ->
    ?DEBUG("filter_rsn_group_and: "
	   "currentPage ~p, ItemsPerpage ~p, Merchant ~p~n"
	   "", [CurrentPage, ItemsPerPage, Merchant]), 
    
    {DConditions, SConditions} = filter_condition(wsale, Conditions, [], []),

    {StartTime, EndTime, CutSConditions}
    	= ?sql_utils:cut(fields_with_prifix, SConditions),

    {_, _, CutDCondtions}
    	= ?sql_utils:cut(fields_no_prifix, DConditions),

    CorrectCutDConditions = ?utils:correct_condition(<<"b.">>, CutDCondtions),
    
    Sql = "select b.id, b.rsn, b.style_number"
	", b.brand as brand_id, b.type as type_id, b.firm as firm_id"
	", b.s_group, b.free, b.total, b.fdiscount"
	", b.fprice, b.path, b.comment, b.entry_date"
	
	", a.shop as shop_id"
	", a.retailer as retailer_id"
	", a.employ as employee_id"
	", a.type as sell_type"
	
    	" from w_sale_detail b, w_sale a"
	
    	" where "
	++ ?sql_utils:condition(proplists_suffix, CorrectCutDConditions)
	++ "b.rsn=a.rsn"
	
    	++ ?sql_utils:condition(proplists, CutSConditions)
    	++ " and a.merchant=" ++ ?to_s(Merchant)
    	++ " and " ++ ?sql_utils:condition(time_with_prfix, StartTime, EndTime)
    	++ ?sql_utils:condition(page_desc, CurrentPage, ItemsPerPage),
    	%% ++ ") a",
	
	%% " left join w_sale b on a.rsn=b.rsn", 
	
    %% CorrectCondition = ?utils:correct_condition(<<"a.">>, Conditions),
    %% Sql = "select a.id, a.rsn, a.style_number"
    %% 	", a.brand as brand_id, a.type as type_id, a.firm as firm_id"
    %% 	", a.s_group, a.free, a.total, a.fdiscount"
    %% 	", a.fprice, a.path, a.comment, a.entry_date"

    %% 	", b.shop as shop_id"
    %% 	", b.retailer as retailer_id"
    %% 	", b.employ as employee_id"
    %% 	", b.type as sell_type"
    %% 	" from w_sale_detail a, w_sale b"
    %% 	" where a.rsn=b.rsn" ++ ?sql_utils:condition(proplists, CorrectCondition)
    %% 	++ ?sql_utils:condition(page_desc, CurrentPage, ItemsPerPage), 

    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State}; 

handle_call({new_trans_export, Merchant, Conditions}, _From, State)->
    ?DEBUG("new_trans_export with merchant ~p, condition ~p", [Merchant, Conditions]),
    Sql = filter_table(w_sale, Merchant, Conditions),
    Reply =  ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({new_trans_note_export, Merchant, Conditions}, _From, State)->
    ?DEBUG("new_trans_note_export: merchant ~p\nConditions~p", [Merchant, Conditions]),
    CorrectCondition = ?utils:correct_condition(<<"a.">>, Conditions),

    Sql = "select a.id, a.rsn, a.style_number, a.brand_id, a.type_id, a.firm_id"
	", a.s_group, a.free, a.total, a.fdiscount, a.fprice"
	", a.path, a.comment, a.entry_date"
    %% ", a.color_id, a.size, a.total"
	", a.shop_id, a.retailer_id, a.employee_id, a.sell_type"

	", b.name as brand"
    %% ", c.name as color"
	", d.name as type"
	", e.name as firm"
	", f.name as shop"
	", g.name as retailer"
	", h.name as employee"

	" from ("

	"select a.id, a.rsn, a.style_number, a.brand as brand_id"
	", a.type as type_id, a.firm as firm_id"
	", a.s_group, a.free, a.total, a.fdiscount"
	", a.fprice, a.path, a.comment, a.entry_date"

	", b.shop as shop_id"
	", b.retailer as retailer_id"
	", b.employ as employee_id"
	", b.type as sell_type"

    %% ", c.color as color_id"
    %% ", c.size"
    %% ", c.total"

	" from w_sale_detail a"
	" inner join w_sale b on a.rsn=b.rsn" 
    %% " right join w_sale_detail_amount c on a.rsn=c.rsn"
    %% " and a.style_number=c.style_number and a.brand=c.brand"

	" where "
	++ ?utils:to_sqls(proplists, CorrectCondition) ++ " order by a.id desc) a"

	" left join brands b on a.brand_id=b.id"
    %% " left join colors c on a.color_id=c.id"
	" left join inv_types d  on a.type_id=d.id"
	" left join suppliers e on a.firm_id=e.id"

	" left join shops f on a.shop_id=f.id"
	" left join w_retailer g on a.retailer_id=g.id"
	" left join (select id, number, name from employees where merchant="
	++ ?to_s(Merchant) ++ ") h on a.employee_id=h.number",

    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.


handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    ?DEBUG("handle_info: info ~p", [_Info]),
    {noreply, State}.


terminate(_Reason, _State) ->
    ?DEBUG("terminate: reason ~p", [_Reason]),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================

sql(update_wsale, RSN, _Merchant, _Shop, Datetime, OldDatetime, []) ->
    case Datetime =:= OldDatetime of
	true -> [];
	false ->
	    ["update w_sale_detail set entry_date=\'"
	     ++ ?to_s(Datetime) ++ "\'"
	     ++ " where rsn=\'" ++ ?to_s(RSN) ++ "\'",
	     "update w_sale_detail_amount set entry_date=\'"
	     ++ ?to_s(Datetime) ++ "\'"
	     ++ " where rsn=\'" ++ ?to_s(RSN) ++ "\'"]
    end;
    
sql(update_wsale, RSN, Merchant, Shop, Datetime, _OldDatetime, Inventories) ->
    %% RSN      = ?v(<<"rsn">>, Props),
    %% Shop     = ?v(<<"shop">>, Props),
    %% DateTime = ?v(<<"datetime">>, Props, ?utils:current_time(localtime)),

    %% NewShop = realy_shop(Merchant, Shop), 
    lists:foldr(
      fun({struct, Inv}, Acc0)-> 
	      Operation   = ?v(<<"operation">>, Inv), 
	      case Operation of
		  <<"d">> ->
		      Amounts = ?v(<<"amount">>, Inv),
		      wsale(delete, RSN, Datetime, Merchant, Shop, Inv, Amounts) ++ Acc0; 
		  <<"a">> ->
		      Amounts = lists:reverse(?v(<<"amount">>, Inv)),
		      wsale(new, RSN, Datetime, Merchant, Shop, Inv, Amounts) ++ Acc0; 
		  <<"u">> -> 
		      wsale(update, RSN, Datetime, Merchant, Shop, Inv) ++ Acc0
	      end
      end, [], Inventories).
    

wsale(update, RSN, DateTime, Merchant, Shop, Inventory) -> 
    StyleNumber    = ?v(<<"style_number">>, Inventory),
    Brand          = ?v(<<"brand">>, Inventory),
    FPrice         = ?v(<<"fprice">>, Inventory),
    FDiscount      = ?v(<<"fdiscount">>, Inventory),
    ChangeAmounts  = ?v(<<"changed_amount">>, Inventory, []),

    Metric = fun()->
		     lists:foldl(
		       fun({struct, Attr}, Acc) ->
			       Count = ?v(<<"count">>, Attr),
			       case ?v(<<"operation">>, Attr) of
				   <<"d">> -> Acc - Count;
				   <<"a">> -> Acc + Count;
				   <<"u">> -> Acc + Count
			       end
		       end, 0, ChangeAmounts)
	     end(),
    
    C1 =
	fun(Color, Size) ->
		?utils:to_sqls(proplists,
			       [{<<"style_number">>, StyleNumber},
				{<<"brand">>, Brand},
				{<<"color">>, Color},
				{<<"size">>,  Size},
				{<<"shop">>,  Shop},
				{<<"merchant">>, Merchant}])
	end,

    C2 =
	fun(Color, Size) ->
		?utils:to_sqls(
		   proplists, [{<<"rsn">>, RSN},
			       {<<"style_number">>, StyleNumber},
			       {<<"brand">>, Brand},
			       {<<"color">>, Color},
			       {<<"size">>, Size}])
	end,
    

    Sql0 = 
	case Metric of
	    0 -> ["update w_sale_detail set fdiscount=" ++ ?to_s(FDiscount)
		  ++ ",fprice=" ++ ?to_s(FPrice)
		  ++ " where rsn=\"" ++ ?to_s(RSN) ++ "\""
		  ++ " and style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
		  ++ " and brand=" ++ ?to_s(Brand)];
	    Metric -> 
		["update w_inventory set amount=amount-" ++ ?to_s(Metric) 
		 ++ " where "
		 "style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
		 ++ " and brand=" ++ ?to_s(Brand)
		 ++ " and shop=" ++ ?to_s(Shop)
		 ++ " and merchant=" ++ ?to_s(Merchant),

		 "update w_sale_detail set total=total+" ++ ?to_s(Metric)
		 ++ ",fdiscount=" ++ ?to_s(FDiscount)
		 ++ ",fprice=" ++ ?to_s(FPrice)
		 ++ ",entry_date=\'" ++ ?to_s(DateTime) ++ "\'"
		 ++ " where rsn=\"" ++ ?to_s(RSN) ++ "\""
		 ++ " and style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
		 ++ " and brand=" ++ ?to_s(Brand)]
	end,

    ChangeFun =
	fun({struct, Attr}, Acc1) ->
		?DEBUG("Attr ~p", [Attr]),
		Color = ?v(<<"cid">>, Attr),
		Size  = ?v(<<"size">>, Attr),
		Count = ?v(<<"count">>, Attr),

		case ?v(<<"operation">>, Attr) of 
		    <<"a">> ->
			Sql01 = "select id, style_number, brand, color, size"
			    " from w_sale_detail_amount"
			    " where " ++ C2(Color, Size),

			["update w_inventory_amount set total=total-" ++ ?to_s(Count)
			 ++ " where " ++ C1(Color, Size),

			 case ?sql_utils:execute(s_read, Sql01) of
			     {ok, []} ->
				 "insert into w_sale_detail_amount(rsn"
				     ", style_number, brand, color, size, total, entry_date)"
				     " values("
				     ++ "\"" ++ ?to_s(RSN) ++ "\","
				     ++ "\"" ++ ?to_s(StyleNumber) ++ "\","
				     ++ ?to_s(Brand) ++ ","
				     ++ ?to_s(Color) ++ ","
				     ++ "\'" ++ ?to_s(Size)  ++ "\',"
				     ++ ?to_s(Count) ++ "," 
				     ++ "\"" ++ ?to_s(DateTime) ++ "\")";
			     {ok, _} ->
				 "update w_sale_detail_amount set total=total+"
				     ++ ?to_s(Count)
				     ++ " where " ++ C2(Color, Size);
			     {error, E00} ->
				 throw({db_error, E00})
			 end | Acc1];

		    <<"d">> -> 
			["update w_inventory_amount set total=total+"
			 ++ ?to_s(Count) ++ " where " ++ C1(Color, Size), 

			 "delete from w_sale_detail_amount"
			 " where " ++ C2(Color, Size)
			 | Acc1];
		    <<"u">> -> 
			["update w_inventory_amount set total=total-" ++ ?to_s(Count)
			 ++ " where " ++ C1(Color, Size),

			 " update w_sale_detail_amount"
			 " set total=total+" ++ ?to_s(Count)
			 ++ " where " ++ C2(Color, Size)|Acc1]
		end
	end,
    Sql0 ++ lists:foldr(ChangeFun, [], ChangeAmounts). 
    
wsale(delete, RSN, _DateTime, Merchant, Shop, Inventory, Amounts)
  when is_list(Amounts)->
    %% Shop       = ?v(<<"shop">>, Props),
    %% change repo    
    StyleNumber = ?v(<<"style_number">>, Inventory),
    Brand       = ?v(<<"brand">>, Inventory), 
    
    Metric = fun()->
		     lists:foldl(
		       fun({struct, Attr}, Acc) ->
			       ?v(<<"sell_count">>, Attr) + Acc
		       end, 0, Amounts)
	     end(),

    ["update w_inventory set amount=amount+" ++ ?to_s(Metric)
     ++ ",sell=sell+" ++ ?to_s(Metric) 
     ++ " where style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
     ++ " and brand=" ++ ?to_s(Brand)
     ++ " and shop=" ++ ?to_s(Shop)
     ++ " and merchant=" ++ ?to_s(Merchant),

     "delete from w_sale_detail"
     ++ " where rsn=\"" ++ ?to_s(RSN) ++ "\""
     ++ " and style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
     ++ " and brand=" ++ ?to_s(Brand)]
	++ 
        lists:foldr(
	  fun({struct, Attr}, Acc1)->
		  CId    = ?v(<<"cid">>, Attr),
		  Size   = ?v(<<"size">>, Attr),
		  Count  = ?v(<<"sell_count">>, Attr),
		  ["update w_inventory_amount set total=total+" ++ ?to_s(Count)
		   ++ " where style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
		   ++ " and brand=" ++ ?to_s(Brand) 
		   ++ " and color=" ++ ?to_s(CId)
		   ++ " and size=\'" ++ ?to_s(Size) ++ "\'"
		   ++ " and shop=" ++ ?to_s(Shop)
		   ++ " and merchant=" ++ ?to_s(Merchant),

		   "delete from w_sale_detail_amount"
		   " where rsn=\"" ++ ?to_s(RSN) ++ "\""
		   ++ " and style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
		   ++ " and brand=" ++ ?to_s(Brand)
		   ++ " and color=" ++ ?to_s(CId)
		   ++ " and size=\'" ++ ?to_s(Size) ++ "\'"
		   | Acc1]
	     end, [], Amounts);


wsale(reject_badrepo, RSN, DateTime, Merchant, {Shop, RealyShop}, Inventory, Amounts) -> 
    StyleNumber = ?v(<<"style_number">>, Inventory),
    Brand       = ?v(<<"brand">>, Inventory),
    Type        = ?v(<<"type">>, Inventory),
    Sex         = ?v(<<"sex">>, Inventory),
    Year        = ?v(<<"year">>, Inventory),
    AlarmDay    = ?v(<<"alarm_day">>, Inventory),
    
    OrgPrice    = ?v(<<"org_price">>, Inventory),
    PkgPrice    = ?v(<<"pkg_price">>, Inventory),
    TagPrice    = ?v(<<"tag_price">>, Inventory),
    P3          = ?v(<<"price3">>, Inventory),
    P4          = ?v(<<"price4">>, Inventory),
    P5          = ?v(<<"price5">>, Inventory),
    Discount    = ?v(<<"discount">>, Inventory),
    
    FDiscount   = ?v(<<"fdiscount">>, Inventory, 100), 
    FPrice      = ?v(<<"fprice">>, Inventory),
    Firm        = ?v(<<"firm">>, Inventory),
    Season      = ?v(<<"season">>, Inventory),
    SizeGroup   = ?v(<<"s_group">>, Inventory),
    Hand        = ?v(<<"hand">>, Inventory, 0),
    Total       = ?v(<<"sell_total">>, Inventory), 
    Free        = ?v(<<"free">>, Inventory),
    Path        = ?v(<<"path">>, Inventory, []),
    Comment     = ?v(<<"comment">>, Inventory, []),
    SellStyle   = ?v(<<"sell_style">>, Inventory, -1),

    C1 =
	fun() ->
		?utils:to_sqls(proplists,
			       [{<<"style_number">>, StyleNumber},
				{<<"brand">>, Brand}, 
				{<<"shop">>, Shop},
				{<<"merchant">>, Merchant}])
	end, 

    C2 =
	fun(Color, Size) ->
		?utils:to_sqls(
		   proplists, [{<<"rsn">>, RSN},
			       {<<"style_number">>, StyleNumber},
			       {<<"brand">>, Brand},
			       {<<"color">>, Color},
			       {<<"size">>, Size}])
	end,

    
    Sql0 = "select id, style_number, brand, shop from w_inventory"
	" where " ++ C1(), 

    Sql1 = 
	case ?sql_utils:execute(s_read, Sql0) of
	    {ok, []} ->
		["insert into w_inventory(rsn"
		 ", style_number, brand, type, sex, season, amount"
		 ", firm, s_group, free, year"
		 ", org_price, tag_price, pkg_price, price3"
		 ", price4, price5, discount, path, alarm_day"
		 ", shop, merchant, last_sell, change_date, entry_date)"
		 " values("
		 ++ "\"" ++ ?to_s(-1) ++ "\","
		 ++ "\"" ++ ?to_s(StyleNumber) ++ "\","
		 ++ ?to_s(Brand) ++ ","
		 ++ ?to_s(Type) ++ ","
		 ++ ?to_s(Sex) ++ ","
		 ++ ?to_s(Season) ++ ","
		 ++ ?to_s(Total) ++ ","
		 ++ ?to_s(Firm) ++ "," 
		 ++ "\"" ++ ?to_s(SizeGroup) ++ "\","
		 ++ ?to_s(Free) ++ ","
		 ++ ?to_s(Year) ++ ","
		 ++ ?to_s(OrgPrice) ++ ","
		 ++ ?to_s(TagPrice) ++ ","
		 ++ ?to_s(PkgPrice) ++ ","
		 ++ ?to_s(P3) ++ ","
		 ++ ?to_s(P4) ++ ","
		 ++ ?to_s(P5) ++ ","
		 ++ ?to_s(Discount) ++ ","
		 ++ "\"" ++ ?to_s(Path) ++ "\","
		 ++ ?to_s(AlarmDay) ++ ","
		 ++ ?to_s(Shop) ++ ","
		 ++ ?to_s(Merchant) ++ ","
		 ++ "\"" ++ ?to_s(DateTime) ++ "\","
		 ++ "\"" ++ ?to_s(DateTime) ++ "\","
		 ++ "\"" ++ ?to_s(DateTime) ++ "\")"]; 
	    {ok, R} ->
		?DEBUG("R ~p", [R]),
		["update w_inventory set"
		 " amount=amount+" ++ ?to_s(Total)
		 ++ ", change_date=" ++ "\"" ++ ?to_s(DateTime) ++ "\""
		 ++ ", entry_date=" ++ "\"" ++ ?to_s(DateTime) ++ "\""
		 ++ " where id=" ++ ?to_s(?v(<<"id">>, R))];
	    {error, Error} ->
		throw({db_error, Error})
	end, 


    Sql2 = ["update w_inventory set sell=sell-" ++ ?to_s(Total)
	    ++ " where style_number=\"" ++ ?to_s(StyleNumber) ++ "\""
	    ++ " and brand=" ++ ?to_s(Brand)
	    ++ " and shop=" ++ ?to_s(RealyShop)
	    ++ " and merchant=" ++ ?to_s(Merchant)],
    
    Sql00 = "select rsn, style_number, brand, type from w_sale_detail"
	" where rsn=\'" ++ ?to_s(RSN) ++ "\'"
	" and style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
	" and brand=" ++ ?to_s(Brand), 

    Sql3 = 
	case ?sql_utils:execute(s_read, Sql00) of
	    {ok, []} ->
		["insert into w_sale_detail("
		 "rsn, style_number, brand, type, s_group, free"
		 ", season, firm, year, hand, total, sell_style, fdiscount"
		 ", fprice, path, comment, entry_date)"
		 " values("
		 ++ "\"" ++ ?to_s(RSN) ++ "\","
		 ++ "\"" ++ ?to_s(StyleNumber) ++ "\","
		 ++ ?to_s(Brand) ++ "," 
		 ++ ?to_s(Type) ++ ","
		 ++ "\"" ++ ?to_s(SizeGroup) ++ "\","
		 ++ ?to_s(Free) ++ "," 
		 ++ ?to_s(Season) ++ ","
		 ++ ?to_s(Firm) ++ ","
		 ++ ?to_s(Year) ++ ","
		 ++ ?to_s(Hand) ++ ","
		 ++ ?to_s(-Total) ++ ","
		 ++ ?to_s(SellStyle) ++ ","
		 ++ ?to_s(FDiscount) ++ ","
		 ++ ?to_s(FPrice) ++ ","
		 ++ "\"" ++ ?to_s(Path) ++ "\","
		 ++ "\"" ++ ?to_s(Comment) ++ "\","
		 ++ "\"" ++ ?to_s(DateTime) ++ "\")"];
	    {ok, _} ->
		["update w_sale_detail set total=total-" ++ ?to_s(Total)
		 ++ " where rsn=\'" ++ ?to_s(RSN) ++ "\'"
		 ++ " and style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
		 ++ " and brand=" ++ ?to_s(Brand)];
	    {error, E00} ->
		throw({db_error, E00})
	end,

    Sql1 ++ Sql2 ++ Sql3
	++ 
	lists:foldr(
	  fun({struct, A}, Acc1)->
		  Color    = ?v(<<"cid">>, A),
		  Size     = ?v(<<"size">>, A), 
		  Count    = ?v(<<"reject_count">>, A), 

		  Sql01 =
		      "select id, style_number, brand, shop, merchant "
		      " from w_inventory_amount"
		      " where style_number=\"" ++ ?to_s(StyleNumber) ++ "\""
		      ++ " and brand=" ++ ?to_s(Brand)
		      ++ " and shop=" ++ ?to_s(Shop)
		      ++ " and merchant=" ++ ?to_s(Merchant)
		      ++ " and color=" ++ ?to_s(Color)
		      ++ " and size=" ++ "\"" ++ ?to_s(Size) ++ "\"",
		      

		  Sql02 =
		      "select rsn, style_number, brand, color, size"
		      " from w_sale_detail_amount"
		      " where " ++ C2(Color, Size),

		  [ case ?sql_utils:execute(s_read, Sql01) of
			{ok, []} ->
			    "insert into w_inventory_amount(rsn"
				", style_number, brand, color, size"
				", shop, merchant, total, entry_date)"
				" values("
				++ "\"" ++ ?to_s(-1) ++ "\","
				++ "\"" ++ ?to_s(StyleNumber) ++ "\","
				++ ?to_s(Brand) ++ ","
				++ ?to_s(Color) ++ ","
				++ "\'" ++ ?to_s(Size)  ++ "\',"
				++ ?to_s(Shop)  ++ ","
				++ ?to_s(Merchant) ++ ","
				++ ?to_s(Count) ++ "," 
				++ "\"" ++ ?to_s(DateTime) ++ "\")";
			{ok, R01} -> 
			    "update w_inventory_amount set"
				" total=total+" ++ ?to_s(Count) 
				++ ", entry_date=" ++ "\"" ++ ?to_s(DateTime) ++ "\""
				++ " where id=" ++ ?to_s(?v(<<"id">>, R01));
			{error, E01} ->
			    throw({db_error, E01})
		    end, 

		    case ?sql_utils:execute(s_read, Sql02) of
			{ok, []} ->
			    "insert into w_sale_detail_amount(rsn, style_number"
				", brand, color, size, total, entry_date) values("
				++ "\"" ++ ?to_s(RSN) ++ "\","
				++ "\"" ++ ?to_s(StyleNumber) ++ "\","
				++ ?to_s(Brand) ++ ","
				++ ?to_s(Color) ++ ","
				++ "\"" ++ ?to_s(Size) ++ "\","
				++ ?to_s(-Count) ++ ","
				++ "\"" ++ ?to_s(DateTime) ++ "\")";
			{ok, _} ->
			    "update w_sale_detail_amount set total=total-" ++ ?to_s(Count)
				++ ", entry_date=" ++ "\'" ++ ?to_s(DateTime) ++ "\'"
				++ " where " ++ C2(Color, Size);
			{error, E02} ->
			    throw({db_error, E02})
		    end|Acc1] 
	  end, [], Amounts);

wsale(Action, RSN, DateTime, Merchant, Shop, Inventory, Amounts) -> 
    StyleNumber = ?v(<<"style_number">>, Inventory),
    Brand       = ?v(<<"brand">>, Inventory),
    Type        = ?v(<<"type">>, Inventory),
    FDiscount   = ?v(<<"fdiscount">>, Inventory, 100), 
    FPrice      = ?v(<<"fprice">>, Inventory),
    Firm        = ?v(<<"firm">>, Inventory),
    Season      = ?v(<<"season">>, Inventory),
    Year        = ?v(<<"year">>, Inventory),
    SizeGroup   = ?v(<<"s_group">>, Inventory),
    Hand        = ?v(<<"hand">>, Inventory, 0),
    Total       = case Action of
		      new -> ?v(<<"sell_total">>, Inventory);
		      reject -> -?v(<<"sell_total">>, Inventory) 
		  end,
    Free        = ?v(<<"free">>, Inventory),
    Path        = ?v(<<"path">>, Inventory, []),
    Comment     = ?v(<<"comment">>, Inventory, []),
    SellStyle   = ?v(<<"sell_style">>, Inventory, -1),

    %% change repo
    %% NewShop = get_repo(Merchant, Shop),
    
    %% CurrentDate = ?v(<<"datetime">>, Props, ?utils:current_time(localtime)),
    C1 =
	fun() ->
		?utils:to_sqls(proplists,
			       [{<<"style_number">>, StyleNumber},
				{<<"brand">>, Brand}, 
				{<<"shop">>, Shop},
				{<<"merchant">>, Merchant}])
	end, 

    C2 =
	fun(Color, Size) ->
		?utils:to_sqls(
		   proplists, [{<<"rsn">>, RSN},
			       {<<"style_number">>, StyleNumber},
			       {<<"brand">>, Brand},
			       {<<"color">>, Color},
			       {<<"size">>, Size}])
	end,

    Sql00 = "select rsn, style_number, brand, type from w_sale_detail"
	" where rsn=\'" ++ ?to_s(RSN) ++ "\'"
	" and style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
	" and brand=" ++ ?to_s(Brand), 
    
    ["update w_inventory set amount=amount-" ++ ?to_s(Total)
     ++ ", sell=sell+" ++ ?to_s(Total) 
     ++ ", last_sell=" ++ "\'" ++ ?to_s(DateTime) ++ "\'"
     ++ " where " ++ C1(),

     case ?sql_utils:execute(s_read, Sql00) of
	 {ok, []} ->
	     "insert into w_sale_detail("
		 "rsn, style_number, brand, type, s_group, free"
		 ", season, firm, year, hand, total, sell_style, fdiscount"
		 ", fprice, path, comment, entry_date)"
		 " values("
		 ++ "\"" ++ ?to_s(RSN) ++ "\","
		 ++ "\"" ++ ?to_s(StyleNumber) ++ "\","
		 ++ ?to_s(Brand) ++ "," 
		 ++ ?to_s(Type) ++ ","
		 ++ "\"" ++ ?to_s(SizeGroup) ++ "\","
		 ++ ?to_s(Free) ++ "," 
		 ++ ?to_s(Season) ++ ","
		 ++ ?to_s(Firm) ++ ","
		 ++ ?to_s(Year) ++ ","
	     %% ++ ?to_s(Retailer) ++ ","
	     %% ++ "\"" ++ ?to_s(Employe) ++ "\","
		 ++ ?to_s(Hand) ++ ","
		 ++ ?to_s(Total) ++ ","
		 ++ ?to_s(SellStyle) ++ ","
		 ++ ?to_s(FDiscount) ++ ","
		 ++ ?to_s(FPrice) ++ ","
		 ++ "\"" ++ ?to_s(Path) ++ "\","
		 ++ "\"" ++ ?to_s(Comment) ++ "\","
	     %% ++ ?to_s(type(Action)) ++ ","
		 ++ "\"" ++ ?to_s(DateTime) ++ "\")";
	 {ok, _} ->
	     "update w_sale_detail set total=total+" ++ ?to_s(Total)
		 ++ " where rsn=\'" ++ ?to_s(RSN) ++ "\'"
		 ++ " and style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
		 ++ " and brand=" ++ ?to_s(Brand);
	 {error, E00} ->
	     throw({db_error, E00})
     end] ++
	
	lists:foldr(
	  fun({struct, A}, Acc1)->
		  Color    = ?v(<<"cid">>, A),
		  Size     = ?v(<<"size">>, A), 
		  Count =
		      case Action of
			  new -> ?v(<<"sell_count">>, A);
			  reject -> -?v(<<"reject_count">>, A)
		      end,

		  Sql01 =
		      "select rsn, style_number, brand, color, size"
		      " from w_sale_detail_amount"
		      " where " ++ C2(Color, Size),
		  
		  ["update w_inventory_amount set total=total-" ++ ?to_s(Count)
		   ++ " where style_number=\"" ++ ?to_s(StyleNumber) ++ "\""
		   ++ " and brand=" ++ ?to_s(Brand)
		   ++ " and color=" ++ ?to_s(Color)
		   ++ " and size=" ++ "\"" ++ ?to_s(Size) ++ "\""
		   ++ " and shop=" ++ ?to_s(Shop)
		   ++ " and merchant=" ++ ?to_s(Merchant),
		   
		   case ?sql_utils:execute(s_read, Sql01) of
		       {ok, []} ->
			   "insert into w_sale_detail_amount(rsn, style_number"
			       ", brand, color, size, total, entry_date) values("
			       ++ "\"" ++ ?to_s(RSN) ++ "\","
			       ++ "\"" ++ ?to_s(StyleNumber) ++ "\","
			       ++ ?to_s(Brand) ++ ","
			       ++ ?to_s(Color) ++ ","
			       ++ "\"" ++ ?to_s(Size) ++ "\","
			       ++ ?to_s(Count) ++ ","
			       ++ "\"" ++ ?to_s(DateTime) ++ "\")";
		       {ok, _} ->
			   "update w_sale_detail_amount set total=total+" ++ ?to_s(Count)
			       ++ ", entry_date=" ++ "\'" ++ ?to_s(DateTime) ++ "\'"
			       ++ " where " ++ C2(Color, Size);
		       {error, E01} ->
			   throw({db_error, E01})
		   end|Acc1] 
	  end, [], Amounts).

count_table(w_sale, Merchant, Conditions) -> 
    SortConditions = sort_condition(wsale, Merchant, Conditions),

    CountSql = "select count(*) as total"
    	", sum(a.total) as t_amount"
    	", sum(a.should_pay) as t_spay"
    	", sum(a.has_pay) as t_hpay"
    	", sum(a.cash) as t_cash"
    	", sum(a.card) as t_card"
    	", sum(a.wire) as t_wire"
    	", sum(a.verificate) as t_verificate"
	" from w_sale a where " ++ SortConditions,
    %% SubSql = "select a.rsn, a.total, a.should_pay, a.has_pay"
    %% 	", a.cash, a.card, a.wire, a.verificate"
    %% 	" from w_sale a"
    %% 	" where " ++ SortConditions, 
    
    %% CountSql = "select count(*) as total"
    %% 	", sum(total) as t_amount"
    %% 	", sum(should_pay) as t_spay"
    %% 	", sum(has_pay) as t_hpay"
    %% 	", sum(cash) as t_cash"
    %% 	", sum(card) as t_card"
    %% 	", sum(wire) as t_wire"
    %% 	", sum(verificate) as t_verificate from ("
    %% 	++  SubSql ++ ") b",
    CountSql.

filter_table(w_sale, Merchant, Conditions) ->
    SortConditions = sort_condition(wsale, Merchant, Conditions),

    Sql = "select a.id, a.rsn, a.employ as employee_id"
	", a.retailer as retailer_id, a.shop as shop_id"
	", a.balance, a.should_pay, a.has_pay, a.cash, a.card"
	", a.wire, a.verificate, a.total, a.comment, a.e_pay, a.type"
	", a.state, a.entry_date"
	", b.name as shop"
	", c.name as employee"
	", d.name as retailer"
	" from w_sale a"
	" left join shops b on a.shop=b.id"
	" left join (select id, number, name from employees where merchant="
	++ ?to_s(Merchant) ++ ") c on a.employ=c.number"
	" left join w_retailer d on a.retailer=d.id"
	" where " ++ SortConditions ++ " order by a.id desc",
    Sql.

filter_table(w_sale_with_page, Merchant, CurrentPage, ItemsPerPage, Conditions) -> 
    SortConditions = sort_condition(wsale, Merchant, Conditions),
    
    Sql = "select a.id, a.rsn, a.employ as employee_id"
    	", a.retailer as retailer_id, a.shop as shop_id"
    	", a.balance, a.should_pay, a.has_pay, a.cash, a.card"
    	", a.wire, a.verificate, a.total, a.comment, a.e_pay, a.type"
    	", a.state, a.entry_date"
    	" from w_sale a"
    	" where " ++ SortConditions
	++ ?sql_utils:condition(page_desc, CurrentPage, ItemsPerPage), 
    Sql.
    
type(new) -> 0;
type(reject) -> 1.

direct(0) -> wsale;
direct(1) -> wreject;
direct(_) -> wsale.


sort_condition(wsale, Merchant, Conditions) ->
    HasPay = ?v(<<"has_pay">>, Conditions, []),

    C = proplists:delete(<<"has_pay">>, Conditions),
    {StartTime, EndTime, NewConditions} = ?sql_utils:cut(fields_with_prifix, C),

    ?sql_utils:condition(proplists_suffix, NewConditions)
	++ "a.merchant=" ++ ?to_s(Merchant)
	%% 0: has_pay > 0, 1: has_pay < 0
	++ case HasPay of
	       [] -> [];
	       0 -> " and a.has_pay>0";
	       1 -> " and a.has_pay<0"
	   end
	++ case ?sql_utils:condition(time_with_prfix, StartTime, EndTime) of
	       [] -> [];
	       TimeSql -> " and " ++ TimeSql
	   end.

realy_shop(Merchant, ShopId) ->
    case ?w_user_profile:get(shop, Merchant, ShopId) of
	{ok, []} -> ShopId;
	{ok, [{ShopInfo}]} -> 
	    case ?v(<<"repo">>, ShopInfo) of
		-1 ->
		    ShopId;
		RepoId ->
		    RepoId 
	    end
    end.

realy_shop(reject, Merchant, ShopId) ->
    case ?w_user_profile:get(shop, Merchant, ShopId) of
	{ok, []} -> ShopId;
	{ok, [{ShopInfo}]} -> 
	    case ?v(<<"repo">>, ShopInfo) of
		-1 ->
		    {?SHOP, ShopId};
		RepoId ->
		    {?v(<<"type">>, ShopInfo), RepoId}
	    end
    end.
    

filter_condition(wsale, [], Acc1, Acc2) ->
    {lists:reverse(Acc1), lists:reverse(Acc2)};
filter_condition(wsale, [{<<"style_number">>,_} = S|T], Acc1, Acc2) ->
    filter_condition(wsale, T, [S|Acc1], Acc2);
filter_condition(wsale, [{<<"brand">>, _} = B|T], Acc1, Acc2) ->
    filter_condition(wsale, T, [B|Acc1], Acc2);
filter_condition(wsale, [{<<"firm">>, _} = F|T], Acc1, Acc2) ->
    filter_condition(wsale, T, [F|Acc1], Acc2);
filter_condition(wsale, [{<<"type">>, _} = OT|T], Acc1, Acc2) ->
    filter_condition(wsale, T, [OT|Acc1], Acc2);
filter_condition(wsale, [{<<"year">>, _} = OT|T], Acc1, Acc2) ->
    filter_condition(wsale, T, [OT|Acc1], Acc2);


filter_condition(wsale, [{<<"rsn">>, _} = R|T], Acc1, Acc2) ->
    filter_condition(wsale, T, Acc1, [R|Acc2]);
filter_condition(wsale, [{<<"start_time">>, _} = ST|T], Acc1, Acc2) ->
    filter_condition(wsale, T, Acc1, [ST|Acc2]);
filter_condition(wsale, [{<<"end_time">>, _} = SE|T], Acc1, Acc2) ->
    filter_condition(wsale, T, Acc1, [SE|Acc2]);
filter_condition(wsale, [{<<"shop">>, _} = S|T], Acc1, Acc2) ->
    filter_condition(wsale, T, Acc1, [S|Acc2]);
filter_condition(wsale, [{<<"sell_type">>, ST}|T], Acc1, Acc2) ->
    filter_condition(wsale, T, Acc1, [{<<"type">>, ST}|Acc2]);
filter_condition(wsale, [O|T], Acc1, Acc2) ->
    filter_condition(wsale, T, Acc1, [O|Acc2]).



    
