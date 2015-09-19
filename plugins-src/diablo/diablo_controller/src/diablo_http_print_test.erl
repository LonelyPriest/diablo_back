%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2015, buxianhui
%%% @doc
%%%  printer test
%%% @end
%%% Created : 22 May 2015 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_http_print_test).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-compile(export_all).
-import(?wifi_print,
	[server/1,
	 title/4, head/8,
	 row/3, body_foot/5,
	 multi_print/1, detail/2, detail/3,
	 get_printer_state/4,
	 multi_send/5]).

print(Merchant, ShopId, _PId) ->
    %% {ok, [{ShopInfo}]} = ?w_user_profile:get(shop, Merchant, ShopId),

    Printers =
	case ?w_user_profile:get(shop, Merchant, ShopId) of
	    {ok, []} -> [];
	    {ok, [{ShopInfo}]} ->
		case ?v(<<"repo">>, ShopInfo) of
		    -1 ->
			{ok, PrintShop}
			    = ?w_user_profile:get(print, Merchant, ShopId),
			PrintShop;
		    RepoId ->
			{ok, PrintShop}
			    = ?w_user_profile:get(print, Merchant, ShopId),
			{ok, PrintRepo}
			    = ?w_user_profile:get(print, Merchant, RepoId),
			PrintShop ++ PrintRepo
		end
	end,
    
    ?DEBUG("printers ~p", [Printers]),
    case Printers of
	[] -> {error, ?err(shop_not_printer, ShopId)}; 
	_  -> 
	    {ok, MerchantInfo} = ?merchant:merchant(get, Merchant), 
	    %% {ok, Banks}  = ?w_base:bank_card(list, Merchant),


	    RSN = lists:concat(["M-", Merchant, "-S", ShopId, "-88"]),
	    Retailer = [{<<"name">>, "令狐冲"},
			{<<"mobile">>, <<"18697378888">>},
			{<<"address">>, <<"湖南省益阳市">>}],
	    Employee = "木婉清",
	    Date     = ?utils:current_time(localdate),
	    
	    MerchantName = ?v(<<"name">>, MerchantInfo),

	    Welcome = "欢迎使用钱掌柜",
	    Promise = "钱掌柜承诺：认真对待客户的每一条意见！！",

	    {ok, Setting}      = detail(base_setting, Merchant, ShopId),
	    PrintModel         = ?to_i(?v(<<"pformat">>, Setting, ?COLUMN)),
	    PrintTable         = ?to_i(?v(<<"ptable">>, Setting, ?STRING)),
	    PrintRetailer      = ?to_i(?v(<<"pretailer">>, Setting, ?NO)),
	    ?DEBUG("print model ~p, print table ~p", [PrintModel, PrintTable]),
	    
	    Fields = ?wifi_print:detail(print_format, Merchant, ShopId), 

	    try
		lists:foldr(
		  fun({P}, Acc) ->
			  SN     = ?v(<<"sn">>, P),
			  Key    = ?v(<<"code">>, P),
			  Path   = ?v(<<"server_path">>, P),

			  Brand  = ?v(<<"brand">>, P),
			  Model  = ?v(<<"model">>, P),
			  Column = ?v(<<"pcolumn">>, P),
			  Height = ?v(<<"pheight">>, P),

			  Server = server(?v(<<"server_id">>, P)),
			  THead = title(Brand, Model, Column, Welcome)
			      ++ ?f_print:br(Brand)
			      ++ title(Brand, Model, Column, Promise)

			      ++ ?f_print:left_pading(Brand, Model)
			      ++ ?f_print:line(equal, Column) ++ ?f_print:br(Brand) 
			      ++ ?f_print:br(Brand) 

			      ++ title(Brand, Model, Column, MerchantName)
			      ++ head(Brand, Model, Column, RSN, PrintRetailer,
				      Retailer, Employee, Date)

			      ++ ?f_print:left_pading(Brand, Model)
			      ++ ?f_print:line(equal, Column) ++ ?f_print:br(Brand),

			  TBody =
			      case PrintModel of
				  ?COLUMN ->
				      ?wifi_print:body_head(
					 PrintTable, ?COLUMN, Brand, Model, Fields, Column); 
				  ?ROW -> 
				      Sizes = [<<"s">>, <<"m">>, <<"l">>,
					       <<"xl">>, <<"2xl">>, <<"3xl">>], 
				      
				      {true, SizeWidth} = ?f_print:field(size, Fields),
				      FlatternSizes =
					  ?f_print:flattern(size, {PrintTable, SizeWidth}, Sizes),
				      
				      ?wifi_print:body_head(PrintTable, ?ROW, Brand, Model,
							    Fields, FlatternSizes)
			      end,
			  
			  %% DBody = ?f_print:pagination(Height * 10, Body),
			  DBody = ?f_print:pagination(auto, Height * 10, THead ++ TBody),
			  [{SN, fun() when Server =:= rcloud ->
					?wifi_print:start_print(
					  rcloud, Brand, Model, Height,
					  SN, Key, Path, DBody);
				   () when Server =:= fcloud ->
					?wifi_print:start_print(
					   fcloud, SN, Key, Path, THead ++ TBody) 
				end}|Acc]
		  end, [], Printers) of
		PrintInfo -> 
		    multi_print(PrintInfo)
		 catch
		     size_not_include ->
			 {error, ?err(print_size_not_include, ShopId)}
		 end
    end.

