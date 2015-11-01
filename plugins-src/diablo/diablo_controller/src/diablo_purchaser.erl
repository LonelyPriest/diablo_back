%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright QianZhangGui(C) 2015, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 16 Jan 2015 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_purchaser).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_server).

%% API
-export([start_link/1]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-export([purchaser_good/2, purchaser_good/3,
	 purchaser_good/4, purchaser_good/5]).

-export([purchaser_inventory/3, purchaser_inventory/4, purchaser_inventory/5]).


-export([filter/4, filter/6, rsn_detail/3, export/3]).
-export([match/3, match/4, match/5, match/6]).

-define(SERVER, ?MODULE). 

-record(state, {}).

%%%===================================================================
%%% API
%%%===================================================================


purchaser_good(lookup, Merchant) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {lookup_good, Merchant}).

purchaser_good(new, Merchant, Attrs) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {new_good, Merchant, Attrs}); 
purchaser_good(update, Merchant, Attrs) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {update_good, Merchant, Attrs});

purchaser_good(lookup, Merchant, GoodId) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {lookup_good, Merchant, GoodId});
purchaser_good(delete, Merchant, GoodId) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {delete_good, Merchant, GoodId});
purchaser_good(price, Merchant, [{_StyleNumber, _Brand}|_] = Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {get_good_price, Merchant, Conditions}).

purchaser_good(lookup, Merchant, StyleNumber, Brand) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {lookup_good, Merchant, StyleNumber, Brand});
    
purchaser_good(used, Merchant, StyleNumber, Brand) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {lookup_used_good, Merchant, StyleNumber, Brand}).
purchaser_good(used, Merchant, Shops, StyleNumber, Brand) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(
      Name, {lookup_used_good, Merchant, Shops, StyleNumber, Brand}).

purchaser_inventory(new, Merchant, Inventories, Props) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {new_inventory, Merchant, Inventories, Props});
purchaser_inventory(update, Merchant, Inventories, Props) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {update_inventory, Merchant, Inventories, Props});
purchaser_inventory(reject, Merchant, Inventories, Props) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {reject_inventory, Merchant, Inventories, Props});
purchaser_inventory(fix, Merchant, Inventories, Props) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {fix_inventory, Merchant, Inventories, Props});

purchaser_inventory(abstract, Merchant, Shop, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {abstract_inventory, Merchant, Shop, Conditions}). 

%%
%% 
%%

purchaser_inventory(list, Merchant, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {list_inventory, Merchant, Conditions});
%% purchaser_inventory(last_reject, Merchant, Conditions) ->
%%     gen_server:call(?SERVER, {last_reject, Merchant, Conditions});

purchaser_inventory(check, Merchant, RSN) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {check_inventory, Merchant, RSN});
purchaser_inventory(get_new, Merchant, RSN) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {get_new, Merchant, RSN});
purchaser_inventory(get_inventory_new_rsn, Merchant, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {get_inventory_new_rsn, Merchant, Conditions});

purchaser_inventory(get_new_amount, Merchant, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {get_new_amount, Merchant, Conditions}).
purchaser_inventory(amount, Merchant, Shop, StyleNumber, Brand) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {get_amount, Merchant, Shop, StyleNumber, Brand}).



%%
%% match
%%
%% match good
match(style_number, Merchant, PromptNumber) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {match_style_number, Merchant, PromptNumber}).
match(style_number_brand_firm, Merchant, PromptNumber, Firm) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {match_style_number_brand_firm,
			      Merchant, PromptNumber, Firm});
match(all_style_number_brand_firm, Merchant, StartTime, Firm) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {match_all_style_number_brand_firm,
			      Merchant, StartTime, Firm}).


%% match inventory 
match(inventory, all_inventory, Merchant, Shop, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {match_all_inventory, Merchant, Shop, Conditions});

match(inventory, QType, Merchant, StyleNumber, Shop) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(
      Name, {match_inventory, QType, Merchant, StyleNumber, Shop}).

match(inventory, QType, Merchant, StyleNumber, Shop, Firm) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(
      Name, {match_inventory, QType, Merchant, StyleNumber, Shop, Firm});

match(all_reject_inventory, QType, Merchant, Shop, Firm, StartTime) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(
      Name, {match_all_reject_inventory,
		QType, Merchant, Shop, Firm, StartTime}).

%% =============================================================================
%% filter with pagination
%% =============================================================================
%% new
filter(total_news, 'and', Merchant, Fields) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {total_news, Merchant, Fields});

filter(total_new_rsn_groups, 'and', Merchant, Fields) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {total_new_rsn_groups, Merchant, Fields});

%% reject
%% filter(total_rejects, 'and', Merchant, Fields) ->
%%     gen_server:call(?SERVER, {total_rejects, Merchant, Fields});

%% filter(total_reject_rsn_groups, 'and', Merchant, Fields) -> 
%%     gen_server:call(?SERVER, {total_new_rsn_groups, reject, Merchant, Fields});

%% fix
filter(total_fix, 'and', Merchant, Fields) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {total_fix, Merchant, Fields});

filter(total_fix_rsn_groups, 'and', Merchant, Fields) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {total_fix_rsn_groups, Merchant, Fields});

%% inventory
filter(total_groups, 'and', Merchant, Fields) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {total_groups, Merchant, Fields});

%% good
filter(total_goods, 'and', Merchant, Fields) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {total_goods, Merchant, Fields}).



%%
%% filter detail
%%
%% new stock
filter(news, 'and', Merchant, CurrentPage, ItemsPerPage, Fields) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(
      Name, {filter_news, Merchant, CurrentPage, ItemsPerPage, Fields});

filter(new_rsn_groups, 'and', Merchant, CurrentPage, ItemsPerPage, Fields) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {filter_new_rsn_groups,
			   Merchant, CurrentPage, ItemsPerPage, Fields});

%% fix
filter(fix, 'and', Merchant, CurrentPage, ItemsPerPage, Fields) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(
      Name, {filter_fix, Merchant, CurrentPage, ItemsPerPage, Fields});

filter(fix_rsn_groups, 'and', Merchant, CurrentPage, ItemsPerPage, Fields) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {filter_fix_rsn_groups,
			   Merchant, CurrentPage, ItemsPerPage, Fields});

%% inventory
filter(groups, 'and', Merchant, CurrentPage, ItemsPerPage, Fields) ->
    Name = ?wpool:get(?MODULE, Merchant),
    %% default use id
    gen_server:call(
      Name, {filter_groups, use_id, Merchant,
	     CurrentPage, ItemsPerPage, Fields});

filter({groups, Mode}, 'and', Merchant, CurrentPage, ItemsPerPage, Fields) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(
      Name, {filter_groups, Mode, Merchant,
	     CurrentPage, ItemsPerPage, Fields});

%% good
filter(goods, 'and', Merchant, CurrentPage, ItemsPerPage, Fields) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(
      Name, {filter_goods, Merchant, CurrentPage, ItemsPerPage, Fields}).

%% rsn
rsn_detail(new_rsn, Merchant, Condition) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {new_rsn_detail, Merchant, Condition});

rsn_detail(reject_rsn, Merchant, Condition) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {new_rsn_detail, Merchant, Condition});

rsn_detail(fix_rsn, Merchant, Condition) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {fix_rsn_detail, Merchant, Condition}).


%%
%% export
%%
export(trans, Merchant, Condition) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {new_trans_export, Merchant, Condition});
export(trans_note, Merchant, Condition) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {new_trans_note_export, Merchant, Condition});
export(stock, Merchant, Condition) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {stock_export, Merchant, Condition}).


