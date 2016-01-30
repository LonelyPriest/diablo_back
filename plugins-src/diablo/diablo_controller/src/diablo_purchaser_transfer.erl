%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2016, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 28 Jan 2016 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_purchaser_transfer).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-compile(export_all).

amount_transfer(Transfer, RSN, Merchant, Shop, Firm, Datetime, Inv) ->
    ?DEBUG("transfer inventory with transfer ~p, rsn ~p~nInv ~p",
	   [Transfer, RSN, Inv]),

    Amounts     = ?v(<<"amounts">>, Inv),
    StyleNumber = ?v(<<"style_number">>, Inv),
    Brand       = ?v(<<"brand">>, Inv),
    Type        = ?v(<<"type">>, Inv),
    Sex         = ?v(<<"sex">>, Inv), 
    Season      = ?v(<<"season">>, Inv),

    OrgPrice    = ?v(<<"org_price">>, Inv),
    TagPrice    = ?v(<<"tag_price">>, Inv),
    PkgPrice    = ?v(<<"pkg_price">>, Inv),
    P3          = ?v(<<"p3">>, Inv),
    P4          = ?v(<<"p4">>, Inv),
    P5          = ?v(<<"p5">>, Inv),
    
    %% Amount      = lists:reverse(?v(<<"amount">>, Inv)),
    SizeGroup   = ?v(<<"s_group">>, Inv),
    Free        = ?v(<<"free">>, Inv),
    Year        = case ?v(<<"year">>, Inv) of
		      undefined -> ?utils:current_time(year);
		      CurYear -> CurYear
		  end,
    
    Total       = ?v(<<"total">>, Inv),
    
    Discount    = ?v(<<"discount">>, Inv),
    Path        = ?v(<<"path">>, Inv, []),
    AlarmDay    = ?v(<<"alarm_day">>, Inv, ?DEFAULT_ALARM_DAY),

    
    Sql1 = case Transfer of
	       transfer_from ->
		   ["update w_inventory set"
		    " amount=amount-" ++ ?to_s(Total)
		    ++ ", change_date=" ++ "\"" ++ ?to_s(Datetime) ++ "\""
		    ++ " where style_number=\"" ++ ?to_s(StyleNumber) ++ "\""
		    ++ " and brand=" ++ ?to_s(Brand)
		    ++ " and shop=" ++ ?to_s(Shop)
		    ++ " and merchant=" ++ ?to_s(Merchant)];
	       transfer_to ->
		   Sql11 = "select id, style_number, brand, shop"
		       " from w_inventory"
		       ++ " where "
		       ++ "style_number=\"" ++ ?to_s(StyleNumber) ++ "\""
		       ++ " and brand=" ++ ?to_s(Brand)
		       ++ " and shop=" ++ ?to_s(Shop)
		       ++ " and merchant=" ++ ?to_s(Merchant),

		   case ?sql_utils:execute(s_read, Sql11) of
		       {ok, []} ->
			   ["insert into w_inventory(rsn"
			    ", style_number, brand, type, sex, season, amount"
			    ", firm, s_group, free, year"
			    ", org_price, tag_price, pkg_price, price3"
			    ", price4, price5, discount, path, alarm_day"
			    ", shop, merchant"
			    ", last_sell, change_date, entry_date)"
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
			    ++ "\"" ++ ?to_s(Datetime) ++ "\","
			    ++ "\"" ++ ?to_s(Datetime) ++ "\","
			    ++ "\"" ++ ?to_s(Datetime) ++ "\")"]; 
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
			    ++ ", change_date="
			    ++ "\"" ++ ?to_s(Datetime) ++ "\""
			    ++ ", entry_date="
			    ++ "\"" ++ ?to_s(Datetime) ++ "\""
			    ++ " where id=" ++ ?to_s(?v(<<"id">>, R))];
		       {error, Error} ->
			   throw({db_error, Error})
		   end
	   end, 

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
	    ++ case Transfer of
		   transfer_from ->?to_s(-Total) ++ ",";
		   transfer_to -> ?to_s(Total) ++ ","
	       end
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
	    ++ "\"" ++ ?to_s(Datetime) ++ "\")"],

    NewFun =
	fun({struct, Attr}, Acc) ->
		Color = ?v(<<"cid">>, Attr),
		Size  = ?v(<<"size">>, Attr),
		Count = ?v(<<"count">>, Attr), 

		Condition = "style_number=\"" ++ ?to_s(StyleNumber) ++ "\""
		    ++ " and brand=" ++ ?to_s(Brand)
		    ++ " and color=" ++ ?to_s(Color)
		    ++ " and size=" ++ "\"" ++ ?to_s(Size) ++ "\""
		    ++ " and shop=" ++ ?to_s(Shop)
		    ++ " and merchant=" ++ ?to_s(Merchant),
		
		case Transfer of
		    transfer_from ->
			["update w_inventory_amount set"
			 " total=total-" ++ ?to_s(Count) 
			 ++ " where " ++ Condition];
		    transfer_to -> 
			Sql01 = "select id, style_number, brand, color, size"
			    " from w_inventory_amount"
			    " where " ++ Condition,
		
			[case ?sql_utils:execute(s_read, Sql01) of
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
				     ++ "\"" ++ ?to_s(Datetime) ++ "\")"; 
			     {ok, R1} ->
				 "update w_inventory_amount set"
				     " total=total+" ++ ?to_s(Count) 
				     ++ ", entry_date="
				     ++ "\"" ++ ?to_s(Datetime) ++ "\""
				     ++ " where id="
				     ++ ?to_s(?v(<<"id">>, R1));
			     {error, E00} ->
				 throw({db_error, E00})
			 end]
		end ++
		    ["insert into w_inventory_new_detail_amount(rsn"
		     ", style_number, brand, color, size"
		     ", total, entry_date)"
		     " values("
		     ++ "\"" ++ ?to_s(RSN) ++ "\","
		     ++ "\"" ++ ?to_s(StyleNumber) ++ "\","
		     ++ ?to_s(Brand) ++ ","
		     ++ ?to_s(Color) ++ ","
		     ++ "\'" ++ ?to_s(Size)  ++ "\',"
		     ++ case Transfer of
			    transfer_from -> ?to_s(-Count) ++ ",";
			    transfer_to -> ?to_s(Count) ++ ","
			end 
		     ++ "\"" ++ ?to_s(Datetime) ++ "\")"] ++ Acc
	end,

    Sql3 = lists:foldr(NewFun, [], Amounts),
    %% ?DEBUG("all sqls ~p", [Sql1 ++ Sql2 ++ Sql3]),
    Sql1 ++ Sql2 ++ Sql3.
