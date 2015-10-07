%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 22 Oct 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_controller_right_init).


-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_server).

-export([catlogs/0]).
-export([get_children/1, get_root/1, get_children/2,
	 get_pass_action/0, get_action/2]).
-export([lookup/0, find_child/2, find_root/3, format_value/2, lookup/1]).

%% API
-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-define(SERVER, ?MODULE). 
-define(ROOT, 0).
-define(ALL_CATLOGS,
	[
	 %% sale
	 ?right_sale,	 
	 ?right_inventory,
	 ?right_member,
	 ?right_shop,
	 ?right_employe,
	 ?right_right,
	 ?right_supplier,
	 ?right_merchant,
	 
	 %% about whole sale
	 ?right_w_sale,
	 ?right_w_inventory,
	 ?right_w_firm,
	 ?right_w_retailer,
	 ?right_w_print,
	 ?right_w_good,
	 ?right_w_report,
	 %% base seting 
	 ?right_w_base, 
	 
	 %% rainbow
	 ?right_rainbow
	 
	]).

%% -record(right_trees,
%% 	{trees = [] :: [tree()],
%% 	 gb_tree    :: gb_tree()}).

-record(right_trees,
	{action_tree       :: gb_tree(),
	 id_tree           :: gb_tree(),
	 pass_actions      :: list() %% these action does not to be authened
	}).


%% right_init(super) ->
%%     gen_server:call(?SERVER, right_super).

get_children(Node) ->
    gen_server:call(?SERVER, {children_include_node, Node}).
get_children(children_only, Node) ->
    gen_server:call(?SERVER, {children_only, Node}).
get_root(Node) ->
    gen_server:call(?SERVER, {root, Node}).

lookup() ->
    gen_server:call(?SERVER, lookup).
lookup(super) ->
    gen_server:call(?SERVER, lookup_super);
lookup(action) ->
    gen_server:call(?SERVER, lookup_action).


get_action(id, ActionName) ->
    gen_server:call(?SERVER, {get_action_id, ?to_binary(ActionName)});
get_action(name, ActionId) ->
    gen_server:call(?SERVER, {get_action_name, ActionId}).
get_pass_action() ->
    gen_server:call(?SERVER, get_pass_action).


start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

