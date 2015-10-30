-module(diablo_purchaser_sql).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-compile(export_all).

good_new(Merchant, UseZero, Shop, Attrs) ->
    StyleNumber = ?v(<<"style_number">>, Attrs),
    BrandId     = ?v(<<"brand_id">>, Attrs),
    TypeId      = ?v(<<"type_id">>, Attrs),
    Sex         = ?v(<<"sex">>, Attrs),
    Firm        = ?v(<<"firm">>, Attrs),
    Season      = ?v(<<"season">>, Attrs),
    Year        = ?v(<<"year">>, Attrs),
    OrgPrice    = ?v(<<"org_price">>, Attrs),
    TagPrice    = ?v(<<"tag_price">>, Attrs),
    PkgPrice    = ?v(<<"pkg_price">>, Attrs),
    P3          = ?v(<<"p3">>, Attrs, 0),
    P4          = ?v(<<"p4">>, Attrs, 0),
    P5          = ?v(<<"p5">>, Attrs, 0),
    Discount    = ?v(<<"discount">>, Attrs, 100),
    Colors      = ?v(<<"colors">>, Attrs, [?FREE_COLOR]),
    Path        = ?v(<<"path">>, Attrs, []),
    AlarmDay    = ?v(<<"alarm_day">>, Attrs, 7),

    Sizes       = ?v(<<"sizes">>, Attrs, [?FREE_SIZE]), 
    Date        = ?utils:current_time(localdate),
    DateTime    = ?utils:current_time(localtime), 


    Free = case Colors =:= [0] andalso Sizes =:= [0] of
	       true  -> 0;
	       false -> 1
	   end,

    {GIds, GNames} = decompose_size(Sizes),
    ?DEBUG("GIds ~p, GNames ~p", [GIds, GNames]),

    Sql1 =
	"insert into w_inventory_good"
	"(style_number, sex, color, year, season, type, size, s_group, free"
	", brand, firm, org_price, tag_price, pkg_price, price3, price4, price5"
	", discount, path, alarm_day, merchant, change_date, entry_date"
	") values("
	++ "\"" ++ ?to_s(StyleNumber) ++ "\","
	++ ?to_s(Sex) ++ ","
	++ "\"" ++ join_with_comma(Colors) ++ "\","
	++ ?to_s(Year) ++ ","
	++ ?to_s(Season) ++ "," 
	++ ?to_s(TypeId) ++ ","
	++ "\"" ++ join_with_comma(GNames) ++ "\","
	++ "\"" ++ join_with_comma(GIds) ++ "\","
	++ ?to_s(Free) ++ ","
	++ ?to_s(BrandId) ++ ","
	++ ?to_s(Firm) ++ ","
	++ ?to_s(OrgPrice) ++ ","
	++ ?to_s(TagPrice) ++ ","
	++ ?to_s(PkgPrice) ++ ","
	++ ?to_s(P3) ++ ","
	++ ?to_s(P4) ++ ","
	++ ?to_s(P5) ++ ","
	++ ?to_s(Discount) ++ ","
	++ "\"" ++ ?to_s(Path) ++ "\","
	++ ?to_s(AlarmDay) ++ ","
	++ ?to_s(Merchant) ++ ","
	++ "\"" ++ ?to_s(DateTime) ++ "\","
	++ "\"" ++ ?to_s(Date) ++ "\");",

     case UseZero of
	 ?NO ->
	     [Sql1];
	 ?YES -> 
	     FSize = fun(S) when S =:= <<>> -> [];
			(S) when S =:= [] -> [];
			(S) -> [S]
		     end,
	     
	     GetSizeGroup =
		 fun([]) -> ["0"];
		 (G) ->
			 SI   = ?v(<<"si">>, G),
			 SII  = ?v(<<"sii">>, G),
			 SIII = ?v(<<"siii">>, G),
			 SIV  = ?v(<<"siv">>, G),
			 SV   = ?v(<<"sv">>, G),
			 SVI  = ?v(<<"svi">>, G),
			 FSize(SI) ++ FSize(SII) ++ FSize(SIII)
			     ++ FSize(SIV) ++ FSize(SV) ++ FSize(SVI) 
		 end,

	     InventoryAmount =
		 fun(Size, Color) ->
			 ["insert into w_inventory_amount(rsn, style_number, brand"
			     ", color, size, shop, merchant, entry_date) values("
			  ++ "-1,"
			  ++ "\"" ++ ?to_s(StyleNumber) ++ "\","
			  ++ ?to_s(BrandId) ++ ","
			  ++ ?to_s(Color) ++ ","
			  ++ "\'" ++ ?to_s(Size) ++ "\',"
			  ++ ?to_s(Shop) ++ ","
			  ++ ?to_s(Merchant) ++ ","
			  ++ "\"" ++ ?to_s(DateTime) ++ "\")"]
		 end,

	     [Sql1, 
	      "insert into w_inventory(rsn"
	      ", style_number, brand, type, sex, season, amount"
	      ", firm, s_group, free, year"
	      ", org_price, tag_price, pkg_price, price3"
	      ", price4, price5, discount, path, alarm_day"
	      ", shop, merchant, last_sell, change_date, entry_date)"
	      " values("
	      ++ "\"" ++ ?to_s(-1) ++ "\","
	      ++ "\"" ++ ?to_s(StyleNumber) ++ "\","
	      ++ ?to_s(BrandId) ++ ","
	      ++ ?to_s(TypeId) ++ ","
	      ++ ?to_s(Sex) ++ ","
	      ++ ?to_s(Season) ++ ","
	      ++ ?to_s(0) ++ ","
	      ++ ?to_s(Firm) ++ "," 
	      %% ++ ?to_s(Color) ++ ","
	      %% ++ "\"" ++ ?to_s(Size) ++ "\","
	      ++ "\"" ++ join_with_comma(GIds) ++ "\","
	      ++ ?to_s(Free) ++ ","
	      ++ ?to_s(Year) ++ ","
	      ++ ?to_s(OrgPrice) ++ ","
	      ++ ?to_s(TagPrice) ++ ","
	      ++ ?to_s(PkgPrice) ++ ","
	      ++ ?to_s(P3) ++ ","
	      ++ ?to_s(P4) ++ ","
	      ++ ?to_s(P5) ++ ","
	      ++ ?to_s(Discount) ++ ","
	      ++ "\"" ++ ?to_s(Path) ++ "\","
	      ++ ?to_s(AlarmDay) ++ ","
	      ++ ?to_s(Shop) ++ ","
	      ++ ?to_s(Merchant) ++ ","
	      ++ "\"" ++ ?to_s(Date) ++ "\","
	      ++ "\"" ++ ?to_s(DateTime) ++ "\","
	      ++ "\"" ++ ?to_s(Date) ++ "\")" 
	     ] ++
		 lists:foldr(
		   fun(GId, Acc0) ->
			   {ok, G} = ?w_user_profile:get(size_group, Merchant, GId),
			   ?DEBUG("G ======= ~p", [G]),
			   lists:foldr(
			     fun(S, Acc1) ->
				     lists:foldr(
				       fun(C, Acc2)->
					       InventoryAmount(S, C) ++ Acc2
				       end, [], Colors) ++ Acc1
			     end, [], GetSizeGroup(G)) ++ Acc0
		   end, [], GIds)
		 
     end.
     
good(detail, Merchant) ->
    good(detail, Merchant, []).


good(delete, Merchant, GoodId) ->
    "delete from w_inventory_good where id=" ++ ?to_s(GoodId)
	++ " and merchant=" ++ ?to_s(Merchant);

good(detail, Merchant, Conditions) ->
    {StartTime, EndTime, NewConditions} =
	?sql_utils:cut(fields_no_prifix, Conditions), 
    %% "select a.id, a.style_number, a.brand as brand_id"
    %% 	", a.firm as firm_id, a.type as type_id"
    %% 	", a.sex, a.color, a.year, a.season, a.size, a.s_group, a.free"
    %% 	", a.org_price, a.tag_price, a.pkg_price"
    %% 	", a.price3, a.price4, a.price5"
    %% 	", a.discount, a.path, a.entry_date"

	%% ", b.name as brand"
	%% ", c.name as firm"
	%% ", e.name as type"
	
    %% " from "
	"select id, style_number"
	", brand as brand_id, firm as firm_id, type as type_id"
	", sex, color, year, season, size, s_group, free"
	", org_price, tag_price" ", pkg_price, price3, price4, price5"
	", discount, path, entry_date"
	" from w_inventory_good"
	" where "
	++ ?sql_utils:condition(proplists_suffix, NewConditions)
	++ "merchant=" ++ ?to_s(Merchant) 
	++ case ?sql_utils:condition(time_no_prfix, StartTime, EndTime) of
	       [] -> [];
	       TimeSql ->  " and " ++ TimeSql
	   end
	++ " and deleted=" ++ ?to_s(?NO);
	
	%% " left join "
	%% "(select id, name from brands where merchant=" ++ ?to_s(Merchant) ++ ")"
	%% " as b on a.brand=b.id"

	%% " left join "
	%% "(select id, name from suppliers where merchant=" ++ ?to_s(Merchant) ++ ")" 
	%% " c on a.firm=c.id"

	%% " left join "
	%% "(select id, name from inv_types) where merchant=" ++ ?to_s(Merchant) ++ ")"	
	%% ++ " e on a.type=e.id"; 