body(test, PBrand, Model, 33, Merchant, Banks) -> 
    Comment = "仅仅测试",
    %% Brand = "钱掌柜",
    StyleNumber = "1A001888",
    FPrice = 100,
    Count  = 2,
    Calc   = "200", 

    ?wifi_print:body_head(Merchant, PBrand, Model, 33)
	++ ?f_print:left_pading(PBrand, Model)
	++ ?to_s(StyleNumber) ++ ?f_print:pading(14 - length(?to_s(StyleNumber))) 
	++ ?to_s(FPrice) ++ ?f_print:pading(6 - length(?to_s(FPrice)))
	++ ?to_s(Count) ++ ?f_print:pading(6 - length(?to_s(Count)))
	++ Calc ++ ?f_print:br(PBrand)

	++ ?f_print:left_pading(PBrand, Model)
	++ ?f_print:pading(20) ++ ?to_s(2) ++ ?f_print:br(PBrand)

	++ ?f_print:left_pading(PBrand, Model)
	++ ?f_print:line(minus, 33) ++ ?f_print:br(PBrand)

	++ ?f_print:left_pading(PBrand, Model) ++ "总计：" ++ ?to_s(2)
	++ ?f_print:pading(1) ++ "总金额：" ++ ?to_s(200)
	++ ?f_print:pading(1) ++ "备注："  ++ ?to_s(Comment)
	++ ?f_print:br(PBrand)

	++ ?f_print:left_pading(PBrand, Model) ++ ?f_print:line(minus, 33)
	++ ?f_print:br(PBrand)
	
	++ ?f_print:left_pading(PBrand, Model) ++ "上次欠款：" ++ ?to_s(500) 
	++ ?f_print:br(PBrand)
	
	++ ?f_print:left_pading(PBrand, Model) ++ "本次欠款：" ++ ?to_s(200)
	++ ?f_print:br(PBrand)

	++ ?f_print:left_pading(PBrand, Model) ++ "累计欠款：" ++ ?to_s(700) 
	++ ?f_print:br(PBrand)

	++ body_foot(PBrand, Model, 33, Banks, Merchant);

body(test, PBrand, Model, 50, Merchant, Banks) -> 
    Comment = "仅仅测试",
    Brand = "钱掌柜", 
    StyleNumber = "1A001888",
    Color = "蓝色",
    Size  = "S",
    FPrice = 100,
    Count  = 2,
    Calc   = "200", 

    MerchantId = ?v(<<"id">>, Merchant),
    {ok, Settings} = detail(base_setting, MerchantId),
    ?DEBUG("Settings ~p", [Settings]),
    
    body_head(MerchantId, PBrand, Model, 50)
	++ ?f_print:left_pading(PBrand, Model)
	++ ?to_s(Brand) ++ ?f_print:pading(12 - ?f_print:width(chinese, Brand))
	++ ?to_s(StyleNumber) ++ ?f_print:pading(8 - length(?to_s(StyleNumber)))

	++ case ?v(<<"pcolor">>, Settings) of
	       <<"1">> ->
		   ?to_s(Color)
		       ++ ?f_print:pading(8 -?f_print:width(chinese, Color));
	       _ -> ?f_print:pading(8)
	   end

	++ case ?v(<<"psize">>, Settings) of
	       <<"1">> ->
		   ?to_s(Size) ++ ?f_print:pading(5 - 1);
	       _ -> ?f_print:pading(5)
	   end
	++ ?to_s(?f_print:clean_zero(FPrice))
	++ ?f_print:pading(6 - length(?to_s(?f_print:clean_zero(FPrice))))
	++ ?to_s(Count) ++ ?f_print:pading(5 - length(?to_s(Count)))
	++ Calc ++ ?f_print:br(PBrand)

	++ ?f_print:left_pading(PBrand, Model)
	++ ?f_print:pading(39) ++ ?to_s(2) ++ ?f_print:br(PBrand)

	++ ?f_print:left_pading(PBrand, Model)
	++ ?f_print:line(minus, 50) ++ ?f_print:br(PBrand)

	++ ?f_print:left_pading(PBrand, Model) ++ "总计：" ++ ?to_s(2)
	++ ?f_print:pading(2) ++ "总金额：" ++ ?to_s(200)
	++ ?f_print:pading(4) ++ "备注："  ++ ?to_s(Comment)
	++ ?f_print:br(PBrand)

	++ ?f_print:left_pading(PBrand, Model)
	++ ?f_print:line(minus, 50) ++ ?f_print:br(PBrand)

	++ ?f_print:left_pading(PBrand, Model) ++ "上次欠款：" ++ ?to_s(500)
	++ ?f_print:pading(2) ++ "本次欠款：" ++ ?to_s(200)
	++ ?f_print:pading(2) ++ "累计欠款：" ++ ?to_s(700) 
	++ ?f_print:br(PBrand)

	++ body_foot(PBrand, Model, 50, Banks, Merchant);

