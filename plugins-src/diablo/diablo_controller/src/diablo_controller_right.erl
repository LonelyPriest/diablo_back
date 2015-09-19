%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 17 Sep 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_controller_right). 

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_server).

%% API
-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-export([right/2, right/3]).
-export([lookup_account/1,
	 lookup_account_right/1,
	 lookup_role_right/1,
	 lookup_role_shop/1]).

-export([get/2]).

-define(SERVER, ?MODULE). 
-define(tbl_merchant, "merchants").


-record(state, {}).

%%%===================================================================
%%% API
%%%===================================================================
%% role
right(new_role, Attrs) ->
    gen_server:call(?MODULE, {new_role, Attrs});
right(update_role, Attrs) ->
    gen_server:call(?MODULE, {update_role, Attrs});
right(new_user_role, Attrs) ->
    gen_server:call(?MODULE, {new_user_role, Attrs});
right(update_user_role, Attrs) ->
    gen_server:call(?MODULE, {update_user_role, Attrs});
right(list_role, Condition) ->
    gen_server:call(?MODULE, {list_role, Condition});
right(role, RoleId) ->
    gen_server:call(?MODULE, {right_by_role, RoleId});

%% account
right(new_account, Attrs) ->
    gen_server:call(?MODULE, {new_account, Attrs}).
right(update_account_role, Account, NewRole) ->
    gen_server:call(?MODULE, {update_account_role, Account, NewRole});
right(update_account_passwd, Account, Attrs) ->
    gen_server:call(?MODULE, {update_account_passwd, Account, Attrs});
right(delete_account, Account, AccountType) ->
    gen_server:call(?MODULE, {delete_account, Account, AccountType}).


get(account, Merchant) ->
    gen_server:call(?MODULE, {get_account, Merchant});
get(merchant_account, Merchant) ->
    gen_server:call(?MODULE, {get_merchant_account, Merchant}).

%% right(update, Condition, Fields) ->
%%     gen_server:call(?MODULE, {update_merchant, Condition, Fields}).


%% right(new_shopowner, Role, Merchant, Attrs) ->
%%     gen_server:call(?MODULE, {new_shopowner, Role, Merchant, Attrs}).

lookup_account(Condition) ->
    gen_server:call(?MODULE, {lookup_account, Condition}).
lookup_account_right(Condition) ->
    gen_server:call(?MODULE, {lookup_account_right, Condition}).
lookup_role_right(Condition) ->
    gen_server:call(?MODULE, {lookup_role_right, Condition}).

lookup_role_shop(Condition) ->
    gen_server:call(?MODULE, {lookup_role_shop, Condition}).

%% lookup(Condition) ->
%%     gen_server:call(?MODULE, {lookup, Condition}).