good(price, Merchant, [{_StyleNumber, _Brand}|_] = Conditions) ->
    [{S1, B1}|T] = Conditions, 
    "select a.id, a.style_number, a.brand as brand_id"
	", a.s_group, a.free, a.org_price, a.tag_price, a.pkg_price"
	", a.price3, a.price4, a.price5, a.discount"
	" from w_inventory_good a where (a.style_number, a.brand) in("
	++ lists:foldr(
	     fun({StyleNumber, Brand}, Acc)->
		     "(\'" ++ ?to_s(StyleNumber) ++ "\',"
			 ++ ?to_s(Brand) ++ ")," ++ Acc
	     end, [], T)
	++ "(\'" ++ ?to_s(S1) ++ "\'," ++ ?to_s(B1) ++ "))"
	++ "and a.merchant=" ++ ?to_s(Merchant).

good(detail_with_pagination, Merchant, Conditions, CurrentPage, ItemsPerPage) -> 
    good(detail, Merchant, Conditions)
	++ ?sql_utils:condition(page_desc, CurrentPage, ItemsPerPage).

good(detail_no_join, Merchant, StyleNumber, Brand) ->
    "select a.id, a.style_number, a.brand as brand_id"
	", a.firm as firm_id, a.type as type_id"
	", a.sex, a.color, a.season, a.size" 
	++ " from w_inventory_good a" 
	++ " where "
	++ " a.style_number=" ++ "\"" ++ ?to_s(StyleNumber) ++ "\""
	++ " and brand=" ++ ?to_s(Brand)
	++ " and a.merchant=" ++ ?to_s(Merchant)
	++ " and a.deleted=" ++ ?to_s(?NO);

good(used_detail, Merchant, StyleNumber, Brand) ->
    "select a.id, a.style_number, a.brand as brand_id"
	", a.firm as firm_id, a.type as type_id"
	", a.sex, a.color, a.season, a.size" 
	++ " from w_inventory_good a, w_inventory b" 
	++ " where a.merchant=" ++ ?to_s(Merchant)
	++ " and a.style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
	++ " and a.brand=" ++ ?to_s(Brand) 
	++ " and a.deleted=" ++ ?to_s(?NO)
	
	++ " and a.style_number=b.style_number"
	++ " and a.brand=b.brand"
	++ " and b.merchant=" ++ ?to_s(Merchant)
	++ " and b.deleted=" ++ ?to_s(?NO)
	++ " group by a.style_number, a.brand".

good_match(style_number, Merchant, StyleNumber) ->
    P = prompt_num(Merchant),
    "select distinct style_number from w_inventory_good"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and deleted=" ++ ?to_s(?NO) 
	++ " and style_number like \'" ++ ?to_s(StyleNumber) ++ "\%'"
	++ " limit " ++ ?to_s(P).

good_match(style_number_brand_firm, Merchant, StyleNumber, Firm) ->
    P = prompt_num(Merchant), 
    "select a.id, a.style_number, a.brand as brand_id"
	", a.type as type_id, a.firm as firm_id"
	", a.sex, a.color, a.year, a.season, a.size, a.s_group, a.free"
	", a.org_price, a.tag_price, a.pkg_price, a.price3, a.price4, a.price5"
	", a.discount, a.path, a.alarm_day, a.entry_date" 
	", b.name as brand"
	", c.name as type"
	" from w_inventory_good a, brands b, inv_types c"
	" where a.merchant=" ++ ?to_s(Merchant)
	++ " and a.firm=" ++ ?to_s(Firm)
	++ " and a.deleted=" ++ ?to_s(?NO)
	++ " and a.brand=b.id"
	++ " and a.type=c.id" 
	++ " and a.style_number like \'" ++ ?to_s(StyleNumber) ++ "\%'"
	++ " limit " ++ ?to_s(P);

good_match(all_style_number_brand_firm, Merchant, StartTime, Firm) ->
    "select a.id, a.style_number, a.brand as brand_id"
	", a.type as type_id, a.firm as firm_id"
	", a.sex, a.color, a.year, a.season, a.size, a.s_group, a.free"
	", a.org_price, a.tag_price, a.pkg_price, a.price3, a.price4, a.price5"
	", a.discount, a.path, a.alarm_day, a.entry_date"
	
	", b.name as brand"
	", c.name as type"
	
	" from w_inventory_good a, brands b, inv_types c"
	
	" where a.merchant=" ++ ?to_s(Merchant)
	++ case Firm of
	       [] -> [];
	       _ -> " and a.firm=" ++ ?to_s(Firm)
	   end
	++ " and a.entry_date>=\'" ++ ?to_s(StartTime) ++ "\'"
	++ " and a.deleted=" ++ ?to_s(?NO)
	++ " and a.brand=b.id"
	++ " and a.type=c.id".


inventory(abstract, Merchant, Shop, [{S1, B1}|T] = _Conditions) -> 
    %% C = lists:foldr(
    %% 	  fun({S, B}, Acc)->
    %% 		  "(\'" ++ ?to_s(S) ++ "\',"
    %% 		      ++ ?to_s(B) ++ ")," ++ Acc
    %% 	  end, [], T)
    %% 	++ "(\'" ++ ?to_s(S1) ++ "\'," ++ ?to_s(B1) ++ ")",

    C = lists:foldr(
    	  fun({S, B}, Acc)->
		  "(style_number=\'" ++ ?to_s(S) ++ "\'"
		      " and brand=" ++ ?to_s(B) ++ ") or " ++ Acc
    	  end, [], T)
    	++ "(style_number=\'" ++ ?to_s(S1) ++ "\' and brand=" ++ ?to_s(B1) ++ ")",
    
    "select a.style_number, a.brand_id, a.type_id, a.sex, a.season"
	", a.total, a.s_group, a.free, a.org_price, a.tag_price, a.pkg_price"
	", a.price3, a.price4, a.price5, a.discount, a.path, a.shop, a.merchant" 

	", b.color as color_id, b.size, b.total as amount"
	" from "
	
	"(select style_number, brand as brand_id, type as type_id, sex, season"
	", amount as total, s_group, free, org_price, tag_price, pkg_price, price3"
	", price4, price5, discount, path, shop, merchant"
	" from w_inventory where (" ++ C  ++ ")"
	++ " and shop=" ++ ?to_s(Shop)
	++ " and merchant=" ++ ?to_s(Merchant)
	++ " and deleted=" ++ ?to_s(?NO) ++ ") a"
	
	" left join w_inventory_amount b on"
	" a.style_number=b.style_number and a.brand_id=b.brand"
	" and a.shop=b.shop"
	" and b.merchant";
    
    %% "select a.style_number, a.brand as brand_id"
    %% 	", a.color as color_id, a.size, a.total as amount"

    %% 	", b.type as type_id, b.sex, b.season, b.amount as total"
    %% 	", b.s_group, b.free, b.org_price, b.tag_price, b.pkg_price"
    %% 	", b.price3, b.price4, b.price5, b.discount, b.path"

    %% 	", c.name as color"

    %% 	" from "
    %% 	"(select style_number, brand, color, size, total"
    %% 	" from w_inventory_amount a"
    %% 	" where (a.style_number, a.brand) in(" ++ C ++ ")"
    %% 	++ " and a.shop=" ++ ?to_s(Shop)
    %% 	++ " and merchant=" ++ ?to_s(Merchant)
    %% 	++ " and deleted=" ++ ?to_s(?NO) ++ ") a"

    %% 	++ " left join "
    %% 	"(select style_number, brand"
    %% 	", type, sex, a.season, a.amount, s_group, free"
    %% 	", a.org_price, a.tag_price, a.pkg_price"
    %% 	", a.price3, a.price4, a.price5, a.discount, path"
    %% 	" from w_inventory a"
    %% 	" where (a.style_number, a.brand) in(" ++ C ++ ")"
    %% 	++ " and a.shop=" ++ ?to_s(Shop)
    %% 	++ " and merchant=" ++ ?to_s(Merchant)
    %% 	++ " and deleted=" ++ ?to_s(?NO) ++ ") b"
    %% 	" on a.style_number=b.style_number and a.brand = b.brand" 
    %% 	++ " left join colors c on a.color=c.id";
    %% "(select id, name from colors where merchant=" ++ ?to_s(Merchant)
%% ++ ") c on a.color=c.id"; 