body(test, PBrand, Model, Column, Merchant, Banks) ->
    ?DEBUG("body_test pbrand ~p, model ~p, column ~p", [PBrand, Model, Column]),
    Comment = "仅仅测试",
    Brand = "钱掌柜",
    StyleNumber = "1A00188888",
    Color = "蓝色",
    FPrice = 100, 

    Sizes = [<<"s">>, <<"m">>, <<"l">>, <<"xl">>, <<"2xl">>, <<"3xl">>],
    FlatternSizes = ?f_print:flattern(size, {Column, 1}, Sizes),

    SortAmounts = [{Brand, StyleNumber, Color, FPrice, [10, 0, 2, 5, 0, 20]}],
    FlatternAmounts = ?f_print:flattern(amount, {Column, 1}, SortAmounts),

    MerchantId = ?v(<<"id">>, Merchant),
    body_head(MerchantId, PBrand, Model, {Column, 1}, FlatternSizes)
	++ row(PBrand, Model, FlatternAmounts)

	++ ?f_print:left_pading(PBrand, Model)
	++ "总计：" ++ ?to_s(37)
	++ ?f_print:pading(2) ++ "总金额：" ++ ?to_s(100 * 37)
	++ ?f_print:pading(2) ++ "备注：" ++ ?to_s(Comment)

	++ case Column - (8 + 14 + 8 + ?f_print:width(chinese, Comment)) 
	       >= 17 + 16 + 16 of
	       true -> ?f_print:pading(4);
	       false -> ?f_print:br(Model) ++ ?f_print:left_pading(PBrand, Model)
	   end

	++ "上次欠款：" ++ ?to_s(500)
	++ ?f_print:pading(2) ++ "本次欠款：" ++ ?to_s(100 * 37)
	++ ?f_print:pading(2) ++ "累计欠款：" ++ ?to_s(500 + 100 * 37) 
	++ ?f_print:br(PBrand)
	++ ?f_print:line(minus, Column) ++ ?f_print:br(PBrand)
	++ body_foot(PBrand, Model, Column, Banks, Merchant).    


body_head(Merchant, Brand, Model, 50) -> 
    {ok, Settings} = detail(base_setting, Merchant),

        ?f_print:left_pading(Brand, Model)
	++ "品牌" ++ ?f_print:pading(12 - 4)
	++ "款号" ++ ?f_print:pading(8 - 4)
	++ case ?v(<<"pcolor">>, Settings) of
	              <<"1">> ->
		   "颜色" ++ ?f_print:pading(8 - 4);

	              _ -> ?f_print:pading(8)
			          end
	++ case ?v(<<"psize">>, Settings) of
	              <<"1">> -> "尺码" ++ ?f_print:pading(5 - 4);
	              _ -> ?f_print:pading(5)
			          end
	++ "单价" ++ ?f_print:pading(6 - 4)
	++ "数量" ++ ?f_print:pading(5 - 4)
	++ "小计" ++ ?f_print:br(Brand).

body_head(_Merchant, Brand, Model, 80, FlatternSizes) ->
        ?f_print:left_pading(Brand, Model)
	++ "品牌" ++ ?f_print:pading(14 - 4)
	++ "款号" ++ ?f_print:pading(8 - 4)
	++ "颜色" ++ ?f_print:pading(8 - 4)
	++ FlatternSizes
	++ ?f_print:pading(30 - ?f_print:width(chinese, FlatternSizes))
	++ "单价" ++ ?f_print:pading(6-4)
	++ "数量" ++ ?f_print:pading(6-4)
	++ "小计" ++ ?f_print:br(Brand);