start_link(Name) ->
    gen_server:start_link({local, Name}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

init([]) ->
    {ok, #state{}}.

handle_call({new_good, Merchant, Attrs}, _Form, State) ->
    ?DEBUG("new_good with merchant ~p~nattrs~p", [Merchant, Attrs]),
    %% Merchant    = ?v(<<"merchant">>, Attrs), 
    StyleNumber = ?v(<<"style_number">>, Attrs),
    BrandId     = ?v(<<"brand_id">>, Attrs),
    Shop        = ?v(<<"shop">>, Attrs),
    UseZero     = ?v(<<"zero_inventory">>, Attrs, ?NO),
    
    Sql = "select style_number, brand from w_inventory_good"
	" where style_number=" ++ "\"" ++ ?to_s(StyleNumber) ++ "\""
	++ " and brand=" ++ ?to_s(BrandId)
	++ " and merchant=" ++ ?to_s(Merchant) ++ ";",

    Reply = 
	case ?sql_utils:execute(s_read, Sql) of
	    {ok, []} ->
		RealyShop = realy_shop(Merchant, Shop),
		Sql1 = ?w_good_sql:good_new(
			  Merchant, UseZero, RealyShop, Attrs),
		?sql_utils:execute(transaction, Sql1, StyleNumber);
	    {ok, _} ->
		{error, ?err(purchaser_good_exist, StyleNumber)};
	    Error ->
		Error
	end,
    {reply, Reply, State};

handle_call({update_good, Merchant, Attrs}, _Form, State) ->
    ?DEBUG("update_good with merchant ~p~nattrs~n~p", [Merchant, Attrs]),
    GoodId         = ?v(<<"good_id">>, Attrs),
    Shop           = ?v(<<"shop">>, Attrs),

    OrgStyleNumber = ?v(<<"o_style_number">>, Attrs),
    OrgBrand       = ?v(<<"o_brand">>, Attrs),

    StyleNumber    = ?v(<<"style_number">>, Attrs),
    Brand          = ?v(<<"brand_id">>, Attrs),
    
    TypeId         = ?v(<<"type_id">>, Attrs), 
    Firm           = ?v(<<"firm_id">>, Attrs), 
    Sex            = ?v(<<"sex">>, Attrs),
    Season         = ?v(<<"season">>, Attrs),
    Year           = ?v(<<"year">>, Attrs),
    
    OrgPrice       = ?v(<<"org_price">>, Attrs),
    TagPrice       = ?v(<<"tag_price">>, Attrs),
    PkgPrice       = ?v(<<"pkg_price">>, Attrs),
    P3             = ?v(<<"price3">>, Attrs),
    P4             = ?v(<<"price4">>, Attrs),
    P5             = ?v(<<"price5">>, Attrs),
    Discount       = ?v(<<"discount">>, Attrs),
    
    Colors         = ?v(<<"color">>, Attrs),
    Path           = ?v(<<"path">>, Attrs),
    
    %% Date     = ?utils:current_time(localdate),
    DateTime = ?utils:current_time(localtime),

    UpdateBase =
	%% ?utils:v(type, string, StyleNumber)
	%% ++ ?utils:v(type, integer, Brand)
	?utils:v(type, integer, TypeId)
	++ ?utils:v(firm, integer, Firm)
	++ ?utils:v(sex, integer, Sex)
	++ ?utils:v(year, integer, Year)
	++ ?utils:v(season, integer, Season)
	++ ?utils:v(org_price, float, OrgPrice)
	++ ?utils:v(tag_price, float, TagPrice)
	++ ?utils:v(pkg_price, float, PkgPrice)
	++ ?utils:v(price3, float, P3)
	++ ?utils:v(price4, float, P4)
	++ ?utils:v(price5, float, P5)
	++ ?utils:v(discount, integer, Discount) 
	++ ?utils:v(path, string, Path),
	%% ++ ?utils:v(change_date, string, DateTime),

    UpdateGood = UpdateBase
	++ case ?utils:v(color, string, Colors) of
	       [] -> [];
	       U -> U ++ ?utils:v(free, integer, 1)
	   end ++ ?utils:v(change_date, string, DateTime),

    Sql1 = 
	"update w_inventory_good set "
	++ ?utils:to_sqls(proplists, comma, UpdateGood)
	++ " where id=" ++ ?to_s(GoodId) 
	++ " and merchant=" ++ ?to_s(Merchant),

    RBrand = fun(undefined) -> OrgBrand; (_) -> Brand end,
    RStyleNumber = fun(undefined) -> ?to_s(OrgStyleNumber);
		      (_) -> ?to_s(StyleNumber) end,
		
    C = fun(true, S, B) ->
		"style_number=\'" ++ ?to_s(S) ++ "\'"
		    ++ " and brand=" ++ ?to_s(B)
		    ++ " and shop="  ++ ?to_s(Shop)
		    ++ " and merchant=" ++ ?to_s(Merchant) ;
	   (false, S, B) ->
		"style_number=\'" ++ ?to_s(S) ++ "\'"
		    ++ " and brand=" ++ ?to_s(B)
		    ++ " and merchant=" ++ ?to_s(Merchant) 
	end,
    

    RC = fun(S, B) ->
		 "style_number=\'" ++ ?to_s(S) ++ "\'"
		     ++ " and brand=" ++ ?to_s(B)
		     ++ " and rsn like \'"
		     "M-" ++ ?to_s(Merchant) ++ "-S-" ++ ?to_s(Shop) ++ "%\'"
	 end,
    
    case StyleNumber =:= undefined andalso Brand =:= undefined of
	true ->
	    case UpdateBase of
		[] ->
		    {reply, ?sql_utils:execute(write, Sql1, GoodId), State};
		_  ->
		    UpdateInv = UpdateBase
			++?utils:v(change_date, string, DateTime),
		    Sql2 = "update w_inventory set "
			++ ?utils:to_sqls(proplists, comma, UpdateInv)
			++ " where " ++ C(true, OrgStyleNumber, OrgBrand),
		    
		    {reply,
		     ?sql_utils:execute(
			transaction, [Sql1, Sql2], GoodId), State}
	    end;
	false -> 
	    FindFun =
		fun(Color, Size) ->
			"select id, style_number, brand, color, size"
			    " from w_inventory_amount"
			    " where style_number=\'"
			    ++ (RStyleNumber(StyleNumber)) ++ "\'"
			    ++ " and brand=" ++ ?to_s(RBrand(Brand))
			    ++ " and color=" ++ ?to_s(Color)
			    ++ " and size=" ++ ?to_s(Size)
			    ++ " and shop=" ++ ?to_s(Shop)
			    ++ " and merchant=" ++ ?to_s(Merchant) 
		end,

	    InsertFun =
		fun(Color, Size, Total) ->
			"insert into w_inventory_amount("
			    "style_number, brand, color, size, shop, merchant"
			    ", total, entry_date"
			    ") values("
			    "\'" ++ (RStyleNumber(StyleNumber)) ++ "\'"
			    ", " ++ ?to_s(Brand) ++ 
			    ", " ++ ?to_s(Color) ++ 
			    ", " ++ ?to_s(Size) ++
			    ", " ++ ?to_s(Shop) ++
			    ", " ++ ?to_s(Merchant) ++
			    ", " ++ ?to_s(Total) ++
			    ", \'" ++ ?to_s(DateTime) ++ "\')"
		end,

	    UpdateFun =
		fun(UId, Total) ->
			"update w_inventory_amount"
			    " set total=total+" ++ ?to_s(Total)
			    ++ " where id=" ++ ?to_s(UId)
		end,
	    
	    FoldrFun =
		fun({R}, Acc) ->
			Color = ?v(<<"color">>, R),
			Size  = ?v(<<"size">>, R),
			Total = ?v(<<"total">>, R),
			case ?sql_utils:execute(
				s_read,
				FindFun(Color, Size)) of
			    {ok, []} ->
				[InsertFun(Color, Size, Total)|Acc];
			    {ok, F} ->
				UId = ?v(<<"id">>, F),
				[UpdateFun(UId, Total)|Acc]
			end
		end,
	    
	    try
		Update2 =
		    ?utils:v(style_number, string, StyleNumber)
		    ++ ?utils:v(brand, integer, Brand),
		
		%% update w_inventory_good 
		Sql00 = 
		    case ?sql_utils:execute(
			    s_read,
			    "select id, style_number, brand "
			    "from w_inventory_good"
			    " where "
			    ++ C(false,
				 RStyleNumber(StyleNumber), RBrand(Brand))) of
			{ok, []} ->
			    ["update w_inventory_good set "
			      ++ ?utils:to_sqls(proplists, comma,
						Update2 ++ UpdateGood)
			      ++ " where id=" ++ ?to_s(GoodId) 
			      ++ " and merchant=" ++ ?to_s(Merchant)];
			{ok, G} ->
			    ["delete from w_inventory_good where id="
			      ++ ?to_s(GoodId) ,
			      
			      "update w_inventory_good set "
			      ++ ?utils:to_sqls(proplists, comma, UpdateGood)
			      ++ " where id=" ++ ?to_s(?v(<<"id">>, G))]
		    end,
		?DEBUG("Sql00 ~p", [Sql00]),

		%% update w_inventory_new 
		Sql10 = 
		    ["update w_inventory_new_detail set "
		     ++ ?utils:to_sqls(
			   proplists, comma,
			   Update2 ++ ?utils:v(path, string, Path))
		     ++ " where " ++ RC(OrgStyleNumber, OrgBrand),

		     "update w_inventory_new_detail_amount set "
		     ++ ?utils:to_sqls(proplists, comma, Update2)
		     ++ " where "
		     ++ RC(OrgStyleNumber, OrgBrand)],
		    
		?DEBUG("Sql10 ~p", [Sql10]),
		
		%% update w_inventory
		UpdateInv = UpdateBase
		    ++?utils:v(change_date, string, DateTime), 

		Sql12 = 
		    case ?sql_utils:execute(
			    s_read,
			    "select id, style_number, brand from w_inventory"
			    " where "
			    ++ C(true,
				 RStyleNumber(StyleNumber), RBrand(Brand))) of
			{ok, []} -> 
			    ["update w_inventory set "
			     ++ ?utils:to_sqls(
				   proplists, comma, Update2 ++ UpdateInv)
			     ++ " where "
			     ++ C(true, OrgStyleNumber, OrgBrand),

			     "update w_inventory_amount set "
			     ++ ?utils:to_sqls(proplists, comma, Update2)
			     ++ " where "
			     ++ C(true, OrgStyleNumber, OrgBrand)];
			{ok, S} ->
			    Sqla = 
				["update w_inventory a inner join("
				 "select style_number, brand, amount, sell"
				 " from w_inventory"
				 " where "
				 ++ C(true, OrgStyleNumber, OrgBrand) ++ ") b"
				 %% " on a.style_number=b.style_number"
				 %% " and a.brand=b.brand"
				 %% " and a.shop=b.shop"
				 %% " and a.merchant=b.merchant"
				 " set a.amount=a.amount+b.amount,"
				 "a.sell=a.sell+b.sell"
				 ++ ?utils:to_sqls(
				       proplists, comma, UpdateInv)
				 ++ " where a.id=" ++ ?to_s(?v(<<"id">>, S))],
			    
			    Sqlb = 
				case ?sql_utils:execute(
					read, "select id, style_number, brand"
					", color, size, total"
					" from w_inventory_amount"
					" where "
					++ C(true,
					     OrgStyleNumber, OrgBrand)) of
				    {ok, Rs} -> 
					lists:foldr(FoldrFun, [], Rs)
				end,
			    %% "update w_inventory_amount a inner join("
			    %% "select "
			    %% ++ "\'" ++ RStyleNumber(StyleNumber) ++ "\'"
			    %% " as style_number"
			    %% ++ ", " ++ ?to_s(RBrand(Brand))
			    %% ++ " as brand"
			    %% ++ ", color, size, shop, merchant, total"
			    %% " from w_inventory_amount where "
			    %% ++ C(true, OrgStyleNumber, OrgBrand) ++ ") b"
			    %% " on a.style_number=b.style_number"
			    %% " and a.brand=b.brand"
			    %% " and a.color=b.color"
			    %% " and a.size=b.size"
			    %% " and a.shop=b.shop"
			    %% " and a.merchant=b.merchant"
			    %% " set a.total=a.total+b.total"
			    %% " where a.merchant=" ++ ?to_s(Merchant),
			    Sqla ++ Sqlb ++ 
				[" delete from w_inventory"
				 " where "
				 ++ C(true, OrgStyleNumber, OrgBrand),
				 " delete from w_inventory_amount"
				 " where "
				 ++ C(true, OrgStyleNumber, OrgBrand)]
		    end,
		
		?DEBUG("Sql12 ~p", [Sql12]),

		Sql14 =
		    [ "update w_sale_detail set "
		      ++ ?utils:to_sqls(
			    proplists, comma,
			    Update2 ++ ?utils:v(path, string, Path))
		      ++ " where "
		      ++ RC(OrgStyleNumber, OrgBrand),

		      "update w_sale_detail_amount set "
		      ++ ?utils:to_sqls(proplists, comma, Update2)
		      ++ " where "
		      ++ RC(OrgStyleNumber, OrgBrand)],
		
		?DEBUG("Sql14 ~p", [Sql14]),

		AllSql = Sql00 ++ Sql10 ++ Sql12 ++ Sql14,
		{reply,
		 ?sql_utils:execute(transaction, AllSql, GoodId), State}
	    catch
		_:{badmatch, Error} ->
		    {reply, Error, State}
	    end
    end;
		
handle_call({delete_good, Merchant, GoodId}, _Form, State) ->
    ?DEBUG("delete_good with merchant ~p, goodId ~p", [Merchant, GoodId]),
    Sql = ?w_good_sql:good(delete, Merchant, GoodId), 
    Reply = ?sql_utils:execute(write, Sql, GoodId),
    {reply, Reply, State};

handle_call({lookup_good, Merchant}, _Form, State) ->
    ?DEBUG("lookup_good with merchant ~p", [Merchant]),
    Sql = ?w_good_sql:good(detail, Merchant),
    Reply =  ?sql_utils:execute(read, Sql),
    {reply, Reply, State};


handle_call({lookup_good, Merchant, GoodId}, _Form, State) ->
    ?DEBUG("lookup_good with merchant ~p, goodId ~p", [Merchant, GoodId]),
    Sql = ?w_good_sql:good(detail, Merchant, [{<<"id">>, ?to_i(GoodId)}]),
    Reply =  ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};
    
handle_call({lookup_good, Merchant, StyleNumber, Brand}, _Form, State) ->
    ?DEBUG("lookup_good with merchant ~p, StyleNumber ~p, Brand ~p",
	   [Merchant, StyleNumber, Brand]),
    Sql = ?w_good_sql:good(detail_no_join, Merchant, StyleNumber, Brand),
    Reply =  ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State}; 