inventory(group_detail, Merchant, Conditions, PageFun) ->
    {StartTime, EndTime, NewConditions} =
	?sql_utils:cut(fields_with_prifix, Conditions),
    
    "select a.id, a.style_number, a.brand as brand_id"
	", a.type as type_id, a.sex, a.season, a.amount"
	", a.firm as firm_id, a.s_group, a.free, a.year"

	", a.org_price, a.tag_price, a.pkg_price, a.price3"
	", a.price4, a.price5, a.discount, a.path, a.alarm_day"
	", a.sell, a.shop as shop_id, a.state"
	", a.last_sell, a.change_date, a.entry_date"
	
	", b.name as shop"
	
	" from w_inventory a"
	" left join shops b on a.shop=b.id"

	" where "
	++ ?sql_utils:condition(proplists_suffix, NewConditions)
	++ "a.merchant=" ++ ?to_s(Merchant)
	++ case ?sql_utils:condition(time_with_prfix, StartTime, EndTime) of
	       [] -> [];
	       TimeSql ->  " and " ++ TimeSql
	   end
	++ " and a.deleted=" ++ ?to_s(?NO) ++ PageFun().
	
	%% "(select id, style_number, brand, type, sex, season, amount"
	%% ", firm, s_group, free, year, org_price, tag_price, pkg_price"
	%% ", price3, price4, price5, discount, path, alarm_day, sell"
	%% ", shop, state, last_sell, change_date, entry_date"
	%% " from w_inventory"
	%% " where "
	%% ++ ?sql_utils:condition(proplists_suffix, NewConditions)
	%% ++ ?sql_utils:condition(time_no_prfix, StartTime, EndTime) 
	%% ++ " and merchant=" ++ ?to_s(Merchant) 
	%% ++ " and deleted=" ++ ?to_s(?NO) ++ PageFun() ++ ") a"

	%% " left join "
	%% "(select id, name from shops where merchant=" ++ ?to_s(Merchant)
	%% ++ ") b on a.shop=b.id".

inventory(inventory_new_rsn, Merchant, Conditions) ->
    {DetailConditions, SaleConditions} = 
	filter_condition(inventory_new, Conditions ++ [{<<"merchant">>, Merchant}], [], []),
    ?DEBUG("inventory_new_rsn conditions ~p, detail condition ~p",
	   [SaleConditions, DetailConditions]), 

    {StartTime, EndTime, CutSaleConditions}
	= ?sql_utils:cut(fields_with_prifix, SaleConditions),

    TimeSql = ?sql_utils:condition(proplists_suffix, CutSaleConditions)
	++ ?sql_utils:condition(time_with_prfix, StartTime, EndTime),

    Sql1 = "select rsn from w_inventory_new a" ++ " where " ++ TimeSql,
	
    case ?v(<<"rsn">>, SaleConditions, []) of
	[] ->
	    case DetailConditions of
		[] -> Sql1;
		_ ->
		    "select a.rsn from w_inventory_new a "
			"inner join (select rsn from w_inventory_new_detail"
			" where rsn like " ++ "\'M-" ++ ?to_s(Merchant) ++"%\'"
			++ ?sql_utils:condition(proplists, DetailConditions) ++ ") b"
			" on a.rsn=b.rsn"
			" where " ++ TimeSql 
	    end;
	_ -> Sql1 
    end;

inventory(list, Merchant, Conditions) ->
    {StartTime, EndTime, NewConditions} =
	?sql_utils:cut(fields_with_prifix, Conditions),

    "select a.style_number, a.brand_id, a.type_id, a.sex, a.season, a.total"
	", a.org_price, a.tag_price, a.pkg_price"
	", a.price3, a.price4, a.price5, a.discount"

	", b.color as color_id, b.size, b.total as amount"
	%% ", c.name as color"
	
	" from ("
	"select a.style_number, a.brand as brand_id"
	", a.type as type_id, a.sex, a.season, a.amount as total"
	", a.org_price, a.tag_price, a.pkg_price, a.price3"
	", a.price4, a.price5, a.discount, a.shop as shop_id"
	" from w_inventory a"
	" where " ++ ?sql_utils:condition(proplists_suffix, NewConditions)
	++ "a.merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:fix_condition(time, time_with_prfix, StartTime, EndTime)
	++") a "

	" left join w_inventory_amount b on"
	" a.style_number=b.style_number and a.brand_id=b.brand"
	" and a.shop_id=b.shop and b.merchant=" ++ ?to_s(Merchant);
	%% " left join colors c on b.color=c.id";
    
    %% "select a.style_number, a.brand as brand_id"
    %% 	", a.type as type_id, a.sex, a.season, a.amount as total"
    %% 	", a.tag_price, a.pkg_price, a.price3, a.price4, a.price5, a.discount"

    %% 	", b.color as color_id, b.size, b.total as amount"
    %% 	", c.name as color"

    %% 	" from w_inventory a"
    %% 	" left join w_inventory_amount b on"
    %% 	" a.style_number=b.style_number and a.brand=b.brand"
    %% 	" left join colors c on b.color=c.id"

    %% 	" where " ++ ?sql_utils:condition(proplists_suffix, NewConditions)
    %% 	++ "a.merchant=" ++ ?to_s(Merchant)
    %% 	++ ?sql_utils:fix_condition(time, time_with_prfix, StartTime, EndTime); 

inventory(get_new_amount, _Merchant, Conditions) ->
    "select a.rsn, a.style_number, a.brand_id, a.type_id, a.sex"
	", a.season, a.firm_id, a.s_group, a.free, a.year"
	", a.org_price, a.tag_price, a.pkg_price, a.price3, a.price4"
	", a.price5, a.discount, a.path"

	", b.color as color_id, b.size, b.total as amount"
	" from "
	
	"(select rsn, style_number, brand as brand_id, type as type_id, sex"
	", season, firm as firm_id, s_group, free, year"
	", org_price, tag_price, pkg_price, price3, price4"
	", price5, discount, path"
	" from w_inventory_new_detail"
	" where "++ ?utils:to_sqls(proplists, Conditions)
	++ " and deleted=" ++ ?to_s(?NO) ++ ") a"

	" inner join w_inventory_new_detail_amount b on a.rsn=b.rsn"
	" and a.style_number=b.style_number and a.brand_id=b.brand";

    %% "select a.rsn, a.style_number, a.brand as brand_id"
    %% 	", a.color as color_id, a.size, a.total as amount"
	
    %% 	", b.type as type_id, b.sex, b.season, b.amount as total"
    %% 	", b.firm as firm_id, b.s_group, b.free, b.year"
    %% 	", b.org_price, b.tag_price, b.pkg_price, b.price3, b.price4"
    %% 	", b.price5, b.discount, b.path"
	
    %% 	", c.name as color"
	
    %% 	" from (" 
    %% 	"select rsn, style_number, brand, color, size, total"
    %% 	" from w_inventory_new_detail_amount"
    %% 	" where " ++ ?utils:to_sqls(proplists, Conditions)
    %% 	++ " and deleted=" ++ ?to_s(?NO) ++ ") a"

    %% 	++ " left join "
    %% 	"w_inventory_new_detail b"
    %% 	" on a.rsn=b.rsn and a.style_number=b.style_number"
    %% 	" and a.brand=b.brand"
    %% 	%% "(select style_number, brand, type, sex, season, amount"
	%% ", firm, s_group, free, year"
	%% ", org_price, tag_price, pkg_price, price3, price4"
	%% ", price5, discount, path"
	%% " from w_inventory_new_detail"
	%% " where "++ ?utils:to_sqls(proplists, Conditions)
	%% ++ " and deleted=" ++ ?to_s(?NO) ++ ") b"
	%% " on a.style_number=b.style_number and a.brand = b.brand"

    %% " left join colors c on a.color=c.id";

inventory(new_rsn_detail, _Merchant, Conditions) ->
    {_StartTime, _EndTime, NewConditions} =
	?sql_utils:cut(fields_no_prifix, Conditions),
    "select a.rsn, a.style_number, a.brand as brand_id"
	", a.color as color_id, a.size, a.total as amount"
	", b.name as color"
	" from ("

	"select rsn, style_number, brand, color, size, total"
	" from w_inventory_new_detail_amount"
	" where " ++ ?sql_utils:condition(proplists_suffix, NewConditions)
	++ "deleted=" ++ ?to_s(?NO) ++ ") a"
	
	" left join colors b on a.color=b.id";
    	
inventory(fix_rsn_detail, _Merchant, Conditions) ->
    {_StartTime, _EndTime, NewConditions} =
	?sql_utils:cut(fields_no_prifix, Conditions), 
    "select a.rsn, a.style_number, a.brand as brand_id"
	", a.color as color_id, a.size"
	", a.exist, a.fixed, a.metric" 
	", b.name as color"
	" from ("

	"select rsn, style_number, brand, color, size, exist, fixed, metric"
	" from w_inventory_fix_detail_amount"
	" where " ++ ?sql_utils:condition(proplists_suffix, NewConditions)
	++ "deleted=" ++ ?to_s(?NO) ++ ") a"

	" left join colors b on a.color=b.id".

