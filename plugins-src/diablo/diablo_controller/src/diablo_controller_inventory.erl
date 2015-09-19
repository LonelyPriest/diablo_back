%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 17 Sep 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_controller_inventory).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_server).

%% API
-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-export([inventory/2, inventory/3]).
-export([lookup/2, lookup/3, lookup/4]).

-export([pagination/4, pagination/5, do_filter/4, do_filter/6]).
-export([save_prompt/3, time_condition/3]).

-define(SERVER, ?MODULE). 
-define(tbl_inventory, "inventory_service").


-record(state, {}).

%%%===================================================================
%%% API
%%%===================================================================
%% inventory(color) ->
%%     gen_server:call(?MODULE, list_color);
inventory(color, Merchant) ->
    gen_server:call(?MODULE, {list_color, Merchant});
inventory(brand, Merchant) ->
    gen_server:call(?MODULE, {list_brand, Merchant});
inventory(type, Merchant) ->
    gen_server:call(?MODULE, {list_type, Merchant});
inventory(total, Conditions) ->
    gen_server:call(?MODULE, {inventory_total, Conditions});

inventory(new, Attrs) ->
    gen_server:call(?MODULE, {new_inventory, Attrs});
inventory(delete, Condition) ->
    gen_server:call(?MODULE, {delete_inventory, Condition});

inventory(update, Payload) ->
    gen_server:call(?MODULE, {update_inventory, Payload});
inventory(check, Payload) ->
    gen_server:call(?MODULE, {check_inventory, Payload});
inventory(pre_move, Payload) ->
    gen_server:call(?MODULE, {pre_move_inventory, Payload});
inventory(do_move, Payload) ->
    gen_server:call(?MODULE, {do_move_inventory, Payload});
inventory(do_reject, Payload) ->
    gen_server:call(?MODULE, {do_reject_inventory, Payload});

inventory(get_color_id, ColorName)->
    gen_server:call(?MODULE, {get_color_id, ColorName}).

inventory(adjust_price, Plan, Condition) ->
    gen_server:call(?MODULE, {adjust_inventory_price, Plan, Condition}).


lookup(by_merchant, Merchant) ->
    gen_server:call(?MODULE, {lookup_by_merchant, Merchant});
lookup(style_number, Merchant) ->
    gen_server:call(?MODULE, {lookup_style_number, Merchant});
lookup(move, Merchant) ->
    gen_server:call(?MODULE, {lookup_move_by_merchant, Merchant});
lookup(reject, Merchant) ->
    gen_server:call(?MODULE, {lookup_reject_by_merchant, Merchant}).

lookup(move, Merchant, Condition) ->
    gen_server:call(?MODULE, {lookup_move_with_condition, Merchant, Condition});

lookup(style_number_with_shop, Merchant, ShopIds) when is_list(ShopIds)->
    gen_server:call(?MODULE, {lookup_style_number_with_shop, Merchant, ShopIds});
lookup(style_number_with_shop, Merchant, ShopId) ->
    gen_server:call(?MODULE, {lookup_style_number_with_shop, Merchant, [ShopId]});

%% get record with shop
lookup(by_shop, ShopId, Merchant) when is_integer(ShopId)->
    gen_server:call(?MODULE, {lookup_by_shop, [ShopId], Merchant});
lookup(by_shop, ShopIds, Merchant) ->
    gen_server:call(?MODULE, {lookup_by_shop, ShopIds, Merchant});

%% with style_number
lookup(by_style_number, StyleNumber, Merchant) ->
    gen_server:call(?MODULE, {lookup_by_style_number, StyleNumber, Merchant});

lookup(by_condition, Condition, Merchant) ->
    gen_server:call(?MODULE, {lookup_by_condition, Condition, Merchant});

lookup(by_group, Group, Merchant) ->
    gen_server:call(?MODULE, {lookup_by_group, Group, Merchant});

lookup(unchecked, Shop, Merchant) ->
    gen_server:call(?MODULE, {lookup_unchecked, Shop, Merchant}).


%% wtih style_number and shop
lookup(by_style_number_and_shop, Merchant, StyleNumber, Shop) ->
    gen_server:call(
      ?MODULE, {lookup_by_style_number_and_shop, Merchant, StyleNumber, Shop}). 

pagination(by_merchant, CurrentPage, CountPerPage, Merchant) ->
    gen_server:call(?MODULE,
		    {pagination_by_merchant, CurrentPage, CountPerPage, Merchant}).

pagination(by_shop, CurrentPage, CountPerPage, ShopIds, Merchant) ->
    gen_server:call(?MODULE,
		    {pagination_by_shop, CurrentPage, CountPerPage, ShopIds, Merchant}).

do_filter(total_with_filter, 'and', Merchant, Fields) ->
    gen_server:call(?MODULE, {total_with_filter, Merchant, Fields}).