handle_call({lookup_used_good, Merchant, StyleNumber, Brand}, _Form, State) ->
    ?DEBUG("lookup_used_good with merchant ~p, StyleNumber ~p, Brand ~p",
	   [Merchant, StyleNumber, Brand]),
    Sql = ?w_good_sql:good(used_detail, Merchant, StyleNumber, Brand),
    Reply =  ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};

handle_call({get_good_price, Merchant, Conditions}, _Form, State) ->
    ?DEBUG("get_good_attr with merchant ~p, conditions ~p", [Merchant, Conditions]),
    Sql = ?w_good_sql:good(price, Merchant, Conditions),
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

%%
%% good match
%%
handle_call({match_style_number, Merchant, PromptNumber}, _Form, State) ->
    ?DEBUG("match_style_number with merchant ~p, promptNumber ~p",
	   [Merchant, PromptNumber]),
    Sql = ?w_good_sql:good_match(style_number, Merchant, PromptNumber),
    Reply =  ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({match_style_number_brand_firm, Merchant, PromptNumber, Firm},
	    _Form, State) ->
    ?DEBUG("match_style_number_brand with merchant ~p, promptNumber ~p"
	   ",firm ~p", [Merchant, PromptNumber, Firm]),
    Sql = ?w_good_sql:good_match(
	     style_number_brand_firm, Merchant, PromptNumber, Firm),
    Reply =  ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({match_all_style_number_brand_firm, Merchant, StartTime, Firm},
	    _Form, State) ->
    ?DEBUG("match_all_style_number_brand with merchant ~p, start time ~p"
	   ",firm ~p", [Merchant, StartTime, Firm]),
    Sql = ?w_good_sql:good_match(
	     all_style_number_brand_firm, Merchant, StartTime, Firm),
    Reply =  ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

%% inventory match
handle_call({match_inventory, QType, Merchant, StyleNumber, Shop}, _Form, State) ->
    ?DEBUG("match_inventory with qtype ~p, merchant ~p, styleNumber ~p, shop ~p",
	   [QType, Merchant, StyleNumber, Shop]),
    RealyShop = case QType of
		    1 -> Shop;
		    _ -> realy_shop(Merchant, Shop)
		end,
    
    Sql = ?w_good_sql:inventory_match(Merchant, StyleNumber, RealyShop),
    Reply =  ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({match_inventory,
	     QType, Merchant, StyleNumber, Shop, Firm}, _Form, State) ->
    ?DEBUG("match_inventory with qtype ~p, merchant ~p, styleNumber ~p"
	   ",shop ~p, firm ~p", [QType, Merchant, StyleNumber, Shop, Firm]),
    RealyShop = case QType of
		    1 -> realy_shop(true, Merchant, Shop);
		    _ -> realy_shop(Merchant, Shop)
		end,
    %% RealyShop = realy_shop(Merchant, Shop),
    Sql = ?w_good_sql:inventory_match(Merchant, StyleNumber, RealyShop, Firm),
    Reply =  ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({match_all_reject_inventory,
	     QType, Merchant, Shop, Firm, StartTime}, _Form, State) ->
    ?DEBUG("match_all_reject_inventory with qtype ~p, merchant ~p"
	   ", shop ~p, firm ~p, StartTime ~p",
	   [QType, Merchant, Shop, Firm, StartTime]),
    RealyShop = case QType of
		    1 -> realy_shop(true, Merchant, Shop);
		    _ -> realy_shop(Merchant, Shop)
		end,
    Sql = ?w_good_sql:inventory_match(
	     all_reject, Merchant, RealyShop, Firm, StartTime),
    Reply =  ?sql_utils:execute(read, Sql),
    {reply, Reply, State}; 