%% inventory(last_reject, Merchant, Shop, Firm, Conditions) ->
%%     Sql = "select a.id, a.rsn, a.style_number, a.sell_style"
%% 	", a.fdiscount, a.fprice"
%% 	" from w_sale_detail a"
%% 	" inner join "
%% 	"(select rsn from w_sale where " ++ ?utils:to_sqls(proplists, C1)
%% 	++ ") b on a.rsn=b.rsn"
%%     %% " where a.rsn in"
%%     %% "(select rsn from w_sale where "
%%     %% ++ ?utils:to_sqls(proplists, C1) ++ ")"
%%     %% ++ ?sql_utils:condition(proplists, C2)
%% 	++ " where " ++ ?utils:to_sqls(proplists, CorrectC2)
%% 	++ " order by id desc limit 1",
    
inventory(new_rsn_groups, new, Merchant, Conditions, PageFun) ->

    {DConditions, NConditions}
	= ?w_good_sql:filter_condition(inventory_new, Conditions, [], []),

    {StartTime, EndTime, CutNConditions}
    	= ?sql_utils:cut(fields_with_prifix, NConditions),

    {_, _, CutDCondtions}
    	= ?sql_utils:cut(fields_no_prifix, DConditions),

    CorrectCutDConditions = ?utils:correct_condition(<<"b.">>, CutDCondtions),

    "select b.id, b.rsn, b.style_number"
	", b.brand as brand_id"
	", b.type as type_id"
	", b.season, b.amount"
	", b.firm as firm_id"
	", b.discount, b.s_group, b.free, b.year, b.path, b.entry_date"

	", a.shop as shop_id"
	", a.employ as employ_id"
	", a.type"
	
    	" from w_inventory_new_detail b, w_inventory_new a" 
    	" where "
	++ ?sql_utils:condition(proplists_suffix, CorrectCutDConditions)
	++ "b.rsn=a.rsn"

    	++ ?sql_utils:condition(proplists, CutNConditions)
    	++ " and a.merchant=" ++ ?to_s(Merchant)
    	++ " and " ++ ?sql_utils:condition(
			 time_with_prfix, StartTime, EndTime)
	++ PageFun();
    
    %% CorrectCondition = ?utils:correct_condition(<<"a.">>, Conditions),
    %% "select a.id, a.rsn, a.style_number, a.brand_id, a.type_id, a.season"
    %% 	", a.amount, a.firm_id, a.discount, a.s_group"
    %% 	", a.free, a.year, a.path, a.entry_date"

    %% 	%% ", b.shop as shop_id, b.employ as employee_id, b.type"
	
    %% 	", a.shop_id, a.employee_id, a.type"

    %% 	" from ("
    %% 	"select a.id, a.rsn, a.style_number, a.brand as brand_id"
    %% 	", a.type as type_id, a.season, a.amount, a.firm as firm_id"
    %% 	", a.discount, a.s_group, a.free, a.year, a.path, a.entry_date"

    %% 	", b.shop as shop_id, b.employ as employee_id, b.type"
	
    %% 	" from w_inventory_new_detail a"
    %% 	%% " where " ++ ?utils:to_sqls(proplists, Conditions) ++ PageFun() ++ ") a" 
    %% 	" inner join w_inventory_new b on a.rsn=b.rsn"
	
    %% 	" where "
    %% 	++ ?utils:to_sqls(proplists, CorrectCondition) ++ PageFun() ++ ") a"; 

inventory(new_detail, new, Merchant, Conditions, PageFun) ->
    SortConditions = sort_condition(w_inventory_new, Merchant, Conditions),
    %% {StartTime, EndTime, NewConditions} =
    %% 	?sql_utils:cut(fields_with_prifix, Conditions),
    "select a.id, a.rsn, a.employ as employee_id"
	", a.firm as firm_id, a.shop as shop_id"
	", a.balance, a.should_pay, a.has_pay, a.cash, a.card, a.wire"
	", a.verificate, a.total, a.comment, a.e_pay_type, a.e_pay"
	", a.type, a.state, a.entry_date"

	" from w_inventory_new a"
	" where " ++ SortConditions
	%% ++ ?sql_utils:condition(proplists_suffix, NewConditions)
	%% ++ case ?sql_utils:condition(time_no_prfix, StartTime, EndTime) of
	%%        [] -> [];
	%%        C -> C ++ " and "
	%%    end
	%% ++ "merchant=" ++ ?to_s(Merchant)
	++ PageFun();

inventory(fix_detail, fix, Merchant, Conditions, PageFun) ->
    {StartTime, EndTime, NewConditions} =
	?sql_utils:cut(fields_with_prifix, Conditions),
    "select a.id, a.rsn, a.shop as shop_id"
	", a.employ as employee_id"
	", a.exist, a.fixed, a.metric, a.entry_date"
    %% ", b.name as employee"
    %% ", c.name as shop"
	" from w_inventory_fix a"

	" where "
	++ ?sql_utils:condition(time_with_prfix, StartTime, EndTime)
	++ ?sql_utils:condition(proplists, NewConditions) 
	++ " and merchant=" ++ ?to_s(Merchant)
	++ PageFun();

inventory(fix_rsn_groups, fix, Merchant, Conditions, PageFun) ->
    StartTime   = ?v(<<"start_time">>, Conditions),
    EndTime     = ?v(<<"end_time">>, Conditions),
    RSN         = ?v(<<"rsn">>, Conditions, []),
    StyleNumber = ?v(<<"style_number">>, Conditions, []),
    Brand       = ?v(<<"brand">>, Conditions, []),
    Firm        = ?v(<<"firm">>, Conditions, []),
    Shop        = ?v(<<"shop">>, Conditions, []),

    C1 = [{<<"rsn">>, RSN}, {<<"shop">>, Shop}],
    C11 = ?sql_utils:condition(proplists_suffix, C1)
	++ ?sql_utils:condition(time_no_prfix, StartTime, EndTime)
	++ " and merchant="++ ?to_s(Merchant),


    C2 = [{<<"style_number">>, StyleNumber}, {<<"brand">>, Brand}, {<<"firm">>, Firm}],
    C21 = ?sql_utils:condition(proplists, C2),

    "select a.id, a.rsn, a.style_number, a.brand as brand_id, a.type"
	", a.s_group, a.free, a.season, a.firm as firm_id, a.path, a.exist"
	", a.fixed, a.metric, a.entry_date"

	", b.employ as employee_id"
	", b.shop as shop_id" 
	" from "

	"(select id, rsn, style_number, brand, type, s_group"
	", free, season, firm, path, exist, fixed, metric, entry_date"
	" from w_inventory_fix_detail"
	" where rsn in(select rsn from w_inventory_fix where " ++ C11 ++ ")"
	++ C21 ++ PageFun() ++ ") a"

	" left join "
	"(select rsn, employ, shop from w_inventory_fix"
	" where " ++ C11 ++ ") b on a.rsn=b.rsn";

inventory({group_detail_with_pagination, Mode},
	  Merchant, Conditions, CurrentPage, ItemsPerPage) -> 
    inventory(group_detail, Merchant, Conditions,
	fun() ->
		?sql_utils:condition(
		   page_desc, Mode, CurrentPage, ItemsPerPage)
	end);

inventory(new_detail_with_pagination, Merchant, Conditions, CurrentPage, ItemsPerPage) -> 
    inventory(new_detail, new, Merchant, Conditions,
	      fun() -> ?sql_utils:condition(page_desc, CurrentPage, ItemsPerPage) end);

inventory(reject_detail_with_pagination, Merchant, Conditions, CurrentPage, ItemsPerPage) ->
    inventory(new_detail, reject, Merchant, Conditions,
	      fun() -> ?sql_utils:condition(page_desc, CurrentPage, ItemsPerPage) end); 


%% inventory(reject_rsn_group_with_pagination, Merchant, Conditions, CurrentPage, ItemsPerPage) -> 
%%     inventory(reject_rsn_groups, Merchant, Conditions) 
%% 	++ ?sql_utils:condition(page_desc, CurrentPage, ItemsPerPage);

inventory(fix_detail_with_pagination, Merchant, Conditions, CurrentPage, ItemsPerPage) ->
    inventory(fix_detail, fix, Merchant, Conditions,
	fun() -> ?sql_utils:condition(page_desc, CurrentPage, ItemsPerPage) end);

inventory(fix_rsn_group_with_pagination, Merchant, Conditions, CurrentPage, ItemsPerPage) ->
    inventory(fix_rsn_groups, fix, Merchant, Conditions,
	fun() -> ?sql_utils:condition(page_desc, CurrentPage, ItemsPerPage) end);