start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
init([]) ->
    {ok, #state{}}.

handle_call({new_role, Attrs}, _From, State)->
    ?DEBUG("new role with attrs ~p", [Attrs]),
    Name      = ?value(<<"name">>, Attrs),
    Type      = ?value(<<"type">>, Attrs),
    Desc      = ?value(<<"desc">>, Attrs, "null"),
    Keys      = ?value(<<"fun_id">>, Attrs),
    CreatedBy = ?value(<<"created_by">>, Attrs),
    
    Sql = "select id, name from roles"
	++ " where name = " ++ "\"" ++ ?to_string(Name) ++ "\""
	++ " and deleted = " ++ ?to_string(?NO) ++ ";",
    case ?sql_utils:execute(s_read, Sql) of
	{ok, []}->
	    Sql1 = "insert into roles(name, remark, type, created_by"
		++ ",create_date) values("
		++ "\"" ++ ?to_string(Name) ++ "\","
		++ "\"" ++ ?to_string(Desc) ++ "\","
		++ ?to_string(Type) ++ ","
		++ ?to_string(CreatedBy) ++ ","
		++ "\"" ++ ?utils:current_time(localtime) ++ "\");",
	    {ok, NewRoleId} = ?sql_utils:execute(insert, Sql1),

	    %% at here, impossible to empty
	    %% {ok, {NewRole}} = ?mysql:fetch(read, Sql),
	    %% NewRoleId = ?value(<<"id">>, NewRole),

	    %% role to right tree
	    Sqls = 
		lists:foldr(
		  fun(RightId, Acc) ->
			  ["insert into role_to_right(role_id, right_id)" ++
			       " values("
			  ++ ?to_string(NewRoleId) ++ ","
			  ++ ?to_string(RightId) ++ ")"|Acc]
		  end, [], Keys),

	    
	    ?DEBUG("new role sql ~p", [Sqls]),
	    Reply = ?sql_utils:execute(transaction, Sqls, Name),
	    {reply, Reply, State};
	    
	{ok, _Any} ->
	    ?DEBUG("role ~p has been exist", [Name]),
	    {reply, {error, ?err(role_exist, Name)}, State};
	Error ->
	    {reply, Error, State}
    end;

handle_call({update_role, Attrs}, _From, State) ->
    ?DEBUG("update role with attrs ~p", [Attrs]),
    RoleId   = ?value(<<"role_id">>, Attrs),
    Added    = ?value(<<"added">>, Attrs, []),
    Deleted  = ?value(<<"deleted">>, Attrs, []),

    Current = 
	case Added of
	    [] -> [];
	    Added ->
		Sql0 = "select right_id from role_to_right"
		    ++ " where role_id=" ++ ?to_s(RoleId) ++ " and  "
		    ++ ?utils:to_sqls(proplists, {<<"right_id">>, Added}) ++ ";",
		case ?mysql:fetch(read, Sql0) of
		    {ok, []} -> [];
		    {ok, Olds} ->
			lists:foldr(
			  fun({Old}, Acc) ->
				  [?value(<<"right_id">>, Old)|Acc]
			  end, [], ?to_tl(Olds)) 
		end
	end,
    
    Sql1 =
	case Deleted of
	    [] -> [];
	    Deleted ->
		["update role_to_right set deleted=" ++ ?to_s(?YES)
		    ++ " where role_id=" ++ ?to_s(RoleId)
		    ++ " and "
		 ++ ?utils:to_sqls(proplists, {<<"right_id">>, Deleted})]
	end,

    Sql2 =
	lists:foldr(
	  fun(RightId, Acc) ->
		  ["insert into role_to_right(role_id, right_id)" ++
		       " values("
		   ++ ?to_s(RoleId) ++ ","
		   ++ ?to_s(RightId) ++ ");"|Acc]
	  end, [], Added -- Current)
	++
	case Current of
	    [] -> [];
	    Current ->
		["update role_to_right set deleted=" ++ ?to_s(?NO)
		 ++ " where role_id=" ++ ?to_s(RoleId)
		 ++ " and "
		 ++ ?utils:to_sqls(proplists, {<<"right_id">>, Current})]
	end,

    Sqls = Sql1 ++ Sql2,
    ?DEBUG("new role sql ~p", [Sqls]),
    {ok, _} = ?mysql:fetch(transaction, Sqls),
    {reply, {ok, RoleId}, State};


handle_call({update_user_role, Attrs}, _From, State) ->
    ?DEBUG("update user role with attrs~n~p", [Attrs]),
    RoleId      = ?value(<<"role_id">>, Attrs),
    AddRight    = ?value(<<"add_right">>, Attrs, []),
    DeleteRight = ?value(<<"delete_right">>, Attrs, []),
    AddShops = lists:foldr(
		 fun({struct, R}, Acc)->
			 Shop = ?value(<<"shop">>, R),
			 Op   = ?value(<<"operation">>, R),
			 [{Shop, Op}|Acc]
		 end, [], ?value(<<"add_shops">>, Attrs, [])),

    DeleteShops = ?value(<<"delete_shops">>, Attrs, []),
    
    %% rights
    Current = 
	case AddRight of
	    [] -> [];
	    AddRight ->
		Sql0 = "select right_id from role_to_right"
		    ++ " where role_id=" ++ ?to_s(RoleId)
		    ++ " and deleted=" ++ ?to_s(?YES)
		    ++ " and "
		    ++ ?utils:to_sqls(proplists, {<<"right_id">>, AddRight})
		    ++ ";",
		case ?mysql:fetch(read, Sql0) of
		    {ok, []} -> [];
		    {ok, Olds} ->
			lists:foldr(
			  fun({Old}, Acc) ->
				  [?value(<<"right_id">>, Old)|Acc]
			  end, [], ?to_tl(Olds)) 
		end
	end,

    Sql1 =
	case DeleteRight of
	    [] -> [];
	    Deleted ->
		["update role_to_right set deleted=" ++ ?to_s(?YES)
		 ++ " where role_id=" ++ ?to_s(RoleId)
		 ++ " and "
		 ++ ?utils:to_sqls(proplists, {<<"right_id">>, Deleted})]
	end,
    %% ?DEBUG("Sq1 ~ts", [Sql1]),
    
    Sql2 =
	lists:foldr(
	  fun(RightId, Acc) ->
		  ["insert into role_to_right(role_id, right_id)" ++
		       " values("
		   ++ ?to_s(RoleId) ++ ","
		   ++ ?to_s(RightId) ++ ");"|Acc]
	  end, [], AddRight -- Current)
	++
	case Current of
	    [] -> [];
	    Current ->
		["update role_to_right set deleted=" ++ ?to_s(?NO)
		 ++ " where role_id=" ++ ?to_s(RoleId)
		 ++ " and "
		 ++ ?utils:to_sqls(proplists, {<<"right_id">>, Current})]
	end,
    %% ?DEBUG("Sq2 ~ts", [Sql2]),

    %% shops    
    HasDeletedShops =
	case AddShops of
	    [] -> [];
	    AddShops ->				
		%% deleted right to shop
		Sql01 = "select func_id as operation, shop_id as shop from role_to_shop"
		    ++ " where role_id=" ++ ?to_s(RoleId)
		    ++ " and deleted=" ++ ?to_s(?YES) ++ ";",
		case ?mysql:fetch(read, Sql01) of
		    {ok, []} -> [];
		    {ok, OldShopRights} ->
			lists:foldr(
			  fun({R}, Acc) ->
				  Shop = ?value(<<"shop">>, R),
				  Op   = ?value(<<"operation">>, R),
				  [{Shop, Op}|Acc]
			  end, [], ?to_tl(OldShopRights))
		end
	end,

    Sql3 = case DeleteShops of
	       [] -> [];
	       DeleteShops ->
		   lists:foldr(
		     fun({struct, R}, Acc) ->
			     Shop = ?value(<<"shop">>, R),
			     Op   = ?value(<<"operation">>, R),
			     ["update role_to_shop set deleted=" ++ ?to_s(?YES)
			      ++ " where role_id=" ++ ?to_s(RoleId)
			      ++ " and shop_id=" ++ ?to_s(Shop)
			      ++ " and func_id=" ++ ?to_s(Op) ++ ";"|Acc]
		     end, [], DeleteShops) 
	   end,
    %% ?DEBUG("Sq3 ~ts", [Sql3]),
    
    Sql4 =	
	lists:foldr(
	  fun({Shop, Op}, Acc) ->
		  ["insert into role_to_shop(role_id, shop_id, func_id) values("
		   ++ ?to_s(RoleId) ++ ","
		   ++ ?to_s(Shop) ++ ","
		   ++ ?to_s(Op) ++  ");"|Acc]
	  end, [], AddShops -- HasDeletedShops)
	++
	lists:foldr(
	  fun({Shop, Op}, Acc) ->
		  ["update role_to_shop set deleted=" ++ ?to_s(?NO)
		   ++ " where role_id=" ++ ?to_s(RoleId)		   
		   ++ " and shop_id=" ++ ?to_s(Shop)
		   ++ " and func_id=" ++ ?to_s(Op) ++ ";"|Acc]
	  end, [], HasDeletedShops),
    %% ?DEBUG("Sq4 ~ts", [Sql4]),
	
    
    Sqls = Sql1 ++ Sql2 ++ Sql3 ++ Sql4,
    ?DEBUG("new role sql~n~ts", [Sqls]),
    {ok, _} = ?mysql:fetch(transaction, Sqls),
    {reply, {ok, RoleId}, State};
    

handle_call({new_user_role, Attrs}, _From, State)->
    ?DEBUG("new_user_role with attrs ~p", [Attrs]),
    Merchant  = ?v(<<"merchant">>, Attrs),
    Name      = ?v(<<"name">>, Attrs),
    Type      = ?v(<<"type">>, Attrs),
    Desc      = ?v(<<"desc">>, Attrs, ""),
    Keys      = ?v(<<"fun_id">>, Attrs),
    CreatedBy = ?v(<<"created_by">>, Attrs),
    Shops     = ?v(<<"shops">>, Attrs, []),

    Sql = "select id, name from roles"
	++ " where "
	++ " name=" ++ "\"" ++ ?to_s(Name) ++ "\""
	++ " and merchant=" ++ ?to_s(Merchant)
	++ " and deleted =" ++ ?to_s(?NO) ++ ";",

    case Shops of
	[] ->
	    {reply, {error, ?err(role_empty_shop, Merchant)}, State};
	Shops -> 
	    case ?sql_utils:execute(s_read, Sql) of
		{ok, []}->
		    Sql1 = "insert into roles(name, remark, type, merchant, created_by"
			",create_date) values("
			++ "\"" ++ ?to_s(Name) ++ "\","
			++ "\"" ++ ?to_s(Desc) ++ "\","
			++ ?to_s(Type) ++ ","
			++ ?to_s(Merchant) ++ ","
			++ ?to_s(CreatedBy) ++ ","
			++ "\"" ++ ?utils:current_time(localtime) ++ "\");",
		    {ok, NewRole} = ?sql_utils:execute(insert, Sql1), 

		    %% role to right tree
		    Sqls = 
			lists:foldr(
			  fun(RightId, Acc) ->
				  ["insert into role_to_right(role_id, right_id, merchant)" ++
				       " values("
				   ++ ?to_s(NewRole) ++ ","
				   ++ ?to_s(RightId) ++ ","
				   ++ ?to_s(Merchant) ++ ");"|Acc]
			  end, [], Keys),

		    Transaction = 
			lists:foldr(
			  fun({struct, Shop}, Acc) ->
				  ["insert into role_to_shop("
				   ++ "role_id, shop_id, func_id, merchant)"
				   ++ " values("
				   ++ ?to_s(NewRole) ++ ","
				   ++ ?to_s(?v(<<"shop">>, Shop)) ++ ","
				   ++ ?to_s(?v(<<"operation">>, Shop)) ++ ","
				   ++ ?to_s(Merchant)++ ")"|Acc]
			  end, Sqls, Shops),

		    Reply = ?sql_utils:execute(transaction, Transaction, Name),
		    {reply, Reply, State};
		{ok, _Any} ->
		    %% ?DEBUG("role ~p has been exist", [Name]),
		    {reply, {error, ?err(role_exist, Name)}, State};
		Error ->
		    {reply, Error, State} 
	    end 
    end;

handle_call({list_role, Condition}, _From, State) ->
    ?DEBUG("list_role with condtion ~p", [Condition]),
    Sql = "select a.id, a.name, a.remark, a.type, a.create_date"
	++ ", b.name as created_by"
	++ ", c.name as merchant"
	++ " from roles a"
	++ " left join users b on a.created_by = b.id"
	++ " left join merchants c on b.merchant = c.id"
	++ " where "
	++ case Condition of
	       [] -> "";
	       Condition ->
		   ?utils:to_sqls(
		      proplists, ?utils:correct_condition(<<"a.">>, Condition))
		       ++ " and "
	   end
	++ "a.deleted=" ++ ?to_string(?NO) ++ ";",
    {ok, Roles} = ?mysql:fetch(read, Sql),
    {reply, {ok, Roles}, State};


handle_call({right_by_role, RoleId}, _From, State) ->
    ?DEBUG("right_by_role with RoleId ~p", [RoleId]),
    Sql = "select a.right_id as id, b.name, b.catlog as parent"
	++" from role_to_right a"
	++" left join funcs b on a.right_id = b.fun_id"
	++" where a.role_id=" ++ ?to_string(RoleId)
	++" and a.deleted=" ++ ?to_string(?NO),
    {ok, RightIds} = ?mysql:fetch(read, Sql),
    {reply, {ok, RightIds}, State};

handle_call({new_account, Attrs}, _From, State)->
    ?DEBUG("new merchant with attrs ~p", [Attrs]),
    Name      = ?v(<<"name">>, Attrs),
    Password  = ?v(<<"password">>, Attrs),
    UserType  = ?v(<<"type">>, Attrs),
    Role      = ?v(<<"role">>, Attrs),
    Merchant  = ?v(<<"merchant">>, Attrs),
    MaxCreate = ?v(<<"max_create">>, Attrs, -1),
    
    %% name should be unique in system
    Sql = "select id, name"
	++ " from users" 
	++ " where "
	++ " name = " ++ "\"" ++ ?to_s(Name) ++ "\""
	++ " and deleted=" ++ ?to_s(?NO) ++ ";",
	
    case ?sql_utils:execute(s_read, Sql) of
	{ok, []} -> 
	    %% first to users
	    Sql1 = "insert into users"
		++ "(name, password, type, merchant, max_create, create_date)"
		++ " values ("
		++ "\"" ++ ?to_s(Name) ++ "\","
		++ "\"" ++ ?to_s(Password) ++ "\","
		++ ?to_s(UserType) ++ ","
		++ ?to_s(Merchant) ++","
		++ ?to_s(MaxCreate) ++ ","
		++ "\"" ++ ?utils:current_time(localtime) ++ "\");",
		
	    %% ?DEBUG("sql to users ~p", [Sql1]),
	    %% {ok, _} = ?mysql:fetch(write, Sql1),

	    %% %% %% get user id
	    %% {ok, {Account}} = ?mysql:fetch(read, Sql),
	    %% UserId = ?v(<<"id">>, Account),

	    Sql2 = "insert into user_to_role"
	    	++ "(user_id, role_id) select id as user_id, " ++ ?to_s(Role)
		++ " from users where name=" ++ "\'" ++ ?to_s(Name) ++ "\'"
		++ " and deleted=" ++ ?to_s(?NO) ++ ";",
	    	%% ++ " values ("
	    	%% ++ ?to_s(UserId) ++ ","
	    	%% ++  ?to_s(Role) ++ ");",
	    
	    %% ?DEBUG("sql to user_to_role ~p", [Sql2]),
	    %% {ok, _} = ?mysql:fetch(write, Sql2),

	    Reply = ?sql_utils:execute(transaction, [Sql1, Sql2], Name),
	    {reply, Reply, State}; 
	{ok, _Any} ->
	    ?DEBUG("account ~p has been exist", [Name]),
	    {reply, {error, ?err(account_exist, Name)}, State};
	Error ->
	    {reply, Error, State}
    end;

handle_call({update_account_role, Account, NewRole}, _From, State) ->
    ?DEBUG("update_account_role with account ~p, newRole ~p",
	   [Account, NewRole]),
    Sql = "update user_to_role set role_id=" ++ ?to_s(NewRole)
	++ " where user_id=" ++ ?to_s(Account)
	++ " and deleted=" ++ ?to_s(?NO) ++ ";",
    Reply = ?sql_utils:execute(write, Sql, Account),
    {reply, Reply, State};

handle_call({update_account_passwd, Account, Attrs}, _From, State) ->
    ?DEBUG("update_account_passwd with account ~p, attrs ~p", [Account, Attrs]), 
    Oldp = ?v(<<"oldp">>, Attrs),
    Newp = ?v(<<"newp">>, Attrs),
    Sql0 = "select id, name from users"
	++ " where name=" ++ "\'" ++ ?to_s(Account) ++ "\'"
	++ " and password=" ++ "\'" ++ ?to_s(Oldp) ++ "\'"
	++ " and deleted=" ++ ?to_s(?NO),
    case ?sql_utils:execute(s_read, Sql0) of
	{ok, []} ->
	    {reply, {error, ?err(base_invalid_update_passwd, Account)}, State};
	{ok, User} ->
	    Sql = "update users set password=" ++ "\'" ++ ?to_s(Newp) ++ "\'"
		++ " where id=" ++ ?to_s(?v(<<"id">>, User)),
	    ?DEBUG("sql ~p", [Sql]),
	    Reply = ?sql_utils:execute(write, Sql, Account),
	    {reply, Reply, State}
    end;


handle_call({delete_account, Account, Type}, _From, State) ->
    ?DEBUG("delete_account with account ~p, type ~p", [Account, Type]),
    Sql = "update users set deleted=" ++ ?to_s(?YES)
	++ " where id=" ++ ?to_s(Account)
	++ " and type=" ++ ?to_s(Type),
    Reply = ?sql_utils:execute(write, Sql, Account),
    {reply, Reply, State}; 
	    

handle_call({lookup_account, Condition}, _From, State) ->
    ?DEBUG("lookup account with Condition ~p", [Condition]),
    Accounts = account(Condition),
    {reply, Accounts, State};


handle_call({lookup_account_right, Condition}, _From, State) ->
    ?DEBUG("lookup_account_right with Condition ~p", [Condition]),
    Sql = "select user_id, role_id"
	++ " from user_to_role"
	++ " where " ++ ?utils:to_sqls(proplists, Condition)
	++ " and deleted =" ++ ?to_string(?NO) ++ ";",
    {ok, Rights} = ?mysql:fetch(read, Sql),
    {reply, Rights, State};



handle_call({lookup_role_right, Condition}, _From, State) ->
    ?DEBUG("lookup_role_right with Condition ~p", [Condition]),    
    Sql = "select right_id as id"
	++" from role_to_right"
	++" where "  ++ ?utils:to_sqls(proplists, Condition)
	++ " and deleted=" ++?to_s(?NO) ++ ";",
    
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};