handle_call({match_all_inventory, Merchant, Shop, Conditions}, _From, State) ->
    ?DEBUG("match_all_inventory  with merchant ~p, shop ~p, conditions ~p",
	   [Merchant, Shop, Conditions]),
    RealyShop = realy_shop(Merchant, Shop),
    Sql = ?w_good_sql:inventory_match(all_inventory, Merchant, RealyShop, Conditions),
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

%% new
handle_call({new_inventory, Merchant, Inventories, Props}, _From, State) ->
    ?DEBUG("new_inventory: merchant ~p~n, Inventories ~p, props ~p",
	   [Merchant, Inventories, Props]),
    
    DateTime  = ?v(<<"datetime">>, Props, ?utils:current_time(localtime)),
    %% Year       = ?utils:current_time(year),
    
    Shop       = ?v(<<"shop">>, Props),
    Firm       = ?v(<<"firm">>, Props),
    Employee   = ?v(<<"employee">>, Props),
    Cash       = ?v(<<"cash">>, Props, 0),
    Card       = ?v(<<"card">>, Props, 0),
    Wire       = ?v(<<"wire">>, Props, 0),
    VerifyPay  = ?v(<<"verificate">>, Props, 0),
    Comment    = ?v(<<"comment">>, Props, ""),
    ShouldPay  = ?v(<<"should_pay">>, Props, 0),
    HasPay     = ?v(<<"has_pay">>, Props, 0),

    EPayType   = ?v(<<"e_pay_type">>, Props, -1),
    EPay       = ?v(<<"e_pay">>, Props, 0),
    
    Balance    = ?v(<<"balance">>, Props),
    Date       = ?v(<<"date">>, Props, ?utils:current_time(localdate)),
    Total      = ?v(<<"total">>, Props, 0),


    Sql0 = "select id, merchant, balance from suppliers"
	" where id=" ++ ?to_s(Firm)
	++ " and merchant=" ++ ?to_s(Merchant)
	++ " and deleted=" ++ ?to_s(?NO) ++ ";",

    case ?sql_utils:execute(s_read, Sql0) of 
	{ok, Account} ->
	    RSn = rsn(new, Merchant, Shop, ?inventory_sn:sn(w_inventory_new_sn, Merchant)),
	    
	    Sql1 = sql(wnew, RSn, Merchant,
		       Shop, Firm, Date, DateTime, Inventories),

	    CurrentBalance = ?v(<<"balance">>, Account),
	    
	    Sql2 = "insert into w_inventory_new(rsn"
		", employ, firm, shop, merchant, balance"
		", should_pay, has_pay, cash, card, wire"
		", verificate, total, comment, e_pay_type, e_pay, type, entry_date) values("
		++ "\"" ++ ?to_s(RSn) ++ "\","
		++ "\"" ++ ?to_s(Employee) ++ "\","
		++ ?to_s(Firm) ++ ","
		++ ?to_s(Shop) ++ ","
		++ ?to_s(Merchant) ++ ","
		++ case ?to_f(CurrentBalance) =:= ?to_f(Balance) of
		       true -> ?to_s(Balance) ++ ",";
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
		++ ?to_s(?NEW_INVENTORY) ++ ","
		++ "\"" ++ ?to_s(DateTime) ++ "\");",

	    case ShouldPay + EPay - (Cash + Card + Wire + VerifyPay) of
		0 ->
		    AllSql = [Sql2|Sql1],
		    Reply = ?sql_utils:execute(transaction, AllSql, RSn),
		    {reply, Reply, State};
		Metric -> 
		    Sql3 = "update suppliers set balance=balance+" ++ ?to_s(Metric)
			++ ", change_date=" ++ "\"" ++ ?to_s(DateTime) ++ "\""
			++ " where id=" ++ ?to_s(?v(<<"id">>, Account)),

		    AllSql = [Sql2, Sql3|Sql1], 
		    Reply = ?sql_utils:execute(transaction, AllSql, RSn),
		    ?w_user_profile:update(firm, Merchant),
		    {reply, Reply, State}
	    end;
	Error ->
	    {reply, Error, State}
    end;

handle_call({update_inventory, Merchant, Inventories, Props}, _From, State) ->
    ?DEBUG("update_inventory: merchant ~p~n, inventories ~p, props ~p",
	   [Merchant, Inventories, Props]), 

    CurTime    = ?utils:current_time(localtime),
    
    Id         = ?v(<<"id">>, Props),
    RSN        = ?v(<<"rsn">>, Props),
    Shop       = ?v(<<"shop">>, Props),
    Datetime   = ?v(<<"datetime">>, Props, CurTime), 
    Firm       = ?v(<<"firm">>, Props),
    Employee   = ?v(<<"employee">>, Props),

    Balance    = ?v(<<"balance">>, Props), 
    Cash       = ?v(<<"cash">>, Props, 0),
    Card       = ?v(<<"card">>, Props, 0),
    Wire       = ?v(<<"wire">>, Props, 0),
    VerifyPay  = ?v(<<"verificate">>, Props, 0),
    EPay       = ?v(<<"e_pay">>, Props, 0),
    Comment    = ?v(<<"comment">>, Props, []), 
    ShouldPay  = ?v(<<"should_pay">>, Props),
    HasPay     = ?v(<<"has_pay">>, Props, 0),
    

    OldFirm      = ?v(<<"old_firm">>, Props),
    OldBalance   = ?v(<<"old_balance">>, Props), 
    OldVerifyPay = ?v(<<"old_verify_pay">>, Props, 0),
    OldShouldPay = ?v(<<"old_should_pay">>, Props),
    OldHasPay    = ?v(<<"old_has_pay">>, Props, 0), 
    OldDatatime  = ?v(<<"old_datetime">>, Props),

    Total      = ?v(<<"total">>, Props),
    
    %% CurTime    = ?utils:current_time(localtime),
    
    RealyShop = realy_shop(Merchant, Shop),
    
    Sql1 = ?w_good_sql:inventory(
	      update, RSN, Merchant, RealyShop, Firm,
	      Datetime, OldDatatime, CurTime, Inventories), 

    Updates =?utils:v(employ, string, Employee)
	++ ?utils:v(firm, integer, Firm) 
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
	++ case Datetime =:= OldDatatime of
	       true -> [];
	       false ->
		   ?utils:v(entry_date, string, Datetime)
	   end,

    case Firm =:= OldFirm of
	true ->
	    Sql2 = "update w_inventory_new set "
		++ ?utils:to_sqls(
		      proplists, comma,
		      ?utils:v(balance, float, OldBalance) ++ Updates)
		++ " where rsn=" ++ "\'" ++ ?to_s(RSN) ++ "\'",

	    case (ShouldPay - HasPay - VerifyPay)
		- (OldShouldPay - OldHasPay - OldVerifyPay) of
		0 ->
		    AllSql = Sql1 ++ [Sql2],
		    Reply = ?sql_utils:execute(transaction, AllSql, RSN), 
		    {reply, Reply, State};
		Metric -> 
		    AllSql = Sql1 ++ [Sql2] ++
			["update suppliers set balance=balance+"
			 ++ ?to_s(Metric) 
			 ++ ", change_date=" ++ "\"" ++ CurTime ++ "\""
			 " where id=" ++ ?to_s(Firm)
			 ++ " and merchant=" ++ ?to_s(Merchant),
			 
			"update w_inventory_new set balance=balance+"
			 ++ ?to_s(Metric)
			 ++ " where shop=" ++ ?to_s(Shop)
			 ++ " and merchant=" ++ ?to_s(Merchant)
			 ++ " and firm=" ++ ?to_s(Firm)
			 ++ " and id>" ++ ?to_s(Id)],
		    
		    Reply = ?sql_utils:execute(transaction, AllSql, RSN),
		    ?w_user_profile:update(firm, Merchant),
		    {reply, Reply, State}
	    end;
	false ->
	    Sql0 = "select id, rsn, firm, shop, merchant, balance"
		", verificate, should_pay, has_pay, e_pay"
		" from w_inventory_new"
		" where shop=" ++ ?to_s(Shop)
		++ " and merchant=" ++ ?to_s(Merchant)
		++ " and firm=" ++ ?to_s(Firm)
		++ " and id<" ++ ?to_s(Id)
		++ " order by id desc limit 1",

	    NewBalance = 
		case ?sql_utils:execute(s_read, Sql0) of
		    {ok, []}  -> Balance;
		    {ok, R}   ->
			?v(<<"balance">>, R)
			    + ?v(<<"should_pay">>, R, 0)
			    + ?v(<<"e_pay">>, R, 0)
			    - ?v(<<"has_pay">>, R, 0)
			    - ?v(<<"verificate">>, R, 0)
		end,
	    
	    
	    Sql2 = "update w_inventory_new set "
		++ ?utils:to_sqls(
		      proplists, comma,
		      ?utils:v(balance, float, NewBalance) ++ Updates)
		++ " where rsn=" ++ "\'" ++ ?to_s(RSN) ++ "\'"
		++ " and id=" ++ ?to_s(Id),

	    BackBalanceOfOldFirm
		= OldShouldPay + EPay - OldVerifyPay - OldHasPay,
	    BalanceOfNewFirm
		= ShouldPay + EPay - HasPay - VerifyPay,
		
	    AllSql = Sql1 ++ [Sql2] ++
		["update suppliers set balance=balance-"
		 ++ ?to_s(BackBalanceOfOldFirm)
		 ++ " where id=" ++ ?to_s(OldFirm),
		 
		 "update suppliers set balance=balance+"
		 ++ ?to_s(BalanceOfNewFirm) 
		 ++ " where id="++ ?to_s(Firm),

		 "update w_inventory_new set balance=balance-"
		 ++ ?to_s(BackBalanceOfOldFirm)
		 ++ " where shop=" ++ ?to_s(Shop)
		 ++ " and merchant=" ++ ?to_s(Merchant)
		 ++ " and firm=" ++ ?to_s(OldFirm)
		 ++ " and id>" ++ ?to_s(Id),
	    
		 "update w_inventory_new set balance=balance+"
		 %% ++ ?to_s(ShouldPay + EPay - HasPay)
		 ++ ?to_s(BalanceOfNewFirm)
		 ++ " where shop=" ++ ?to_s(Shop)
		 ++ " and merchant=" ++ ?to_s(Merchant)
		 ++ " and firm=" ++ ?to_s(Firm)
		 ++ " and id>" ++ ?to_s(Id)
		],
	    
	    Reply = ?sql_utils:execute(transaction, AllSql, RSN),
	    ?w_user_profile:update(firm, Merchant),
	    {reply, Reply, State}
    end; 
