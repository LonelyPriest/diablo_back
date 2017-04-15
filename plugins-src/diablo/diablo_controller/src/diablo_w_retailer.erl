%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2015, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 10 Feb 2015 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_w_retailer).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_server).

%% API
-export([start_link/1]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-export([retailer/2, retailer/3, retailer/4]).
-export([province/2, city/2, city/4]).
-export([bill/3, print_trans/2, match/3]).

-define(SERVER, ?MODULE). 

-record(state, {}).



%%%===================================================================
%%% API
%%%===================================================================

retailer(list, Merchant) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {list_retailer, Merchant}).

retailer(new, Merchant, Attrs) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {new_retailer, Merchant, Attrs});
retailer(delete, Merchant, RetailerId) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {delete_retailer, Merchant, RetailerId});
retailer(get, Merchant, RetailerId) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {get_retailer, Merchant, RetailerId}).
    
retailer(update, Merchant, RetailerId, Attrs) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {update_retailer, Merchant, RetailerId, Attrs}).

city(new, Merchant, City, Province) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {new_city, City, Province}).
city(list, Merchant) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, list_city).
province(list, Merchant) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, list_province).
   
bill(check, Merchant, Attrs) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {bill_check, Merchant, Attrs}).

match(match, Merchant, Prompt) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {match, Merchant, Prompt}).

%% get(retailer, Merchant, RetailerId) ->
%%     Name = ?wpool:get(?MODULE, Merchant), 
%%     gen_server:call(Name, {get_retailer, Merchant, RetailerId}).

print_trans(Merchant, Attrs) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {print_trans, Merchant, Attrs}).

