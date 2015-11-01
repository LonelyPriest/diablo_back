%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 30 Oct 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_controller_authen).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_server).

-export([authen/2, authen/3]).
-export([navbar/1, navbar/2, lookup/0]).
-export([catlog/2, get_user_shop/1]).
-export([cache/2, lookup/1, find/2]).

%% API
-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-define(SERVER, ?MODULE). 


-record(func_tree,
	{tree   :: gb_tree(),
	 rights :: dict() %% cache the current user's right
	}).

%%%===================================================================
%%% API
%%%===================================================================

%% =============================================================================
%% @desc: get the navbar form session
%% =============================================================================
navbar(super) ->
    gen_server:call(?SERVER, {navbar, super}).
navbar(session, Session) ->
    UserId = ?session:get(id, Session),
    gen_server:call(?SERVER, {navbar, UserId});
navbar(user, UserId) ->
    gen_server:call(?SERVER, {navbar, UserId}).

catlog(session, Session) ->
    UserId = ?session:get(id, Session),
    catlog(user, UserId);
catlog(user, UserId) ->
    gen_server:call(?SERVER, {user_right, UserId});
catlog(role, RoleId) when is_integer(RoleId) ->
    %% ?DEBUG("catlog role ~p", [RoleId]),
    gen_server:call(?SERVER, {role_right, [RoleId]});
catlog(role, RoleIds) ->
    %% ?DEBUG("catlog roles ~p", [RoleIds]),
    gen_server:call(?SERVER, {role_right, RoleIds}).

get_user_shop(Session) ->
    UserId = ?session:get(id, Session),
    gen_server:call(?SERVER, {get_user_shop, UserId}).

authen(FunId, Session) ->
    UserId = ?session:get(id, Session),
    gen_server:call(?SERVER, {authen_id, FunId, UserId}).

authen(action, Action, Session) ->
    UserId = ?session:get(id, Session),
    gen_server:call(?SERVER, {authen_action, Action, UserId});
authen(user, Action, UserId) ->
    gen_server:call(?SERVER, {authen_action, Action, UserId}).


lookup() ->
    gen_server:call(?SERVER, lookup).


cache(right, UserId) ->
    gen_server:call(?SERVER, {cache_right, UserId}).
lookup(right) ->
    gen_server:call(?SERVER, lookup_right).
find(right, UserId) ->
    gen_server:call(?SERVER, {find_right, UserId}).

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

init([]) ->
    Empty = gb_trees:empty(),

    Funcs = 
	[{?right_sale,      {"/sale",      "销售",     ?sale_request}},
	 {?right_member,    {"/member",    "会员",     ?member_request}},
	 {?right_shop,      {"/shop",      "店铺",     ?shop_request}},
	 {?right_merchant,  {"/merchant",  "商家",     ?merchant_request}},
	 {?right_employe,   {"/employ",    "员工",     ?employ_request}},
	 {?right_inventory, {"/inventory", "库存",     ?inventory_request}},
	 {?right_right,     {"/right",     "权限",     ?right_request}},
	 {?right_supplier,  {"/supplier",  "供应商",   ?supplier_request}},

	 %% about whole sale
	 {?right_w_sale,       {"/wsale",     "销售",   ?w_sale_request}}, 
	 {?right_w_firm,       {"/firm",      "厂商",   ?firm_request}}, 
	 {?right_w_inventory,  {"/purchaser", "采购",   ?w_inventory_request}},
	 {?right_w_retailer,   {"/wretailer", "零售商", ?w_retailer_request}}, 
	 {?right_w_print,      {"/wprint",    "打印",   ?w_print_request}}, 
	 {?right_w_good,       {"/wgood",     "货品",   ?w_good_request}}, 
	 {?right_w_report,     {"/wreport",   "报表",   ?w_report_request}}, 
	 %% base setting
	 {?right_w_base,       {"/wbase",     "设置",   ?w_base_request}}
	],

    Tree = 
	lists:foldl(
	  fun({K, V}, Acc) ->
		  T = gb_trees:insert(K, V, Acc),
		  T
	  end, Empty, Funcs),

    
    %% Tree = gb_trees:from_orddict(Funcs),
    {ok, #func_tree{tree  = Tree,
		    rights = dict:new()}}.