%% Error ->
%% 	    {reply, Error, State}
%% end;

handle_call({check_inventory, Merchant, RSN}, _From, State) ->
    ?DEBUG("check_inventory with merchant ~p, RSN ~p", [Merchant, RSN]),
    Sql = "update w_inventory_new set state=" ++ ?to_s(?CHECKED)
	++ ", check_date=\'" ++ ?utils:current_time(localtime) ++ "\'"
	++ " where rsn=\'" ++ ?to_s(RSN) ++ "\'"
	++ " and merchant=" ++ ?to_s(Merchant),

    Reply = ?sql_utils:execute(write, Sql, RSN),
    {reply, Reply, State};

%% reject
handle_call({reject_inventory, Merchant, Inventories, Props}, _From, State) ->
    ?DEBUG("reject_inventory with merchant ~p~n~p, props ~p",
	   [Merchant, Inventories, Props]),

    Now         = ?utils:current_time(localtime),
    Date        = ?v(<<"date">>, Props, ?utils:current_time(localdate)),

    Shop        = ?v(<<"shop">>, Props),
    Firm        = ?v(<<"firm">>, Props),
    DateTime    = ?v(<<"datetime">>, Props, Now),
    Cash        = ?v(<<"cash">>, Props, 0),
    Card        = ?v(<<"card">>, Props, 0),
    Wire        = ?v(<<"wire">>, Props, 0),
    VerifyPay   = ?v(<<"verificate">>, Props, 0),
    Employe     = ?v(<<"employee">>, Props), 
    Balance     = ?v(<<"balance">>, Props),
    ShouldPay   = ?v(<<"should_pay">>, Props, 0),
    HasPay      = ?v(<<"has_pay">>, Props, 0), 
    EPayType    = ?v(<<"e_pay_type">>, Props, -1),
    EPay        = ?v(<<"e_pay">>, Props, 0), 
    
    RejectTotal = ?v(<<"total">>, Props),
    Comment     = ?v(<<"comment">>, Props, ""), 
    
    Sql0 = "select id, merchant, balance from suppliers"
	" where id=" ++ ?to_s(Firm)
	++ " and merchant=" ++ ?to_s(Merchant)
	++ " and deleted=" ++ ?to_s(?NO) ++ ";",
    case ?sql_utils:execute(s_read, Sql0) of 
	{ok, Account} ->
	    RSN = rsn(reject, Merchant, Shop,
		      ?inventory_sn:sn(w_inventory_reject_sn, Merchant)),

	    Sql1 = case RejectTotal of
		       0 -> [];
		       _ -> sql(wreject, RSN, Merchant, Shop, Firm, Date, DateTime, Inventories)
		   end, 
	    
	    RealBalance = ?v(<<"balance">>, Account),
	    Sql2 = ["insert into w_inventory_new(rsn"
		    ", employ, firm, shop, merchant, balance"
		    ", should_pay, has_pay, cash, card, wire"
		    ", verificate, total, comment, e_pay_type, e_pay"
		    ", type, entry_date) values(" 
		    ++ "\"" ++ ?to_s(RSN) ++ "\","
		    ++ "\"" ++ ?to_s(Employe) ++ "\","
		    ++ ?to_s(Firm) ++ ","
		    ++ ?to_s(Shop) ++ ","
		    ++ ?to_s(Merchant) ++ ","
		    ++ case ?to_f(RealBalance) =:= ?to_f(Balance) of
			   true -> ?to_s(Balance) ++ ",";
			   false -> ?to_s(RealBalance) ++ ","
		       end
		    ++ ?to_s(ShouldPay) ++ ","
		    ++ ?to_s(HasPay) ++ ","
		    ++ ?to_s(Cash) ++ ","
		    ++ ?to_s(Card) ++ ","
		    ++ ?to_s(Wire) ++ ","
		    ++ ?to_s(VerifyPay) ++ ","
		    ++ ?to_s(-RejectTotal) ++ ","
		    ++ "\"" ++ ?to_s(Comment) ++ "\","
		    ++ ?to_s(EPayType) ++ ","
		    ++ ?to_s(-EPay) ++ ","
		    ++ ?to_s(?REJECT_INVENTORY) ++ ","
		    ++ "\"" ++ ?to_s(DateTime) ++ "\")"],
	    
	    Sql3 =
		case ShouldPay - EPay == 0 of
		    true  -> [];
		    false -> ["update suppliers set balance=balance+" ++ ?to_s(ShouldPay - EPay)
			      ++ ", change_date=" ++ "\"" ++ Now ++ "\""
			      ++ " where id=" ++ ?to_s(?v(<<"id">>, Account))]
		end,
	    
	    AllSql = Sql1 ++ Sql2 ++ Sql3,
	    %% ?DEBUG("AllSql ~p", [AllSql]),
	    case ?sql_utils:execute(transaction, AllSql, RSN) of
		{ok, _} = OK ->
		    case ShouldPay - EPay == 0 of
			true -> ok;
			false -> ?w_user_profile:update(firm, Merchant)
		    end,
		    {reply, OK, State};
		{error, _} = Error-> 
		    {reply, Error, State} 
	    end;
	Error ->
	    {reply, Error, State}
    end;

%% fix
handle_call({fix_inventory, Merchant, Inventories, Props}, _From, State) ->
    ?DEBUG("fix_inventory with merchant ~p~ninventory ~p~nprops ~p",
	   [Merchant, Inventories, Props]), 
    Now             = ?utils:current_time(localtime), 
    Shop            = ?v(<<"shop">>, Props),
    DateTime        = ?v(<<"datetime">>, Props, Now),
    Employe         = ?v(<<"employee">>, Props), 
    TotalExist      = ?v(<<"total_exist">>, Props),
    TotalFixed      = ?v(<<"total_fixed">>, Props),
    TotalMetric     = ?v(<<"total_metric">>, Props), 
    
    RSN = rsn(fix, Merchant, Shop,
	      ?inventory_sn:sn(w_inventory_fix_sn, Merchant)),

    RealyShop = realy_shop(Merchant, Shop),
    Sql1 = sql(wfix, RSN, DateTime, Merchant, RealyShop, Inventories),
    
    Sql2 = "insert into w_inventory_fix(rsn"
	", shop, employ, exist, fixed, metric, merchant, entry_date)"
	" values("
	++ "\"" ++ ?to_s(RSN) ++ "\","
	++ ?to_s(Shop) ++ ","
	++ "\"" ++ ?to_s(Employe) ++ "\","
	++ ?to_s(TotalExist) ++ ","
	++ ?to_s(TotalFixed) ++ ","
	++ ?to_s(TotalMetric) ++ ","
	++ ?to_s(Merchant) ++ "," 
	++ "\"" ++ ?to_s(DateTime) ++ "\");", 

    AllSql = Sql1 ++ [Sql2],
    Reply = ?sql_utils:execute(transaction, AllSql, RSN),
    {reply, Reply, State}; 