inventory(new_rsn_group_with_pagination, Merchant, Conditions, CurrentPage, ItemsPerPage) -> 
    inventory(new_rsn_groups, new, Merchant, Conditions,
	      fun() -> ?sql_utils:condition(page_desc, CurrentPage, ItemsPerPage) end).


%%
%% match
%%
inventory_match(Merchant, StyleNumber, Shop) ->
    P = prompt_num(Merchant),
    "select style_number from w_inventory"
	++ " where style_number like \'" ++ ?to_s(StyleNumber) ++ "\%'"
	++ ?sql_utils:condition(proplists, [{<<"shop">>, Shop}])
	++ " and merchant=" ++ ?to_s(Merchant)
	++ " and deleted=" ++ ?to_s(?NO)
	++ " group by style_number"
	++ " limit " ++ ?to_s(P).

inventory_match(all_inventory, Merchant, Shop, Conditions) ->
    {StartTime, EndTime, NewConditions} =
	?sql_utils:cut(fields_with_prifix, Conditions),

    "select a.id, a.style_number, a.brand as brand_id, a.type as type_id"
	", a.sex, a.season, a.firm as firm_id, a.s_group, a.free, a.year"
	", a.org_price, a.tag_price, a.pkg_price"
	", a.price3, a.price4, a.price5, a.discount, a.path, a.alarm_day"

	", b.name as brand" 
	", c.name as type"
	" from w_inventory a"

	" left join brands b on a.brand=b.id" 
	" left join inv_types c on a.type=c.id"
	
	" where " ++ ?sql_utils:condition(proplists_suffix, [{<<"a.shop">>, Shop}|NewConditions]) 
	++ "a.merchant=" ++ ?to_s(Merchant)
	++ case ?sql_utils:condition(time_with_prfix, StartTime, EndTime) of
	       [] -> [];
	       TimeSql -> " and " ++ TimeSql
	   end
	++ " order by id";

inventory_match(Merchant, StyleNumber, Shop, Firm) ->
    P = prompt_num(Merchant),
    "select a.id, a.style_number, a.brand as brand_id, a.type as type_id"
	", a.sex, a.season, a.firm as firm_id, a.s_group, a.free, a.year"
	", a.org_price, a.tag_price, a.pkg_price"
	", a.price3, a.price4, a.price5, a.discount, a.path, a.alarm_day"
	
	", b.name as brand" 
	", c.name as type"
	" from w_inventory a"
	
	" left join brands b on a.brand=b.id" 
	" left join inv_types c on a.type=c.id"
	
	%% " (select id, style_number, brand, type, sex, season"
	%% ", firm, s_group, free, org_price, tag_price, pkg_price"
	%% ", price3, price4, price5, discount, path from w_inventory"
	" where a.style_number like \'" ++ ?to_s(StyleNumber) ++ "\%'"
	" and a.shop=" ++ ?to_s(Shop)
	++ case Firm of
	       [] -> [];
	       Firm -> " and a.firm=" ++ ?to_s(Firm)
	   end
	++ " and a.merchant=" ++ ?to_s(Merchant)
	%% ++ " and deleted=" ++ ?to_s(?NO)
	++ " order by a.id"
	++ " limit " ++ ?to_s(P).

inventory_match(all_reject, Merchant, Shop, Firm, StartTime) ->
    "select a.id, a.style_number, a.brand as brand_id, a.type as type_id"
	", a.sex, a.season, a.firm as firm_id, a.s_group, a.free, a.year"
	", a.org_price, a.tag_price, a.pkg_price"
	", a.price3, a.price4, a.price5, a.discount, a.path, a.alarm_day"

	", b.name as brand" 
	", c.name as type"
	" from w_inventory a"

	" left join brands b on a.brand=b.id" 
	" left join inv_types c on a.type=c.id"

    %% " (select id, style_number, brand, type, sex, season"
    %% ", firm, s_group, free, org_price, tag_price, pkg_price"
    %% ", price3, price4, price5, discount, path from w_inventory"
	" where a.shop=" ++ ?to_s(Shop)
	++ case Firm of
	       [] -> [];
	       Firm -> " and a.firm=" ++ ?to_s(Firm)
	   end
	++ " and a.merchant=" ++ ?to_s(Merchant)
	++ " and entry_date>=\'" ++ ?to_s(StartTime) ++ "\'"
    %% ++ " and deleted=" ++ ?to_s(?NO)
	++ " order by a.id".
	

inventory(update, RSN, _Merchant, _Shop, _Firm,
	  Datetime,  OldDatetime, _Curtime, []) ->
    case Datetime =:= OldDatetime of
	true -> [];
	false ->
	    ["update w_inventory_new set entry_date=\'"
	     ++ ?to_s(Datetime) ++ "\'"
	     ++ " where rsn=\'" ++ ?to_s(RSN) ++ "\'",
	     "update w_inventory_new_detail set entry_date=\'"
	     ++ ?to_s(Datetime) ++ "\' where rsn=\'" ++ ?to_s(RSN) ++ "\'"]
    end;

inventory(update, RSN, Merchant, Shop, Firm,
	  Datetime, _OldDatetime, Curtime, Inventories) ->
    
    lists:foldr(
      fun({struct, Inv}, Acc0)-> 
	      Operation   = ?v(<<"operation">>, Inv),
	      %% StyleNumber = ?v(<<"style_number">>, Inv),
	      %% Brand       = ?v(<<"brand">>, Inv),

	      Amounts = case Operation of
			    <<"d">> -> ?v(<<"amount">>, Inv);
			    <<"a">> -> ?v(<<"amount">>, Inv);
			    <<"u">> -> ?v(<<"changed_amount">>, Inv)
			end,
	      
	      
	      case Operation of
		  <<"d">> ->
		      amount_delete(RSN, Merchant, Shop, Inv, Amounts) ++ Acc0;
		  <<"a">> ->
		      amount_new(RSN, Merchant, Shop,
				 Firm, Datetime, Curtime, Inv, Amounts)
			  ++ Acc0; 
		  <<"u">> -> 
		      amount_update(RSN, Merchant, Shop, Datetime, Inv) ++ Acc0
	      end
      end, [], Inventories).

%% =============================================================================
%% internal function
%% =============================================================================
decompose_size([?FREE_SIZE]) ->
    {[0], [0]};
decompose_size(Sizes) ->
    decompose_size(Sizes, [], []).

decompose_size([], GIds, GNames) ->
    {lists:sort(GIds), GNames};
decompose_size([{struct, SizeGroup}|T], GIds, GNames) ->

    decompose_size(
      T, [?v(<<"id">>, SizeGroup)|GIds],
      lists:append(GNames, ?v(<<"group">>, SizeGroup))).

join_with_comma(List) ->
    join_with_comma(List, "").
join_with_comma([], Acc) ->
    Acc;
join_with_comma([Last], Acc) ->
    join_with_comma([], Acc ++ ?to_s(Last));
join_with_comma([H|T], Acc) ->
    join_with_comma(T, Acc ++ ?to_s(H) ++ ",").