init([]) ->
    Catlog = [
	      {?right_sale,      <<"销售管理">>,   <<"sale">>},
	      {?right_inventory, <<"库存管理">>,   <<"inventory">>},
	      {?right_member,    <<"会员管理">>,   <<"member">>},
	      {?right_shop,      <<"店铺管理">>,   <<"shop">>},
	      {?right_employe,   <<"员工管理">>,   <<"employ">>},
	      {?right_right,     <<"权限管理">>,   <<"right">>},
	      {?right_supplier,  <<"供应商管理">>, <<"supplier">>},
	      {?right_merchant,  <<"商家管理">>,   <<"merchant">>},
	      
	      %% about wholesale
	      {?right_w_sale,      <<"批发销售管理">>,   <<"wsale">>},
	      {?right_w_inventory, <<"批发采购管理">>,   <<"purchaser">>},
	      {?right_w_firm,      <<"批发厂商管理">>,   <<"firm">>},
	      {?right_w_retailer,  <<"批发零售商管理">>, <<"wretailer">>},
	      {?right_w_print,     <<"打印机管理">>,     <<"wprint">>},
	      {?right_w_good,      <<"批发货品管理">>,   <<"wgood">>},
	      {?right_w_report,    <<"批发报表管理">>,   <<"wreport">>},

	      %% rainbow
	      {?right_rainbow,     <<"高级功能组">>,  <<"rainbow">>},
	      
	      %% base setting
	      {?right_w_base,      <<"批发基本设置">>, <<"wbase">>}
	      
	     ],

    Sale = 
	[{?perment,             <<"前台销售">>, <<"payment">>,             ?right_sale},
	 {?list_sale_info,      <<"销售详情">>, <<"list_sale_info">>,      ?right_sale},
	 {?reject_and_exchange, <<"退换货">>,   <<"reject_and_exchange">>, ?right_sale},
	 {?list_reject_info,    <<"退货详情">>, <<"list_reject_info">>,    ?right_sale}
	],

    Inventory = 
	[{?new_inventory,    <<"新增库存">>,   <<"new_inventory">>,    ?right_inventory},
	 {?del_inventory,    <<"删除库存">>,   <<"delete_inventory">>, ?right_inventory},
	 {?update_inventory, <<"修改库存">>,   <<"update_inventory">>, ?right_inventory},
	 {?list_inventory,   <<"查询库存">>,   <<"list_inventory">>,   ?right_inventory},
	 {?new_size_group,   <<"新增尺码组">>, <<"new_size_group">>,   ?right_inventory},
	 {?del_size_group,   <<"删除尺码组">>, <<"del_size_group">>,   ?right_inventory},
	 {?update_size_group,<<"修改尺码组">>, <<"update_size_group">>,?right_inventory},
	 {?list_size_group,  <<"查询尺码组">>, <<"list_size_group">>,  ?right_inventory},
	 {?check_inventory,  <<"库存审核">>,   <<"check_inventory">>,  ?right_inventory},
	 {?move_inventory,   <<"移仓">>,       <<"move_inventory">>,   ?right_inventory}, 
	 {?do_move_inventory,<<"移仓审核">>,   <<"do_move_inventory">>,?right_inventory},
	 {?reject_inventory, <<"退货">>,       <<"reject_inventory">>, ?right_inventory},
	 {?import_inventory, <<"导入">>,       <<"import_inventory">>, ?right_inventory},
	 {?export_inventory, <<"导出">>,       <<"export_inventory">>, ?right_inventory},
	 {?adjust_price,     <<"调价">>,       <<"adjust_price">>, ?right_inventory}
	],

    Member = 
	[{?new_member,            <<"新增会员">>,     <<"new_member">>,            ?right_member},
	 {?del_member,            <<"删除会员">>,     <<"delete_member">>,         ?right_member},
	 {?update_member,         <<"修改会员">>,     <<"update_member">>,         ?right_member},
	 {?list_member,           <<"查询会员">>,     <<"list_member">>,           ?right_member},
	 %% {?acc_score,          <<"累计计分">>,     <<"acc_score">>,             ?list_member},
	 {?acc_score_detail,      <<"累计计分详情">>, <<"acc_score_detail">>,      ?right_member},
	 {?exchange_score,        <<"兑换计分">>,     <<"exchange_score">>,        ?right_member},
	 {?exchange_score_detail, <<"兑换计分详情">>, <<"exchange_score_detail">>, ?right_member},
	 {?query_score_stratege,  <<"查询计分策略">>, <<"query_score_strategy">>,  ?right_member},
	 {?update_score_stratege, <<"修改计分策略">>, <<"modify_score_strategy">>, ?right_member}
	],

    
    Shop = 
	[{?new_shop,       <<"新增店铺">>, <<"new_shop">>,    ?right_shop},
	 {?del_shop,       <<"删除店铺">>, <<"delete_shop">>, ?right_shop},
	 {?update_shop,    <<"修改店铺">>, <<"update_shop">>, ?right_shop},
	 {?list_shop,      <<"查询店铺">>, <<"list_shop">>,   ?right_shop},
	 
	 {?new_repo,       <<"新增仓库">>, <<"new_repo">>,    ?right_shop},
	 {?del_repo,       <<"删除仓库">>, <<"del_repo">>,    ?right_shop},
	 {?update_repo,    <<"修改仓库">>, <<"update_repo">>, ?right_shop},
	 {?list_repo,      <<"查询仓库">>, <<"list_repo">>,   ?right_shop},
	 
	 {?new_badrepo,    <<"新增次品仓">>, <<"new_badrepo">>,    ?right_shop},
	 {?del_badrepo,    <<"删除次品仓">>, <<"del_badrepo">>,    ?right_shop},
	 {?update_badrepo, <<"修改次品仓">>, <<"update_badrepo">>, ?right_shop},
	 {?list_badrepo,   <<"查询次品仓">>, <<"list_badrepo">>,   ?right_shop}
	],

    
    
    Employ = 
	[{?new_employe,    <<"新增员工">>, <<"new_employe">>,    ?right_employe},
	 {?del_employe,    <<"删除员工">>, <<"delete_employe">>, ?right_employe},
	 {?update_employe, <<"修改员工">>, <<"update_employe">>, ?right_employe},
	 {?list_employe,   <<"查询员工">>, <<"list_employe">>,   ?right_employe}
	],

    Right =
	[{?new_role,       <<"新增角色">>, <<"new_role">>,      ?right_right},
	 {?del_role,       <<"删除角色">>, <<"del_role">>,      ?right_right},
	 {?update_role,    <<"修改角色">>, <<"update_role">>,   ?right_right},
	 {?list_role,      <<"查询角色">>, <<"list_role">>,     ?right_right},
	 {?new_account,    <<"新增用户">>, <<"new_account">>,   ?right_right},
	 {?del_account,    <<"删除用户">>, <<"del_account">>,   ?right_right},
	 {?update_account, <<"修改用户">>, <<"update_account">>,?right_right},
	 {?list_account,   <<"查询用户">>, <<"list_account">>,  ?right_right}
	],

    Supplier = 
	[{?new_supplier,    <<"新增供应商">>, <<"new_supplier">>,      ?right_supplier},
	 {?del_supplier,    <<"删除供应商">>, <<"delete_supplier">>,   ?right_supplier},
	 {?update_supplier, <<"修改供应商">>, <<"update_supplier">>,   ?right_supplier},
	 {?list_supplier,   <<"查询供应商">>, <<"list_supplier">>,     ?right_supplier},
	 %% {?new_brand,       <<"新增品牌">>,   <<"new_brand">>,         ?right_supplier},
	 {?del_brand,       <<"删除品牌">>,   <<"del_brand">>,         ?right_supplier},
	 {?update_brand,    <<"修改品牌">>,   <<"update_brand">>,      ?right_supplier},
	 {?list_brand,      <<"查询品牌">>,   <<"list_brand">>,        ?right_supplier},
	 {?connect_brand,   <<"关联品牌">>,   <<"connect_brand">>,     ?right_supplier}
	],

    Merchant =
	[{?new_merchant,    <<"新增商家">>,     <<"new_merchant">>,         ?right_merchant},
	 {?del_merchant,    <<"删除商家">>,     <<"delete_merchant">>,      ?right_merchant},
	 {?update_merchant, <<"修改商家信息">>, <<"update_merchant">>,      ?right_merchant},
	 {?list_merchant,   <<"查看商家信息">>, <<"list_merchant">>,        ?right_merchant}
	],

    %% =========================================================================
    %% about wholesale
    %% =========================================================================    

    %% sale
    WSale =
	[{?new_w_sale,    <<"销售开单">>,     <<"new_w_sale">>,       ?right_w_sale},
	 {?reject_w_sale, <<"销售退货">>,     <<"reject_w_sale">>,    ?right_w_sale},
	 {?print_w_sale,  <<"销售单打印">>,   <<"print_w_sale">>,     ?right_w_sale},
	 {?update_w_sale, <<"销售单编辑">>,   <<"update_w_sale">>,    ?right_w_sale},
	 {?check_w_sale,  <<"销售单审核">>,   <<"check_w_sale">>,     ?right_w_sale} 
	],
    
    %% inventory
    WInventory =
	[%% {?new_w_order,   <<"新增定单">>,   <<"new_purchase_order">>,    ?right_w_inventory},
	 %% {?del_w_order,   <<"删除定单">>,   <<"delete_purchase_order">>, ?right_w_inventory}, 
	 %% {?list_w_order,  <<"定单详情">>,   <<"list_purchase_order">>,   ?right_w_inventory},

	 %% %% size
	 %% {?new_w_size,    <<"新增尺码组">>, <<"new_purchaser_size">>,    ?right_w_inventory},
	 %% {?del_w_size,    <<"删除尺码组">>, <<"delete_purchaser_size">>, ?right_w_inventory},
	 %% {?update_w_size, <<"修改尺码组">>, <<"update_purchaser_size">>, ?right_w_inventory},

	 %% %% color
	 %% {?new_w_color,   <<"新增颜色">>,   <<"new_purchaser_color">>,   ?right_w_inventory},
	 %% {?del_w_color,   <<"删除颜色">>,   <<"delete_purchaser_color">>,?right_w_inventory},
	 %% {?update_w_color,<<"删除颜色">>,   <<"update_purchaser_color">>,?right_w_inventory},

	 %% %% goods
	 %% {?new_w_good,    <<"新增货品">>,    <<"new_purchaser_good">>,    ?right_w_inventory},
	 %% {?del_w_good,    <<"删除货品">>,    <<"delete_purchaser_good">>, ?right_w_inventory},
	 %% {?update_w_good, <<"修改货品信息">>,<<"update_purchaser_good">>, ?right_w_inventory},
	 %% {?list_w_good,   <<"查询货品信息">>,<<"list_purchaser_good">>,   ?right_w_inventory},

	 %% inventory
	 {?new_w_inventory, <<"新增库存">>, <<"new_w_inventory">>,     ?right_w_inventory},
	 {?del_w_inventory, <<"删除库存">>, <<"delete_w_inventoryy">>, ?right_w_inventory},
	 {?update_w_inventory, <<"修改库存">>, <<"update_w_inventory">>,  ?right_w_inventory},
	 %% {?list_w_inventory,
	 %%  <<"查询库存">>, <<"list_purchaser_inventory">>,    ?right_w_inventory},
	 
	 %% {?update_w_inventory_price,
	 %%  <<"修改进货价">>, <<"update_w_inventory_price">>,  ?right_w_inventory},
	 
	 %% {?list_new_w_inventory,
	 %%  <<"入库详情">>, <<"list_w_inventory_new">>, ?right_w_inventory},
	 {?check_w_inventory, <<"库存审核">>, <<"check_w_inventory">>,  ?right_w_inventory},
	 {?reject_w_inventory,
	  <<"退货">>, <<"reject_w_inventory">>, ?right_w_inventory},
	 
	 {?fix_w_inventory,
	  <<"库存盘点">>, <<"fix_w_inventory">>, ?right_w_inventory}
	 
	 %% {?filter_fix_w_inventory,
	 %%  <<"盘点详情">>, <<"filter_fix_w_inventory">>, ?right_w_inventory}
	],

    %% firm
    WFirm =
	[{?new_w_firm,    <<"新增厂商">>,     <<"new_firm">>,         ?right_w_firm},
	 {?del_w_firm,    <<"删除厂商">>,     <<"delete_firm">>,      ?right_w_firm},
	 {?update_w_firm, <<"修改厂商信息">>, <<"update_firm">>,      ?right_w_firm}
	 %% {?list_w_firm,   <<"查看厂商信息">>, <<"list_firm">>,        ?right_w_firm}
	],

    %% sale
    WSaler =
    	[{?new_w_retailer,    <<"新增零售商">>, <<"new_w_retailer">>,   ?right_w_retailer},
    	 {?del_w_retailer,    <<"删除零售商">>, <<"del_w_retailer">>,   ?right_w_retailer},
	 {?update_w_retailer, <<"修改零售商">>, <<"update_w_retailer">>,?right_w_retailer}
    	],
    
    %% print
    WPrint = 
    	[{?new_w_print_server, <<"新增服务器">>, <<"new_w_print_server">>, ?right_w_print},
    	 {?del_w_print_server, <<"删除服务器">>, <<"del_w_print_server">>, ?right_w_print},

	 {?new_w_printer,      <<"新增打印机">>, <<"new_w_printer">>,      ?right_w_print},
	 {?del_w_printer,      <<"删除打印机">>, <<"del_w_printer">>,      ?right_w_print},
	 {?update_w_printer,   <<"修改打印机">>, <<"update_w_printer">>,   ?right_w_print},
	 {?list_w_printer,     <<"查询打印机">>, <<"list_w_printer">>,     ?right_w_print}

	 %% {?new_w_printer_conn,   <<"关联打印机">>,    <<"new_w_printer_conn">>,?right_w_print},
	 %% {?del_w_printer_conn,   <<"删除打印机关联">>,<<"del_w_printer_conn">>,?right_w_print},
	 %% {?update_w_printer_conn,<<"修改打印机关联">>,<<"update_w_printer_conn">>,  ?right_w_print},
	 %% {?list_w_printer_conn,  <<"查询打印机关联">>,<<"list_w_printer_conn">>,    ?right_w_print}
    	],

    WGood =
	[{?new_w_good,    <<"新增货品">>,    <<"new_w_good">>,    ?right_w_good},
	 {?del_w_good,    <<"删除货品">>,    <<"delete_w_good">>, ?right_w_good},
	 {?update_w_good, <<"修改货品信息">>,<<"update_w_good">>, ?right_w_good}
	 %% {?list_w_good,   <<"查询货品信息">>,<<"list_w_good">>,   ?right_w_good}
	 ,
	 %% size
	 {?new_w_size,    <<"新增尺码组">>, <<"new_w_size">>,    ?right_w_good},
	 {?del_w_size,    <<"删除尺码组">>, <<"delete_w_size">>, ?right_w_good},
	 {?update_w_size, <<"修改尺码组">>, <<"update_w_size">>, ?right_w_good},

	 %% color
	 {?new_w_color,   <<"新增颜色">>,   <<"new_w_color">>,   ?right_w_good},
	 {?del_w_color,   <<"删除颜色">>,   <<"delete_w_color">>,?right_w_good},
	 {?update_w_color,<<"修改颜色">>,   <<"update_w_color">>,?right_w_good} 
	],

    WReport =
	[{?daily_wreport,   <<"日报表">>,   <<"daily_wreport">>, ?right_w_report},
	 {?weekly_wreport,  <<"周报表">>,   <<"weekly_wreport">>, ?right_w_report},
	 {?monthly_wreport, <<"月报表">>,   <<"monthly_wreport">>, ?right_w_report},
	 {?quarter_wreport, <<"季度报表">>, <<"quarter_wreport">>, ?right_w_report},
	 {?half_wreport,    <<"年中报表">>, <<"half_wreport">>, ?right_w_report},
	 {?year_wreport,    <<"年中报表">>, <<"year_wreport">>, ?right_w_report} 
	],
    
    %% rainbow
    Rainbow =
	[{?inventory_fifo, <<"库存先进先出">>, <<"inventory_fifo">>,   ?right_rainbow}],

    %% base setting
    Base =
    	[{?new_w_bank_card,   <<"新增银行卡">>, <<"new_w_bank_card">>,   ?right_w_base},
	 {?del_w_bank_card,   <<"删除银行卡">>, <<"del_w_bank_card">>,   ?right_w_base},
	 {?update_w_bank_card,<<"修改银行卡">>, <<"update_w_bank_card">>,?right_w_base},
	 
	 {?new_w_printer_conn,
	  <<"关联打印机">>,    <<"new_w_printer_conn">>,   ?right_w_base},
	 {?del_w_printer_conn,
	  <<"删除打印绑定">>,<<"del_w_printer_conn">>,     ?right_w_base},
	 {?update_w_printer_conn,
	  <<"修改打印绑定">>,<<"update_w_printer_conn">>,  ?right_w_base},
	 {?list_w_printer_conn,
	  <<"查询打印绑定">>,<<"list_w_printer_conn">>,    ?right_w_base}
	 %% {?list_w_bank_card,  <<"银行卡详情">>, <<"list_w_bank_card">>,  ?right_w_base}
    	],

    
    lists:foreach(fun set_catlog/1, Catlog),
    
    lists:foreach(fun set_fun/1,
		  %% sale
		  Inventory ++ Employ ++ Shop ++ Member ++ Supplier
		  ++ Right ++ Sale ++ Merchant
		  %% about wholesale
		  ++ WInventory ++ WSale ++ WFirm ++ WSaler ++ WPrint ++ WGood
		  ++ WReport ++ Base
		  %% finance
		  ++ Rainbow
		  %% base setting
		  %% ++ Setting
		 ),

    Catlogs = catlogs(),
    %% Trees = build_right_tree(Catlogs, []),
    IdTree = build_tree_use_id(Catlogs, gb_trees:empty()),
    ActionTree = build_tree_use_action(Catlogs, gb_trees:empty()),

    
    
    %% ?DEBUG("right tree~n ~p", [Trees]),
    {ok, #right_trees{action_tree = ActionTree,
		      id_tree = IdTree,
		      pass_actions=
			  pass_action(saler) ++ pass_action(wholesaler)}}.