handle_call({list_inventory, Merchant, Conditions}, _From, State) ->
    ?DEBUG("list_inventory  with merchant ~p, conditions ~p",
	   [Merchant, Conditions]), 
    QType = ?v(<<"qtype">>, Conditions, 0), 
    NewConditions = 
	lists:foldr(fun({<<"shop">>, Shop}, Acc) ->
			    [{<<"shop">>, case QType of
					      1 -> realy_shop(true, Merchant, Shop);
					      _ -> realy_shop(Merchant, Shop)
					  end}|Acc];
		       ({<<"qtype">>, _}, Acc) ->
			    Acc;
		       (C, Acc) ->
			    [C|Acc]
		    end, [], Conditions),
    
		   
    Sql = ?w_good_sql:inventory(list, Merchant, NewConditions),
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

%% handle_call({last_reject, Merchant, Conditions}, _From, State) ->
%%     ?DEBUG("last_reject with merchant ~p, Conditions ~p", [Merchant, Conditions]),
%%     Shop = ?v(<<"shop">>, Conditions),
%%     Firm = ?v(<<"firm">>, Conditions),
%%     NewConditions = proplists:delete(<<"firm">>,
%% 			  proplists:delete(<<"shop">>, Conditions)),
    
%%     Sql = ?w_good_sql:inventory(last_reject, Merchant, Shop, Firm, NewConditions),
%%     Reply = ?sql_utils:execute(s_read, Sql),
%%     {reply, Reply, State}; 
    
handle_call({abstract_inventory, Merchant, Shop, Conditions}, _From, State) ->
    ?DEBUG("abstract_inventory with merchant ~p, Shop ~p, conditions ~p",
	   [Merchant, Shop, Conditions]),
    Sql = ?w_good_sql:inventory(abstract, Merchant, Shop, Conditions),
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({get_new, Merchant, RSN}, _From, State) ->
    ?DEBUG("get_new_inventory wht merchant ~p, RSN ~p", [Merchant, RSN]),
    Sql = ?w_good_sql:inventory(
	     new_detail, new, Merchant,
	     [{<<"rsn">>, ?to_b(RSN)}], fun()-> "" end),
    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};

handle_call({get_amount, Merchant, Shop, StyleNumber, Brand}, _From, State) ->
    ?DEBUG("get_amount, with Merchant ~p, Shop ~p, StyleNumber ~p, Brand ~p",
	   [Merchant, Shop, StyleNumber, Brand]),

    RealyShop = realy_shop(true, Merchant, Shop),
    Sql = "select amount as total from w_inventory"
	" where style_number=" ++ "\'" ++ ?to_s(StyleNumber) ++ "\'"
	" and brand=" ++ ?to_s(Brand)
	++ " and shop=" ++ ?to_s(RealyShop) 
	++ " and merchant=" ++ ?to_s(Merchant),

    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};

%% =============================================================================
%% filter with pagination
%% =============================================================================
%% new
handle_call({total_news, Merchant, Fields}, _From, State) ->
    {_, C} = ?w_good_sql:filter_condition(inventory_new, Fields, [], []),
    CountSql = count_table(w_inventory_new, Merchant, C),
    Reply = ?sql_utils:execute(s_read, CountSql),
    {reply, Reply, State}; 

handle_call({filter_news, Merchant, CurrentPage, ItemsPerPage, Fields}, _From, State) ->
    ?DEBUG("filter_new_with_and: currentPage ~p, ItemsPerpage ~p, Merchant ~p~n"
	   "fields ~p", [CurrentPage, ItemsPerPage, Merchant, Fields]),
    {_, C} = ?w_good_sql:filter_condition(inventory_new, Fields, [], []),
    Sql = ?w_good_sql:inventory(
	     new_detail_with_pagination, Merchant, C, CurrentPage, ItemsPerPage), 
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State}; 

%% reject
%% handle_call({total_rejects, Merchant, Fields}, _From, State) ->
%%     CountSql = count_table(w_inventory_new, reject, Merchant, Fields),
%%     Reply = ?sql_utils:execute(s_read, CountSql),
%%     {reply, Reply, State}; 

%% handle_call({filter_rejects, Merchant, CurrentPage, ItemsPerPage, Fields}, _From, State) ->
%%     ?DEBUG("filter_rejects_with_and: currentPage ~p, ItemsPerpage ~p, Merchant ~p~n"
%% 	   "fields ~p", [CurrentPage, ItemsPerPage, Merchant, Fields]), 
%%     %% {StartTime, EndTime, Conditions} = cut(fields_with_prifix, Fields),
%%     Sql = ?w_good_sql:inventory(
%% 	     reject_detail_with_pagination, Merchant, Fields, CurrentPage, ItemsPerPage),
%%     Reply = ?sql_utils:execute(read, Sql),
%%     {reply, Reply, State}; 

%% fix
handle_call({total_fix, Merchant, Fields}, _From, State) ->
    Sql = "rsn, exist, fixed, metric",
    CountTable = ?sql_utils:count_table(w_inventory_fix, Sql, Merchant, Fields),
    CountSql = "select count(*) as total"
    	", sum(exist) as t_exist"
    	", sum(fixed) as t_fixed"
    	", sum(metric) as t_metric"
    	" from ("
	++ CountTable ++ ") a",
    %% Sql = ?sql_utils:count_table("w_inventory_fix", Merchant, Fields),
    Reply = ?sql_utils:execute(s_read, CountSql),
    {reply, Reply, State}; 

handle_call({filter_fix, Merchant, CurrentPage, ItemsPerPage, Fields}, _From, State) ->
    ?DEBUG("filter_fix_with_and: currentPage ~p, ItemsPerpage ~p, Merchant ~p~n"
	   "fields ~p", [CurrentPage, ItemsPerPage, Merchant, Fields]), 
    Sql = ?w_good_sql:inventory(
	     fix_detail_with_pagination, Merchant, Fields, CurrentPage, ItemsPerPage),
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State}; 

%% good
handle_call({total_goods, Merchant, Fields}, _From, State) ->
    Sql = ?sql_utils:count_table("w_inventory_good", Merchant, Fields),
    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State}; 

handle_call({filter_goods, Merchant, CurrentPage, ItemsPerPage, Fields}, _From, State) ->
    ?DEBUG("filter_goods_with_and: currentPage ~p, ItemsPerpage ~p, Merchant ~p~n"
	   "fields ~p", [CurrentPage, ItemsPerPage, Merchant, Fields]),

    Sql = ?w_good_sql:good(
	     detail_with_pagination, Merchant, Fields, CurrentPage, ItemsPerPage), 
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State}; 

%% inventory
handle_call({total_groups, Merchant, Fields}, _From, State) ->
    CountSql = "count(*) as total"
	", sum(amount) as t_amount"
	", sum(sell) as t_sell",
    Sql = ?sql_utils:count_table(
	     w_inventory, CountSql, Merchant, realy_conditions(Merchant, Fields)), 
    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State}; 

handle_call({filter_groups, Mode, Merchant,
	     CurrentPage, ItemsPerPage, Fields}, _From, State) ->
    ?DEBUG("filter_groups_with_and: mode ~p, currentPage ~p, ItemsPerpage ~p"
	   ", Merchant ~p~nfields ~p",
	   [Mode, CurrentPage, ItemsPerPage, Merchant, Fields]),
    C = realy_conditions(Merchant, Fields),
    Sql = ?w_good_sql:inventory(
	     {group_detail_with_pagination, Mode},
	     Merchant, C, CurrentPage, ItemsPerPage), 
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

%% =============================================================================
%% new
%% =============================================================================
handle_call({get_inventory_new_rsn, Merchant, Conditions}, _From, State) ->
    Sql = ?w_good_sql:inventory(inventory_new_rsn, Merchant, Conditions),
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({total_new_rsn_groups, Merchant, Conditions}, _From, State) ->
    %% ?DEBUG("total_new_rsn_groups whith conditions ~p", [Conditions]),
    %% CountSql = "select count(*) as total"
    %% 		", SUM(amount) as t_amount"
    %% 		" from w_inventory_new_detail"
    %% 		" where " ++ ?utils:to_sqls(proplists, Conditions),

    {DConditions, NConditions}
	= ?w_good_sql:filter_condition(inventory_new, Conditions, [], []),

    {StartTime, EndTime, CutNConditions}
    	= ?sql_utils:cut(fields_with_prifix, NConditions),

    {_, _, CutDCondtions}
    	= ?sql_utils:cut(fields_no_prifix, DConditions),

    CorrectCutDConditions = ?utils:correct_condition(<<"b.">>, CutDCondtions),
    
    CountSql = "select count(*) as total"
    	", SUM(b.amount) as t_amount"
    	%% ", SUM(b.fprice * b.fdiscount * b.total) as t_balance" 
    	" from w_inventory_new_detail b, w_inventory_new a" 
    	" where "
	++ ?sql_utils:condition(proplists_suffix, CorrectCutDConditions)
	++ "b.rsn=a.rsn"

    	++ ?sql_utils:condition(proplists, CutNConditions)
    	++ " and a.merchant=" ++ ?to_s(Merchant)
    	++ " and " ++ ?sql_utils:condition(time_with_prfix, StartTime, EndTime),
    Reply = ?sql_utils:execute(s_read, CountSql),
    {reply, Reply, State};
    