amount_new(RSN, Merchant, Shop, Firm, Date, CurDateTime, Inv, Amounts) ->
    ?DEBUG("new inventory with rsn ~p~namounts ~p", [RSN, Amounts]), 
    StyleNumber = ?v(<<"style_number">>, Inv),
    Brand       = ?v(<<"brand">>, Inv),
    Type        = ?v(<<"type">>, Inv),
    Sex         = ?v(<<"sex">>, Inv),
    Year        = case ?v(<<"year">>, Inv) of
		      undefined ->
			  [CurYear|_] = string:tokens(?to_s(Date), "-"),
			  CurYear;
		      CurYear -> CurYear
		  end, 
    Season      = ?v(<<"season">>, Inv),
    %% Amount   = lists:reverse(?v(<<"amount">>, Inv)),
    SizeGroup   = ?v(<<"s_group">>, Inv),
    Free        = ?v(<<"free">>, Inv),
    Total       = ?v(<<"total">>, Inv),
    OrgPrice    = ?v(<<"org_price">>, Inv),
    TagPrice    = ?v(<<"tag_price">>, Inv),
    PkgPrice    = ?v(<<"pkg_price">>, Inv),
    P3          = ?v(<<"p3">>, Inv),
    P4          = ?v(<<"p4">>, Inv),
    P5          = ?v(<<"p5">>, Inv),
    Discount    = ?v(<<"discount">>, Inv),
    Path        = ?v(<<"path">>, Inv, []),
    AlarmDay    = ?v(<<"alarm_day">>, Inv, 7), 

    %% InventoryExist = ?sql_utils:execute(s_read, Sql0),

	
    Sql0 = "select id, style_number, brand from w_inventory"
	" where style_number=\"" ++ ?to_s(StyleNumber) ++ "\""
	++ " and brand=" ++ ?to_s(Brand)
    %% ++ " and color=" ++ ?to_s(Color)
    %% ++ " and size=" ++ "\"" ++ ?to_s(Size) ++ "\""
	++ " and shop=" ++ ?to_s(Shop)
	++ " and merchant=" ++ ?to_s(Merchant),
    Sql1 = 
	case ?sql_utils:execute(s_read, Sql0) of
	    {ok, []} ->
		["insert into w_inventory(rsn"
		 ", style_number, brand, type, sex, season, amount"
		 ", firm, s_group, free, year"
		 ", org_price, tag_price, pkg_price, price3"
		 ", price4, price5, discount, path, alarm_day"
		 ", shop, merchant, last_sell, change_date, entry_date)"
		 " values("
		 ++ "\"" ++ ?to_s(-1) ++ "\","
		 ++ "\"" ++ ?to_s(StyleNumber) ++ "\","
		 ++ ?to_s(Brand) ++ ","
		 ++ ?to_s(Type) ++ ","
		 ++ ?to_s(Sex) ++ ","
		 ++ ?to_s(Season) ++ ","
		 ++ ?to_s(Total) ++ ","
		 ++ ?to_s(Firm) ++ "," 
		 %% ++ ?to_s(Color) ++ ","
		 %% ++ "\"" ++ ?to_s(Size) ++ "\","
		 ++ "\"" ++ ?to_s(SizeGroup) ++ "\","
		 ++ ?to_s(Free) ++ ","
		 ++ ?to_s(Year) ++ ","
		 ++ ?to_s(OrgPrice) ++ ","
		 ++ ?to_s(TagPrice) ++ ","
		 ++ ?to_s(PkgPrice) ++ ","
		 ++ ?to_s(P3) ++ ","
		 ++ ?to_s(P4) ++ ","
		 ++ ?to_s(P5) ++ ","
		 ++ ?to_s(Discount) ++ ","
		 ++ "\"" ++ ?to_s(Path) ++ "\","
		 ++ ?to_s(AlarmDay) ++ ","
		 ++ ?to_s(Shop) ++ ","
		 ++ ?to_s(Merchant) ++ ","
		 ++ "\"" ++ ?to_s(Date) ++ "\","
		 ++ "\"" ++ ?to_s(CurDateTime) ++ "\","
		 ++ "\"" ++ ?to_s(Date) ++ "\")"]; 
	    {ok, R} ->
		["update w_inventory set"
		 " amount=amount+" ++ ?to_s(Total)
		 ++ ", org_price=" ++ ?to_s(OrgPrice)
		 %% ++ ", tag_price=" ++ ?to_s(TagPrice)
		 %% ++ ", pkg_price=" ++ ?to_s(PkgPrice)
		 %% ++ ", price3=" ++ ?to_s(P3)
		 %% ++ ", price4=" ++ ?to_s(P4)
		 %% ++ ", price5=" ++ ?to_s(P5)
		 %% ++ ", discount=" ++ ?to_s(Discount)
		 ++ ", change_date=" ++ "\"" ++ ?to_s(CurDateTime) ++ "\""
		 ++ ", entry_date=" ++ "\"" ++ ?to_s(Date) ++ "\""
		 ++ " where id=" ++ ?to_s(?v(<<"id">>, R))];
	    {error, Error} ->
		throw({db_error, Error})
	end,
	
    
    Sql20 = "select id, rsn, style_number, brand from w_inventory_new_detail"
	" where rsn=\'" ++ ?to_s(RSN) ++ "\'"
	" and style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
	" and brand=" ++ ?to_s(Brand),
    
    Sql2 = 
	case ?sql_utils:execute(s_read, Sql20) of
	    {ok, []} ->
		["insert into w_inventory_new_detail(rsn, style_number"
		 ", brand, type, sex, season, amount, firm"
		 ", s_group, free, year"
		 ", org_price, tag_price, pkg_price"
		 ", price3, price4, price5, discount, path"
		 ", entry_date) values("
		 ++ "\"" ++ ?to_s(RSN) ++ "\","
		 ++ "\"" ++ ?to_s(StyleNumber) ++ "\","
		 ++ ?to_s(Brand) ++ ","
		 ++ ?to_s(Type) ++ ","
		 ++ ?to_s(Sex) ++ ","
		 ++ ?to_s(Season) ++ ","
		 ++ ?to_s(Total) ++ ","
		 ++ ?to_s(Firm) ++ ","

		 ++ "\"" ++ ?to_s(SizeGroup) ++ "\","
		 ++ ?to_s(Free) ++ ","
		 ++ ?to_s(Year) ++ "," 

		 ++ ?to_s(OrgPrice) ++ ","
		 ++ ?to_s(TagPrice) ++ ","
		 ++ ?to_s(PkgPrice) ++ ","
		 ++ ?to_s(P3) ++ ","
		 ++ ?to_s(P4) ++ ","
		 ++ ?to_s(P5) ++ ","
		 ++ ?to_s(Discount) ++ ","
		 ++ "\"" ++ ?to_s(Path) ++ "\"," 
		 ++ "\"" ++ ?to_s(CurDateTime) ++ "\")"];
	    {ok, R20} ->
		["update w_inventory_new_detail set amount=amount+" ++ ?to_s(Total)
		 ++ " where id=" ++ ?to_s(?v(<<"id">>, R20))];
	    {error, Error20} ->
		throw({db_error, Error20})
	end,
    
    NewFun =
	fun({struct, Attr}, Acc) ->
		Color = ?v(<<"cid">>, Attr),
		Size  = ?v(<<"size">>, Attr),
		Count = ?v(<<"count">>, Attr),

		Sql00 = "select id, style_number, brand, color, size"
		    " from w_inventory_amount"
		    " where style_number=\"" ++ ?to_s(StyleNumber) ++ "\""
		    ++ " and brand=" ++ ?to_s(Brand)
		    ++ " and color=" ++ ?to_s(Color)
		    ++ " and size=" ++ "\"" ++ ?to_s(Size) ++ "\""
		    ++ " and shop=" ++ ?to_s(Shop)
		    ++ " and merchant=" ++ ?to_s(Merchant),

		Sql01 =
		    "select id, style_number, brand, color, size"
		    " from w_inventory_new_detail_amount"
		    " where rsn=\'" ++ ?to_s(RSN) ++ "\'"
		    ++ " and style_number=\"" ++ ?to_s(StyleNumber) ++ "\""
		    ++ " and brand=" ++ ?to_s(Brand)
		    ++ " and color=" ++ ?to_s(Color)
		    ++ " and size=" ++ "\"" ++ ?to_s(Size) ++ "\"",
		%% ++ " and shop=" ++ ?to_s(Shop)
		%% ++ " and merchant=" ++ ?to_s(Merchant),
		
		[case ?sql_utils:execute(s_read, Sql00) of
		     {ok, []} ->
			 "insert into w_inventory_amount(rsn"
			     ", style_number, brand, color, size"
			     ", shop, merchant, total, entry_date)"
			     " values("
			     ++ "\"" ++ ?to_s(-1) ++ "\","
			     ++ "\"" ++ ?to_s(StyleNumber) ++ "\","
			     ++ ?to_s(Brand) ++ ","
			     ++ ?to_s(Color) ++ ","
			     ++ "\'" ++ ?to_s(Size)  ++ "\',"
			     ++ ?to_s(Shop)  ++ ","
			     ++ ?to_s(Merchant) ++ ","
			     ++ ?to_s(Count) ++ "," 
			     ++ "\"" ++ ?to_s(CurDateTime) ++ "\")"; 
		     {ok, R00} ->
			 "update w_inventory_amount set"
			     " total=total+" ++ ?to_s(Count) 
			     ++ ", entry_date=" ++ "\"" ++ ?to_s(CurDateTime) ++ "\""
			     ++ " where id=" ++ ?to_s(?v(<<"id">>, R00));
		     {error, E00} ->
			 throw({db_error, E00})
		 end,

		 case ?sql_utils:execute(s_read, Sql01) of
		     {ok, []} ->
			 "insert into w_inventory_new_detail_amount(rsn"
			     ", style_number, brand, color, size, total, entry_date)"
			     " values("
			     ++ "\"" ++ ?to_s(RSN) ++ "\","
			     ++ "\"" ++ ?to_s(StyleNumber) ++ "\","
			     ++ ?to_s(Brand) ++ ","
			     ++ ?to_s(Color) ++ ","
			     ++ "\'" ++ ?to_s(Size)  ++ "\',"
			     ++ ?to_s(Count) ++ "," 
			     ++ "\"" ++ ?to_s(CurDateTime) ++ "\")";
		     {ok, R01} ->
			 "update w_inventory_new_detail_amount"
			     " set total=total+" ++ ?to_s(Count)
			     ++ ", entry_date=" ++ ?to_s(CurDateTime)
			     ++ " where id=" ++ ?to_s(?v(<<"id">>, R01));
		     {error, E00} ->
			 throw({db_error, E00})
		 end|Acc]
	end,

    Sql3 = lists:foldr(NewFun, [], Amounts),
    Sql1 ++ Sql2 ++ Sql3.

