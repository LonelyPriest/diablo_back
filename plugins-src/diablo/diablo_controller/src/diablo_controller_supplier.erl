%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 17 Sep 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_controller_supplier).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_server).

%% API
-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-export([supplier/2, supplier/3]).

-define(SERVER, ?MODULE). 
-define(tbl_supplier, "suppliers").


-record(state, {}).

%%%===================================================================
%%% API
%%%=================================================================== 
supplier(w_new, Attrs) ->
    gen_server:call(?MODULE, {w_new_supplier, Attrs});
supplier(w_list, Merchant) ->
    gen_server:call(?MODULE, {w_list, Merchant}). 
supplier(w_delete, Merchant, Id) ->
    gen_server:call(?MODULE, {w_delete_supplier, Merchant, Id});
supplier(w_update, Merchant, Attrs) ->
    gen_server:call(?MODULE, {w_update_supplier, Merchant, Attrs}).

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
init([]) ->
    {ok, #state{}}.

handle_call({w_new_supplier, Attrs}, _From, State)->
    ?DEBUG("w_new supplier with Attrs ~p", [Attrs]),
    Name     = ?v(<<"name">>, Attrs),
    %% Pinyin   = ?v(<<"pinyin">>, Attrs),
    Balance  = ?v(<<"balance">>, Attrs, 0),
    Mobile   = ?v(<<"mobile">>, Attrs, []),
    Address  = ?v(<<"address">>, Attrs),
    Merchant = ?v(<<"merchant">>, Attrs),
    
    %% name can not be same
    Sql = "select id, " ++ fields()
	++ " from " ++ ?tbl_supplier
	++ " where "
	++ " name=" ++ "\"" ++ ?to_s(Name) ++ "\""
	++ " and merchant=" ++ ?to_s(Merchant)
	++ " and deleted=" ++ ?to_s(?NO),
    
    case ?sql_utils:execute(read, Sql) of
	{ok, []} ->
	    Sql1 = "insert into " ++ ?tbl_supplier
		++ "(name, balance, mobile, address, merchant, change_date, entry_date)"
		++ " values ("
		++ "\"" ++ ?to_s(Name) ++ "\","
		++ ?to_s(Balance) ++ ","
		++ "\"" ++ ?to_s(Mobile) ++ "\","
		++ "\"" ++ ?to_s(Address) ++ "\","
		++ ?to_s(Merchant) ++ ","
		++ "\"" ++ ?utils:current_time(localtime) ++ "\","
		++ "\"" ++ ?utils:current_time(localtime) ++ "\");",

	    %% ?DEBUG("sql to supplier ~tp", [?to_b(Sql1)]),
	    Reply = ?sql_utils:execute(insert, Sql1),
	    ?w_user_profile:update(firm, Merchant),
	    {reply, Reply, State};
	{ok, _Any} ->
	    ?DEBUG("merchant ~p has been exist", [Name]),
	    {reply, {error, ?err(supplier_exist, Name)}, State};
	Error ->
	    {reply, Error, State}
    end;

handle_call({w_update_supplier, Merchant, Attrs}, _From, State) ->
    ?DEBUG("w_update_supplier with merhcant ~p, attrs ~p", [Merchant, Attrs]),
    FirmId   = ?v(<<"firm_id">>, Attrs),
    Name     = ?v(<<"name">>, Attrs), 
    Balance  = ?v(<<"balance">>, Attrs), 
    Mobile   = ?v(<<"mobile">>, Attrs),
    Address  = ?v(<<"address">>, Attrs),

    Sql = "select id, " ++ fields()
	++ " from " ++ ?tbl_supplier
	++ " where "
	++ " name=" ++ "\"" ++ ?to_s(Name) ++ "\""
	++ " and merchant=" ++ ?to_s(Merchant)
	++ " and deleted=" ++ ?to_s(?NO),
    %% ++ " and mobile = " ++ "\"" ++ ?to_s(Mobile) ++ "\";",
    
    case ?sql_utils:execute(s_read, Sql) of
	{ok, []} ->
	    Updates = ?utils:v(name, string, Name)
		++ ?utils:v(balance, float, Balance)
		++ ?utils:v(mobile,  string, Mobile)
		++ ?utils:v(address, string, Address),
	    Sql1 = 
		"update " ++ ?tbl_supplier ++ " set "
		++ ?utils:to_sqls(proplists, comma, Updates)
		++ " where id=" ++ ?to_s(FirmId)
		++ " and merchant=" ++ ?to_s(Merchant),

	    Reply = ?sql_utils:execute(write, Sql1, FirmId),
	    ?w_user_profile:update(firm, Merchant),
	    {reply, Reply, State};
	{ok, _} ->
	    {reply, {error, ?err(supplier_exist, Name)}, State};
	Error ->
	    {reply, Error, State}
    end;

handle_call({w_delete_supplier, Merchant, Id}, _From, State) ->
    ?DEBUG("w_delete_supplier with merchant ~p, Id ~p", [Merchant, Id]),
    Sql = "delete from " ++ ?tbl_supplier
	++ " where id=" ++ ?to_s(Id)
	++ " and merchant=" ++ ?to_s(Merchant), 
    Reply = ?sql_utils:execute(write, Sql, Id),
    ?w_user_profile:update(firm, Merchant),
    {reply, Reply, State}; 

handle_call({update_supplier, Condition, Fields}, _From, State) ->
    ?DEBUG("Update supplier with condtion: condition ~p, fields ~p", [Condition, Fields]),
    C = ?utils:to_sqls(proplists, Condition),
    ?DEBUG("C ~p", [C]),

    Values = ?utils:to_sqls(proplists, Fields),
    ?DEBUG("U ~p", [Values]),
    
    Sql = "update " ++ ?tbl_supplier ++ " set " ++ Values ++ " where " ++ C ++ ";",    
    ?DEBUG("sql ~p", [Sql]),
    {ok, _} = ?mysql:fetch(write, Sql),
    {reply, ok, State};

handle_call({w_list, Merchant}, _From, State) ->
    ?DEBUG("w_list with merchant ~p", [Merchant]),
    Sql = "select id, name, mobile, address, balance, entry_date from suppliers"
	++ " where "
	++ " merchant=" ++ ?to_s(Merchant)
	++ " and deleted = " ++ ?to_s(?NO)
	++ " order by id desc",
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

%% brand
handle_call({new_brand, Attrs}, _From, State)->
    ?DEBUG("new brand with Attrs ~p", [Attrs]),
    Name     = ?value(<<"name">>, Attrs),
    Supplier = ?value(<<"supplier">>, Attrs),
    Merchant = ?value(<<"merchant">>, Attrs),

    %% name can not be same
    Sql = "select id, name, supplier, merchant"
	++ " from brands"
	++ " where "
	++ " name = " ++ "\"" ++ ?to_string(Name) ++ "\""
	++ " and supplier = " ++ ?to_string(Supplier)
	++ " and merchant = " ++ ?to_string(Merchant)
	++ " and deleted = "  ++ ?to_string(?NO) ++ ";",
	
    case ?mysql:fetch(read, Sql) of
	{ok, []} ->
	    Sql1 = "insert into brands"
		++ "(name, supplier, merchant)"
		++ " values ("
		++ "\"" ++ ?to_string(Name) ++ "\","
		++ ?to_string(Supplier) ++ ","
		++ ?to_string(Merchant) ++ ");",

	    ?DEBUG("sql to brands ~ts", [?to_binary(Sql1)]),
	    {ok, _} = ?mysql:fetch(write, Sql1),
	    {reply, {ok, Name}, State};
	{ok, _Any} ->
	    ?DEBUG("brands of merchant ~p has been exist", [Name]),
	    {reply, {error, ?err(brand_exist, Name)}, State}
    end;


handle_call({connect_brand, Attrs}, _From, State)->
    ?DEBUG("connect brand with Attrs ~p", [Attrs]),
    Brand    = ?value(<<"brand">>, Attrs),
    Supplier = ?value(<<"supplier">>, Attrs),
    Merchant = ?value(<<"merchant">>, Attrs),
    
    Sql1 = "update brands set"
	++ " supplier=" ++ ?to_string(Supplier)
	++ " where id=" ++ ?to_string(Brand)
	++ " and merchant=" ++ ?to_string(Merchant)
	++ ";",
	
    ?DEBUG("sql to connect_brands ~ts", [?to_binary(Sql1)]),
    {ok, _} = ?mysql:fetch(write, Sql1),
    {reply, {ok, Brand}, State};


handle_call({lookup_unconnect_brand, Condition}, _From, State) ->
    ?DEBUG("lookup brand with condition ~p", [Condition]),
    CorrectCondition = ?utils:correct_condition(<<"a.">>, Condition),
    C = ?utils:to_sqls(proplists, CorrectCondition),
    Sql = "select a.id, a.name"
	++ " from brands a"
	++ " where " ++ C
	++ " and supplier = -1"
	++ " and a.deleted = " ++ ?to_string(?NO) ++ ";",
    {ok, Suppliers} = ?mysql:fetch(read, Sql),
    {reply, ?to_tuplelist(Suppliers), State};
    
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
fields() ->
    "name, mobile, address, merchant".
    

%% sql_fun_reply(SqlFun, SuccReply) ->
%%     case SqlFun() of
%% 	{error, Error} ->
%% 	    ?DEBUG("failed to sql fun ~p, error: ~p", [SqlFun, Error]),
%% 	    {error, ?err(db_error, Error)};
%% 	{ok, _} -> 
%% 	    {ok, SuccReply}
%%     end.