handle_call({filter_new_rsn_groups, Merchant,
	     CurrentPage, ItemsPerPage, Fields}, _From, State) ->
    ?DEBUG("filter_new_rsn_group_and: "
	   "currentPage ~p, ItemsPerpage ~p, Merchant ~p~n"
	   "fields ~p", [CurrentPage, ItemsPerPage, Merchant, Fields]), 
    Sql = ?w_good_sql:inventory(
	     new_rsn_group_with_pagination, Merchant,
	     Fields, CurrentPage, ItemsPerPage), 
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({new_rsn_detail, Merchant, Conditions}, _From, State) ->
    ?DEBUG("new_rsn_detail with merchant ~p, Conditions ~p",
	   [Merchant, Conditions]), 
    Sql = ?w_good_sql:inventory(new_rsn_detail, Merchant, Conditions),
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({get_new_amount, Merchant, Conditions}, _From, State) ->
    ?DEBUG("new_rsn_detail with merchant ~p, Conditions ~p",
	   [Merchant, Conditions]), 
    Sql = ?w_good_sql:inventory(get_new_amount, Merchant, Conditions),
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};


%% =============================================================================
%% fix
%% =============================================================================
handle_call({total_fix_rsn_groups, Merchant, Fields}, _From, State) ->
    Sql = "rsn",
    CountTable = ?sql_utils:count_table(w_inventory_fix, Sql, Merchant, Fields),
    CountSql = "select count(*) as total"
	", SUM(exist) as t_exist"
	", SUM(fixed) as t_fixed"
	", SUM(metric) as t_metric"
	" from w_inventory_fix_detail"
	" where rsn in(" ++ CountTable ++ ")",
    Reply = ?sql_utils:execute(s_read, CountSql),
    {reply, Reply, State}; 

handle_call({filter_fix_rsn_groups,
	     Merchant, CurrentPage, ItemsPerPage, Fields}, _From, State) ->
    ?DEBUG("filter_fix_rsn_group_and: currentPage ~p, ItemsPerpage ~p, Merchant ~p~n"
	   "fields ~p", [CurrentPage, ItemsPerPage, Merchant, Fields]), 
    Sql = ?w_good_sql:inventory(
	     fix_rsn_group_with_pagination, Merchant, Fields, CurrentPage, ItemsPerPage),
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State}; 

handle_call({fix_rsn_detail, Merchant, Conditions}, _From, State) ->
    ?DEBUG("rsn_detail with merchant ~p, Conditions ~p", [Merchant, Conditions]), 
    Sql = ?w_good_sql:inventory(fix_rsn_detail, Merchant, Conditions),
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

%%
%% export
%%
handle_call({new_trans_export, Merchant, Conditions}, _From, State)->
    ?DEBUG("new_trans_export with merchant ~p, condition ~p", [Merchant, Conditions]),
    {_, C} = ?w_good_sql:filter_condition(inventory_new, Conditions, [], []),
    SortConditions = ?w_good_sql:sort_condition(w_inventory_new, Merchant, C),
    Sql = "select a.id, a.rsn, a.employ as employee_id"
	", a.firm as firm_id, a.shop as shop_id"
	", a.balance, a.should_pay, a.has_pay, a.cash, a.card, a.wire"
	", a.verificate, a.total, a.comment, a.e_pay_type, a.e_pay"
	", a.type, a.state, a.entry_date"

	", b.name as firm"
	", c.name as shop"
	", d.name as employee"

	" from w_inventory_new a"
	" left join suppliers b on a.firm=b.id"
	" left join shops c on a.shop=c.id"
	" left join (select id, number, name from employees where merchant="
	++ ?to_s(Merchant) ++ ") d on a.employ=d.number"
	" where " ++ SortConditions ++ "order by a.id desc",
    
    Reply =  ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({new_trans_note_export, Merchant, Conditions}, _From, State)->
    ?DEBUG("new_trans_note_export: merchant ~p\nConditions~p", [Merchant, Conditions]),
    CorrectCondition = ?utils:correct_condition(<<"a.">>, Conditions),

    Sql = 
	"select a.id, a.rsn, a.style_number, a.brand_id, a.type_id, a.season"
	", a.amount as total, a.firm_id, a.year, a.discount, a.entry_date"
	", a.shop_id, a.employee_id, a.in_type"
	
	", b.name as brand"
	", d.name as type"
	", e.name as firm"
	", f.name as shop"
	", h.name as employee"

	" from ("
	"select a.id, a.rsn, a.style_number, a.brand as brand_id"
	", a.type as type_id, a.season, a.amount, a.firm as firm_id"
	", a.year, a.discount, a.entry_date"

	", b.shop as shop_id"
	", b.employ as employee_id"
	", b.type as in_type"

    %% ", c.color as color_id"
    %% ", c.size"
    %% ", c.total"

	" from w_inventory_new_detail a"
	" left join w_inventory_new b on a.rsn=b.rsn" 
    %% " right join w_inventory_new_detail_amount c on a.rsn=c.rsn"
    %% " and a.style_number=c.style_number and a.brand=c.brand"
	" where "
	++ ?utils:to_sqls(proplists, CorrectCondition) ++ " order by a.id desc) a"

	" left join brands b on a.brand_id=b.id"
    %% " left join colors c on a.color_id=c.id"
	" left join inv_types d  on a.type_id=d.id"
	" left join suppliers e on a.firm_id=e.id"

	" left join shops f on a.shop_id=f.id"
	" left join (select id, number, name from employees where merchant="
	++ ?to_s(Merchant) ++ ") h on a.employee_id=h.number", 
    
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({stock_export, Merchant, Conditions}, _From, State) ->
    {StartTime, EndTime, NewConditions} =
	?sql_utils:cut(fields_with_prifix, realy_conditions(Merchant, Conditions)),
    Sql =
	"select a.id, a.style_number, a.brand as brand_id"
	", a.type as type_id, a.sex, a.season, a.amount"
	", a.firm as firm_id, a.year"

	", a.org_price, a.tag_price, a.pkg_price, a.price3"
	", a.price4, a.price5, a.discount, a.shop as shop_id, a.entry_date"

	", b.name as shop"
	", c.name as brand"
	", d.name as type"
	", e.name as firm"

	" from w_inventory a"
	" left join shops b on a.shop=b.id"
	" left join brands c on a.brand=c.id"
	" left join inv_types d on a.type=d.id"
	" left join suppliers e on a.firm=e.id"

	" where "
	++ ?sql_utils:condition(proplists_suffix, NewConditions)
	++ "a.merchant=" ++ ?to_s(Merchant)
	++ case ?sql_utils:condition(time_with_prfix, StartTime, EndTime) of
	       [] -> [];
	       TimeSql ->  " and " ++ TimeSql
	   end
	++ " and a.deleted=" ++ ?to_s(?NO)
	++ " order by a.id desc",
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

%% @desc: generate a sn of record
rsn(new, Merchant, Shop, Rsn) ->
    lists:concat(["M-", ?to_i(Merchant), "-S-", ?to_i(Shop), "-", Rsn]);
rsn(reject, Merchant, Shop, Rsn) ->
    lists:concat(["M-", ?to_i(Merchant), "-S-", ?to_i(Shop), "-R-", Rsn]);
rsn(fix, Merchant, Shop, Rsn) ->
    lists:concat(["M-", ?to_i(Merchant), "-S-", ?to_i(Shop), "-", Rsn]).

%% @desc: geratte a sql
sql(wnew, RSN, Merchant, Shop, Firm, Date, DateTime, Inventories) ->
    RealyShop = realy_shop(Merchant, Shop),
    lists:foldr(
      fun({struct, Inv}, Acc0)->
	      Amounts      = lists:reverse(?v(<<"amount">>, Inv)),
	      ?w_good_sql:amount_new(
		 RSN, Merchant, RealyShop,
		 Firm, Date, DateTime, Inv, Amounts) ++ Acc0 
      end, [], Inventories);