do_filter(pagination, CurrentPage, CountPerPage, 'and', Merchant, Fields) ->
    gen_server:call(?MODULE, {pagination_with_filter,
			      CurrentPage, CountPerPage, Merchant, Fields}).

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
init([]) ->
    {ok, #state{}}.

handle_call({get_color_id, ColorName}, _Form, State) ->
    ?DEBUG("get_color_id with colors name ~p", [ColorName]),
    Sql = "select id, name"
	++ " from colors"
	++ " where deleted = " ++ ?to_string(?NO)
	++ " and type=0"
	++ " and name=" ++ "\'" ++ ?to_string(ColorName) ++ "\';",
    {ok, {Color}} = ?mysql:fetch(read, Sql),
    {reply, ?value(<<"id">>, Color), State};


handle_call({list_color, Merchant}, _Form, State) ->
    ?DEBUG("list colors with merchant ~p", [Merchant]),
    Sql = "select id, name from colors"
	++ " where type=0"
	++ " and merchant=" ++ ?to_s(Merchant)
	++ " and deleted = " ++ ?to_string(?NO) ++ ";",
    {ok, Colors} = ?mysql:fetch(read, Sql),
    {reply, Colors, State};

handle_call({list_brand, Merchant}, _Form, State) ->
    ?DEBUG("list brand of inventory"),
    Sql = "select id, name from brands"
	++ " where "
	++ " merchant = " ++ ?to_string(Merchant)
	++ " and deleted = " ++ ?to_string(?NO) ++ ";",
    {ok, Brands} = ?mysql:fetch(read, Sql),
    {reply, Brands, State};

handle_call({list_type, Merchant}, _Form, State) ->
    ?DEBUG("list types of inventory"),
    Sql = "select id, name from inv_types"
	++ " where "
	++ " merchant = " ++ ?to_string(Merchant)
	++ " and deleted = " ++ ?to_string(?NO) ++ ";",
    {ok, Types} = ?mysql:fetch(read, Sql),
    {reply, Types, State};

handle_call({new_inventory, Attrs}, _From, State)->
    ?DEBUG("new inventory with attrs~n ~p", [Attrs]),
    Brand       = ?value(<<"brand">>, Attrs),
    StyleNumber = ?value(<<"number">>, Attrs),
    Type        = ?value(<<"type">>, Attrs),
    Color       = ?value(<<"color">>, Attrs),
    Price       = ?value(<<"price">>, Attrs),
    Discount    = ?value(<<"discount">>, Attrs),
    Year        = ?value(<<"year">>, Attrs),
    Season      = ?value(<<"season">>, Attrs),
    Sex         = ?value(<<"sex">>, Attrs),
    %% Supplier    = ?value(<<"supplier">>, Attrs),
    Merchant    = ?value(<<"merchant">>, Attrs),
    Shop        = ?value(<<"shop">>, Attrs),
    %% SizeGroup   = ?value(<<"size_group">>, Attrs, -1),
    Amounts     = ?value(<<"amount">>, Attrs),
    
    ColorId = save_prompt(colors, Color, Merchant),
    BrandId = save_prompt(brands, Brand, Merchant),
    TypeId  = save_prompt(inv_types, Type, Merchant),

    %% cancel the condition, because the same inventory can be entered
    %% on different day 

    Sql2 = 
	lists:foldl(
	  fun({struct, Amount}, Acc) ->
		  Size = ?v(<<"size">>, Amount),
		  Count = ?v(<<"count">>, Amount),

		  Sql0 = "select sn from inventory_to_shop"
		      " where style_number=\"" ++ ?to_s(StyleNumber) ++ "\""
		      ++ " and brand=" ++ ?to_s(BrandId)
		      ++ " and color=" ++ ?to_s(ColorId)
		      ++ " and size=" ++ "\"" ++ ?to_s(Size) ++ "\";",

		  Sn = case ?mysql:fetch(read, Sql0) of
			   {ok, []} ->
			       U = ?inventory_sn:sn(ad, Merchant),
			       sn(Shop, Merchant, U); 
			   {ok, R} ->
			       ?v(<<"sn">>, R)
		       end, 
		  
		  Acc ++ 
		      ["insert into inventory_to_shop"
		       ++ "(sn, style_number, sex, color, season"
		       ++ ", year, type, size, amount"
		       ++ ", brand, plan_price, discount, shop, merchant, state"
		       ++ " ,rdate) values("
		       ++ "\"" ++ ?to_s(Sn) ++ "\","
		       ++ "\"" ++ ?to_s(StyleNumber) ++ "\","
		       ++ ?to_s(Sex) ++ ","
		       ++ ?to_s(ColorId) ++ ","
		       ++ ?to_s(Season) ++ ","
		       ++ "\"" ++ ?to_s(Year) ++ "\","
		       ++ ?to_s(TypeId) ++ ","
		       ++ "\"" ++ ?to_s(Size) ++ "\","
		       %% ++ ?to_s(SizeGroup) ++ ","
		       ++ ?to_s(Count) ++ ","
		       ++ ?to_s(BrandId) ++ ","
		       ++ ?to_s(Price) ++ ","
		       ++ ?to_s(Discount) ++ ","
		       ++ ?to_s(Shop) ++ ","
		       ++ ?to_s(Merchant) ++ ","
		       ++ ?to_s(state(wait_check)) ++ ","
		       ++ "\"" ++ ?utils:current_time(localtime) ++ "\");"]
	  end, [], Amounts),

    %% Sql3 = 
    %% 	case ?mysql:fetch(read, Sql1) of
    %% 	{ok, []} ->
    %% 		["insert into inventory_service"
    %% 		 ++ "(style_number, brand ,plan_price, discount, merchant)"
    %% 		 ++ " values ("
    %% 		 %% ++ "\"" ++ ?to_string(Sn) ++ "\","
    %% 		 ++ "\"" ++ ?to_string(StyleNumber) ++ "\","
    %% 		 ++ ?to_string(BrandId) ++ ","
    %% 		 %% ++ ?to_string(TypeId) ++ ","
    %% 		 %% ++ ?to_string(Sex) ++ ","
    %% 		 %% ++ ?to_string(Season) ++ ","
    %% 		 %% ++ "\"" ++ ?to_string(Size) ++ "\","
    %% 		 %% ++ ?to_string(SizeGroup) ++ ","
    %% 		 ++ ?to_string(Price) ++ ","
    %% 		 ++ ?to_string(Discount) ++ ","
    %% 		 %% ++ ?to_string(ColorId) ++ ","
    %% 		 %% ++ case Shop of
    %% 		 %% 	 undefined ->
    %% 		 %% 	     ?to_string(Count) ++ ",";
    %% 		 %% 	 Shop ->
    %% 		 %% 	     ?to_string(0) ++ ","
    %% 		 %%    end
    %% 		 %% ++ case Supplier of
    %% 		 %% 	undefined ->
    %% 		 %% 	    ?to_string(-1) ++ ",";
    %% 		 %% 	Supplier ->
    %% 		 %% 	    ?to_string(Supplier) ++ ","
    %% 		 %%    end
    %% 		 ++ ?to_string(Merchant) ++ ");"]
    %% 		    ++ Sql2;
    %% 	    {ok, _} ->
    %% 		Sql2
    %% 	end,
		

    ?DEBUG("sql to inventory ~ts", [Sql2]),
    case ?mysql:fetch(transaction, Sql2) of
	{error, Error} ->
	    ?DEBUG("failed to new inventory, error: ~p", [Error]),
	    {reply, {error, ?err(db_error, Error)}, State};
	{ok, _} ->
	    {reply, {ok, StyleNumber}, State}
    end;


handle_call({delete_inventory, Condition}, _From, State) ->
    ?DEBUG("delete inventory with condtion ~p", [Condition]),
    C = ?utils:to_sqls(proplists, Condition),
    %% Sql = "delete from " ++ ?tbl_inventory ++ " where " ++ C ++ ";",
    Sql = "update inventory_to_shop" ++
	" set deleted = " ++ ?to_string(?YES) ++ " where " ++ C ++ ";",    
    {ok, _} = ?mysql:fetch(write, ?to_binary(Sql)),
    {reply, ok, State};

handle_call({update_inventory, Payload}, _From, State) ->
    ?DEBUG("Update inventory with condtion:~npayload ~p", [Payload]),

    NStyleNumber  = v(check_style_number, style_number, string, Payload),
    NBrand        = v(check_brand, brand, integer, Payload),
    Type          = v(check_type, type, integer, Payload),
    PlanPrice     = v(check_plan_price, plan_price, float, Payload),
    Discount      = v(check_discount, discount, integer, Payload),

    Merchant      = ?v(<<"merchant">>, Payload),
    StyleNumber   = ?v(<<"style_number">>, Payload),
    Brand         = ?v(<<"brand">>, Payload),
    Shop          = ?v(<<"shop">>, Payload),
    UpdateAmounts = ?v(<<"update_amounts">>, Payload, []),

    UpdateValues = NStyleNumber ++ NBrand ++ Type ++ PlanPrice ++ Discount,

    Sql0 =
	case UpdateAmounts of
	    [] ->
		["update inventory_to_shop set "
		 ++ ?utils:to_sqls(proplists, comma, UpdateValues)
		 ++ " where merchant=" ++ ?to_s(Merchant)
		 ++ " and style_number=\"" ++ ?to_s(StyleNumber) ++ "\""
		 ++ " and brand=" ++ ?to_s(Brand)
		 ++ " and state=" ++ ?to_s(state(wait_check))
		 ++ " and shop="  ++ ?to_s(Shop)
		 ++ " and deleted=" ++ ?to_s(?NO)];
	    UpdateAmounts ->
		lists:foldr(
		  fun({struct, A}, Acc) ->
			  %% record
			  Color = ?v(<<"cid">>, A),
			  Size  = ?v(<<"size">>, A),
			  Count = ?v(<<"count">>, A),

			  Sql1 = "select id, style_number, brand, "
			      "color, size, state, shop from inventory_to_shop"
			      ++ " where merchant=" ++ ?to_s(Merchant)
			      ++ " and style_number=\"" ++ ?to_s(StyleNumber) ++ "\""
			      ++ " and brand=" ++ ?to_s(Brand)
			      ++ " and color=" ++ ?to_s(Color)
			      ++ " and size=" ++ "\"" ++ ?to_s(Size) ++ "\""
			      ++ " and state=" ++ ?to_s(state(wait_check))
			      ++ " and shop="  ++ ?to_s(Shop)
			      ++ " and deleted=" ++ ?to_s(?NO),

			  {UseId, NouseIds} =
			      case ?mysql:fetch(read, Sql1) of
				  {ok, {One}} -> {?v(<<"id">>, One), []};
				  {ok, Many} when is_list(Many) ->
				      [First|Rest] = 
					  lists:foldr(
					    fun({R}, Acc1) ->
						    [?v(<<"id">>, R)|Acc1]
					    end, [], Many),
				      {First, Rest}
			      end,

			  ["update inventory_to_shop set amount="
			   ++ ?to_s(Count) ++ ","
			   ++ ?utils:to_sqls(proplists, comma, UpdateValues)
			   ++ " where id=" ++ ?to_s(UseId)
			   %% ++ " and shop="  ++ ?to_s(Shop)
			   %% ++ " and deleted=" ++ ?to_s(?NO)
			   %% ++ " where style_number=" ++ "\"" ++ ?to_s(StyleNumber) ++ "\""
			   %% ++ " and brand=" ++ ?to_s(Brand)
			   %% ++ " and color=" ++ ?to_s(Color)
			   %% ++ " and size=" ++ "\"" ++ ?to_s(Size) ++ "\""
			   %% ++ " and state=" ++ ?to_s(state(wait_check))
			   %% ++ " and shop="  ++ ?to_s(Shop)
			   %% ++ " and deleted=" ++ ?to_s(?NO) 
			  ] ++ case NouseIds of
				   [] -> Acc;
				   NouseIds ->
				       ["update inventory_to_shop set deleted="
					++ ?to_s(?YES) ++ " where "
					++ ?utils:to_sqls(proplists, {<<"id">>, NouseIds})]
					   ++ Acc
			       end 
		  end, [], UpdateAmounts)
	end,
    
    ?DEBUG("sql ~p", [Sql0]),
    case ?mysql:fetch(transaction, Sql0) of
    	{ok, _} ->
    	    {reply, ok, State};
    	{error, Error} ->
    	    {reply, {error, ?err(db_error, Error)}, State} 
    end;


handle_call({check_inventory, Payload}, _From, State) ->
    ?DEBUG("check inventory with condtion:~npayload ~p", [Payload]),
    %% Brand        = v(brand, brand, integer, Payload),
    %% NStyleNumber = ?v(<<"check_style_number">>, Payload),
    %% OStyleNumber = v(old_style_number, style_number, string, Payload),
    %% Color        = v(color, color, integer, Payload),
    
    Type         = v(check_type, type, integer, Payload),
    OrgPrice     = v(check_org_price, org_price, float, Payload),
    PlanPrice    = v(check_plan_price, plan_price, float, Payload),
    Discount     = v(check_discount, discount, integer, Payload),
    
    %% Year         = v(year, year, string, Payload), 
    Supplier     = v(supplier, supplier, integer, Payload),
    CheckDate    = v(check_date, check_date, string, Payload),
    CheckState   = v(check_state, state, integer, Payload), 
    
    Values =
	Type ++ PlanPrice ++ Discount ++ Supplier
	++ OrgPrice ++ CheckState ++ CheckDate,

    Merchant     = ?v(<<"merchant">>, Payload),
    StyleNumber  = ?v(<<"style_number">>, Payload),
    Brand        = ?v(<<"brand">>, Payload),
    Amounts      = ?v(<<"check_amounts">>, Payload, []),
    Shop         = ?v(<<"shop">>, Payload, []), 
    
    Sql0 =
	case Amounts of
	    [] ->
		?DEBUG("values ~p", [Values]),
		%% ?DEBUG("sql ~p", [?utils:to_sqls(proplists, comma, Values)]),
		["update inventory_to_shop set check_num=check_num+1,"
		 ++ ?utils:to_sqls(proplists, comma, Values)
		 ++ " where merchant=" ++ ?to_s(Merchant)
		 ++ " and style_number=\"" ++ ?to_s(StyleNumber) ++ "\""
		 ++ " and brand=" ++ ?to_s(Brand)
		 ++ " and state=" ++ ?to_s(state(wait_check))
		 ++ " and shop="  ++ ?to_s(Shop)
		 ++ " and deleted=" ++ ?to_s(?NO)];
	    Amounts ->
	      lists:foldr(
		fun({struct, A}, Acc) ->
			%% record
			Color = ?v(<<"cid">>, A),
			Size  = ?v(<<"size">>, A),
			Count = ?v(<<"count">>, A),

			Sql1 = "select id, style_number, brand, "
			    "color, size, state, shop from inventory_to_shop"
			    ++ " where merchant=" ++ ?to_s(Merchant)
			    ++ " and style_number=\"" ++ ?to_s(StyleNumber) ++ "\"" 
			    ++ " and brand=" ++ ?to_s(Brand)
			    ++ " and color=" ++ ?to_s(Color)
			    ++ " and size=" ++ "\"" ++ ?to_s(Size) ++ "\""
			    ++ " and state=" ++ ?to_s(state(wait_check))
			    ++ " and shop="  ++ ?to_s(Shop)
			    ++ " and deleted=" ++ ?to_s(?NO),
			
			{UseId, NouseIds} =
			    case ?mysql:fetch(read, Sql1) of
				{ok, {One}} -> {?v(<<"id">>, One), []};
				{ok, Many} when is_list(Many) ->
				    [First|Rest] = 
					lists:foldr(
					  fun({R}, Acc1) ->
						  [?v(<<"id">>, R)|Acc1]
					  end, [], Many),
				    {First, Rest}
			    end,
			
			["update inventory_to_shop set check_num=check_num+1,"
			 "amount=" ++ ?to_s(Count) ++ ","
			 ++ ?utils:to_sqls(proplists, comma, Values)
			 ++ " where id=" ++ ?to_s(UseId)
			 %% ++ " and shop="  ++ ?to_s(Shop)
			 %% ++ " and deleted=" ++ ?to_s(?NO)
			 %% ++ " where style_number=" ++ "\"" ++ ?to_s(StyleNumber) ++ "\""
			 %% ++ " and brand=" ++ ?to_s(Brand)
			 %% ++ " and color=" ++ ?to_s(Color)
			 %% ++ " and size=" ++ "\"" ++ ?to_s(Size) ++ "\""
			 %% ++ " and state=" ++ ?to_s(state(wait_check))
			 %% ++ " and shop="  ++ ?to_s(Shop)
			 %% ++ " and deleted=" ++ ?to_s(?NO) 
			] ++ case NouseIds of
				 [] -> Acc;
				 NouseIds ->
				     ["update inventory_to_shop set deleted="
				      ++ ?to_s(?YES) ++ " where "
				      ++ ?utils:to_sqls(proplists, {<<"id">>, NouseIds})]
					 ++ Acc
			     end 
		end, [], Amounts)
	end,

    ?DEBUG("sql ~p", [Sql0]),
    case ?mysql:fetch(transaction, Sql0) of
    	{ok, _} ->
    	    {reply, ok, State};
    	{error, Error} ->
    	    {reply, {error, ?err(db_error, Error)}, State} 
    end;

handle_call({pre_move_inventory, Payload}, _From, State) ->
    ?DEBUG("pre_move_inventory with payload ~p", [Payload]),
    Sn       = ?value(<<"sn">>, Payload),
    StyleNumber = ?value(<<"style_number">>, Payload),
    Source   = ?value(<<"source">>, Payload),
    Target   = ?value(<<"target">>, Payload),
    Amount   = ?value(<<"amount">>, Payload),
    Merchant = ?value(<<"merchant">>, Payload),

    Sql1 = "insert into inventory_to_move("
	++ "sn, style_number, source, target, amount, merchant"
	++ ", move_date) values("
	++ "\"" ++ ?to_string(Sn) ++ "\","
	++ "\"" ++ ?to_string(StyleNumber) ++ "\","
	++ ?to_string(Source)   ++ ","
	++ ?to_string(Target)   ++ ","
	++ ?to_string(Amount)   ++ ","
	++ ?to_string(Merchant) ++ ","
	++ "\"" ++ ?utils:current_time(localtime) ++ "\");",
    
    Sql2 = "update inventory_to_shop set amount=amount-" ++ ?to_string(Amount)
	++ " where sn="++ "\"" ++ ?to_string(Sn) ++ "\";",

    case ?mysql:fetch(transaction, [Sql1, Sql2]) of
	{error, Error} ->
	    {reply, {error, ?err(db_error, Error)}, State};
	{ok, _} ->
	    {reply, {ok, Sn}, State}
    end;

handle_call({do_move_inventory, Payload}, _From, State) ->
    ?DEBUG("do_move_inventory with payload ~p", [Payload]),
    Sn          = ?value(<<"sn">>, Payload),
    Target      = ?value(<<"target">>, Payload),
    Amount      = ?value(<<"amount">>, Payload),
    Merchant    = ?value(<<"merchant">>, Payload),

    %% get inventory propertis
    Sql0 = "select style_number, sex, color, type, size, size_group"
	++" ,brand, supplier, org_price"
	++" from inventory_to_shop where sn=" ++ "\"" ++ ?to_string(Sn) ++ "\";",

    case ?mysql:fetch(read, Sql0) of
	{ok, []} ->
	    {reply, {error, ?err(move_invalid_inventory, Sn)}, State};
	{ok, {Attr}} ->
	    NewSn     = sn(Target, Merchant, ?inventory_sn:sn(ad, Merchant)),
	    SNumber   = ?value(<<"style_number">>, Attr),
	    Sex       = ?value(<<"sex">>, Attr),
	    Color     = ?value(<<"color">>, Attr),
	    Type      = ?value(<<"type">>, Attr),
	    Size      = ?value(<<"size">>, Attr),
	    SizeGroup = ?value(<<"size_group">>, Attr),
	    Brand     = ?value(<<"brand">>, Attr),
	    Supplier  = ?value(<<"supplier">>, Attr),
	    OrgPrice  = ?value(<<"org_price">>, Attr),
	    Sql1 = "insert into inventory_to_shop("
		++ "sn, style_number, sex, color, type, size"
		++ " ,size_group, amount, brand, supplier, org_price"
		++ " ,shop ,merchant ,rdate) values("
		++ "\"" ++ ?to_string(NewSn) ++ "\","
		++ "\"" ++ ?to_string(SNumber) ++ "\","
		++ ?to_string(Sex) ++ ","
		++ ?to_string(Color) ++ ","
		++ ?to_string(Type) ++ ","
		++ "\"" ++ ?to_string(Size) ++ "\","
		++ ?to_string(SizeGroup)   ++ ","
		++ ?to_string(Amount)   ++ ","
		++ ?to_string(Brand)   ++ ","
		++ ?to_string(Supplier)   ++ ","
		++ ?to_string(OrgPrice)   ++ ","
		++ ?to_string(Target)   ++ ","
		++ ?to_string(Merchant) ++ ","
		++ "\"" ++ ?utils:current_time(localtime) ++ "\");",
	    
	    Sql2 = "update inventory_to_move set state=1"
		++ " where sn="++ "\"" ++ ?to_string(Sn) ++ "\";",
	    
	    case ?mysql:fetch(transaction, [Sql1, Sql2]) of
		{error, Error} ->
		    {reply, {error, ?err(db_error, Error)}, State};
		{ok, _} ->
		    {reply, {ok, Sn}, State}
	    end
    end;

handle_call({do_reject_inventory, Payload}, _From, State) ->
    Sn          = ?value(<<"sn">>, Payload),
    StyleNumber = ?value(<<"style_number">>, Payload),
    Shop        = ?value(<<"shop">>, Payload),
    Amount      = ?value(<<"amount">>, Payload),
    Merchant    = ?value(<<"merchant">>, Payload),

    case check_inventory_amount(Merchant, Sn, Amount) of
	ok ->
	    Sql1 = "insert into inventory_reject_to_supplier(sn"
		", style_number, shop, amount, merchant, reject_date)"
		"values("
		++ "\"" ++ ?to_string(Sn) ++ "\","
		++ "\"" ++ ?to_string(StyleNumber) ++ "\","
		++ ?to_string(Shop) ++ ","
		++ ?to_string(Amount) ++ ","
		++ ?to_string(Merchant) ++ ","
		++ "\"" ++ ?utils:current_time(localtime) ++ "\");",

	    Sql2 = "update inventory_to_shop set amount=amount-" ++ ?to_string(Amount)
		++ " where sn="++ "\"" ++ ?to_string(Sn) ++ "\";",

	    case ?mysql:fetch(transaction, [Sql1, Sql2]) of
		{error, Error} ->
		    {reply, {error, ?err(db_error, Error)}, State};
		{ok, _} ->
		    {reply, {ok, Sn}, State}
	    end;
	{error, Error} ->
	    {reply, Error}
    end;

handle_call({adjust_inventory_price, Plan, Condition}, _From, State)->
    ?DEBUG("adjust_inventory_price with plan ~p, condition ~p",
	   [Plan, Condition]),
    Sql = "update inventory_to_shop set "
	++ ?utils:to_sqls(proplists, comma, Plan)
	++ " where " ++ ?utils:to_sqls(proplists, Condition) ++ ";",
    ?DEBUG("sql to adjust_price ~ts", [Sql]),
    
    case ?mysql:fetch(write, Sql) of
	{ok, _} -> {reply, ok, State};
	{error, Error} ->
	    {reply, {error, ?err(db_error, Error)}, State}
    end;

handle_call({lookup_style_number, Merchant}, _From, State) ->
    ?DEBUG("lookup all style_number ", []),
    Sql1 = "select DISTINCT style_number "
	++ " from inventory_to_shop"
	++ " where "
	++ " merchant = " ++ ?to_string(Merchant)
	++ " and deleted = " ++ ?to_string(?NO) ++ ";",
    
    ?DEBUG("sql to inventory_to_shop ~p", [Sql1]),
    {ok, Numbers} = ?mysql:fetch(read, Sql1),
    {reply, Numbers, State};

handle_call({lookup_style_number_with_shop, Merchant, ShopIds}, _From, State) ->
    ?DEBUG("lookup style_number with shop ~p", [ShopIds]),
    Sql1 = "select DISTINCT style_number "
	++ " from inventory_to_shop"
	++ " where "
	++ " deleted = " ++ ?to_string(?NO)
	++ " and merchant = " ++ ?to_string(Merchant)
	++ " and shop in ("
	++ string:join([?to_s(Id) || Id <- ShopIds], ",") ++ ");",

    ?DEBUG("sql to inventory ~p", [Sql1]),
    {ok, Numbers} = ?mysql:fetch(read, Sql1),
    {reply, Numbers, State};

%% handle_call({lookup_color_to_brand, Merchant}, _From, State) ->
%%     ?DEBUG("lookup color_to_brand with merchant ~p", [Merchant]),
%%     Sql = "select a.id, a.remark, b.name, c.name"
%% 	++ " from color_to_brand a"
%% 	++ " left join brands b on a.brand=b.id"
%% 	++ " left join colors c on a.color=c.id"
%% 	++ " where a.merchant = " ++ ?to_string(Merchant)
%% 	++ " and a.deleted = " ++ ?to_string(?NO) ++ ";",
%%     {ok, Colors} = ?mysql:fetch(read, Sql),

%%     %% make sure result is a list
%%     {reply, ?to_tuplelist(Colors), State};


handle_call({lookup_by_merchant, Merchant}, _From, State) ->
    ?DEBUG("lookup_by_merchant inventory ", []),
    {ok, Inventories} =
	?mysql:fetch(read, sql(find_with_shop, {<<"merchant">>, Merchant})),
    {reply, Inventories, State};

handle_call({lookup_by_shop, ShopIds, Merchant}, _From, State) ->
    ?DEBUG("lookup inventory with shopIds ~p", [ShopIds]),
    Sql = sql(find_with_shop, [{<<"merchant">>, Merchant},
			       {<<"shop">>, ShopIds}]),
    {ok, Inventories} = ?mysql:fetch(read, Sql),
    {reply, Inventories, State};

handle_call({lookup_by_condition, Condition, Merchant}, _From, State) ->
    ?DEBUG("lookup_by_condtion with condition ~p, merchant ~p",
	   [Condition, Merchant]),
    Sql = sql(find_with_shop, [{<<"merchant">>, Merchant}, Condition]),
    {ok, Inventories} = ?mysql:fetch(read, Sql),
    {reply, Inventories, State};

handle_call({lookup_by_group, Merchant, Group}, _From, State) ->
    ?DEBUG("lookup_by_group with group ~p, merchant ~p", [Merchant, Group]),
    
    Sql = sql(find_with_shop, [{<<"merchant">>, Merchant},
			       {<<"style_number">>, ?v(<<"style_number">>, Group)},
			       {<<"brand">>, ?v(<<"brand">>, Group)},
			       {<<"shop">>, ?v(<<"shop">>, Group)}]),
    {ok, Inventories} = ?mysql:fetch(read, Sql),
    {reply, Inventories, State};

handle_call({lookup_by_style_number, StyleNumber, Merchant}, _From, State) ->
    ?DEBUG("lookup inventory with styleNumber ~p", [StyleNumber]),
    Sql = sql(find_with_shop,
	      [{<<"style_number">>, ?to_binary(StyleNumber)},
	       {<<"merchant">>, ?to_integer(Merchant)}]), 
    {ok, Inventories} = ?mysql:fetch(read, ?to_binary(Sql)),
    {reply, Inventories, State};


handle_call({lookup_by_style_number_and_shop, Merchant, StyleNumber, ShopId},
	    _From, State) ->
    ?DEBUG("lookup_by_style_number_and_shop with~n"
	   "merchant ~p, styleNumber ~p, ShopId~p", [Merchant, StyleNumber, ShopId]),
    %% Sql = "select a.id, a.inv_sn as sn, a.shop as shop_id, a.merchant,"
    %% 	++ " b.style_number, b.plan_price, b.discount,"
    %% 	++ " b.year, b.season, b.sex,"
    %% 	++ " b.size, b.amount, b.entry_date,"
    %% 	++ " c.name as brand,"
    %% 	++ " d.name as color,"
    %% 	++ " e.name as supplier,"
    %% 	++ " f.name as type,"
    %% 	++ " g.name as shop_name"
    %% 	++ " from inventory_to_shop a"
    %% 	++ " left join shops g on a.shop = g.id"
    %% 	++ " left join inventories b on a.inv_sn = b.sn"
    %% 	++ " left join brands c on b.brand = c.id"
    %% 	++ " left join colors d on b.color = d.id"
    %% 	++ " left join suppliers e on b.supplier = e.id"
    %% 	++ " left join inv_types f on b.type = f.id"
    %% 	++ " where "
    %% 	++ " a.deleted = " ++ ?to_string(?NO)
    %% 	++ " and a.shop = " ++ ?to_string(ShopId)
    %% 	++ " and a.merchant = " ++ ?to_string(Merchant)
    %% 	++ " and b.style_number=" ++ "\'" ++ ?to_string(StyleNumber) ++ "\';",

    Sql = sql(find_with_shop,
	      [{<<"style_number">>, ?to_binary(StyleNumber)},
	       {<<"merchant">>, ?to_integer(Merchant)},
	       {<<"shop">>, ?to_integer(ShopId)}]),
    
    ?DEBUG("sql ~ts", [Sql]),
    %% ?DEBUG("sql to inventory ~p", [Sql]),

    {ok, Inventories} = ?mysql:fetch(read, Sql),
    %% get shops
    %% {ok, Shops} = 
    {reply, Inventories, State};

handle_call({lookup_unchecked, Merchant, Shop}, _From, State) ->
    ?DEBUG("lookup_unchecked with~nmerchant ~p, Shop ~p", [Merchant, Shop]), 
    Sql = "select a.style_number, a.season, a.year"
	", a.sex, SUM(a.amount) as total"
	", a.shop as shop_id, a.brand as brand_id, a.supplier as supplier_id"
	", a.plan_price, a.org_price, a.discount"
	", b.name as brand"
	", c.name as supplier"
	", d.name as shop"
	", e.name as type"
	" from inventory_to_shop a"
	++ " left join brands b on a.brand=b.id"
	++ " and b.merchant=" ++ ?to_s(Merchant)
	++ " left join suppliers c on a.supplier=c.id"
	++ " and c.merchant=" ++ ?to_s(Merchant)
	++ " left join shops d on a.shop=d.id"
	++ " and d.merchant=" ++ ?to_s(Merchant)
	++ " left join inv_types e on a.type=e.id"
	++ " and e.merchant=" ++ ?to_s(Merchant)
	++ " where a.shop=" ++ ?to_s(Shop)
	++ " and a.merchant=" ++ ?to_s(Merchant)
	++ " and a.state=" ++ ?to_s(?CHECKING)
	++ " and a.deleted=" ++ ?to_s(?NO)
	++ " group by a.style_number, a.brand;",
    
    %% Sql = sql(find_with_shop,
    %% 	      [{<<"merchant">>, ?to_i(Merchant)},
    %% 	       {<<"shop">>, [?to_i(ShopId)]},
    %% 	       {<<"size_group">>, ?to_i(SizeGroup)},
    %% 	       {<<"state">>, ?CHECKING}]),

    ?DEBUG("sql to unchecked ~ts", [Sql]),
    
    {ok, Inventories} = ?mysql:fetch(read, Sql),
    {reply, ?to_tl(Inventories), State};

%% =============================================================================
%% move detail
%% =============================================================================
handle_call({lookup_move_by_merchant, Merchant}, _From, State) ->
    ?DEBUG("lookup_move_by_merchant with merchant ~p", [Merchant]),
    Sql = "select a.id, a.sn, a.source, a.target, a.amount"
	++ " ,a.state, a.move_date, a.style_number"
	++ " ,c.plan_price, c.discount"
	++ " ,c.sex, c.size, c.season, c.year"
	++ " ,d.name as brand"
	++ " ,e.name as color"
	++ " ,f.name as supplier"
	++ " ,g.name as type"
	++ " from inventory_to_move a"
    %% ++ " left join inventory_service b on a.style_number=b.style_number"
    %% ++ " and b.merchant=" ++ ?to_string(Merchant)
	++ " left join inventory_to_shop c on a.sn=c.sn"
	++ " left join brands d on c.brand=d.id"
	++ " left join colors e on c.color=e.id"
	++ " left join suppliers f on c.supplier=f.id"
	++ " left join inv_types g on c.type=g.id"
	++ " where a.merchant=" ++ ?to_string(Merchant) ++ ";",

    {ok, Detail} = ?mysql:fetch(read, Sql),
    {reply, ?to_tuplelist(Detail), State};


handle_call({lookup_move_with_condition, Merchant, Condition}, _From, State) ->
    ?DEBUG("lookup_move_with_condition with merchant ~p, condition ~p",
	   [Merchant, Condition]),
    Sql = "select id, sn, source, target, amount ,state, move_date"
	++ " from inventory_to_move"
	++ " where merchant=" ++ ?to_string(Merchant)
	++ " and " ++ ?utils:to_sqls(proplists, Condition),

    {ok, Detail} = ?mysql:fetch(read, Sql),
    {reply, Detail, State};

%% ============================================================================
%% reject detail
%% =============================================================================
handle_call({lookup_reject_by_merchant, Merchant}, _From, State) ->
    ?DEBUG("lookup_reject_by_merchant with merchant ~p", [Merchant]),
    Sql = "select a.id, a.sn, a.style_number"
	++ " ,a.shop as shop_id, a.amount, a.reject_date"
	++ " ,c.plan_price, c.discount"
	++ " ,c.sex, c.size, c.org_price, c.season, c.year"
	++ " ,d.name as brand"
	++ " ,e.name as color"
	++ " ,f.name as supplier"
	++ " ,g.name as type"
	++ " ,h.name as shop_name"
	++ " from inventory_reject_to_supplier a"
    %% ++ " left join inventory_service b on a.style_number=b.style_number"
    %% ++ " and b.merchant=" ++ ?to_string(Merchant)
	++ " left join inventory_to_shop c on a.sn=c.sn"
	++ " left join brands d on c.brand=d.id"
	++ " left join colors e on c.color=e.id"
	++ " left join suppliers f on c.supplier=f.id"
	++ " left join inv_types g on c.type=g.id"
	++ " left join shops h on a.shop=h.id"
	++ " where a.merchant=" ++ ?to_string(Merchant) ++ ";",

    {ok, Detail} = ?mysql:fetch(read, Sql),
    {reply, ?to_tuplelist(Detail), State};

%% =============================================================================
%% pagnation
%% =============================================================================
handle_call({pagination_by_merchant, CurrentPage, CountPerPage, Merchant},
	    _From, State) ->
    ?DEBUG("pagination_by_merchant with currentPage ~p, countPerPage ~p, "
	   "Merchant ~p", [CurrentPage, CountPerPage, Merchant]),
    Sql = sql(pagination, group, Merchant, [], CurrentPage, CountPerPage),

    {ok, Inventories} = ?mysql:fetch(read, Sql),
    {reply, ?to_tuplelist(Inventories), State};

handle_call({pagination_by_shop, CurrentPage, CountPerPage, ShopIds, Merchant},
	    _From, State) ->
    ?DEBUG("pagination_by_shop with currentPage ~p, countPerPage ~p, ShopIds ~p,"
	   " Merchant ~p", [CurrentPage, CountPerPage, ShopIds, Merchant]),
    Sql = sql(pagination, group, Merchant, [{<<"shop">>, ShopIds}],
	      CurrentPage, CountPerPage),

    {ok, Inventories} = ?mysql:fetch(read, Sql),
    {reply, ?to_tuplelist(Inventories), State};

handle_call({total_with_filter, Merchant, Fields}, _from, State) ->
    StartTime = ?value(<<"start_time">>, Fields),
    EndTime   = ?value(<<"end_time">>, Fields),
    CutFields = proplists:delete(<<"end_time">>,
				 proplists:delete(<<"start_time">>, Fields)),
    
    %% Sql = "select count(*) from inventory_to_shop"
    %% 	++ " where " ++ ?utils:to_sqls(
    %% 			   proplists, [{<<"merchant">>, Merchant}|CutFields]),

    Sql = "select count(distinct style_number, brand) as total"
	" from inventory_to_shop where "
	++ ?utils:to_sqls(proplists, [{<<"merchant">>, Merchant}|CutFields]),
	   
    Time0 = time_condition(StartTime, "rdate", ge),
    Time1   = time_condition(EndTime, "rdate", le),
    
    {ok, {Total}} = ?mysql:fetch(read, Sql ++ Time0 ++ Time1),
    ?DEBUG("count(*) ~p", [Total]),
    {reply, ?value(<<"total">>, Total), State};

handle_call({pagination_with_filter, CurrentPage, CountPerPage,
	     Merchant, Fields}, _From, State) ->
    StartTime = ?value(<<"start_time">>, Fields),
    EndTime   = ?value(<<"end_time">>, Fields),

    CutFields = proplists:delete(
		  <<"end_time">>,
		  proplists:delete(<<"start_time">>, Fields)),

    %% Time0 = time_condition(StartTime, "a.rdate", ge),
    %% Time1 = time_condition(EndTime, "a.rdate", le),
    
    Sql0 = sql(group, Merchant, CutFields, StartTime, EndTime), 

    Pagination = " limit " ++ ?to_string((CurrentPage-1)*CountPerPage)
	++ ", " ++ ?to_string(CountPerPage),

    Sql = Sql0 ++ Pagination,
    
    ?DEBUG("sql to filter ~ts", [Sql]),
    {ok, Inventories} = ?mysql:fetch(read, Sql),
    {reply, ?to_tuplelist(Inventories), State};
    

handle_call({inventory_total, Conditions}, _From, State) ->
    ?DEBUG("inventory_total with conditions ~p", [Conditions]),
    Sql = "select count(distinct style_number, brand) as total"
	" from inventory_to_shop where "
	++ ?utils:to_sqls(proplists, Conditions) ++";",
	
    {ok, {Total}} = ?mysql:fetch(read, Sql),
    ?DEBUG("count(*) ~p", [Total]),
    {reply, {[{count, ?value(<<"total">>, Total)}]}, State};

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
%% fields() ->
%%     "style_number, size, color".

%% size_to_number(S) when is_atom(S) =/= true ->
%%     size_to_number(?to_atom(S));
%% size_to_number(s)    -> 0;
%% size_to_number(m)    -> 1;
%% size_to_number(l)    -> 2;
%% size_to_number(xl)   -> 3;
%% size_to_number(xxl)  -> 4;
%% size_to_number(xxxl) -> 5.

%%--------------------------------------------------------------------
%% @desc: save the prompt value to the prompt table
%% @param promptTbl: table of prompt
%% @param prompt:    value of prompt
%% @return: the id of this prompt in the table
%%--------------------------------------------------------------------
save_prompt(_PromptTbl, undefined, _Merchant) ->
    {ok, undefined};
save_prompt(PromptTbl, Prompt, Merchant) ->
    Sql = "select id, name from " ++ ?to_s(PromptTbl)
	++ " where name=" ++ "\"" ++ ?to_s(Prompt) ++ "\"" 
	++ " and merchant =" ++ ?to_s(Merchant)
	++  case PromptTbl of
		colors -> " and type=0";
		_ -> []
	    end
	++ " and deleted=" ++ ?to_s(?NO), 
    
    case ?mysql:fetch(read, Sql) of
	{ok, []} ->
	    Sql1 = "insert into " ++ ?to_s(PromptTbl)
		++"(name, merchant) values("
		++ "\"" ++?to_s(Prompt) ++ "\","
		++ ?to_s(Merchant) ++ ");",
	    case ?mysql:fetch(insert, Sql1) of
		{ok, InsertId} -> {ok, InsertId};
		{error, Error} -> throw({db_error, Error})
	    end;
	{ok, {R}} ->
	    {ok, ?v(<<"id">>, R)}
    end.
    

state(wait_check) -> 0;
state(checked) -> 1.

check_inventory_amount(Merchant, Sn, Amount) ->
    Sql = "select id, sn, style_number, amount from inventory_to_shop"
	" where sn=" ++ "\"" ++ ?to_string(Sn) ++ "\""
	" and merchant=" ++ ?to_string(Merchant) ++ ";",
    
    case ?mysql:fetch(read, Sql) of
	{error, DBError} ->
	    {error, ?err(db_error, DBError)};
	{ok, []}->
	    {error, ?err(inventory_empty, Sn)};
	{ok, {Record}} ->
	    NowAmount = ?value(<<"amount">>, Record),
	    case ?to_integer(NowAmount) < ?to_integer(Amount) of
		true ->
		    {error, ?err(inventory_not_enough, Sn)};
		false ->
		    ok
	    end
    end.
	
%% sql(find) ->
%%     sql(find, []).
sql(find_with_shop, Conditions) ->
    ?DEBUG("find_with_shop with conditions ~p", [Conditions]),
    %% Merchant = ?value(<<"merchant">>, ?to_tuplelist(Conditions)),
    CorrectCondition = ?utils:correct_condition(<<"a.">>, Conditions),
    Sql = "select a.id, a.sn, a.style_number, a.sex"
	++ " ,a.size, a.amount, a.brand as brand_id"
	++ " ,a.color as color_id, a.brand as brand_id"
	++ " ,a.supplier as supplier_id, a.org_price, a.season"
	++ " ,a.shop as shop_id, a.state, a.check_num"
	++ " ,a.check_date, a.year, a.rdate"
	++ " ,a.plan_price, a.discount"
	++ " ,c.name as brand" 
	++ " ,d.name as color"
	++ " ,e.name as supplier"
	++ " ,f.name as type"
	++ " ,g.name as shop_name"
	++ " from inventory_to_shop a"
	%% ++ " left join inventory_service b on a.style_number=b.style_number"
	%% ++ " and b.merchant="++?to_string(Merchant)
	++ " left join brands c on a.brand=c.id"
	++ " left join colors d on a.color=d.id"
	++ " and d.type=0"
	++ " left join suppliers e on a.supplier=e.id"
	++ " left join inv_types f on a.type=f.id"
	++ " left join shops g on a.shop=g.id"
	++ " where "
	++ case Conditions of
	       [] ->
		   "a.deleted = " ++ ?to_string(?NO);
	       _  ->
		   ?utils:to_sqls(proplists, CorrectCondition)
		       ++ " and a.deleted = " ++ ?to_string(?NO)
	   end,
    
    ?DEBUG("sql ~ts", [Sql]),
    Sql.

sql(group, Merchant, Conditions) ->
    sql(group, Merchant, Conditions, undefined, undefined).
sql(group, Merchant, Conditions, StartTime, EndTime) ->
    Sql = "select a.style_number, a.season, a.year"
	", a.sex, SUM(a.amount) as total"
	", a.shop as shop_id, a.brand as brand_id, a.supplier as supplier_id"
	", a.plan_price, a.org_price, a.discount"
	", b.name as brand"
	", c.name as supplier"
	", d.name as shop"
	", e.name as type"
	" from inventory_to_shop a"
	++ " left join brands b on a.brand=b.id"
	++ " and b.merchant=" ++ ?to_s(Merchant)
	++ " left join suppliers c on a.supplier=c.id"
	++ " and c.merchant=" ++ ?to_s(Merchant)
	++ " left join shops d on a.shop=d.id"
	++ " and d.merchant=" ++ ?to_s(Merchant)
	++ " left join inv_types e on a.type=e.id"
	++ " and e.merchant=" ++ ?to_s(Merchant)
	++ " where "
	++ " a.merchant=" ++ ?to_s(Merchant)
	++ time_condition(StartTime, "a.rdate", ge)
	++ time_condition(EndTime, "a.rdate", le)
    %% ++ " and a.state=" ++ ?to_s(?CHECKING)
	++ " and a.deleted=" ++ ?to_s(?NO)
	++ case Conditions of
	       [] -> "";
	       _  ->
		   CorrectCondition = ?utils:correct_condition(<<"a.">>, Conditions), 
		   " and " ++ ?utils:to_sqls(proplists, CorrectCondition)
	   end ++ " group by a.style_number, a.brand, a.shop",
	Sql.
    
sql(pagination, group, Merchant, Conditions, CurrentPage, CountPerPage) ->
    Sql = sql(group, Merchant, Conditions),
    Pagination = " limit " ++ ?to_string((CurrentPage-1)*CountPerPage)
	++ ", " ++ ?to_string(CountPerPage),

    SqlOfPagination = Sql ++ Pagination,
    ?DEBUG("sql of pagination ~ts", [SqlOfPagination]),

    SqlOfPagination.
	
%% sql(find, Conditions) ->
%%     Sql = "select a.id, a.sn, a.style_number,"
%% 	++ " a.plan_price, a.discount, a.year, a.season, a.sex,"
%% 	++ " a.size, a.amount, a.entry_date,"
%% 	++ " b.name as brand,"
%% 	++ " c.name as color,"
%% 	++ " d.name as supplier,"
%% 	++ " e.shop as shop_id,"
%% 	++ " g.name as type"
%% 	++ " from inventories a"
%% 	++ " left join brands            b on a.brand    = b.id"
%% 	++ " left join colors            c on a.color    = c.id"
%% 	++ " left join suppliers         d on a.supplier = d.id"
%% 	++ " left join inventory_to_shop e on a.sn       = e.inv_sn"
%% 	++ " left join inv_types         g on a.type     = g.id"
%% 	++ " where "
%% 	++ case Conditions of
%% 	       [] ->
%% 		   "a.deleted = " ++ ?to_string(?NO) ++ ";";
%% 	       _  ->
%% 		   ?utils:to_sqls(proplists, Conditions)
%% 		       ++ " and a.deleted = " ++ ?to_string(?NO) ++ ";"
%% 	   end,
%%     ?DEBUG("sql ~ts", [Sql]),
%%     Sql.

sn(Shop, Merchant, SN) ->
    lists:concat(["M-", ?to_integer(Merchant),
		  "S-", ?to_integer(Shop), "-", SN]).



v(Vk, Dk, DkType, Payload) ->
    case ?value(?to_b(Vk), Payload) of
	undefined -> [];
	Value  ->
	    [{?to_b(Dk), case DkType of
			     float   -> ?to_f(Value);
			     string  -> ?to_b(Value);
			     integer -> ?to_i(Value)
			 end
	     }]
    end.

time_condition(Time, TimeField, ge) ->
    case Time of
	undefined -> "";
	Time ->
	    " and " ++ ?to_s(TimeField) ++ ">=\"" ++ ?to_s(Time) ++ "\""
    end;
time_condition(Time, TimeField, le) ->
    case Time of
	undefined -> "";
	Time ->
	    " and " ++ ?to_s(TimeField) ++ "<=\"" ++ ?to_s(Time) ++ "\""
    end.
