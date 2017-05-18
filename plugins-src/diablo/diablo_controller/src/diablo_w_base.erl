%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2015, buxianhui
%%% @doc
%%%
%%% @end
%%% Created :  8 Apr 2015 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_w_base).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_server).

%% API
-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-export([bank_card/2, bank_card/3,
	 setting/2, setting/3,
	 delete_data/5, config/1]).

-define(SERVER, ?MODULE). 

-record(state, {}).

%%%===================================================================
%%% API
%%%===================================================================
bank_card(new, Merchant, Attrs) ->
    gen_server:call(?SERVER, {new_bank_card, Merchant, Attrs});
bank_card(delete, Merchant, CardId) ->
    gen_server:call(?SERVER, {delete_bank_card, Merchant, CardId});
bank_card(update, Merchant, Attrs) ->
    gen_server:call(?SERVER, {update_bank_card, Merchant, Attrs}).

bank_card(list, Merchant) ->
    gen_server:call(?SERVER, {list_bank_card, Merchant}).


setting(list, Merchant) ->
    gen_server:call(?SERVER, {list_base_setting, Merchant}).

setting(add_to_shop, Merchant, Shop) ->
    gen_server:call(?SERVER, {add_shop_setting, Merchant, Shop});

setting(list, Merchant, Conditions) ->
    gen_server:call(?SERVER, {list_base_setting, Merchant, Conditions});
setting(add, Merchant, Attr) ->
    gen_server:call(?SERVER, {add_base_setting, Merchant, Attr});
setting(update, Merchant, Update) ->
    gen_server:call(?SERVER, {update_base_setting, Merchant, Update}).

delete_data(expire, Merchant, Expire, DeleteStock, DeleteSell) ->
    gen_server:call(
      ?SERVER, {delete_expire_data,
		Merchant, Expire, DeleteStock, DeleteSell}).

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

init([]) ->
    {ok, #state{}}.

handle_call({new_bank_card, Merchant, Attrs}, _From, State) ->
    ?DEBUG("new_bank_card with merchant ~p, attr~p", [Merchant, Attrs]),
    CardName   = ?v(<<"name">>, Attrs),
    CardNo     = ?v(<<"no">>, Attrs),
    CardBank   = ?v(<<"bank">>, Attrs),
    CardRemark = ?v(<<"remark">>, Attrs, ""),

    Sql = "select id, no from w_bank_card where no=\'" ++ ?to_s(CardNo) ++ "\'"
	++ " and merchant=" ++ ?to_s(Merchant)
	++ " and deleted=" ++ ?to_s(?NO),
    
    case ?sql_utils:execute(s_read, Sql) of
	{ok, []} ->
	    Sql1 = "insert into w_bank_card(name, no, bank, remark, merchant"
		", entry_date) values("
		++ "\'" ++ ?to_s(CardName) ++ "\',"
		++ "\'" ++ ?to_s(CardNo) ++ "\',"
		++ "\'" ++ ?to_s(CardBank) ++ "\',"
		++ "\'" ++ ?to_s(CardRemark) ++ "\',"
		++ ?to_s(Merchant) ++ ","
		++ "\'" ++ ?utils:current_time(localtime) ++ "\');",

	    Reply = ?sql_utils:execute(insert, Sql1),
	    {reply, Reply, State};
	{ok, _Any} ->
	    ?DEBUG("bank card ~p has been exist of merchant ~p", [CardNo, Merchant]),
	    {reply, {error, ?err(base_card_exist, CardNo)}, State};
	Error ->
	    {reply, Error, State}
    end;

handle_call({update_bank_card, Merchant, Attrs}, _From, State) ->
    ?DEBUG("update_bank_card with merchant ~p, attrs ~p", [Merchant, Attrs]),
    CardId     = ?v(<<"id">>, Attrs),
    CardNo     = ?v(<<"no">>, Attrs),
    CardBank   = ?v(<<"bank">>, Attrs),

    Sql = "update w_bank_card set"
	" no=\'"   ++ ?to_s(CardNo) ++ "\',"
	" bank=\'" ++ ?to_s(CardBank) ++ "\'"
	" where id=" ++ ?to_s(CardId)
	++ " and merchant=" ++ ?to_s(Merchant),

    Reply = ?sql_utils:execute(write, Sql, CardNo),
    {reply, Reply, State}; 

handle_call({delete_bank_card, Merchant, CardId}, _From, State) ->
    ?DEBUG("delete_bank_card with merchant ~p, CardId ~p", [Merchant, CardId]),

    Sql = "update w_bank_card set deleted=" ++ ?to_s(?YES)
	++ " where id=" ++ ?to_s(CardId)
	++ " and merchant=" ++ ?to_s(Merchant),

    Reply = ?sql_utils:execute(write, Sql, CardId),
    {reply, Reply, State}; 
	
handle_call({list_bank_card, Merchant}, _From, State) ->
    ?DEBUG("list_bank_card with merchant ~p", [Merchant]),
    Sql = "select id, name, no, bank, remark, entry_date from w_bank_card"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and deleted=" ++ ?to_s(?NO),
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State}; 