start_link(Name) ->
    gen_server:start_link({local, Name}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

init([]) ->
    {ok, #state{}}.

handle_call({new_retailer, Merchant, Attrs}, _From, State) ->
    ?DEBUG("new_retailer with attrs ~p", [Attrs]),
    Name     = ?v(<<"name">>, Attrs),
    Balance  = ?v(<<"balance">>, Attrs, 0),
    Mobile   = ?v(<<"mobile">>, Attrs, []),
    Address  = ?v(<<"address">>, Attrs, []),
    %% Merchant = ?v(<<"merchant">>, Attrs),
    Province = ?v(<<"province">>, Attrs, -1),
    City     = ?v(<<"city">>, Attrs, -1),

    %% name can not be same
    Sql = "select id, name, mobile, address"
	++ " from w_retailer" 
	++ " where name = " ++ "\"" ++ ?to_s(Name) ++ "\""
	++ " and merchant = " ++ ?to_s(Merchant) 
	++ " and deleted = " ++ ?to_s(?NO),
    %% ++ " and mobile = " ++ "\"" ++ ?to_s(Mobile) ++ "\";",

    case ?sql_utils:execute(read, Sql) of
	{ok, []} ->
	    %% Sql0 = "select id, name from city where name=\'"
	    %% 	++ ?to_s(Name) ++ "\'",
	    %% case ?sql_utils:execute(read, Sql) of
	    %% 	{ok, []} ->
	    %% 	    Sql1 = "insert into city(name, province) values ("
	    %% 		++ "\'" ++ ?to_s(Name) ++ "\',"
	    %% 		++ ?to_s(Province) ++ ")",
	    %% 	    case ?sql_utils:execute(insert, Sql1) of
	    %% 		{ok, CityId} -> 
	    Sql2 = "insert into w_retailer"
		++ "(name, balance, mobile, address"
		" ,province, city, merchant, entry_date)"
		++ " values ("
		++ "\"" ++ ?to_s(Name) ++ "\","
		++ ?to_s(Balance) ++ "," 
		++ "\"" ++ ?to_s(Mobile) ++ "\","
		++ "\"" ++ ?to_s(Address) ++ "\","
		++ ?to_s(Province) ++ ","
		++ ?to_s(City) ++ ","
		++ ?to_s(Merchant) ++ ","
		++ "\"" ++ ?utils:current_time(localdate) ++ "\");", 
	    Reply = ?sql_utils:execute(insert, Sql2),
	    ?w_user_profile:update(retailer, Merchant),
	    {reply, Reply, State};
			%% {Error} ->
			%%     {reply, Error, State}
	{ok, _Any} ->
	    %% ?DEBUG("retailer ~p has been exist", [Name]),
	    {reply, {error, ?err(retailer_exist, Name)}, State};
	Error ->
	    {reply, Error, State}
    end;


handle_call({update_retailer, Merchant, RetailerId, Attrs}, _From, State) ->
    ?DEBUG("update_retailer with merchant ~p, retailerId ~p~nattrs ~p",
	   [Merchant, RetailerId, Attrs]),

    Name     = ?v(<<"name">>, Attrs),
    Mobile   = ?v(<<"mobile">>, Attrs),
    Address  = ?v(<<"address">>, Attrs),
    Province = ?v(<<"province">>, Attrs),
    City     = ?v(<<"city">>, Attrs),
    Balance  = ?v(<<"balance">>, Attrs),

    NameExist =
	case Name of
	    undefined -> {ok, []};
	    Name ->
		Sql = "select id, name from w_retailer"
		    " where name=" ++ "\'" ++ ?to_s(Name) ++ "\'"
		    ++ " and merchant=" ++ ?to_s(Merchant)
		    ++ " and deleted=" ++ ?to_s(?NO),
		case ?mysql:fetch(read, Sql) of
		    {ok, R} -> {ok, R};
		    {error, {_, Err}} ->
			{error, ?err(db_error, Err)}
		end
	end,

    case NameExist of
	{ok, []} ->
	    Updates = ?utils:v(name, string, Name)
		++ ?utils:v(balance, float, Balance)
		++ ?utils:v(mobile, string, Mobile)
		++ ?utils:v(address, string, Address)
		++ ?utils:v(province, integer, Province)
		++ ?utils:v(city, integer, City), 

	    Sql1 = "select id, balance, merchant from w_retailer"
		" where id=" ++ ?to_s(RetailerId)
		++ " and merchant=" ++ ?to_s(Merchant),

	    case ?sql_utils:execute(s_read, Sql1) of
		{ok, []} -> {reply, {error, ?err(retailer_not_exist, RetailerId)}, State};
		{ok, R1} ->
		    CurrentBalance = ?v(<<"balance">>, R1),
		    Sql2 = "update w_retailer set "
			++ ?utils:to_sqls(proplists, comma, Updates)
			++ " where id=" ++ ?to_s(RetailerId)
			++ " and merchant=" ++ ?to_s(Merchant),
	    
		    case ?utils:v(balance, float, Balance) of
			[] -> 
			    Reply = ?sql_utils:execute(write, Sql2, RetailerId),
			    ?w_user_profile:update(retailer, Merchant),
			    {reply, Reply, State};
			_ ->
			    Sqls = [Sql2,
				    "insert into trace_retailer_balance("
				    "rsn, retailer, cur_balance, ch_balance"
				    ", action, merchant, entry_date) values("
				    ++ "\'" ++ ?to_s(-1) ++ "\',"
				    ++ ?to_s(RetailerId) ++ ","
				    ++ ?to_s(CurrentBalance) ++ ","
				    ++ ?to_s(Balance) ++ ","
				    ++ ?to_s(0) ++ ","
				    ++ ?to_s(Merchant) ++ ","
				    ++ "\'" ++ ?utils:current_time(format_localtime) ++ "\')"],
			    Reply = ?sql_utils:execute(transaction, Sqls, RetailerId),
			    ?w_user_profile:update(retailer, Merchant),
			    {reply, Reply, State}
		    end;
		{error, Error1} ->
		    {reply, {error, Error1}, State}
	    end;
	{error, Error} ->
	    {reply, {error, Error}, State}
    end;

%% handle_call({get_retailer, Merchant, RetailerId}, _From, State) ->
%%     ?DEBUG("get_retailer with merchant ~p, retailerId ~p",
%% 	   [Merchant, RetailerId]),
%%     Sql = "select id, name, mobile, province as pid,city as cid"
%% 	", address, balance, merchant, entry_date"
%% 	" from w_retailer where id=" ++ ?to_s(RetailerId)
%% 	++ " and merchant=" ++ ?to_s(Merchant), 
%%     Reply = ?sql_utils:execute(write, Sql, RetailerId),
%%     {reply, Reply, State};

handle_call({delete_retailer, Merchant, RetailerId}, _From, State) ->
    ?DEBUG("delete_retailer with merchant ~p, retailerId ~p",
	   [Merchant, RetailerId]),
    Sql = "delete from w_retailer where id=" ++ ?to_s(RetailerId)
	++ " and merchant=" ++ ?to_s(Merchant), 
    Reply = ?sql_utils:execute(write, Sql, RetailerId),
    ?w_user_profile:update(retailer, Merchant),
    {reply, Reply, State};

handle_call({list_retailer, Merchant}, _From, State) ->
    ?DEBUG("lookup retail with merchant ~p", [Merchant]),
    Sql = "select id, name, mobile, province as pid, city as cid"
	", address, balance, merchant, entry_date"
	" from w_retailer"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and deleted=" ++ ?to_s(?NO)
	++ " order by id desc",

    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({new_city, City, Province}, _From, State) ->
    ?DEBUG("new_city with city ~p", [City]),
    Sql0 = "select id, name from city where name=\'"
    	++ ?to_s(City) ++ "\'",
    case ?sql_utils:execute(s_read, Sql0) of
    	{ok, []} ->
    	    Sql1 = "insert into city(name, province) values ("
    		++ "\'" ++ ?to_s(City) ++ "\',"
    		++ ?to_s(Province) ++ ")",
    	    Reply = ?sql_utils:execute(insert, Sql1),
	    {reply, Reply, State};
	{ok, CityInfo} ->
	    {reply, {ok, ?v(<<"id">>, CityInfo)}, State};
	Error ->
	    {reply, Error, State}
    end;

handle_call(list_city, _From, State)->
    Sql = "select id, name, province as pid from city where deleted=" ++  ?to_s(?NO),
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call(list_province, _From, State) ->
    Sql = "select id, name from province where deleted=" ++  ?to_s(?NO),
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({bill_check, Merchant, Attrs}, _From, State) ->
    ?DEBUG("bill_check with merchant ~p, attrs ~p", [Merchant, Attrs]), 
    Retailer    = ?v(<<"retailer">>, Attrs),
    Bill        = ?v(<<"bill">>, Attrs, 0),
    CheckYear   = ?v(<<"check_year">>, Attrs),
    Shop        = ?v(<<"shop">>, Attrs),
    Employee    = ?v(<<"employee">>, Attrs),
    Comment     = ?v(<<"comment">>, Attrs, []),
    Datetime    = ?utils:current_time(format_localtime),
    {Cash, Card, Wire}  = case ?v(<<"mode">>, Attrs) of
			      0 -> {Bill, 0, 0} ;
			      1 -> {0, Bill, 0};
			      2 -> {0, 0, Bill}
			  end,


    Sql0 = "select id, name, balance from w_retailer"
	" where id=" ++ ?to_s(Retailer)
	++ " and merchant=" ++ ?to_s(Merchant)
	++ " and deleted=" ++ ?to_s(?NO),
    case ?sql_utils:execute(s_read, Sql0) of 
	{ok, Account} ->
	    SaleSn = lists:concat(
		       ["M-", ?to_i(Merchant),
			"-S-", ?to_i(Shop), "-",
			?inventory_sn:sn(w_sale_new_sn, Merchant)]), 
	    
	    LastBalance = ?v(<<"balance">>, Account),
	    Sql2 = "insert into w_sale(rsn"
		", employ, retailer, shop, merchant, balance"
		", has_pay, cash, card, wire, comment"
		", type, bill_date, entry_date) values("
		++ "\"" ++ ?to_s(SaleSn) ++ "\","
		++ "\"" ++ ?to_s(Employee) ++ "\","
		++ ?to_s(Retailer) ++ ","
		++ ?to_s(Shop) ++ ","
		++ ?to_s(Merchant) ++ ","
		++ ?to_s(LastBalance) ++ ","
		++ ?to_s(Bill) ++ ","
		++ ?to_s(Cash) ++ ","
		++ ?to_s(Card) ++ ","
		++ ?to_s(Wire) ++ ","
		++ "\"" ++ ?to_s(Comment) ++ "\"," 
		++ ?to_s(9) ++ ","
		++ ?to_s(CheckYear) ++ ","
		++ "\"" ++ ?to_s(Datetime) ++ "\");",

	    Sql3 = "update w_retailer set balance=balance-" ++ ?to_s(Bill) 
		++ " where id=" ++ ?to_s(?v(<<"id">>, Account)),

	    AllSql = [Sql2, Sql3],
	    Reply = ?sql_utils:execute(transaction, AllSql, SaleSn),
	    {reply, Reply, State};
	Error ->
	    {reply, Error, State}
    end;

handle_call({match, Merchant, Prompt}, _From, State) ->
    ?DEBUG("Prompt ~p", [Prompt]),
    Sql = "select id, name, mobile, balance"
	" from w_retailer"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and name like \'" ++ ?to_s(Prompt) ++ "%\'"
	++ " and deleted=" ++ ?to_s(?NO),
    
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({get_retailer, Merchant, RetailerId}, _From, State) ->
    Sql = "select id, name, mobile, balance"
	" from w_retailer"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and id="  ++ ?to_s(RetailerId)
	++ " and deleted=" ++ ?to_s(?NO),
    
    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};

handle_call({print_trans, Merchant, Attrs}, _From, State) ->
    ?DEBUG("print_trans with merchant ~p, attrs ~p", [Merchant, Attrs]),

    {StartTime, EndTime, NewConditions} = ?sql_utils:cut(fields_with_prifix, Attrs),
    Sql = "select a.id, a.rsn, a.retailer as retailer_id, a.shop as shop_id"
	", a.balance, a.should_pay, a.has_pay, a.cash, a.card"
	", a.wire, a.verificate, a.total, a.comment, a.entry_date"
    %% ", b.name as employee"
	", c.name as retailer"
	", d.name as shop"
	" from w_sale a"
    %% ++ " left join employees b on a.employ=b.number"
    %% ++ " and b.merchant=" ++ ?to_s(Merchant)
	++ " left join w_retailer c on a.retailer=c.id"
	++ " left join shops d on a.shop=d.id"
	++ " where a.merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, NewConditions)
	++ " and " ++ ?sql_utils:condition(time_with_prfix, StartTime, EndTime)
	++ " order by id",
    
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