handle_call({lookup_role_shop, Condition}, _From, State) ->
    ?DEBUG("lookup_role_shop with Condition ~p", [Condition]),
    CorrectCondition = ?utils:correct_condition(<<"a.">>, Condition),
    Sql = "select a.func_id, a.shop_id, b.name, b.type, b.repo as repo_id"
	++" from role_to_shop a, shops b"
	++" where "  ++ ?utils:to_sqls(proplists, CorrectCondition)
	++" and a.shop_id = b.id and a.deleted=" ++ ?to_s(?NO) ++ ";",

    {ok, Shops} = ?sql_utils:execute(read, Sql),
    {reply, lists:reverse(?to_tl(Shops)), State};


%% handle_call({lookup, merchant}, _From, State) ->
%%     ?DEBUG("lookup right with merchant right", []),
%%     Accounts = account(merchant),
%%     {reply, Accounts, State};

handle_call({lookup, _Condition}, _From, State) ->
    _Sql2 = "select a.name, a.role, b.shopowner from user a, user_to_shopowner b"
	" where a.id=b.user",
    %% {ok, User2} = ?mysql:fetch(read, Sql1),
    {reply, ok, State};

handle_call({get_account, Merchant}, _From, State) ->
    ?DEBUG("get_account with merchant ~p", [Merchant]),
    Sql0 = "select id, name, type, max_create from users"
	++ " where merchant=" ++ ?to_s(Merchant)
	++ " and deleted=0",
    {ok, Accounts}  = ?mysql:fetch(read, Sql0), 
    {reply, {ok, ?to_tl(Accounts)}, State};