handle_call({list_base_setting, Merchant, Conditions}, _From, State) ->
    ?DEBUG("list_base_setting with merchant ~p, condtions ~p",
	   [Merchant, Conditions]),

    Sql = "select id, ename, cname, value, type"
	", remark, shop, entry_date from w_base_setting"
	" where " ++ ?utils:to_sqls(proplists, Conditions)
	++ " and merchant=" ++ ?to_s(Merchant)
	++ " and deleted=" ++ ?to_s(?NO),

    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State}; 

handle_call({list_base_setting, Merchant}, _From, State) ->
    ?DEBUG("list_base_setting with merchant ~p", [Merchant]),

    Sql = "select id, ename, cname, value, type"
	", remark, shop, entry_date from w_base_setting"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and deleted=" ++ ?to_s(?NO),

    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({add_base_setting, Merchant, Attr}, _From, State) ->
    ?DEBUG("add_base_setting with merchant ~p, attr ~p", [Merchant, Attr]),
    EName  = ?v(<<"ename">>, Attr),
    CName  = ?v(<<"cname">>, Attr),
    Value  = ?v(<<"value">>, Attr),
    Type   = ?v(<<"type">>, Attr),
    Remark = ?v(<<"remark">>, Attr, []),
    Shop   = ?v(<<"shop">>, Attr, -1),

    Sql0 = "select id, ename, value from w_base_setting"
	" where shop=" ++ ?to_s(Shop)
	++ " and merchant=" ++ ?to_s(Merchant)
	++ " and ename=\'" ++ ?to_s(EName) ++ "\'"
	++ " and deleted=" ++ ?to_s(?NO),
	%% ++ " and value=\'" ++ ?to_s(Value) ++ "\'",

    case ?sql_utils:execute(s_read, Sql0) of
	{ok, []} ->
	    Sql1 = "insert into w_base_setting("
		"ename, cname, value, type, remark"
		", shop, merchant, entry_date) values("
		++ "\'" ++ ?to_s(EName) ++ "\',"
		++ "\'" ++ ?to_s(CName) ++ "\',"
		++ "\'" ++ ?to_s(Value) ++ "\',"
		++ ?to_s(Type) ++ ","
		++ "\'" ++ ?to_s(Remark) ++ "\',"
		++ ?to_s(Shop) ++ ","
		++ ?to_s(Merchant) ++ ","
		++ "\'" ++ ?utils:current_time(localdate) ++ "\')", 
	    Reply = ?sql_utils:execute(insert, Sql1),
	    {reply, Reply, State}; 
	{ok, _} ->
	    {reply, {error, ?err(base_setting_exist, EName)}, State};
	Error ->
	    {reply, Error, State}
    end;
	