handle_call(lookup, _From, #func_tree{tree=Tree} = State) ->
    {reply, Tree, State};

handle_call({navbar, super}, _From, #func_tree{tree=Tree} = State) ->
    %% super only have merchant and right menu
    RootKeys = [?right_merchant, ?right_right, ?right_w_print],
    Navs = 
	lists:foldr(
	  fun(Root, Acc) ->
		  [gb_trees:get(Root, Tree)|Acc]
	  end,[], RootKeys),
    ?DEBUG("navs ~p", [Navs]),
    {reply, Navs, State};

handle_call({navbar, UserId}, _From, #func_tree{tree=Tree} = State) ->
    ?DEBUG("navbar with UserId ~p", [UserId]),
    %% first, get login user role
    RoleIds = get_roles(by_user, UserId),

    %% second, get right of thd role
    {ok, RightIds} = ?right:lookup_role_right({<<"role_id">>, RoleIds}),
    ?DEBUG("RightIds ~p", [RightIds]),
    
    Roots = 
	lists:foldr(
	  fun({RightId}, Acc) ->
		  %% only one root node in the tree
		  case ?right_init:get_root(RightId) of
		      {ok, []} ->
			  Acc;
		      {ok, Root} ->
			  case lists:member(Root, Acc) of
			      true  -> Acc;
			      false -> [Root|Acc]
			  end
		  end
	  end, [], RightIds), 
    ?DEBUG("Roots ~p", [Roots]),


    %% order right
    OrderRoots = [?right_w_sale, ?right_w_inventory, ?right_w_good,
		  ?right_sale, ?right_inventory, ?right_member,
		  ?right_employe, ?right_shop, ?right_w_firm,
		  ?right_supplier, ?right_w_retailer, ?right_w_report,
		  ?right_right
		  %% ?right_w_base
		 ], 
    ?DEBUG("OrderRoots ~p", [OrderRoots]),

    OrderRights = order_root(OrderRoots, ?to_tl(Roots)),
    ?DEBUG("OrderRights ~p", [OrderRights]),

    %% get root navbar
    Navs = 
	lists:foldr(
	  fun({Root}, Acc) ->
		  %% [gb_trees:get(?value(<<"id">>, Root), Tree)|Acc] 
		  RId = ?v(<<"id">>, Root),
		  {Href, Name, Module} = gb_trees:get(RId, Tree),

		  %% mobile hidden when xs, sm
		  case RId =:= ?right_shop
		      orelse RId =:= ?right_employe
		      orelse RId =:= ?right_right of
		      true ->  [{Href, Name, Module, true}|Acc];
		      false ->[{Href, Name, Module, false}|Acc]
		  end 
	  end,[], OrderRights),
    ?DEBUG("navs ~p", [Navs]),
    

    {reply, Navs, State};
    

handle_call({user_right, UserId}, _From, State) ->
    ?DEBUG("user_right with userid ~p", [UserId]),
    Roles = ?right:lookup_account_right({<<"user_id">>, ?to_i(UserId)}),
    RoleIds =
	lists:foldr(
	  fun({Role}, Acc)->
		  [?value(<<"role_id">>, Role)|Acc]
	  end, [], ?to_tl(Roles)),
    {ok, Catlogs} = catlogs(role, RoleIds),
    {reply, Catlogs, State};

handle_call({role_right, RoleIds}, _From, State) ->
    ?DEBUG("role_right with roleId ~p", [RoleIds]),
    {ok, Catlogs} = catlogs(role, RoleIds),
    {reply, Catlogs, State};


handle_call({get_user_shop, UserId}, _From, State) ->
    ?DEBUG("get_user_shop with UserId ~p", [UserId]),
    RoleIds = get_roles(by_user, UserId),
    Shops = ?right:lookup_role_shop({<<"role_id">>, RoleIds}),
    {reply, Shops, State};

handle_call({authen_action, Action, UserId}, _From,
	    #func_tree{rights = Rights} = State) ->
    ?DEBUG("authen action ~p  of user ~p", [Action, UserId]),
    %% Reply = 
    %% 	case ?right_init:get_action_id(Action) of
    %% 	    none ->
    %% 		{error, ?err(function_not_found, Action)};
    %% 	    FunId ->
    %% 		case authen_funcion(FunId, UserId) of
    %% 		    []   ->
    %% 			{error, ?err(not_enought_right, FunId)};
    %% 		    Find ->
    %% 			?DEBUG("find valid right ~p", [Find]),
    %% 			{ok, FunId}
    %% 		end
    %% 	end,
    PassActions = ?right_init:get_pass_action(),

    case lists:member(?to_b(Action), PassActions) of
	true  ->
	    {reply, {ok, Action}, State};
	false ->
	    case dict:find(UserId, Rights) of
	    {ok, UserTree} ->
		    case gb_trees:lookup(?to_binary(Action), UserTree) of
			none       ->
			    {reply,
			     {error, ?err(not_enought_right, Action)}, State};
			{value, V} ->
			    ?DEBUG("~p found of action ~p", [V, Action]),
			    {reply, {ok, Action}, State}
		    end;
		error ->
		    {reply, {error, ?err(not_enought_right, Action)}, State}
	    end
    end;    

handle_call({authen_id, ActionId, UserId}, _From,
	    #func_tree{rights = Rights} = State) ->
    ?DEBUG("authen action with Id ~p  of user ~p", [ActionId, UserId]),
    %% ?DEBUG("Children ~p", [Children]),

    %% Reply = 
    %% 	case authen_funcion(FunId, UserId) of
    %% 	    []   ->
    %% 		{error, ?err(not_enought_right, FunId)};
    %% 	    Find ->
    %% 		?DEBUG("find valid right ~p", [Find]),
    %% 		{ok, FunId}
    %% 	end,

    %% {reply, Reply, State},

    Reply = 
	case ?right_init:get_action(name, ActionId) of
	    none ->
		?DEBUG("action with id ~p does not found", [ActionId]),
		{error, ?err(function_not_found, ActionId)};
	    Action ->
		case dict:find(UserId, Rights) of
		    {ok, UserTree} ->
			case gb_trees:lookup(Action, UserTree) of
			    none ->
				?DEBUG("action with name ~p does not found",
				       [Action]),
				{error, ?err(not_enought_right, Action)};
			    {value, V} ->
				?DEBUG("action ~p of id ~p found",
				       [V, Action]),
				{ok, ActionId}
			end;
		    error ->
			%% user tree not found
			?DEBUG("action with id ~p with user ~p does not found",
			       [ActionId, UserId]),
			{error, ?err(user_not_found, UserId)}
		end
	end,
    {reply, Reply, State};
	


handle_call({cache_right, UserId}, _From,
	    #func_tree{rights = Rights} =  State) ->
    RoleIds = get_roles(by_user, UserId),

    {ok, RightIds} = ?right:lookup_role_right({<<"role_id">>, RoleIds}),

    Children = 
	lists:foldr(
	  fun({RightId}, Acc)->
		  {ok, C} = ?right_init:get_children(RightId),
		  C ++ Acc
	  end, [], ?to_tuplelist(RightIds)),
    ?DEBUG("Children ~p", [Children]),


    Right = 
	lists:foldr(
	  fun(Child, Acc) ->
		  gb_trees:insert(?value(<<"action">>, Child), Child, Acc)
	  end, gb_trees:empty(), Children),

        
    {reply, ok,  State#func_tree{rights = dict:store(UserId, Right, Rights)}};



handle_call(lookup_right, _From, #func_tree{rights = Rights} =  State) ->    
    {reply, Rights,  State};


handle_call({find_right, UserId}, _From, #func_tree{rights = Rights} =  State) ->
    case dict:find(UserId, Rights) of
	{ok, Value} ->
	    {reply, Value,  State};
	error ->
	    {reply, error,  State}
    end;

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
catlogs(role, RoleIds) ->
    {ok, RightIds} = ?right:lookup_role_right({<<"role_id">>, RoleIds}),
    ?DEBUG("RightIds ~p", [RightIds]),
    
    Children = 
	lists:foldr(
	  fun({RightId}, Acc)->
		  {ok, C} = ?right_init:get_children(RightId),
		  C ++ Acc
	  end, [], ?to_tl(RightIds)),
    %% ?DEBUG("Children ~p", [Children]),

    {ok, AllRight} = ?right_init:lookup(),

    Parents = 
	lists:foldr(
	  fun({Right}, Acc) ->
		  case find_parent(Right, AllRight, []) of
		      [] -> Acc;
		      [P] ->
			  case lists:member(P, Acc) of
			      true -> Acc;
			      false ->
				  case lists:member(P, Children) of
				      true -> Acc;
				      false -> [P|Acc]
				  end
			  end
		  end
	  end, [], Children),
    ?DEBUG("parents ~p", [Parents]),
    {ok, Parents ++ Children}. 


find_parent(Node, Catlogs, Acc) ->
    Parent = 
	lists:foldr(
	  fun({Catlog}, Acc0) ->
		  case ?value(<<"parent">>, Node) =:= ?value(<<"id">>, Catlog) of
		      true -> [{Catlog}|Acc0];
		      false -> Acc0
		  end
	  end, [], Catlogs),
    case Parent of
	[] ->
	    Acc;
	[P] ->
	     case lists:member(P, Acc) of
		true  -> Acc;
		false ->
		     find_parent(P, Catlogs, [P|Acc])
	     end
	end.


get_roles(by_user, UserId) ->
    Roles = ?right:lookup_account_right({<<"user_id">>, ?to_i(UserId)}),
    RoleIds = lists:foldr(
		fun({Role}, Acc)->
			[?v(<<"role_id">>, Role)|Acc]
		end, [], ?to_tl(Roles)),

    ?DEBUG("RoleIds ~p", [RoleIds]),
    RoleIds.
    
%% authen_funcion(FunId, UserId) ->
%%     Roles = ?right:lookup_account_right({<<"user_id">>, UserId}),

%%     RoleIds =
%% 	lists:foldr(
%% 	  fun({Role}, Acc)->
%% 		  [?value(<<"role_id">>, Role)|Acc]
%% 	  end, [], ?to_tuplelist(Roles)),
    
%%     RightIds = ?right:lookup_role_right({<<"role_id">>, RoleIds}),

%%     Result  = 
%% 	lists:foldr(
%% 	  fun({RightId}, Acc)->
%% 		  {ok, C} = ?right_init:get_children(RightId),
%% 		  case lists:filter(
%% 			 fun({V}) -> ?value(<<"id">>, V) =:= FunId end, C) of
%% 		      [] ->  Acc;
%% 		      L  -> L ++ Acc
%% 		  end
%% 	  end, [], ?to_tuplelist(RightIds)),

%%     ?DEBUG("authen result ~p", [Result]),
%%     Result.

order_root(Orders, Currents) ->
    order_root(Orders, Currents, []).
order_root([], _Currents, Acc) ->
    lists:reverse(Acc);
order_root([H|T], Currents, Acc) -> 
    case  [ {[{<<"id">>, Id}]} || {[{<<"id">>, Id}|_]} <- Currents, Id =:= H] of
	[] ->
	    order_root(T, Currents, Acc);
	[Order] ->
	    order_root(T, Currents, [Order|Acc])
    end.