handle_call(lookup, _From, #right_trees{id_tree=GBTree} = State) ->
    %% Children =
    %% 	?tree:find_child(Trees, #diablo_node{id=?value(<<"id">>, Node)}),
    %% Format = ?tree:list([Children]),
    Iter = gb_trees:iterator(GBTree),
    Values = format_value(Iter),
    %% ?DEBUG("lookup with value ~p", [Values]),
    {reply, {ok, Values}, State};


handle_call(lookup_action, _From,
	    #right_trees{action_tree=ActionTree} = State) ->
    %% Children =
    %% 	?tree:find_child(Trees, #diablo_node{id=?value(<<"id">>, Node)}),
    %% Format = ?tree:list([Children]),
    %% Iter = gb_trees:iterator(ActionTree),
    %% Values = format_value(Iter),
    %% ?DEBUG("lookup with value ~p", [Values]),
    {reply, {ok, ActionTree}, State};

handle_call(lookup_super, _From, #right_trees{id_tree=GBTree} = State) ->
    %% Cares = ?ALL_CATLOGS -- [?right_merchant, ?right_right],
    %% normal user does not right to set merchant, print
    Cares = ?ALL_CATLOGS -- [?right_merchant, ?right_w_print],
    

    Iter = gb_trees:iterator(GBTree),
    Super = 
    	lists:foldr(
    	  fun(Key, Acc) ->		  
    		  Children = find_child(Iter, Key),
    		  Children ++ Acc
    	  end, [], Cares),
    
    ?DEBUG("lookup_super ~p", [Super]),
    {reply, {ok, Super}, State};

handle_call({children_include_node, Node}, _From, #right_trees{id_tree=GBTree} = State) ->
    %% ?DEBUG("find child_include_node of node ~p", [Node]),
    Iter = gb_trees:iterator(GBTree),
    Children = find_child(Iter, ?value(<<"id">>, Node)),
    {reply, {ok, Children}, State};


handle_call({children_only, Node}, _From, #right_trees{id_tree=GBTree} = State) ->
    ?DEBUG("find children_only of node ~p", [Node]),
    Iter = gb_trees:iterator(GBTree),
    All  = find_child(Iter, ?value(<<"id">>, Node)),
    Children = [{C} || {C} <- All, ?value(<<"id">>, C) =/= ?value(<<"id">>, Node)],
    {reply, {ok, Children}, State};


handle_call({root, Node}, _From, #right_trees{id_tree=GBTree} = State) ->
    %% ?DEBUG("get root of node ~p", [Node]),
    %% Root = ?tree:get_root(Trees, #diablo_node{id=?value(<<"id">>, Node)}),
    %% Format = ?tree:list([Root]),
    Root = find_root(GBTree, ?value(<<"id">>, Node)),
    {reply, {ok, Root}, State};


handle_call({get_action_id, ActionName},
	    _From, #right_trees{action_tree=ActionTree} = State) ->
    ?DEBUG("get_action_id of action ~p", [ActionName]),
    %% Root = ?tree:get_root(Trees, #diablo_node{id=?value(<<"id">>, Node)}),
    %% Format = ?tree:list([Root]),
    Reply = 
	case gb_trees:lookup(ActionName, ActionTree) of
	    {value, Value} ->
		node(id, Value);
	    none ->
		?DEBUG("action ~p id does not found", [ActionName]),
		none
	end,
    {reply, Reply, State};


handle_call({get_action_name, ActionId},
	    _From, #right_trees{id_tree=GBTree} = State) ->
    ?DEBUG("get_action_name with action id ~p", [ActionId]),
    %% Root = ?tree:get_root(Trees, #diablo_node{id=?value(<<"id">>, Node)}),
    %% Format = ?tree:list([Root]),
    Reply = 
	case gb_trees:lookup(ActionId, GBTree) of
	    {value, Value} ->
		node(action, Value);
	    none ->
		?DEBUG("action ~p id does not found", [ActionId]),
		none
	end,
    {reply, Reply, State};


handle_call(get_pass_action, _From,
	    #right_trees{pass_actions=Pass} = State) ->
    %% ?DEBUG("get pass action ~p", [Pass]),
    {reply, Pass, State};


%% handle_call(right_super, _From, State) ->
%%     Catlogs = catlogs(super) ++ funcs(super),
%%     {reply, Catlogs, State};

handle_call(_Request, _From, State) ->
    ?DEBUG("receive unkown request ~p", [_Request]),
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
build_tree_use_id([], Tree) ->
    Tree;
build_tree_use_id([Catlog|T], Tree) ->
    Node = #diablo_node{id     = ?value(<<"id">>, Catlog),
			name   = ?value(<<"name">>, Catlog),
			action = ?value(<<"action">>, Catlog), 
			parent = ?value(<<"parent">>, Catlog)
		       },
    build_tree_use_id(
      T, gb_trees:insert(?value(<<"id">>, Catlog), Node, Tree)).


build_tree_use_action([], Tree) ->
    Tree;
build_tree_use_action([Catlog|T], Tree) ->
    Node = #diablo_node{id     = ?value(<<"id">>, Catlog),
			name   = ?value(<<"name">>, Catlog),
			action = ?value(<<"action">>, Catlog), 
			parent = ?value(<<"parent">>, Catlog)
		       },
    build_tree_use_action(
      T, gb_trees:insert(?value(<<"action">>, Catlog), Node, Tree)).
    
    
%% build_right_tree([], Tree) ->
%%     Tree;
%% build_right_tree([Catlog|T], Tree) ->
%%     Node = #diablo_node{id     = ?value(<<"id">>, Catlog),
%% 			name   = ?value(<<"name">>, Catlog),
%% 			action = ?value(<<"action">>, Catlog), 
%% 			parent = ?value(<<"parent">>, Catlog)
%% 		       },
%%     NewTree = ?tree:make(Tree, Node),
%%     build_right_tree(T, NewTree).

set_catlog({Id, Name, Path}) ->
    set_catlog({Id, Name, Path, ?ROOT});
set_catlog({Id, Name, Path, Parent}) ->
    Sql1 = "select catlog_id, name, path from catlog where catlog_id="
	++ ?to_string(Id) ++ ";",
    case ?mysql:fetch(read, Sql1) of
	{ok, []} ->
	    Sql2 = "insert into catlog(catlog_id, name, path, parent) values("
		++ ?to_string(Id) ++ ","
		++ "\"" ++ ?to_string(Name) ++ "\","
		++ "\"" ++ ?to_string(Path) ++ "\","
		++ ?to_string(Parent) ++ ");",
	    {ok, _} = ?mysql:fetch(write, Sql2),
	    ok;
	{ok, _} ->
	    ok
    end.

set_fun({Id, Name, CallFun, Parent}) ->
    Sql1 = "select fun_id, name from funcs where fun_id="
	++ ?to_string(Id) ++ ";",
    case ?mysql:fetch(read, Sql1) of
	{ok, []} ->
	    Sql2 = "insert into funcs(fun_id, name, call_fun, catlog) values("
		++ ?to_string(Id) ++ ","
		++ "\"" ++ ?to_string(Name) ++ "\","
		++ "\"" ++ ?to_string(CallFun) ++ "\","
		++ ?to_string(Parent) ++ ");",
	    {ok, _} = ?mysql:fetch(write, Sql2),
	    ok;
	{ok, _} ->
	    ok
    end.


catlogs() ->
    catlogs([]) ++ funcs(super).

%% catlogs(super) ->
%%     %% super does not care merchant, shop, inventory
%%     Cares = ?ALL_CATLOGS -- [?right_member, ?right_shop],
%%     catlogs({<<"catlog_id">>, Cares});

catlogs(Conditions) ->
    ?DEBUG("conditions ~p", [Conditions]),
    Sql = "select catlog_id as id, name as name,"
	++ " path as action, parent as parent"
	++ " from catlog "
	++ " where "
	++  case Conditions of
		[] ->
		    "";
		Conditions->
		    ?utils:to_sqls(proplists, Conditions) ++ " and "
	    end
	++ " deleted = " ++ ?to_string(?NO)
	++ " order by parent desc;",
    {ok, Catlogs} = ?mysql:fetch(read, Sql),
    Catlogs.

funcs(super) ->
    Sql1 = "select a.fun_id as id, a.name as name, a.call_fun as action,"
	++ " a.catlog as parent"
	++ " from funcs a "
	++ " where deleted = " ++ ?to_string(?NO)
	++ " order by catlog desc;",
    {ok, Funcs} = ?mysql:fetch(read, Sql1),
    Funcs.

find_child(Iter, Id) ->
    find_child(Iter, Id, []).

find_child(Iter, Id, Acc) ->
    case gb_trees:next(Iter) of
	{K, #diablo_node{parent=Parent} = V, NextIter} ->
	    case K =:= Id orelse Parent =:= Id of
		true ->
		    find_child(NextIter, Id, [format(V)|Acc]);
		false ->
		    find_child(NextIter, Id, Acc)
	    end;
	none ->
	    lists:reverse(Acc)
    end.


%% 0 means root node
find_root(Tree, Id) ->
    find_root(Tree, Id, []).

find_root(_Tree, 0, Root) ->
    format(Root);
find_root(Tree, Id, _Root) ->
    case gb_trees:lookup(Id, Tree) of
	{value, #diablo_node{parent=Parent}=P} -> 
	    find_root(Tree, Parent, P);
	none ->
	    []
    end.

format_value(Iter) ->
    format_value(Iter, []).

format_value(Iter, Acc) ->
    case gb_trees:next(Iter) of
	{_K, V, NextIter} ->
	    format_value(NextIter, [format(V)|Acc]);
	none ->
	    lists:reverse(Acc)
    end.

format(#diablo_node{id=Id, name=Name, action=Action, parent=Parent} = _Node) ->
    {[{<<"id">>, Id},
      {<<"name">>, Name},
      {<<"action">>, Action},
      {<<"parent">>, Parent}]}.




node(id, #diablo_node{id=Id} = _N) ->
    Id;
node(name, #diablo_node{name=Name} = _N) ->
    Name;
node(action, #diablo_node{action=Action} = _N) ->
    Action;
node(parent, #diablo_node{parent=Parent} = _N) ->
    Parent;
node(children, #diablo_node{children=Children} = _N) ->
    Children.


pass_action(saler) ->
    [
     %% get a member by a certain number
     <<"get_member_by_number">>,
     %% list all the member
     <<"list_member">>,
     %% list the calog of the user
     <<"list_right_catlog">>,
     %% get the right catlog by a certain role id
     <<"get_right_by_role_id">>,
     %% get the shops of the role
     <<"get_shop_by_role">>,
     %% get the children of inventory
     <<"list_inventory_children">>,
     %% get the children of sales
     <<"list_sales_children">>,
     %% get the account role by a certain account id
     <<"list_account_right">>,

     %% login user
     %% <<"list_login_user_right">>,
     %% <<"list_login_user_shop">>,
     <<"get_login_user_info">>,

     %% about inventory
     <<"list_color">>,
     <<"list_brand">>,
     <<"list_unconnect_brand">>,
     <<"list_type">>,
     %% information of inventory of the merchant
     <<"list_inventory">>,
     <<"list_inventory_with_condition">>,
     %% <<"list_by_shop_and_size_group">>,
     <<"list_unchecked_inventory_group">>,
     <<"list_inventory_by_group">>,
     %% information of transferring inventory from one shop to another
     <<"list_move_inventory">>,
     %% information of inventory return to supplier
     <<"list_reject_inventory">>,
     <<"list_by_pagination">>,
     <<"get_total_inventories">>,
     <<"filter_inventory">>,

     %% about sale
     <<"list_style_number">>,
     <<"list_style_number_of_shop">>,
     <<"list_by_style_number_and_shop">>,
     <<"list_employe">>,
     <<"list_sale_info">>,
     <<"filter_sale_info">>,
     <<"list_sale_info_with_running">>,
     <<"list_reject_info">>,

     %% about size group
     <<"list_size_group">>,

     %% about supplier
     <<"list_supplier">> 
    ];
pass_action(wholesaler) ->
    [
     %%
     <<"list_w_province">>,
     <<"list_w_city">>,
     
     %% login user
     <<"get_login_user">>,
     <<"destroy_login_user">>,
     
     %% attribute
     <<"get_colors">>,
     <<"list_w_color">>,
     <<"list_color_type">>, 
     <<"list_w_size">>,

     %% good
     %% <<"list_w_good">>,
     <<"get_w_good">>,
     <<"get_used_w_good">>,
     <<"filter_w_good">>,
     <<"match_w_good">>,
     <<"match_all_w_good">>,
     <<"match_w_good_style_number">>,

     %% inventnory
     <<"list_w_inventory">>,
     <<"filter_w_inventory_group">>, 
     <<"match_w_inventory">>,
     <<"match_all_w_inventory">>,
     <<"match_all_reject_w_inventory">>,

     %% inventory new
     <<"get_w_inventory_new">>,
     <<"get_w_inventory_new_amount">>,
     <<"filter_w_inventory_new">>,
     <<"filter_w_inventory_new_rsn_group">>,
     <<"w_inventory_new_rsn_detail">>,

     %% inventnory reject 
     <<"filter_w_inventory_reject">>,
     <<"filter_w_inventory_reject_rsn_group">>,
     <<"w_inventory_reject_rsn_detail">>,
     
     %% inventory fix
     <<"filter_fix_w_inventory">>, 
     <<"filter_w_inventory_fix_rsn_group">>,
     <<"w_inventory_fix_rsn_detail">>,

     %% export
     <<"w_inventory_export">>,
     
     
     %% retailer
     <<"list_w_retailer">>,
     
     %% wsale
     %% <<"list_w_sale_new">>,
     <<"new_w_sale_draft">>,
     <<"list_w_sale_draft">>,
     <<"get_w_sale_draft">>,
     <<"get_last_sale">>,

     <<"filter_w_sale_new">>,
     <<"get_w_sale_new">>,
     <<"filter_w_sale_reject">>,
     <<"filter_w_sale_rsn_group">>,
     <<"w_sale_rsn_detail">>,
     <<"filter_w_sale_image">>,
     <<"w_sale_export">>,

     %% base_setting
     <<"list_w_bank_card">>,
     <<"list_base_setting">>,
     <<"update_base_setting">>,
     <<"add_base_setting">>,
     <<"add_shop_setting">>,

     %% print
     <<"list_w_printer">>, 
     <<"list_w_print_server">>,
     <<"test_w_printer">>,
     <<"list_w_printer_format">>,
     <<"update_w_printer_format">>,
     <<"add_w_printer_format_to_shop">>,

     %% firm
     <<"list_firm">>,

     <<"update_user_passwd">>,

     %% print
     <<"get_w_print_content">>

     %% shop
     %% <<"list_repo">>
    ].