handle_call({get_merchant_account, Merchant}, _From, State) ->
    ?DEBUG("get_merchant_account with merchant ~p", [Merchant]),
    Sql0 = "select id, name, type, max_create from users"
	++ " where merchant=" ++ ?to_s(Merchant)
	++ " and type=" ++ ?to_s(?MERCHANT)
	++ " and deleted=0",
    {ok, Account}  = ?mysql:fetch(read, Sql0), 
    {reply, {ok, Account}, State};
    
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
account(Conditions) ->
    CorrectConditions = ?utils:correct_condition(<<"a.">>, Conditions),
    Sql1 = "select a.id, a.name, a.type, a.merchant"
	", a.max_create, a.create_date"
	", tc.user_id, tc.role_id, tc.role_name"
	%% ", b.role_id as role"
	%% ", c.name as role_name"
	" from users a,"
	" (select b.user_id, b.role_id, c.name as role_name"
	" from user_to_role b, roles c"
	" where b.role_id=c.id) as tc"
	%% " left join user_to_role b on b.user_id=a.id"
	%% " left join roles c on c.created_by="
	++ " where " ++ ?utils:to_sqls(proplists, CorrectConditions)
	++ " and a.id=tc.user_id"
	++ " and a.deleted=" ++ ?to_s(?NO),
    {ok, Users} = ?mysql:fetch(read, Sql1),

    MerchantIds = 
	lists:foldr(fun({User}, Acc) ->
			    M = ?to_s(?value(<<"merchant">>, User)),
			    case lists:member(M, Acc) of
				true -> Acc;
				false ->
				    [M|Acc]
			    end
		    end, [], ?to_tl(Users)),

    Merchants = 
	case MerchantIds of
	    [] -> [];
	    MerchantIds ->
		Sql2 = "select id, name, owner from merchants where id"
		    " in (" ++ string:join(MerchantIds, ",") ++ ")"
		    " and deleted = " ++ ?to_s(?NO) ++ ";",
		{ok, M} = ?mysql:fetch(read, Sql2),
		M
	end,

    Accounts = 
	lists:foldr(
	  fun({User}, Acc0) ->
		  MerchantId = ?v(<<"merchant">>, User),
		  Matched = 
		      lists:foldr(
			fun({Merchant}, Acc1) -> 
				case ?v(<<"id">>, Merchant) =:= MerchantId of
				    true ->
					[{[{<<"merchant">>, ?v(<<"name">>, Merchant)},
					   {<<"owner">>, ?v(<<"owner">>, Merchant)}|
					   proplists:delete(<<"merchant">>, User)]}|Acc1];
				    false ->
					Acc1
				end 
			end, [], ?to_tl(Merchants)),
		  Matched ++ Acc0
	  end, [], ?to_tl(Users)),

    Accounts.

    
    