handle_call({update_base_setting, Merchant, Update}, _From, State) ->
    ?DEBUG("update_base_setting with merchant ~p, update ~p",
	   [Merchant, Update]),

    Id     = ?v(<<"id">>, Update),
    EName  = ?v(<<"ename">>, Update),
    Value  = ?v(<<"value">>, Update),
    Shop   = ?v(<<"shop">>, Update),
    Remark = ?v(<<"remark">>, Update, []),

    Sql = "update w_base_setting set value=\'" ++ ?to_s(Value) ++ "\'"
	", remark=\'" ++ ?to_s(Remark) ++ "\'"
	++ " where id=" ++ ?to_s(Id)
	++ " and shop=" ++ ?to_s(Shop)
	++ " and merchant=" ++ ?to_s(Merchant),

    Reply = ?sql_utils:execute(write, Sql, EName),
    %% refresh profile
    ?w_user_profile:update(setting, Merchant),
    {reply, Reply, State};

handle_call({add_shop_setting, Merchant, Shop}, _From, State) ->
    ?DEBUG("add_shop_setting with merchant ~p, shop ~p", [Merchant, Shop]),
    Now = ?utils:current_time(localdate),

    Values = config(default),
    Sql0 = lists:foldr(
	     fun({EName, CName, Value, Type}, Acc) ->
		     Sql00 = "select id, ename, value from w_base_setting"
			 " where ename=\'" ++ EName ++ "\'"
			 ++ " and shop=" ++ ?to_s(Shop)
			 ++ " and merchant=" ++ ?to_s(Merchant),
		     case ?sql_utils:execute(s_read, Sql00) of
			 {ok, []} ->
			     ["insert into w_base_setting("
			      "ename, cname, value, type"
			      ", shop, merchant, entry_date) values("
			      "\'" ++ EName ++ "\',"
			      "\'" ++ CName ++ "\',"
			      ++ "\'" ++ ?to_s(Value) ++ "\',"
			      ++ Type  ++ ","
			      ++ ?to_s(Shop) ++ ","
			      ++ ?to_s(Merchant) ++ "," 
			      "\'" ++ Now ++ "\');"|Acc];
			 {ok, _} ->
			     Acc
		     end
	     end, [], Values),

    Reply = ?sql_utils:execute(transaction, Sql0, Shop),
    ?w_user_profile:update(setting, Merchant),
    {reply, Reply, State};

handle_call({delete_expire_data, Merchant, Expire, DeleteStock, DeleteSell},
	    _From, State) ->
    ?DEBUG("delete_expire_data with merchant ~p"
	   ", expire ~p, deleteStock ~p, deleteSell ~p",
	   [Merchant, Expire, DeleteStock, DeleteSell]),

    Condition = "merchant=" ++ ?to_s(Merchant)
	++ " and entry_date<\'" ++ ?to_s(Expire) ++ "\'",

    Sqls = [
	    %% delete product
	    "delete from w_inventory_good where " ++ Condition, 

	    %% delete stock
	    %% "delete from w_inventory_new_detail_amount"
	    %% " where rsn in "
	    %% "(select rsn from w_inventory_new where " ++ Condition ++ ")", 

	    %% "delete from w_inventory_new_detail"
	    %% " where rsn in "
	    %% "(select rsn from w_inventory_new where " ++ Condition ++ ")",

	    %% "delete from w_inventory_new where " ++ Condition,

	    %% delete stock
	    "delete from w_inventory_amount where "
	    "merchant=" ++ ?to_s(Merchant)
	    ++ " and entry_date<\'" ++ ?to_s(Expire) ++ "\'",
	    
	    "delete from w_inventory where "
	    "merchant=" ++ ?to_s(Merchant)
	    ++ " and entry_date<\'" ++ ?to_s(Expire) ++ "\'",
	    
	    %% delete stock fix
	    "delete from w_inventory_fix_detail_amount"
	    " where rsn in "
	    "(select rsn from w_inventory_fix where " ++ Condition ++ ")", 

	    "delete from w_inventory_fix_detail"
	    " where rsn in "
	    "(select rsn from w_inventory_fix where " ++ Condition ++ ")",

	    "delete from w_inventory_fix where " ++ Condition]
	
	++ case DeleteStock of
	       true -> [
			%% delete stock record
			"delete from w_inventory_new_detail_amount"
			" where rsn in "
			"(select rsn from w_inventory_new where "
			++ Condition ++ ")", 

			"delete from w_inventory_new_detail"
			" where rsn in "
			"(select rsn from w_inventory_new where "
			++ Condition ++ ")",
			
			"delete from w_inventory_new where " ++ Condition
		       ];
	       false -> []
	   end

	++ case DeleteSell of
	       true -> [
			%% delete sell
			"delete from w_sale_detail_amount"
			" where rsn in "
			"(select rsn from w_sale where " ++ Condition ++ ")", 

			"delete from w_sale_detail"
			" where rsn in "
			"(select rsn from w_sale where " ++ Condition ++ ")",

			"delete from w_sale where " ++ Condition];
	       false -> []
	   end, 

    Reply = ?sql_utils:execute(transaction, Sqls, Merchant), 
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