amount_reject(RSN, Merchant, Shop, Firm, Date, DateTime, Inv, Amounts) ->
    ?DEBUG("reject inventory with rsn ~p~namounts ~p", [RSN, Amounts]), 
    StyleNumber = ?v(<<"style_number">>, Inv),
    Brand       = ?v(<<"brand">>, Inv),
    Type        = ?v(<<"type">>, Inv),
    Sex         = ?v(<<"sex">>, Inv),
    Year        = case ?v(<<"year">>, Inv) of
		      undefined ->
			  [CurYear|_] = string:tokens(?to_s(Date), "-"),
			  CurYear;
		      CurYear -> CurYear
		  end, 
    Season      = ?v(<<"season">>, Inv),
    %% Amount      = lists:reverse(?v(<<"amount">>, Inv)),
    SizeGroup   = ?v(<<"s_group">>, Inv),
    Free        = ?v(<<"free">>, Inv),
    Total       = ?v(<<"total">>, Inv),
    OrgPrice    = ?v(<<"org_price">>, Inv),
    TagPrice    = ?v(<<"tag_price">>, Inv),
    PkgPrice    = ?v(<<"pkg_price">>, Inv),
    P3          = ?v(<<"p3">>, Inv),
    P4          = ?v(<<"p4">>, Inv),
    P5          = ?v(<<"p5">>, Inv),
    Discount    = ?v(<<"fdiscount">>, Inv),
    Path        = ?v(<<"path">>, Inv, []), 

    %% purchaser rejecting means reject to the firm,
    %% so, should minus from the inventory
    Sql1 = ["update w_inventory set"
	    " amount=amount-" ++ ?to_s(Total)
	    ++ ", change_date=" ++ "\"" ++ ?to_s(DateTime) ++ "\""
	    ++ " where style_number=\"" ++ ?to_s(StyleNumber) ++ "\""
	    ++ " and brand=" ++ ?to_s(Brand)
	    ++ " and shop=" ++ ?to_s(Shop)
	    ++ " and merchant=" ++ ?to_s(Merchant)],
    
    Sql2 = ["insert into w_inventory_new_detail(rsn, style_number"
	    ", brand, type, sex, season, amount, firm"
	    ", s_group, free, year"
	    ", org_price, tag_price, pkg_price"
	    ", price3, price4, price5, discount, path"
	    ", entry_date) values("
	    ++ "\"" ++ ?to_s(RSN) ++ "\","
	    ++ "\"" ++ ?to_s(StyleNumber) ++ "\","
	    ++ ?to_s(Brand) ++ ","
	    ++ ?to_s(Type) ++ ","
	    ++ ?to_s(Sex) ++ ","
	    ++ ?to_s(Season) ++ ","
	    ++ ?to_s(-Total) ++ ","
	    ++ ?to_s(Firm) ++ ","

	    ++ "\"" ++ ?to_s(SizeGroup) ++ "\","
	    ++ ?to_s(Free) ++ ","
	    ++ ?to_s(Year) ++ "," 

	    ++ ?to_s(OrgPrice) ++ ","
	    ++ ?to_s(TagPrice) ++ ","
	    ++ ?to_s(PkgPrice) ++ ","
	    ++ ?to_s(P3) ++ ","
	    ++ ?to_s(P4) ++ ","
	    ++ ?to_s(P5) ++ ","
	    ++ ?to_s(Discount) ++ ","
	    ++ "\"" ++ ?to_s(Path) ++ "\"," 
	    ++ "\"" ++ ?to_s(DateTime) ++ "\")"],

    NewFun =
	fun({struct, Attr}, Acc) ->
		Color = ?v(<<"cid">>, Attr),
		Size  = ?v(<<"size">>, Attr),
		Count = ?v(<<"reject_count">>, Attr), 
		
		["update w_inventory_amount set"
		 " total=total-" ++ ?to_s(Count) 
		 ++ " where style_number=\"" ++ ?to_s(StyleNumber) ++ "\""
		 ++ " and brand=" ++ ?to_s(Brand)
		 ++ " and color=" ++ ?to_s(Color)
		 ++ " and size=" ++ "\"" ++ ?to_s(Size) ++ "\""
		 ++ " and shop=" ++ ?to_s(Shop)
		 ++ " and merchant=" ++ ?to_s(Merchant), 
		

		 "insert into w_inventory_new_detail_amount(rsn"
		 ", style_number, brand, color, size, total, entry_date)"
		 " values("
		 ++ "\"" ++ ?to_s(RSN) ++ "\","
		 ++ "\"" ++ ?to_s(StyleNumber) ++ "\","
		 ++ ?to_s(Brand) ++ ","
		 ++ ?to_s(Color) ++ ","
		 ++ "\'" ++ ?to_s(Size)  ++ "\',"
		 ++ ?to_s(-Count) ++ "," 
		 ++ "\"" ++ ?to_s(Date) ++ "\")"|Acc] 
	end,

    Sql3 = lists:foldr(NewFun, [], Amounts),
    %% ?DEBUG("all sqls ~p", [Sql1 ++ Sql2 ++ Sql3]),
    Sql1 ++ Sql2 ++ Sql3.
   
amount_delete(RSN, Merchant, Shop, Inv, Amounts) ->
    ?DEBUG("delete inventory with rsn ~p~namounts ~p", [RSN, Amounts]), 
    StyleNumber = ?v(<<"style_number">>, Inv),
    Brand       = ?v(<<"brand">>, Inv),
    Metric      = update_metric(Amounts),
		     
    ["update w_inventory set amount=amount-" ++ ?to_s(Metric)
     ++ " where style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
     ++ " and brand=" ++ ?to_s(Brand)
     ++ " and shop=" ++ ?to_s(Shop)
     ++ " and merchant=" ++ ?to_s(Merchant),
     
     "delete from w_inventory_new_detail"
     ++ " where rsn=\"" ++ ?to_s(RSN) ++ "\""
     ++ " and style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
     ++ " and brand=" ++ ?to_s(Brand)] ++
    
	lists:foldr(
	  fun({struct, Attr}, Acc1)->
		  CId    = ?v(<<"cid">>, Attr),
		  Size   = ?v(<<"size">>, Attr),
		  Count  = ?v(<<"count">>, Attr),
		  ["update w_inventory_amount set total=total-"
		   ++ ?to_s(Count)
		   ++ " where style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
		   ++ " and brand=" ++ ?to_s(Brand)
		   ++ " and color=" ++ ?to_s(CId)
		   ++ " and size=\'" ++ ?to_s(Size) ++ "\'"
		   ++ " and shop=" ++ ?to_s(Shop) 
		   ++ " and merchant=" ++ ?to_s(Merchant),

		   "delete from w_inventory_new_detail_amount"
		   " where rsn=\"" ++ ?to_s(RSN) ++ "\""
		   ++ " and style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
		   ++ " and brand=" ++ ?to_s(Brand)
		   ++ " and color=" ++ ?to_s(CId)
		   ++ " and size=\'" ++ ?to_s(Size) ++ "\'"
		   | Acc1]
	  end, [], Amounts).

