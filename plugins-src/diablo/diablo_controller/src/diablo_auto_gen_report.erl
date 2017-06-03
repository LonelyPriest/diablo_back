%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2016, buxianhui
%%% @doc
%%%
%%% @end
%%% Created :  5 Jul 2016 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_auto_gen_report).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_server).

%% API
-export([start_link/0]).
-export([lookup/1, report/2, cancel_report/1, task/3, add/3]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-export([syn_report/3, sys_vip_of/2]).

-export([gen_report/3]).

-define(SERVER, ?MODULE).

-record(state, {merchant :: [],
		task_of_per_shop :: []}).

%%%===================================================================
%%% API
%%%===================================================================
lookup(state) ->
    gen_server:call(?SERVER, lookup_state).

report(stastic_per_shop, TriggerTime) ->
    gen_server:cast(?SERVER, {stastic_per_shop, TriggerTime}). 
cancel_report(stastic_per_shop) ->
    gen_server:cast(?SERVER, cancel_stastic_per_shop). 
syn_report(stastic_per_shop, Merchant, Conditions) ->
    %% 30 minute
    gen_server:call(?SERVER, {syn_stastic_per_shop, Merchant, Conditions}, 60000 * 30).

add(report_task, Merchant, TriggerTime) ->
    gen_server:call(?SERVER, {add_report_task, Merchant, TriggerTime}).

%% triggerTime: {12, 13, am}
%% ticket(preferential, TriggerTime) ->
%%     gen_server:cast(?SERVER, {gen_ticket, TriggerTime}).
%% cancel_ticket(preferential) ->
%%     gen_server:cast(?SERVER, cancel_ticket).

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

init([]) ->
    Sql = "select id, name from merchants order by id", 
    case ?sql_utils:execute(read, Sql) of
	{ok, Merchants} ->
	    L = lists:foldr(
		  fun({Merchant}, Acc) ->
			  [?v(<<"id">>, Merchant)|Acc]
		  end, [], Merchants),
	    ?INFO("start cron task to genarate report ....~n", []),
	    {ok, #state{merchant=L, task_of_per_shop=[]}};
	{error, _Error} ->
	    {ok, #state{}}
    end.

handle_call({add_report_task, Merchant, TriggerTime},
	    _From, #state{merchant=Merchants, task_of_per_shop=Tasks} = State) ->
    case lists:member(Merchant, Merchants) of
	true -> {reply, ok, State};
	false ->
	    CronTask = {{daily, TriggerTime},
			fun(_Ref, Datetime) ->
				task(stastic_per_shop, Datetime, Merchant)
			end},
	    NewTask = ?cron:cron(CronTask),
	    {reply, ok, State#state{merchant=[Merchant|Merchants],
				    task_of_per_shop=[NewTask|Tasks]}}
    end;
    
handle_call(lookup_state, _From, #state{merchant=Merchants,
					task_of_per_shop=Tasks} = State) ->
    {reply, {Merchants, Tasks}, State};

handle_call({syn_stastic_per_shop, Merchant, Conditions}, _From, State) ->
    ?DEBUG("syn_stastic_per_shop: merchant ~p, conditions ~p", [Merchant, Conditions]),
    StartTime = ?v(<<"start_time">>, Conditions),
    EndTime = ?v(<<"end_time">>, Conditions),
    Shops = case ?v(<<"shop">>, Conditions) of
		undefined ->
		    {ok, AllShops} = ?w_user_profile:get(shop, Merchant),
		    lists:foldr(fun({Shop}, Acc) ->
					[?v(<<"id">>, Shop)|Acc]
				end, [], AllShops);
		_Shops ->
		    _Shops
	    end,

    StartDays = calendar:date_to_gregorian_days(?utils:to_date(datetime, StartTime)),
    EndDays = calendar:date_to_gregorian_days(?utils:to_date(datetime, EndTime)),

    ToListFun = fun(V) when is_list(V) -> V;
		   (V) -> [V]
		end,
    try 
	lists:foreach(
	  fun(Shop) ->
		  ok = syn_stastic_per_shop(Merchant, Shop, StartDays, EndDays)
	  end, ToListFun(Shops)),
	{reply, {ok, Merchant}, State}
    catch
	_:{badmatch, Error} -> {reply, Error, State}
    end;
    
handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

handle_cast({stastic_per_shop, TriggerTime},
	    #state{merchant=Merchants, task_of_per_shop=Tasks} = State) ->
    ?DEBUG("stastic_per_shop ~p, tasks ~p", [TriggerTime, Tasks]),
    case Tasks of
	[] -> 
	    NewTasks = 
		lists:foldr(
		  fun(M, Acc) ->
			  CronTask = {{daily, TriggerTime},
				      fun(_Ref, Datetime) ->
					      task(stastic_per_shop, Datetime, M)
				      end}, 
			  [?cron:cron(CronTask)|Acc] 
			  %% end, [], Merchants),
		  end, [], [3]),
	    ?DEBUG("new tasks ~p with merchants ~p", [NewTasks, Merchants]),
	    %% {noreply, #state{merchant=Merchants, task_of_per_shop=NewTasks}};
	    {noreply, State#state{task_of_per_shop=NewTasks}};
	_ -> {noreply, State}
    end;

handle_cast(cancel_stastic_per_shop, #state{task_of_per_shop=Tasks} = State) ->
    ?DEBUG("cancel_stastic_per_shop", []),
    lists:foreach(
      fun(Task) ->
	      ?cron:cancel(Task)
      end, Tasks),
    {noreply, State#state{task_of_per_shop=[]}};

handle_cast(_Msg, State) ->
    ?DEBUG("handle_cast receive unkown message ~p, State ~p", [_Msg, State]),
    {noreply, State}.

handle_info(_Info, State) ->
    %% ?DEBUG("handle_info receive unkown message ~p", [_Info]),
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

syn_stastic_per_shop(_Merchant, _Shop, StartDay, EndDay) when StartDay >= EndDay -> 
    ok;
syn_stastic_per_shop(Merchant, Shop, StartDay, EndDay) ->
    {BaseSetting, _} = ?wifi_print:detail(base_setting, Merchant, Shop),
    Date = calendar:gregorian_days_to_date(StartDay),
    {BeginOfDay, EndOfDay} = day(begin_to_end, Date),
    
    ?DEBUG("syn_stastic_per_shop: beginOfDay ~p, EndOfDay ~p", [BeginOfDay, EndOfDay]),

    Conditions = [{<<"shop">>, Shop},
		  {<<"start_time">>, ?to_b(BeginOfDay)},
		  {<<"end_time">>, ?to_b(EndOfDay)}],

    {ok, StockCalcTotal, StockCalcCost} =
	get_stock(calc, Merchant,
		  [{<<"shop">>, Shop},
		   {<<"start_time">>, ?v(<<"qtime_start">>, BaseSetting)},
		   {<<"end_time">>, ?to_b(EndOfDay)}
		  ]),

    %% {ok, LastStockInfo} = ?w_report:stastic(last_stock_of_shop, Merchant, Shop, BeginOfDay),
    %% LastStockTotal = stock(last_stock, LastStockInfo),

    {ok, SaleInfo} = ?w_report2:stastic(stock_sale, Merchant, Conditions),
    ?DEBUG("SaleInfo ~p", [SaleInfo]),
    {ok, SaleProfit} = ?w_report2:stastic(stock_profit, Merchant, Conditions),
    ?DEBUG("SaleProfit ~p", [SaleProfit]),

    {ok, StockIn}  = ?w_report2:stastic(stock_in, Merchant, Conditions),
    ?DEBUG("StockIn ~p", [StockIn]),
    {ok, StockOut} = ?w_report2:stastic(stock_out, Merchant, Conditions),
    ?DEBUG("StockOut ~p", [StockOut]),

    %% {ok, StockTransferIn} = ?w_report2:stastic(stock_transfer_in, Merchant, Conditions),
    %% {ok, StockTransferOut} = ?w_report2:stastic(stock_transfer_out, Merchant, Conditions),

    %% {ok, StockFix} = ?w_report2:stastic(stock_fix, Merchant, Conditions),

    {SellTotal, SellShouldPay, SellHasPay, SellCash, SellCard, SellWire, SellVeri}
	= sell(info, SaleInfo),
    {SellCost} = sell(cost, SaleProfit),

    %% {CurrentStockTotal, CurrentStockCost} = stock(current, StockR), 
    {StockInTotal, StockInCost} = stock(in, StockIn),
    {StockOutTotal, StockOutCost} = stock(out, StockOut),

    %% {StockTransferInTotal, StockTransferInCost}  = stock(t_in, StockTransferIn),
    %% {StockTransferOutTotal, StockTransferOutCost} = stock(t_out, StockTransferOut), 
    %% {StockFixTotal, StockFixCost} = stock(fix, StockFix),

    case SellTotal == 0
	andalso StockInTotal == 0
	andalso StockOutTotal == 0
	%% andalso StockTransferInTotal == 0
	%% andalso StockTransferOutTotal == 0
	%% andalso StockFixTotal == 0
    of
	true ->
	    syn_stastic_per_shop(Merchant, Shop, StartDay + 1, EndDay);
	false ->
	    Sql="select id, merchant, shop, day from w_daily_report"
		" where merchant=" ++ ?to_s(Merchant)
		++ " and shop=" ++ ?to_s(Shop)
		++ " and day=\'" ++ ?to_s(BeginOfDay) ++ "\'",

	    case ?sql_utils:execute(s_read, Sql) of
		{ok, []} ->		    
		    Sql1 =
			"insert into w_daily_report(merchant, shop"
			", sell, sell_cost, should_pay, has_pay"
			", cash, card, wire, veri"
			", stock, stockc, stock_cost"
			", stock_in, stock_out, stock_in_cost, stock_out_cost"
			", t_stock_in, t_stock_out, t_stock_in_cost, t_stock_out_cost"
			", stock_fix, stock_fix_cost"
			", day, entry_date) values(" 
			++ ?to_s(Merchant) ++ ","
			++ ?to_s(Shop) ++ ","

			++ ?to_s(SellTotal) ++ ","
			++ ?to_s(SellCost) ++ ","
			++ ?to_s(SellShouldPay) ++ ","
			++ ?to_s(SellHasPay) ++ ","
			++ ?to_s(SellCash) ++ ","
			++ ?to_s(SellCard) ++ ","
			++ ?to_s(SellWire) ++ ","
			++ ?to_s(SellVeri) ++ "," 

			++ ?to_s(0) ++ ","
			++ ?to_s(StockCalcTotal) ++ ","
			++ ?to_s(StockCalcCost) ++ ","

			++ ?to_s(StockInTotal) ++ ","
			++ ?to_s(StockOutTotal) ++ ","
			++ ?to_s(StockInCost) ++ ","
			++ ?to_s(StockOutCost) ++ ","

			%% ++ ?to_s(StockTransferInTotal) ++ ","
			%% ++ ?to_s(StockTransferOutTotal) ++ ","
			%% ++ ?to_s(StockTransferInCost) ++ ","
			%% ++ ?to_s(StockTransferOutCost) ++ ","

			%% ++ ?to_s(StockFixTotal) ++ ","
			%% ++ ?to_s(StockFixCost) ++ ","

		    %% transfer
			++ ?to_s(0) ++ ","
			++ ?to_s(0) ++ ","
			++ ?to_s(0) ++ ","
			++ ?to_s(0) ++ ","

		    %% fix
			++ ?to_s(0) ++ ","
			++ ?to_s(0) ++ ","

			++ "\'" ++ ?to_s(BeginOfDay) ++ "\',"
			++ "\'" ++ ?utils:current_time(format_localtime) ++ "\')",
		    {ok, _} = ?sql_utils:execute(insert, Sql1), 
		    syn_stastic_per_shop(Merchant, Shop, StartDay + 1, EndDay);
		{ok, R} ->
		    Updates = ?utils:v(sell, integer, SellTotal)
			++ ?utils:v(sell_cost, integer, SellCost)
			++ ?utils:v(should_pay, float, SellShouldPay)
			++ ?utils:v(has_pay, float, SellHasPay)
			++ ?utils:v(cash, float, SellCash)
			++ ?utils:v(card, float, SellCard)
			++ ?utils:v(wire, float, SellWire) 
			++ ?utils:v(veri, float, SellVeri) 
			
		    %% ++ ?utils:v(stock, integer, LastStockTotal) 
			++ ?utils:v(stockc, integer, StockCalcTotal)
			++ ?utils:v(stock_cost, float, StockCalcCost)
			
			++ ?utils:v(stock_in, integer, StockInTotal)
			++ ?utils:v(stock_out, integer, StockOutTotal)
			++ ?utils:v(stock_in_cost, float, StockInCost)
			++ ?utils:v(stock_out_cost, float, StockOutCost)

			%% ++ ?utils:v(t_stock_in, integer, StockTransferInTotal)
			%% ++ ?utils:v(t_stock_out, integer, StockTransferOutTotal)
			%% ++ ?utils:v(t_stock_in_cost, float, StockTransferInCost)
			%% ++ ?utils:v(t_stock_out_cost, float, StockTransferOutCost)

			%% ++ ?utils:v(stock_fix, integer, StockFixTotal)
			%% ++ ?utils:v(stock_fix_cost, float, StockFixCost)
			, 
		    Sql1 = "update w_daily_report set "
			++ ?utils:to_sqls(proplists, comma, Updates)
			++ " where id=" ++ ?to_s(?v(<<"id">>, R))
			++ " and merchant=" ++ ?to_s(Merchant),
		    {ok, _} = ?sql_utils:execute(write, Sql1, ?v(<<"id">>, R)),
		    syn_stastic_per_shop(Merchant, Shop, StartDay + 1, EndDay)
	    end
	    
    end.
	
task(stastic_per_shop, Datetime, Merchants) when is_list(Merchants)->
    {YestodayStart, YestodayEnd} = yestoday(Datetime),
    FormatDatetime = format_datetime(Datetime),

    SqlsOfAllMerchant=
	gen_report(stastic_per_shop,
		   {YestodayStart, YestodayEnd, FormatDatetime}, Merchants), 
    ?DEBUG("SqlsOfAllMerchant ~p", [SqlsOfAllMerchant]),
    
    lists:foreach(
      fun({_M, Sqls}) ->
	      lists:foreach(
		fun(Sql)->
			case ?sql_utils:execute(insert, Sql) of
			    {ok, _} -> ok;
			    {error, Error} ->
				?WARN("sql error to create daily report: ~p", [Error])
			end
		end, Sqls)
      end, SqlsOfAllMerchant);
task(stastic_per_shop, Datetime, Merchant) when is_number(Merchant)->
    task(stastic_per_shop, Datetime, [Merchant]).

gen_report(stastic_per_shop, Datetime, Merchants) ->
    gen_report(stastic_per_shop, Datetime, Merchants, []).
    
gen_report(stastic_per_shop, _Datetime, [], Acc) ->
    Acc;
gen_report(stastic_per_shop, {StartTime, EndTime, GenDatetime} , [M|Merchants], Acc) ->
    {ok, Shops} = ?w_user_profile:get(shop, M),
    %% ?DEBUG("merchant ~p with shops ~p",
    %% 	   [M, lists:foldr(fun({Shop}, Acc1)-> [?v(<<"id">>, Shop)|Acc1] end, [], Shops)]),
    {M, Sqls} = gen_shop_report({StartTime, EndTime, GenDatetime}, M, Shops, []),
    gen_report(stastic_per_shop, {StartTime, EndTime, GenDatetime} , Merchants, [{M, Sqls}|Acc]).

gen_shop_report(_Datetime, M, [], Sqls) ->
    ?DEBUG("merchant ~p gen sql ~p", [M, Sqls]),
    {M, Sqls};
gen_shop_report({StartTime, EndTime, GenDatetime}, M, [S|Shops], Sqls) ->
    %% ?DEBUG("gen_shop_report with merchant ~p, shop ~p, startTime ~p, endTime ~p, genTime ~p",
    %% 	   [M, S, StartTime, EndTime, GenDatetime]),
    ShopId  = ?v(<<"id">>, S),
    {BaseSetting, _} = ?wifi_print:detail(base_setting, M, ShopId), 
    IsShopDailyReport = ?v(<<"d_report">>, BaseSetting, 1),
    
    case ?to_i(IsShopDailyReport) of
	1 -> 
	    Conditions = [{<<"shop">>, ShopId},
			  {<<"start_time">>, ?to_b(StartTime)},
			  {<<"end_time">>, ?to_b(EndTime)}],

	    {ok, SaleInfo} = ?w_report2:stastic(stock_sale, M, Conditions),
	    {ok, SaleProfit} = ?w_report2:stastic(stock_profit, M, Conditions),

	    {ok, StockIn}  = ?w_report2:stastic(stock_in, M, Conditions),
	    {ok, StockOut} = ?w_report2:stastic(stock_out, M, Conditions),

	    %% {ok, StockTransferIn} = ?w_report2:stastic(stock_transfer_in, M, Conditions),
	    %% {ok, StockTransferOut} = ?w_report2:stastic(stock_transfer_out, M, Conditions),

	    %% {ok, StockFix} = ?w_report2:stastic(stock_fix, M, Conditions),

	    {ok, StockCalcTotal, StockCalcCost} =
		get_stock(calc, M,
			  [{<<"shop">>, ShopId},
			   {<<"start_time">>, ?v(<<"qtime_start">>, BaseSetting)},
			   {<<"end_time">>, ?to_b(EndTime)}
			  ]),
	    
	    {ok, StockR} = ?w_report2:stastic(
			      stock_real, M,
			      [{<<"shop">>, ShopId},
			       {<<"start_time">>, ?v(<<"qtime_start">>, BaseSetting)}
			      ]),

	    {SellTotal, SellShouldPay, SellHasPay, SellCash, SellCard, SellWire, SellVeri}
		= sell(info, SaleInfo),
	    {SellCost} = sell(cost, SaleProfit),

	    {CurrentStockTotal, _CurrentStockCost} = stock(current, StockR), 
	    {StockInTotal, StockInCost} = stock(in, StockIn),
	    {StockOutTotal, StockOutCost} = stock(out, StockOut),

	    %% {StockTransferInTotal, StockTransferInCost}  = stock(t_in, StockTransferIn),
	    %% {StockTransferOutTotal, StockTransferOutCost} = stock(t_out, StockTransferOut), 
	    %% {StockFixTotal, StockFixCost} = stock(fix, StockFix),

	    case SellTotal == 0
		andalso StockInTotal == 0
		andalso StockOutTotal == 0
		%% andalso StockTransferInTotal == 0
		%% andalso StockTransferOutTotal == 0
		%% andalso StockFixTotal == 0
	    of
		true ->
		    ?DEBUG("no input, no daily report", []),
		    gen_shop_report({StartTime, EndTime, GenDatetime}, M, Shops, Sqls);
		false ->
		    Sql0 = "select id, merchant, shop, day from w_daily_report"
			" where merchant=" ++ ?to_s(M)
			++ " and shop=" ++ ?to_s(ShopId)
			++ " and day=\'" ++ ?to_s(StartTime) ++ "\'", 
		    case ?sql_utils:execute(s_read, Sql0) of
			{ok, []} ->
			    Sql = 
				"insert into w_daily_report(merchant, shop"
				", sell, sell_cost, should_pay, has_pay"
				", cash, card, wire, veri"
				", stock, stockc, stock_cost"
				", stock_in, stock_out, stock_in_cost, stock_out_cost"
				", t_stock_in, t_stock_out, t_stock_in_cost, t_stock_out_cost"
				", stock_fix, stock_fix_cost"
				", day, entry_date) values("
				++ ?to_s(M) ++ ","
				++ ?to_s(ShopId) ++ ","

				++ ?to_s(SellTotal) ++ ","
				++ ?to_s(SellCost) ++ ","
				++ ?to_s(SellShouldPay) ++ ","
				++ ?to_s(SellHasPay) ++ ","
				++ ?to_s(SellCash) ++ ","
				++ ?to_s(SellCard) ++ ","
				++ ?to_s(SellWire) ++ ","
				++ ?to_s(SellVeri) ++ ","
				
				++ ?to_s(CurrentStockTotal) ++ ","
				++ ?to_s(StockCalcTotal) ++ ","
				++ ?to_s(StockCalcCost) ++ ","
			    %% ++ ?to_s(CurrentStockCost) ++ ","

				++ ?to_s(StockInTotal) ++ ","
				++ ?to_s(StockOutTotal) ++ ","
				++ ?to_s(StockInCost) ++ ","
				++ ?to_s(StockOutCost) ++ ","

				%% ++ ?to_s(StockTransferInTotal) ++ ","
				%% ++ ?to_s(StockTransferOutTotal) ++ ","
				%% ++ ?to_s(StockTransferInCost) ++ ","
				%% ++ ?to_s(StockTransferOutCost) ++ ","

				%% ++ ?to_s(StockFixTotal) ++ ","
				%% ++ ?to_s(StockFixCost) ++ ","

				%% transfer
				++ ?to_s(0) ++ ","
				++ ?to_s(0) ++ ","
				++ ?to_s(0) ++ ","
				++ ?to_s(0) ++ ","

				%% fix
				++ ?to_s(0) ++ ","
				++ ?to_s(0) ++ ","

				++ "\'" ++ StartTime ++ "\',"
				++ "\'" ++ GenDatetime ++ "\')", 
			    gen_shop_report({StartTime, EndTime, GenDatetime}, M, Shops, [Sql|Sqls]);
			{ok, R} ->
			    Updates = ?utils:v(sell, integer, SellTotal)
				++ ?utils:v(sell_cost, integer, SellCost)
				++ ?utils:v(should_pay, float, SellShouldPay)
				++ ?utils:v(has_pay, float, SellHasPay)
				++ ?utils:v(cash, float, SellCash)
				++ ?utils:v(card, float, SellCard)
				++ ?utils:v(wire, float, SellWire) 
				++ ?utils:v(veri, float, SellVeri)

				++ ?utils:v(stock, integer, CurrentStockTotal) 
				++ ?utils:v(stockc, integer, StockCalcTotal)
				++ ?utils:v(stock_cost, float, StockCalcCost)

				++ ?utils:v(stock_in, integer, StockInTotal)
				++ ?utils:v(stock_out, integer, StockOutTotal)
				++ ?utils:v(stock_in_cost, float, StockInCost)
				++ ?utils:v(stock_out_cost, float, StockOutCost)

				%% ++ ?utils:v(t_stock_in, integer, StockTransferInTotal)
				%% ++ ?utils:v(t_stock_out, integer, StockTransferOutTotal)
				%% ++ ?utils:v(t_stock_in_cost, float, StockTransferInCost)
				%% ++ ?utils:v(t_stock_out_cost, float, StockTransferOutCost)

				%% ++ ?utils:v(stock_fix, integer, StockFixTotal)
				%% ++ ?utils:v(stock_fix_cost, float, StockFixCost)
				,

			    Sql = "update w_daily_report set "
				++ ?utils:to_sqls(proplists, comma, Updates)
				++ " where id=" ++ ?to_s(?v(<<"id">>, R)),
			    gen_shop_report({StartTime, EndTime, GenDatetime}, M, Shops, [Sql|Sqls]);
			{error, _Error} ->
			    ?INFO("failed to gen daily report merchant ~p, shop ~p, date ~p",
				  [M, ShopId, GenDatetime]),
			    gen_shop_report({StartTime, EndTime, GenDatetime}, M, Shops, Sqls)
		    end
	    end;
	0 ->
	    %% ?DEBUG("daily report does not opend ~p", [S]),
	    gen_shop_report({StartTime, EndTime, GenDatetime}, M, Shops, Sqls)
    end.


get_stock(calc, Merchant, Conditions) ->
    {ok, SaleInfo} = ?w_report2:stastic(stock_sale, Merchant, Conditions),
    {ok, SaleProfit} = ?w_report2:stastic(stock_profit, Merchant, Conditions),
    {ok, StockIn}  = ?w_report2:stastic(stock_in, Merchant, Conditions),
    {ok, StockOut} = ?w_report2:stastic(stock_out, Merchant, Conditions),
    %% {ok, StockTransferIn} = ?w_report2:stastic(stock_transfer_in, Merchant, Conditions),
    %% {ok, StockTransferOut} = ?w_report2:stastic(stock_transfer_out, Merchant, Conditions),
    %% {ok, StockFix} = ?w_report2:stastic(stock_fix, Merchant, Conditions),

    {SellTotal, _SellShouldPay, _SellHasPay, _SellCash, _SellCard, _SellWire, _SellVeri}
	= sell(info, SaleInfo),
    {SellCost} = sell(cost, SaleProfit),

    {StockInTotal, StockInCost} = stock(in, StockIn),
    {StockOutTotal, StockOutCost} = stock(out, StockOut),

    %% {StockTransferInTotal, StockTransferInCost}  = stock(t_in, StockTransferIn),
    %% {StockTransferOutTotal, StockTransferOutCost} = stock(t_out, StockTransferOut), 
    %% {StockFixTotal, StockFixCost} = stock(fix, StockFix),

    StockCalcTotal = StockInTotal + StockOutTotal - SellTotal
	%% + StockTransferInTotal - StockTransferOutTotal
	%% + StockFixTotal
	,

    StockCalcCost = StockInCost + StockOutCost - SellCost
	%% + StockTransferInCost - StockTransferOutCost
	%% + StockFixCost
	,

    {ok, StockCalcTotal, StockCalcCost}.

format_datetime({{Year, Month, Day}, {Hour, Minute, Second}}) ->
    lists:flatten(
      io_lib:format("~4..0w-~2..0w-~2..0w ~2..0w:~2..0w:~2..0w",
		    [Year, Month, Day, Hour, Minute, Second])).


-spec yestoday/1 :: (calender:datetime()) -> calender:datetime(). 
yestoday(Datetime) ->
    SecondsOfYestoday = calendar:datetime_to_gregorian_seconds(Datetime) - ?ONE_DAY,
    {{Year, Month, Day}, _} = calendar:gregorian_seconds_to_datetime(SecondsOfYestoday),
    {Hour, Minute, Second} = calendar:seconds_to_time(86399),

    Start = 
	lists:flatten(
	  io_lib:format("~4..0w-~2..0w-~2..0w", [Year, Month, Day])),

    End = 
	lists:flatten(
	  io_lib:format("~4..0w-~2..0w-~2..0w ~2..0w:~2..0w:~2..0w",
			[Year, Month, Day, Hour, Minute, Second])),
    {Start, End}.


-spec day/2::(atom(), calendar:date()) -> tuple(). 
day(begin_to_end, {Year, Month, Day}) ->
    {Hour, Minute, Second} = calendar:seconds_to_time(86399),
    Start = 
	lists:flatten(
	  io_lib:format("~4..0w-~2..0w-~2..0w", [Year, Month, Day])),

    End = 
	lists:flatten(
	  io_lib:format("~4..0w-~2..0w-~2..0w ~2..0w:~2..0w:~2..0w",
			[Year, Month, Day, Hour, Minute, Second])),
    {Start, End}.
    


sell(info, [])->
    {0, 0, 0, 0, 0, 0, 0};
sell(info, [{SaleInfo}])->
    {?v(<<"total">>, SaleInfo, 0),
     ?v(<<"spay">>, SaleInfo, 0),
     ?v(<<"hpay">>, SaleInfo, 0),
     ?v(<<"cash">>, SaleInfo, 0),
     ?v(<<"card">>, SaleInfo, 0),
     ?v(<<"wire">>, SaleInfo, 0),
     ?v(<<"veri">>, SaleInfo, 0)
     %% ?v(<<"draw">>, SaleInfo, 0),
     %% ?v(<<"ticket">>, SaleInfo, 0)
    };

sell(cost, []) ->
    {0};
sell(cost, [{SaleProfit}]) ->
    {?v(<<"cost">>, SaleProfit)}.

stock(current, []) ->
    {0, 0};
stock(current, [{StockCurrent}]) ->
    {?v(<<"total">>, StockCurrent, 0),
     ?v(<<"cost">>, StockCurrent, 0)};

stock(last_stock, []) ->
    0;
stock(last_stock, [{StockInfo}]) ->
    ?v(<<"total">>, StockInfo, 0);

stock(in, []) ->
    {0, 0};
stock(in, [{StockIn}]) ->
    {?v(<<"total">>, StockIn, 0),
     ?v(<<"cost">>, StockIn, 0)};
stock(out, []) ->
    {0, 0};
stock(out, [{StockOut}]) ->
    {?v(<<"total">>, StockOut, 0),
     ?v(<<"cost">>, StockOut, 0)};

stock(t_in, []) ->
    {0, 0};
stock(t_in, [{StockTIn}]) ->
    {?v(<<"total">>, StockTIn, 0),
     ?v(<<"cost">>, StockTIn, 0)};
stock(t_out, []) ->
    {0, 0};
stock(t_out, [{StockTOut}]) ->
    {?v(<<"total">>, StockTOut, 0),
     ?v(<<"cost">>, StockTOut, 0)};

stock(fix, []) ->
    {0, 0};
stock(fix, [{StockFix}]) ->
    {?v(<<"total">>, StockFix, 0),
     ?v(<<"cost">>, StockFix, 0)}.


sys_vip_of(merchant, Merchant) ->
    {ok, Settings} = ?w_user_profile:get(setting, Merchant),
    SysVips =
	lists:foldr(
	  fun({S}, Acc) ->
		  case ?v(<<"ename">>, S) =:= <<"s_customer">> of
		      true ->
			  SysVip = ?to_i(?v(<<"value">>, S)),
			  %% ?DEBUG("sysvip ~p", [SysVip]),
			  case SysVip /= 0 andalso not lists:member(SysVip, Acc) of
			      true -> [SysVip] ++ Acc;
			      false -> Acc 
			  end;
		      false -> Acc
		  end
	  end, [], Settings),
    SysVips.