sql(wreject, RSN, Merchant, Shop, Firm, Date, DateTime, Inventories) ->
    RealyShop = realy_shop(true, Merchant, Shop),
    lists:foldr(
      fun({struct, Inv}, Acc0)->
	      Amounts      = lists:reverse(?v(<<"amounts">>, Inv)),
	      ?w_good_sql:amount_reject(
		 RSN, Merchant, RealyShop,
		 Firm, Date, DateTime, Inv, Amounts) ++ Acc0 
      end, [], Inventories). 

sql(wfix, RSN, DateTime, Merchant, Shop, Inventories) ->
    %% Shop       = ?v(<<"shop">>, Props),
    %% Employe    = ?v(<<"employee">>, Props),

    lists:foldr(
      fun({struct, Inv}, Acc0)->
	      StyleNumber = ?v(<<"style_number">>, Inv),
	      Brand       = ?v(<<"brand">>, Inv),
	      Type        = ?v(<<"type">>, Inv),
	      Firm        = ?v(<<"firm">>, Inv),
	      Season      = ?v(<<"season">>, Inv),
	      SizeGroup   = ?v(<<"s_group">>, Inv),
	      Free        = ?v(<<"free">>, Inv),
	      Path        = ?v(<<"path">>, Inv),
	      Exist       = ?v(<<"exist">>, Inv),
	      Fixed       = ?v(<<"fixed">>, Inv),
	      Metric      = ?v(<<"metric">>, Inv),

	      Sql0 = 
		  ["insert into w_inventory_fix_detail(rsn, style_number, brand"
		   ", type, s_group, free, season, firm, path"
		   ", exist, fixed, metric, entry_date)"
		   " values("
		   ++ "\"" ++ ?to_s(RSN) ++ "\","
		   ++ "\"" ++ ?to_s(StyleNumber) ++ "\","
		   ++ ?to_s(Brand) ++ ","
		   ++ ?to_s(Type) ++ ","
		   ++ "\"" ++ ?to_s(SizeGroup) ++ "\","
		   ++ ?to_s(Free) ++ ","
		   ++ ?to_s(Season) ++ ","
		   ++ ?to_s(Firm) ++ ","
		   ++ "\'" ++ ?to_s(Path) ++ "\',"
		   %% ++ ?to_s(Shop) ++ ","
		   %% ++ ?to_s(Merchant) ++ ","
		   %% ++ ?to_s(Season) ++ ","
		   %% ++ ?to_s(Firm) ++ ","
		   %% ++ "\"" ++ ?to_s(Path) ++ "\","
		   %% ++ "\"" ++ ?to_s(Employe) ++ "\","
		   ++ ?to_s(Exist) ++ ","
		   ++ ?to_s(Fixed) ++ ","
		   ++ ?to_s(Metric) ++ ","
		   ++ "\'" ++ ?to_s(DateTime) ++ "\')",
		  "update w_inventory set amount=amount+" ++ ?to_s(Metric)
		   ++ " where style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
		   ++ " and brand=" ++ ?to_s(Brand)
		   ++ " and shop=" ++ ?to_s(Shop)
		   ++ " and merchant=" ++ ?to_s(Merchant)],

	      Amounts     = lists:reverse(?v(<<"amounts">>, Inv)),
	      
	      Sql0 ++ 
		  lists:foldr(
		    fun({struct, A}, Acc1)->
			    Color  = ?v(<<"cid">>, A),
			    Size   = ?v(<<"size">>, A),
			    AExist  = ?v(<<"count">>, A),
			    AFixed  = ?v(<<"fixed_count">>, A), 
			    AMetric = AFixed - AExist,

			    ["update w_inventory_amount set total=total+" ++ ?to_s(AMetric)
			     ++ " where style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
			     ++ " and brand=" ++ ?to_s(Brand)
			     ++ " and color=" ++ ?to_s(Color)
			     ++ " and size=" ++ "\'" ++ ?to_s(Size) ++ "\'"
			     ++ " and shop=" ++ ?to_s(Shop)
			     ++ " and merchant=" ++ ?to_s(Merchant),
			     "insert into w_inventory_fix_detail_amount(rsn"
			     ", style_number, brand, color, size"
			     ", exist, fixed, metric, entry_date)"
			     " values("
			     ++ "\'" ++ ?to_s(RSN) ++ "\',"
			     ++ "\'" ++ ?to_s(StyleNumber) ++ "\',"
			     ++ ?to_s(Brand) ++ ","
			     ++ ?to_s(Color) ++ ","
			     ++ "\'" ++ ?to_s(Size) ++ "\'," 
			     ++ ?to_s(AExist) ++ ","
			     ++ ?to_s(AFixed) ++ ","
			     ++ ?to_s(AMetric) ++ ","
			     ++ "\'" ++ ?to_s(DateTime) ++ "\')"|Acc1] 
		    end, [], Amounts) ++ Acc0

      end, [], Inventories).

count_table(w_inventory_new, Merchant, Conditions) -> 
    %% SubSql = "select a.rsn, a.total, a.should_pay, a.has_pay"
    %% 	", a.cash, a.card, a.wire, a.verificate"
    %% 	" from w_inventory_new a"
    %% 	" where "
    %% 	++ ?w_good_sql:sort_condition(w_inventory_new, Merchant, Conditions),

    CountSql = "select count(*) as total"
    	", sum(a.total) as t_amount"
    	", sum(a.should_pay) as t_spay"
    	", sum(a.has_pay) as t_hpay"
    	", sum(a.cash) as t_cash"
    	", sum(a.card) as t_card"
    	", sum(a.wire) as t_wire"
    	", sum(a.verificate) as t_verificate"
	" from w_inventory_new a where "
	++ ?w_good_sql:sort_condition(w_inventory_new, Merchant, Conditions),
    CountSql.


realy_shop(Merchant, ShopIds) when is_list(ShopIds) ->
    realy_shop(false, Merchant, ShopIds);
realy_shop(Merchant, ShopId) ->
    realy_shop(false, Merchant, ShopId).

realy_shop(UseBad, Merchant, ShopIds) when is_list(ShopIds) ->
    %% get all shops 
    case ?w_user_profile:get(shop, Merchant) of
	{ok, []} -> ShopIds;
	{ok, AllShops} ->
	    AllIds = 
		lists:foldr(
		  fun({Shop}, Acc) ->
			  ShopId = ?v(<<"id">>, Shop),
			  case lists:member(ShopId, ShopIds) of
			      true ->
				  case ?v(<<"repo">>, Shop) of
				      -1 ->
					  [ShopId|Acc];
				      Repo ->
					  case ?v(<<"type">>, Shop) =:= ?BAD_REPERTORY
					      andalso UseBad of
					      true  -> [ShopId|Acc];
					      false -> [Repo|Acc]
					  end
				  end;
			      false -> Acc
			  end
		  end, [], AllShops),
	    lists:usort(AllIds)
    end;
	    
	    %% [case lists:member(?v(<<"id">>, Shop), ShopIds) of
	    %% 	 true ->
	    %% 	     case ?v(<<"repo">>, Shop) of
	    %% 		 -1 ->
	    %% 		     ?v(<<"id">>, Shop);
	    %% 		 Repo ->
	    %% 		     case ?v(<<"type">>, Shop) =:= ?BAD_REPERTORY
	    %% 			 andalso UseBad of
	    %% 			 true  -> ?v(<<"id">>, Shop);
	    %% 			 false -> Repo
	    %% 		     end
	    %% 	     end;
	    %% 	 false -> []
	    %%  end || Shop <- AllShops]
	%%  end;
    
realy_shop(UseBad, Merchant, ShopId) ->
    case ?w_user_profile:get(shop, Merchant, ShopId) of
	{ok, []} -> ShopId;
	{ok, [{ShopInfo}]} -> 
	    case ?v(<<"repo">>, ShopInfo) of
		-1 -> ShopId;
		RepoId ->
		    case ?v(<<"type">>, ShopInfo) =:= ?BAD_REPERTORY
			andalso UseBad of
			true -> ?v(<<"id">>, ShopInfo);
			_ -> RepoId
		    end
	    end
    end.

realy_conditions(Merchant, Conditions) ->
    lists:foldr(
      fun({<<"shop">>, Shop}, Acc) -> 
	      [{<<"shop">>, realy_shop(true, Merchant, Shop)}|Acc];
	 (C, Acc) ->
	      [C|Acc]
      end, [], Conditions).

%% get_setting([], _Key, Value) ->
%%     Value;
%% get_setting([S|T], Key, Value) ->
%%     case Key =:= ?v(<<"ename">>, S) of
%% 	true -> get_setting([], Key, ?v(<<"value">>, S));
%% 	false -> get_setting(T, Key, Value)
%%     end.
	    