amount_update(RSN, Merchant, Shop, Date, Inv) ->
    ?DEBUG("update inventory with rsn ~p~namounts ~p",
	   [RSN, ?v(<<"changed_amount">>, Inv)]),
    StyleNumber    = ?v(<<"style_number">>, Inv),
    Brand          = ?v(<<"brand">>, Inv),
    OrgPrice       = ?v(<<"org_price">>, Inv, 0),
    Discount       = ?v(<<"discount">>, Inv, 0),
    %% OldTotal       = ?v(<<"old_total">>, Inv),
    %% Total          = ?v(<<"total">>, Inv),
    ChangeAmounts  = ?v(<<"changed_amount">>, Inv, []),

    C1 =
	fun(Color, Size) ->
		?utils:to_sqls(proplists,
			       [{<<"style_number">>, StyleNumber},
				{<<"brand">>, Brand},
				{<<"color">>, Color},
				{<<"size">>, Size},
				{<<"shop">>, Shop}, 
				{<<"merchant">>, Merchant}])
	end,

    C2 =
	fun(Color, Size) ->
		?utils:to_sqls(
		   proplists, [{<<"rsn">>, RSN},
			       {<<"style_number">>, StyleNumber},
			       {<<"brand">>, Brand},
			       {<<"color">>, Color},
			       {<<"size">>, Size}])
	end,

    Sql0 = 
	case update_metric(ChangeAmounts) of
	    0 -> ["update w_inventory_new_detail set org_price=" ++ ?to_s(OrgPrice)
		  ++ ",discount=" ++ ?to_s(Discount)
		  ++ " where rsn=\"" ++ ?to_s(RSN) ++ "\""
		  ++ " and style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
		  ++ " and brand=" ++ ?to_s(Brand),
		  
		  "update w_inventory set org_price=" ++ ?to_s(OrgPrice)
		  ++ ",discount=" ++ ?to_s(Discount)
		  ++ " where "
		  ++ "style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
		  ++ " and brand=" ++ ?to_s(Brand)
		  ++ " and shop=" ++ ?to_s(Shop)
		  ++ " and merchant=" ++ ?to_s(Merchant)
		 ];
	    Metric -> 
		["update w_inventory set amount=amount+" ++ ?to_s(Metric)
		 ++ ",org_price=" ++ ?to_s(OrgPrice)
		 ++ ",discount=" ++ ?to_s(Discount) 
		 ++ " where "
		 "style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
		 ++ " and brand=" ++ ?to_s(Brand)
		 ++ " and shop=" ++ ?to_s(Shop)
		 ++ " and merchant=" ++ ?to_s(Merchant),

		 "update w_inventory_new_detail set amount=amount+" ++ ?to_s(Metric)
		 ++ ",org_price=" ++ ?to_s(OrgPrice)
		 ++ ",discount=" ++ ?to_s(Discount) 
		 ++ " where rsn=\"" ++ ?to_s(RSN) ++ "\""
		 ++ " and style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
		 ++ " and brand=" ++ ?to_s(Brand)]
	end,

    %% Metric = ?to_i(Total) - ?to_i(OldTotal), 
    %% Metric = update_metric(ChangeAmounts), 
    ChangeFun =
	fun({struct, Attr}, Acc1) ->
		?DEBUG("Attr ~p", [Attr]),
		Color = ?v(<<"cid">>, Attr),
		Size  = ?v(<<"size">>, Attr),
		Count = ?v(<<"count">>, Attr),
		
		case ?v(<<"operation">>, Attr) of 
		    <<"a">> -> 
			Sql01 = "select id, style_number, brand, color, size"
			    " from w_inventory_amount"
			    " where " ++ C1(Color, Size),
			
			Sql02 = "select id, style_number, brand, color, size"
			    " from w_inventory_new_detail_amount"
			    " where " ++ C2(Color, Size),
			
			[ case ?sql_utils:execute(s_read, Sql01) of
			      {ok, []} ->
				  "insert into w_inventory_amount(rsn"
				      ", style_number, brand, color, size, shop"
				      ", merchant, total, entry_date) values("
				      ++ "\'" ++ ?to_s(-1) ++ "\',"
				      ++ "\"" ++ ?to_s(StyleNumber) ++ "\","
				      ++ ?to_s(Brand) ++ ","
				      ++ ?to_s(Color) ++ ","
				      ++ "\'" ++ ?to_s(Size)  ++ "\',"
				      ++ ?to_s(Shop) ++ ","
				      ++ ?to_s(Merchant) ++ ","
				      ++ ?to_s(Count) ++ ","
				      ++ "\"" ++ ?to_s(Date) ++ "\")";
			      {ok, _} ->
				  "update w_inventory_amount set total=total+" ++ ?to_s(Count)
				      ++ " where " ++ C1(Color, Size);
			      {error, E00} ->
				  throw({db_error, E00})
			  end,
			 
			 case ?sql_utils:execute(s_read, Sql02) of
			     {ok, []} ->
				 "insert into w_inventory_new_detail_amount(rsn"
				     ", style_number, brand, color, size, total, entry_date)"
				     " values("
				     ++ "\"" ++ ?to_s(RSN) ++ "\","
				     ++ "\"" ++ ?to_s(StyleNumber) ++ "\","
				     ++ ?to_s(Brand) ++ ","
				     ++ ?to_s(Color) ++ ","
				     ++ "\'" ++ ?to_s(Size)  ++ "\',"
				     ++ ?to_s(Count) ++ "," 
				     ++ "\"" ++ ?to_s(Date) ++ "\")";
			     {ok, _} ->
				 "update w_inventory_new_detail_amount set total=total+"
				     ++ ?to_s(Count)
				     ++ " where " ++ C2(Color, Size);
			     {error, E00} ->
				 throw({db_error, E00})
			 end | Acc1];
		    
		    <<"d">> -> 
			["update w_inventory_amount set total=total-"
			 ++ ?to_s(Count) ++ " where " ++ C1(Color, Size), 

			 "delete from w_inventory_new_detail_amount"
			 " where " ++ C2(Color, Size)
			 | Acc1];
		    <<"u">> -> 
			["update w_inventory_amount set total=total+" ++ ?to_s(Count)
			 ++ " where " ++ C1(Color, Size),

			 " update w_inventory_new_detail_amount"
			 " set total=total+" ++ ?to_s(Count)
			 ++ " where " ++ C2(Color, Size)|Acc1]
		end
	end,
    Sql0 ++ lists:foldr(ChangeFun, [], ChangeAmounts). 

update_metric(Amounts) ->
    lists:foldl(
      fun({struct, Attr}, Acc) ->
	      Count = ?v(<<"count">>, Attr),
	      case ?v(<<"operation">>, Attr) of
		  <<"d">> -> Acc - Count;
		  <<"a">> -> Acc + Count;
		  <<"u">> -> Acc + Count;
		  _ -> Acc + Count 
	      end
      end, 0, Amounts).

type(new) -> 0;
type(reject) -> 1.


sort_condition(w_inventory_new, Merchant, Conditions) ->
    HasPay = ?v(<<"has_pay">>, Conditions, []),

    C = proplists:delete(<<"has_pay">>, Conditions),
    {StartTime, EndTime, NewConditions} = ?sql_utils:cut(fields_with_prifix, C),

    ?sql_utils:condition(proplists_suffix, NewConditions)
	++ "a.merchant=" ++ ?to_s(Merchant)
	++ case HasPay of
	       [] -> [];
	       0 -> " and a.has_pay>0";
	       1 -> " and a.has_pay<0"
	   end
	++ case ?sql_utils:condition(time_with_prfix, StartTime, EndTime) of
	       [] -> [];
	       TimeSql -> " and " ++ TimeSql
	   end.

filter_condition(inventory_new, [], Acc1, Acc2) ->
    {lists:reverse(Acc1), lists:reverse(Acc2)};
filter_condition(inventory_new, [{<<"style_number">>,_} = S|T], Acc1, Acc2) ->
    filter_condition(inventory_new, T, [S|Acc1], Acc2);
filter_condition(inventory_new, [{<<"brand">>, _} = B|T], Acc1, Acc2) ->
    filter_condition(inventory_new, T, [B|Acc1], Acc2);
filter_condition(inventory_new, [{<<"firm">>, _} = F|T], Acc1, Acc2) ->
    filter_condition(inventory_new, T, [F|Acc1], [F|Acc2]);
filter_condition(inventory_new, [{<<"type">>, _} = OT|T], Acc1, Acc2) ->
    filter_condition(inventory_new, T, [OT|Acc1], Acc2);
filter_condition(inventory_new, [{<<"year">>, _} = OT|T], Acc1, Acc2) ->
    filter_condition(inventory_new, T, [OT|Acc1], Acc2);


%% filter_condition(inventory_new, [{<<"rsn">>, _} = R|T], Acc1, Acc2) ->
%%     filter_condition(inventory_new, T, Acc1, [R|Acc2]); 
%% filter_condition(inventory_new, [{<<"start_time">>, _} = SS|T], Acc1, Acc2) ->
%%     filter_condition(inventory_new, T, Acc1, [SS|Acc2]);
%% filter_condition(inventory_new, [{<<"end_time">>, _} = SE|T], Acc1, Acc2) ->
%%     filter_condition(inventory_new, T, Acc1, [SE|Acc2]);
filter_condition(inventory_new, [{<<"purchaser_type">>, OT}|T], Acc1, Acc2) ->
    filter_condition(inventory_new, T, Acc1, [{<<"type">>, OT}|Acc2]);
%% filter_condition(inventory_new, [{<<"shop">>, _} = S|T], Acc1, Acc2) ->
%%     filter_condition(inventory_new, T, Acc1, [S|Acc2]);


filter_condition(inventory_new, [O|T], Acc1, Acc2) ->
    filter_condition(inventory_new, T, Acc1, [O|Acc2]).

prompt_num(Merchant) ->
    {ok, Setting}      = ?wifi_print:detail(base_setting, Merchant, -1),
    PromptNum     = ?to_i(?v(<<"prompt">>, Setting, 8)),
    ?DEBUG("prompt ~p", [PromptNum]),
    PromptNum.
    %% {ok, Settings} = ?w_user_profile:get(setting, Merchant, -1),
    