body_head(_Merchant, Brand, Model, 106, FlatternSizes) ->
        ?f_print:left_pading(Brand, Model)
	++ "品牌" ++ ?f_print:pading(20 - 4)
	++ "款号" ++ ?f_print:pading(12 - 4)
	++ "颜色" ++ ?f_print:pading(12 - 4)
	++ FlatternSizes
	++ ?f_print:pading(40 - ?f_print:width(chinese, FlatternSizes))
	++ "单价" ++ ?f_print:pading(8-4)
	++ "数量" ++ ?f_print:pading(8-4)
	++ "小计" ++ ?f_print:br(Brand).


start_print(rcloud, Brand, Model, Height, SN, Key, Path, {IsPage, Body})  ->
    ?DEBUG("print with brand ~p, Model ~p, Height ~p, sn ~p, key ~p, path ~p"
	   "IsPage ~p, body~n~ts",
	   [Brand, Model, Height, SN, Key, Path, IsPage, ?to_b(Body)]),

    CureentTimeTicks = (?SECONDS_BEFOR_1970 + ?utils:current_time(timestamp)) * 10000, 
    Head = ?f_print:decorate_data(head, ?to_a(Brand), ?to_a(Model), Height * 10), 
    Tail = ?f_print:decorate_data(tail, ?to_a(Brand), ?to_a(Model)),

    %% ?DEBUG("Head ~p", [Head]),
    %% ?DEBUG("Tail ~p", [Tail]),

    try 
	%% query state 
	{ok, SN} = get_printer_state(Path, SN, Key, CureentTimeTicks),

	%% TB = ?to_s(<<16#1b, 16#44, 16#04, 16#08, 16#16, 00,
	%% 	      16#31, 16#32, 16#09,
	%% 	      16#33, 16#34, 16#09,
	%% 	      16#35, 16#36, 16#38, 16#09,
	%% 	      16#39, 16#40, 16#41, 16#42, 16#0a>>),

	%% ?DEBUG("TB ~p", [TB]),

	%% Utf8Data = unicode:characters_to_list(?to_s(TB), utf8),
	%% ?DEBUG("utf8 data ~p", [Utf8Data]),
	%% GBKData  = diablo_iconv:convert("utf-8", "gbk", Utf8Data),
	%% ?DEBUG("GBKData ~p", [GBKData]),
	%% Base64 = base64:encode_to_string(GBKData),
	%% ?DEBUG("Base64 ~p", [Base64]), 
	
	GBKBodys = 
	    lists:foldr(
	      fun(B, Acc) ->
		      %% ?DEBUG("B~ts", [?to_b(B)]),
		      Utf8Data = unicode:characters_to_list(?to_s(B), utf8),
		      %% ?DEBUG("utf8 data ~p", [Utf8Data]),
		      GBKData  = diablo_iconv:convert("utf-8", "gbk", Utf8Data),
		      %% ?DEBUG("GBKData ~p", [GBKData]),
		      Base64 = 
			  case IsPage of
			      true ->
			  	  base64:encode_to_string(Head ++ GBKData ++ Tail);
			      false -> 
				  base64:encode_to_string(GBKData)
			  end,
		      %% ?DEBUG("Base64 ~p", [Base64]),
		      [Base64|Acc]
	      end,  [], Body),

	%% {ok, SN} = get_printer_state(Path, SN, Key, CureentTimeTicks),
	SignHead = lists:concat(
		     ["action=send&device_id=", ?to_s(SN),
		      "&secretkey=", ?to_s(Key),
		      "&timestamp=" ++ ?to_s(CureentTimeTicks) ++ "&"]),

	multi_send(SignHead, Path, SN, GBKBodys, {}) 
    catch
    	throw:{printer_unconnect, DeviceId} ->
    	    ?DEBUG("printer ~p unconnect", [DeviceId]),
	    {error, ?err(printer_unconnect, DeviceId)};
	throw:{printer_no_paper, DeviceId} ->
	    ?DEBUG("printer ~p has not paper", [DeviceId]),
	    {error, ?err(printer_no_paper, DeviceId)};
	throw:{printer_unkown_state, DeviceId} ->
	    ?DEBUG("printer ~p unkown", [DeviceId]),
	    {error, ?err(printer_unkown_state, DeviceId)};
	throw:{printer_conn_not_found, DeviceId} ->
	    {error, ?err(printer_conn_not_found, DeviceId)} 
    end.