config(default) ->
    %% default one month ago
    {M, S, T} = erlang:now(), 
    {{YY, MM, DD}, _} = calendar:now_to_datetime({M, S - 86400 * 30, T}),
    DefaultDate = lists:flatten(
		    io_lib:format("~4..0w-~2..0w-~2..0w", [YY, MM, DD])),
    
    %% ename,            cname,          value,type
    [{"pum",             "打印份数",     "1",  "0"},
     {"ptype",           "打印方式",     "1",  "0"}, %% 0: front; 1:backend 
     {"pformat",         "打印格式",     "1",  "0"},
     {"ptable",          "表格打印",     "0",  "0"},
     {"pretailer",       "打印零售商",   "0",  "0"},
     {"pround",          "四舍五入",     "0",  "0"},
     {"ptrace_price",    "价格跟踪",     "0",  "0"},
     {"prompt",          "提示数目",     "8",  "0"},
     {"pim_print",       "立即打印",     "0",  "0"},
     {"qtime_start",     "查询开始时间", DefaultDate,  "0"},
     {"qtime_length",    "查询跨度",     "30",  "0"},
     {"qtypeahead",      "提示方式",     "1",   "0"}, %% 0: front; 1:backend
     {"reject_negative", "零库存退货",   "0",   "0"},
     {"check_sale",      "检测库存销售", "1",   "0"},
     {"show_discount",   "开单显示折扣", "1",   "0"},
     {"se_pagination",   "顺序翻页",     "0",   "0"},
     {"stock_alarm",     "库存告警",     "0",   "0"},
     {"price_type",      "默认价格类型", "1",   "0"},
     {"pccmix",          "打印混排",     "0",   "0"},
     {"bdebt",           "欠款打印加粗", "0",   "0"},
     {"h_price3_5",      "隐藏价3到5",   "0",   "0"},
     {"m_sgroup",        "多尺码组方式", "0",   "0"},
     {"r_snumber",       "开单重复款号", "0",   "0"},
     {"baddr",           "地址打印加粗", "0",   "0"},
     {"auto_cash",       "开单自动计算金额", "0",   "0"},
     {"reject_pgood",    "允许补货退单",     "0",   "0"},
     {"e_sgroup1",       "导出尺码组1",      "0",   "0"},
     {"e_sgroup2",       "导出尺码组2",      "0",   "0"},
     {"e_sgroup3",       "导出尺码组3",      "0",   "0"},
     {"s_customer",      "系统客户",         "0",   "0"},
     {"e_color",         "导出颜色",         "0",   "0"},
     {"head_phone",      "联系方式打印置前", "0",   "0"},
     {"pseconed_good",   "打印补单标志",     "0",   "0"},
     {"check_debt",      "检测零售商欠款",   "1",   "0"},
     {"h_tagprice",      "开单隐藏单价",     "0",   "0"},
     {"h_sell_style",    "开单隐藏单价类型", "0",   "0"},
     {"head_amount",     "开单数量字段置前", "0",   "0"},
     {"m_comment",       "备注可修改",       "0",   "0"},
     {"bluetooth",       "蓝牙打印",         "0",   "0"}
    ].
