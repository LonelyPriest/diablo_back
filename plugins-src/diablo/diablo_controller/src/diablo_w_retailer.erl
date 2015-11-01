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
	    undefined -> {ok, []} ;
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

	    Sql1 = "update w_retailer set "
		++ ?utils:to_sqls(proplists, comma, Updates)
		++ " where id=" ++ ?to_s(RetailerId)
		++ " and merchant=" ++ ?to_s(Merchant),

	    Reply = ?sql_utils:execute(write, Sql1, RetailerId),
	    ?w_user_profile:update(retailer, Merchant),
	    {reply, Reply, State}; 
	{error, Error} ->
	    {reply, {error, Error}, State}
    end;

handle_call({get_retailer, Merchant, RetailerId}, _From, State) ->
    ?DEBUG("get_retailer with merchant ~p, retailerId ~p",
	   [Merchant, RetailerId]),
    Sql = "select id, name, mobile, province as pid,city as cid"
	", address, balance, merchant, entry_date"
	" from w_retailer where id=" ++ ?to_s(RetailerId)
	++ " and merchant=" ++ ?to_s(Merchant), 
    Reply = ?sql_utils:execute(write, Sql, RetailerId),
    {reply, Reply, State};

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


