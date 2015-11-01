%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2015, buxianhui
%%% @doc
%%%
%%% @end
%%% Created :  3 Mar 2015 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_http_print).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_server).

%% API
-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-export([print/4, print/5, call/2]).

-export([server/1,
	 title/4, head/7, head/8,  body_head/6,
	 row/2, body_foot/6, detail/2, detail/3,
	 start_print/8, start_print/5,
	 multi_print/1, get_printer_state/4, multi_send/5]).

-import(?f_print,
	[width/2, middle/3, pading/1, left_pading/2, clean_zero/1, br/1,
	 line/2, line/4, line/5, phd/1, line_space/1,
	 sort_amount/3, flattern/3, field_len/4, field/2, f_round/1]).

-import(?f_print,[decorate_data/1]).

-define(SERVER, ?MODULE).
-define(PRINT_FIELDS,
	[brand, style_number, type, color, size_name,
	 size, price, discount, dprice, hand, count, calc]).

-record(state, {}).

%%%===================================================================
%%% API
%%%===================================================================

%% print(Merchant, Shop, Content) ->
%%     gen_server:call(?SERVER, {print, Merchant, Shop, Content}).

print(test, Merchant, Shop, PId) ->
    gen_server:call(?SERVER, {print_test, Merchant, Shop, PId}).

print(RSn, Merchant, Inventories, Attrs, Print) ->
    %% call({print, RSn, Merchant, Inventories, Attrs, Print}).
    %% gen_server:call(
    %% ?SERVER, {print, RSn, Merchant, Inventories, Attrs, Print}).
    
    Self = self(),
    spawn(?MODULE, call,
	  [Self, {print, RSn, Merchant, Inventories, Attrs, Print}]),

    receive
	{Self, Any} -> Any
    after 3000 ->
	    {error, ?err(print_timeout, RSn)}
    end.
    

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

init([]) ->
    inets:start(),
    {ok, #state{}}. 

handle_call({print_test, Merchant, Shop, PId}, _Form, State) ->
    Reply = diablo_http_print_test:print(Merchant, Shop, PId),
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


call(Parent, {print, RSN, Merchant, Invs, Attrs, Print}) ->
    ?DEBUG("print with RSN ~p, merchant ~p~ninventory ~p~nAttrs ~p"
	   ", Print  ~p", [RSN, Merchant, Invs, Attrs, Print]),

    ShopId = ?v(<<"shop">>, Attrs), 

    {Printers, ShopInfo} =
	case ?w_user_profile:get(shop, Merchant, ShopId) of
	    {ok, []} -> {[], []};
	    {ok, [{Shop}]} ->
		case ?v(<<"repo">>, Shop) of
		    -1 ->
			case ?w_user_profile:get(print, Merchant, ShopId) of
			    {ok, []} -> {[], []};
			    {ok, [{P1}]} ->
				{[[{<<"pshop">>, ShopId}|P1]], Shop}
			end;
		    RepoId ->
			{[case ?w_user_profile:get(print, Merchant, ShopId) of
			      {ok, []} -> [];
			      {ok, [{P1}]} ->
				  [{<<"pshop">>, ShopId}|P1]
			  end,
			  case ?w_user_profile:get(print, Merchant, RepoId) of
			      {ok, []} -> [];
			      {ok, [{P2}]} -> [{<<"pshop">>, RepoId}|P2]
			  end], Shop}
		end
	end,

    %% ?DEBUG("printers ~p", [Printers]),
    VPrinters = [P || P <- Printers, length(P) =/= 0 ],
    ?DEBUG("printers ~p", [VPrinters]),
    case VPrinters of
	[] ->
	    Parent ! {Parent, {error, ?err(shop_not_printer, ShopId)}};
	_  ->
	    %% content info
	    %% Retailer     = ?v(<<"retailer">>, Print),
	    RetailerId = ?v(<<"retailer_id">>, Print),
	    {ok, Retailer}
		= ?w_user_profile:get(retailer, Merchant, RetailerId),
	    %% ?DEBUG("retailer  ~p", [Retailer]),
	    Employee     = ?v(<<"employ">>, Print), 
	    DateTime     = ?v(<<"datetime">>, Attrs),
	    Total        = ?v(<<"total">>, Attrs, 0),
	    Direct       = ?v(<<"direct">>, Attrs, 0),
	    [Date, _]    = string:tokens(?to_s(DateTime), " "),

	    %% shop info
	    ShopName = case ?w_sale:direct(Direct) of
			   wreject ->
			       ?to_s(?v(<<"name">>, ShopInfo))
				   ++ "（退货单）";
			   _       ->
			       ?v(<<"name">>, ShopInfo)
		       end,

	    ShopAddr = ?v(<<"address">>, ShopInfo),

	    %% profile
	    {ok, MerchantInfo} = detail(merchant, Merchant), 
	    {ok, Banks}        = detail(bank, Merchant),
	    %% {ok, Setting}      = detail(base_setting, Merchant, ShopId),
	    %% PrintRetailer      = ?to_i(?v(<<"pretailer">>, Setting, ?NO)),
	    %% PrintTable         = ?to_i(?v(<<"ptable">>, Setting, ?STRING)),
	    %% IsRound            = ?to_i(?v(<<"pround">>, Setting, ?NO)),
	    Mobile             = ?v(<<"mobile">>, MerchantInfo),

	    %% ?DEBUG("PrintRetailer ~p, PrintTable ~p", [PrintRetailer, PrintTable]), 

	    try
		lists:foldr(
		  fun(P, Acc) ->
			  SN     = ?v(<<"sn">>, P),
			  Key    = ?v(<<"code">>, P),
			  Path   = ?v(<<"server_path">>, P),

			  Brand  = ?v(<<"brand">>, P),
			  Model  = ?v(<<"model">>, P),

			  Column = ?v(<<"pcolumn">>, P),
			  Height = ?v(<<"pheight">>, P),
			  PShop  = ?v(<<"pshop">>, P),

			  ?DEBUG("P ~p", [P]),
			  Server = server(?v(<<"server_id">>, P)),

			  {ok, Setting}
			      = detail(base_setting, Merchant, PShop),
			  PrintRetailer
			      = ?to_i(?v(<<"pretailer">>, Setting, ?NO)),
			  PrintTable
			      = ?to_i(?v(<<"ptable">>, Setting, ?STRING)),
			  IsRound
			      = ?to_i(?v(<<"pround">>, Setting, ?NO)),

			  %% ?DEBUG("PrintRetailer ~p, PrintTable ~p",
			  %% [PrintRetailer, PrintTable]), 
			  %% ?DEBUG("column ~p", [Column]),

			  Head = title(Brand, Model, Column, ShopName)
			      ++ address(Brand, Model, Column, ShopAddr)
			      ++ head(Brand, Model, Column, RSN,
				      PrintRetailer, Retailer, Employee, Date)

			      ++ left_pading(Brand, Model)

			      ++ case PrintTable of
				     ?TABLE  ->
					 line_space('1/8');
				     %% ++ line(minus, Column) ++ br(Brand);
				     ?STRING ->
					 line(equal, Column) ++ br(Brand)
				 end,

			  Body = print_content(
				   PShop, Brand, Model, Column,
				   Merchant, Setting, Invs, Total,
				   ?v(<<"should_pay">>, Attrs, 0))
			      ++ case PrintTable of
				     ?TABLE  ->
					 %% line_space(default);
					 line_space('1/6');
				     ?STRING ->
					 []
				 end,
			  %% ?DEBUG("body ~ts", [?to_b(Body)]),

			  Stastic = body_stastic(
				      IsRound, Brand, Model, Column, Attrs),
			  Foot = body_foot(
				   Brand, Model, Column, Banks, Mobile, Setting), 
			  Content = Head ++ Body ++ Stastic ++ Foot,

			  UpgradeDevices =
			      ["1006", "1008", "1024", "1037", "1031"],
			  DBody = 
			      case lists:member(?to_s(SN), UpgradeDevices) of
				  true -> 
				      %% no page
				      %% ?DEBUG("no page with sn ~p", [SN]),
				      ?f_print:pagination(
					 just, Height * 10, Content);
				  false ->
				      %% auto page
				      %% ?DEBUG("auto page with sn ~p", [SN]),
				      ?f_print:pagination(
					 auto, Height * 10, Content)
			      end,

			  %% page by height
			  %% DBody = ?f_print:pagination(Height * 10, Content), 
			  ?DEBUG("server ~p", [Server]),
			  [{SN, fun() when Server =:= rcloud ->
					start_print(
					  rcloud, Brand, Model, Height,
					  SN, Key, Path, DBody);
				   () when Server =:= fcloud ->
					start_print(
					  fcloud, SN, Key, Path, Content) 
				end}|Acc] 
		  end, [], VPrinters) of
		PrintInfo -> 
		    Reply = multi_print(PrintInfo),
		    Parent ! {Parent, Reply}
	    catch
		size_not_include ->
		   Parent ! {Parent,
			     {error, ?err(print_size_not_include, ShopId)}}
	    end
    end.

print_content(_ShopId, PBrand, Model, 33, Merchant, _Setting, Invs, _T, _S) ->
    %% DateTime     = ?v(<<"datetime">>, Attrs), 
    %% Retailer     = ?v(<<"retailer">>, Print),
    %% Employee     = ?v(<<"employ">>, Print),

    %% [Date, _] = string:tokens(?to_s(DateTime), " "),

    %% {ok, MerchantInfo} = detail(merchant, Merchant), 
    %% {ok, Banks}        = detail(bank, Merchant),
    %% {ok, Setting}      = detail(base_setting, Merchant),

    %% MerchantName   = ?v(<<"name">>, MerchantInfo),
    %% Mobile         = ?v(<<"mobile">>, MerchantInfo),
    %% Address        = ?v(<<"address">>, MerchantInfo),

    %% ?DEBUG("==== invs ~p", [Invs]),

    TFun = fun(Amounts) ->
		   lists:foldr(
		     fun({struct, A}, Acc) ->
			     ?v(<<"sell_count">>, A) + Acc
		     end, 0, Amounts)
	   end,

    SortAmounts = 
	lists:foldr(
	  fun({struct, Inv}, Acc0)->
		  Amounts     = ?v(<<"amounts">>, Inv), 
		  StyleNumber = ?v(<<"style_number">>, Inv),
		  FPrice      = ?v(<<"fprice">>, Inv),
		  SellTotal   = TFun(Amounts),

		  case [ A || {S, F, _} = A <- Acc0,
			      S =:= StyleNumber, F =:= FPrice] of
		      [] -> [{StyleNumber, FPrice, SellTotal}|Acc0];
		      _ ->
			  lists:foldr(
			    fun({SN, F, S}, Acc1) when
				      SN =:= StyleNumber, F =:= FPrice ->
				    [{SN, F, S + SellTotal}|Acc1];
			       ({SN, F, S}, Acc1) ->
				    [{SN, F, S}|Acc1]
			    end, [], Acc0)
		  end
	  end, [], Invs),

    %% ?DEBUG("===== sortamounts ~p",[SortAmounts]),
    
    Content =
    	%% title(PBrand, Model, 33, MerchantName)
	%% ++ address(PBrand, Model, 50, Address)
    	%% ++ head(PBrand,Model, 33, RSN, Retailer, Employee, Date) 
    	%% ++ ?f_print:left_pading(PBrand, Model)
    	%% ++ ?f_print:line(equal, 33) ++ ?f_print:br(PBrand)

    	body_head(Merchant, PBrand, Model, 33)
    	++ lists:foldr(
    	     fun({StyleNumber, F, S}, Acc0)->
		     [?to_s(StyleNumber)
		      ++ ?f_print:pading(14 - length(?to_s(StyleNumber))) 
		      ++ ?to_s(F)
		      ++ ?f_print:pading(6 - length(?to_s(F)))
		      ++ ?to_s(S)
		      ++ ?f_print:pading(6 - length(?to_s(S)))
		      ++ ?to_s(F * S) ++ ?f_print:br(PBrand)|Acc0] 
    	     end, [], SortAmounts),

    	%% ++ body_stastic(PBrand, Model, 33, Attrs) 
    	%% ++ body_foot(PBrand, Model, 33, Banks, Mobile, Setting),

    Content;
    
print_content(Shop, PBrand, Model, Column, Merchant, Setting, Invs, Total, ShouldPay) -> 
    Fields     = detail(print_format, Merchant, Shop), 
    PrintModel = ?to_i(?v(<<"pformat">>, Setting, ?COLUMN)),
    PrintTable = ?to_i(?v(<<"ptable">>, Setting, ?STRING)),
    ?DEBUG("PrintModel ~p, PrintTable ~p", [PrintModel, PrintTable]),

    Len2total = field_len(Fields, <<"count">>, PrintModel, 0),
    ?DEBUG("Len2total ~p", [Len2total]), 
    {IsHand, _}      = field(hand, Fields),
    {IsSizeName, _}  = field(size_name, Fields),
    
    {ok, SizeGroups} = 
	case IsHand orelse IsSizeName orelse PrintModel =:= ?ROW of
	    true  -> detail(size_group, Merchant);
	    false -> {ok, []}
	end, 

    {true, WidthTotal}  = field(<<"count">>, Fields),
    {true, WidthCalc}   = field(<<"calc">>, Fields),
    
    %% ColumnModeRowLen = field_len(Fields, <<"calc">>, PrintModel, 0) + WidthCalc,
    RowFun =
	fun(Inv, A) ->
		left_pading(PBrand, Model) ++ 
		    format_row_content(
		      PrintTable, PrintModel, IsHand, Fields, SizeGroups, Inv, A)
		    ++  br(PBrand)
		    ++ case PrintTable of
			   ?TABLE ->
			       %% line(minus, ColumnModeRowLen)
			       line(add_minus, ?TABLE, ?COLUMN, Fields)
				   ++ br(PBrand);
			   ?STRING -> []
		       end
	end,
    
    StasticFun =
	fun(?TABLE) ->
		
		{Mh, Ml} = middle(?TABLE, WidthTotal, Total),
		{Mh1, Ml1} = middle(?TABLE, WidthCalc, round(ShouldPay)),
		
		left_pading(PBrand, Model) ++ "|" ++ pading(Len2total -2)
		    ++ "|" ++ pading(Mh)
		    ++ ?to_s(Total) ++ pading(Ml)
		    
		    ++ "|" ++ pading(Mh1)
		    ++ ?to_s(round(ShouldPay)) ++ pading(Ml1)
		    
		    ++ "|" ++ br(PBrand)
		    
		    ++ line(add_minus, ?TABLE, ?COLUMN, Fields)
		%% ++ line(minus, Column)
		    ++ br(PBrand);
	   (?STRING) ->
		left_pading(PBrand, Model) ++ pading(Len2total) ++ ?to_s(Total)
		    ++ br(PBrand)
	end,
    
    Body =
	fun(hand, _) ->
		HandFun =
		    fun({struct, A}, {T, _Hand}) ->
			    T1 = 
				case ?w_sale:direct(?v(<<"direct">>, A)) of
				    wreject ->
					?v(<<"reject_count">>, A);
				    _       ->
					?v(<<"sell_count">>, A)
				end,
			    H1 = 
			    case ?v(<<"hand">>, A) of
				undefined -> 0;
				W ->  W
			    end,
			    {T1 + T, H1}
		    end,
		
		NewInvs = sort_inv(by_color, Invs, []),
		?DEBUG("NewInvs ~p", [NewInvs]),
		
		%% BodyHead = body_head(PBrand, Model, Fields, Column),
		BodyHead = body_head(PrintTable, PrintModel, PBrand, Model, Fields),
		?DEBUG("body head ~ts", [?to_b(BodyHead)]),
		
		BodyContent = 
		    lists:foldr(
		      fun({struct, Inv}, Acc0)->
			      Amounts = ?v(<<"amounts">>, Inv), 
			      {RT, RH} = lists:foldr(HandFun, {0, 0}, Amounts),
			      RowFun([{<<"total">>, RT},
				      {<<"hand">>, RH}|Inv], []) ++ Acc0 
		      end, "", NewInvs)
		    ++ left_pading(PBrand, Model) ++ pading(Len2total) ++ ?to_s(Total)
		    ++ br(PBrand),
		?DEBUG("body content ~ts", [?to_b(BodyContent)]),
		BodyHead ++ BodyContent;
	   (no_hand, ?COLUMN) ->

		BodyHead = body_head(PrintTable, ?COLUMN, PBrand, Model, Fields),
		
		?DEBUG("body head ~ts", [?to_b(BodyHead)]),
		BodyContent = 
		    lists:foldr(
		      fun({struct, Inv}, Acc0)->
			      Amounts = ?v(<<"amounts">>, Inv), 
			      lists:foldr(
				fun({struct, A}, Acc1) ->
					RowFun(Inv, A) ++ Acc1 
				end, [], Amounts) ++ Acc0
		      end, "", Invs)
		    %%++ left_pading(PBrand, Model) ++ pading(Len2total) ++ ?to_s(Total)
		    ++ StasticFun(PrintTable),
		?DEBUG("body content ~ts", [?to_b(BodyContent)]),
		line(add_minus, ?TABLE, ?COLUMN, Fields) ++ br(PBrand)
		    ++ BodyHead ++ BodyContent;
	   (no_hand, ?ROW) -> 
		CombinedInvs  = combine_with_size(Invs, []),
		?DEBUG("combinedInvs~n~p", [CombinedInvs]),
		lists:foldr(
		  fun({SizeGroup, {UsedSizes, Amounts}}, Acc0)->
			  ?DEBUG("SizeGroup ~p, used sizes ~p",
				 [SizeGroup, UsedSizes]),
			  GS = [?to_i(G) ||
				   G <- string:tokens(?to_s(SizeGroup), ",")],
			  
			  AllSize = lists:foldr(
				      fun(G, Acc) ->
					      find_size(G, SizeGroups) ++ Acc
				      end, [], lists:sort(GS)),

			  ?DEBUG("lenght gs ~p", [length(GS)]),
			  Sizes = 
			      case length(GS) =:= 2 of
			      	  true -> [Us || Us <- AllSize,
						 lists:member(Us, UsedSizes)];
			      	  false -> AllSize
			      end,
			  
			  AFun =
			      fun(Color, A) ->
				      CID = ?v(<<"cid">>, Color),
				      CName = color2name(CID, Color),
				      N = proplists:delete(
					    <<"amounts">>,
					    proplists:delete(
					      <<"cid">>,
					      proplists:delete(
						<<"colors">>, A))),
				      {[{<<"color">>, CName}|N],
				       sort_amount(
					 CID, Sizes, ?v(<<"amounts">>, A))}
			      end,
			  
			  SortAmounts = 
			      lists:foldr(
				fun({A}, Acc1) ->
					Colors = ?v(<<"colors">>, A),
					lists:foldl(
					  fun({struct, Color}, Acc2) -> 
						  [AFun(Color, A)|Acc2] 
					  end, [], Colors) ++ Acc1
				end, [], Amounts), 
			  ?DEBUG("SortAmounts ~p", [SortAmounts]),

			  FlatternAmounts =
			      flattern(amount,
				       {PrintTable, Column, length(Sizes),
					Fields}, SortAmounts),
			  ?DEBUG("flattern amounts ~ts",
				 [?to_b(FlatternAmounts)]),

			  {true, SizeWidth} = field(size, Fields), 
			  FlatternSizes =
			      flattern(size, {PrintTable, SizeWidth}, Sizes),
			  
			  ?DEBUG("flattern sizes ~p", [FlatternSizes]),
			  
			  Head = body_head(PrintTable, ?ROW, PBrand,
					   Model, Fields, FlatternSizes),
			  
			  %% ?DEBUG("Head ~ts", [?to_b(Head)]),
			  %% RealyColumn =
			  %% ?f_print:column(?TABLE, length(Sizes), Fields),

			  TableLine =
			      case PrintTable of
				  ?TABLE ->
				      line(add_minus, ?TABLE, ?ROW,
					   length(Sizes), Fields);
				  ?STRING -> [] 
			      end,
			  TableLine ++ br(PBrand)
			      ++ Head
			      ++ row({PrintTable, PBrand, Model, TableLine},
				     FlatternAmounts)
			      ++ Acc0 
		  end, "", CombinedInvs)
	end,
    case IsHand of
	true -> Body(hand, PrintModel) ;
	false -> Body(no_hand, PrintModel)
    end.

%% =============================================================================
%% internal function
%% =============================================================================
sort_inv(by_color, [], NewInvs) ->
    NewInvs;
sort_inv(by_color, [{struct, Inv}|T], NewInvs) ->
    Amounts = ?v(<<"amounts">>, Inv),
    ColorIds = lists:foldr(
	       fun({struct, A}, Acc) ->
		       case lists:member(?v(<<"cid">>, A), Acc) of
			   true -> Acc;
			   false -> [?v(<<"cid">>, A)|Acc]
		       end
	       end, [], Amounts),
    NewAmounts = classify(by_color, lists:reverse(ColorIds), ?v(<<"amounts">>, Inv), []),
    %% ShortInv = proplists:delete(<<"colors">>, proplists:delete(<<"amounts">>, Inv)),
    ShortInv = proplists:delete(<<"amounts">>, Inv),
    sort_inv(
      by_color, T,
      [{struct, [{<<"color_hand">>, CId}, {<<"amounts">>, A}|ShortInv]}
       || {CId, A} <- NewAmounts] ++ NewInvs).
   
	
classify(by_color, [], _Amounts, Classes) ->
    Classes;
classify(by_color, [CId|T], Amounts, Classes) ->
    C = 
	lists:filter(
	  fun({struct, A}) ->
		  CId =:= ?v(<<"cid">>, A)
	  end, Amounts),
    classify(by_color, T, Amounts, [{CId, C}|Classes]).
    
format_row_content(?STRING, PrintModel, IsHand, Fields, SizeGroups, Inv, Amount) ->
    Brand       = ?v(<<"brand_name">>, Inv),
    StyleNumber = ?v(<<"style_number">>, Inv),
    Type        = ?v(<<"type_name">>, Inv),
    Price       = ?v(<<"fprice">>, Inv),
    Discount    = ?v(<<"fdiscount">>, Inv, 100),
    Hand        = ?v(<<"hand">>, Inv), 
    FPrice      = Price * Discount / 100,

    Count = case IsHand of
		true -> ?v(<<"total">>, Inv);
		false ->
		    case ?w_sale:direct(?v(<<"direct">>, Amount)) of
			wreject -> ?v(<<"reject_count">>, Amount);
			_       -> ?v(<<"sell_count">>,   Amount)
		    end
	    end,
    
    lists:foldr(
      fun({F, _, Width}, Acc) ->
	      case F of
		  <<"brand">>        ->
		      ?to_s(Brand)
			  ++ pading(Width - width(chinese, Brand));
		  <<"style_number">> ->
		      ?to_s(StyleNumber)
			  ++ pading(Width - width(latin1, StyleNumber)); 
		  <<"type">>         ->
		      TypeLen = width(chinese, Type), 
		      ?to_s(Type) ++ pading(Width - TypeLen);
		  <<"color">>        ->
		      CId = 
			  case IsHand of
			      true ->
				  ?to_i(?v(<<"color_hand">>, Inv));
			      false ->
				  ?to_i(?v(<<"cid">>, Amount))
			  end,
		      Color = find_color(CId, ?v(<<"colors">>, Inv)),
		      ?to_s(Color) ++ pading(Width - width(chinese, Color)); 
		  <<"size_name">>    ->
		      [G1|GT] = string:tokens(?to_s(?v(<<"s_group">>, Inv)), ","),
		      N1 = ?to_s(find_size_name(?to_i(G1), SizeGroups)),
		      SizeName =
			  lists:foldl(
			    fun(G, Acc2) ->
				    Acc2 ++ "，" ++ ?to_s(find_size_name(G, SizeGroups))
			    end, N1, GT),
		      SizeName ++ pading(Width - width(chinese, SizeName)); 
		  <<"size">>         ->
		      case PrintModel of
			  ?ROW -> [];
			  ?COLUMN ->
			      Size = size2name((?v(<<"size">>, Amount))),
			      ?to_s(Size) ++ pading(Width - width(chinese, Size))
		      end;
		  <<"price">>        ->
		      CleanPrice = clean_zero(Price),
		      ?to_s(CleanPrice) ++ pading(Width - width(latin1, CleanPrice)); 
		  <<"discount">>     ->
		      ?to_s(Discount)
			  ++ pading(Width - width(latin1, Discount));
		  <<"dprice">>       ->
		      CleanFPrice = clean_zero(FPrice),
		      ?to_s(CleanFPrice)
			  ++ pading(Width - width(latin1, CleanFPrice));
		  <<"hand">>         ->
		      ?to_s(Hand) ++ pading(Width - width(latin1, Hand)); 
		  <<"count">>        -> 
		      ?to_s(Count) ++ pading(Width - width(latin1, Count)); 
		  <<"calc">>         ->
		      %% ?DEBUG("fprice ~p, count ~p", [FPrice, Count]),
		      ?to_s(clean_zero(FPrice * Count))
	      end ++ Acc 
      end, [], Fields);

format_row_content(?TABLE, PrintModel, IsHand, Fields, SizeGroups, Inv, Amount) ->
    Brand       = ?v(<<"brand_name">>, Inv),
    StyleNumber = ?v(<<"style_number">>, Inv),
    Type        = ?v(<<"type_name">>, Inv),
    Price       = ?v(<<"fprice">>, Inv),
    Discount    = ?v(<<"fdiscount">>, Inv, 100),
    Hand        = ?v(<<"hand">>, Inv), 
    FPrice      = Price * Discount / 100,

    ?DEBUG("amount ~p", [Amount]),
    Count = case IsHand of
		true -> ?v(<<"total">>, Inv);
		false ->
		    case ?w_sale:direct(?v(<<"direct">>, Amount)) of
			wreject -> ?v(<<"reject_count">>, Amount);
			_       -> ?v(<<"sell_count">>,   Amount)
		    end
	    end,

    [{FirstName, _, _}|_] = Fields, 
    
    lists:foldr(
      fun({F, _, Width}, Acc) ->
	      case F of
		  <<"brand">> = Name when Name =:= FirstName ->
		      phd("|") ++ ?to_s(Brand)
			  ++ pading(Width - width(chinese, Brand) -2 ) ++ phd("|");
		  <<"style_number">> = Name when Name =:= FirstName ->
		      phd("|") ++ ?to_s(StyleNumber)
			  ++ pading(Width - width(latin1, StyleNumber) -2) ++ phd("|");
		  <<"style_number">> ->
		      ?to_s(StyleNumber)
			  ++ pading(Width - width(latin1, StyleNumber) -1) ++ phd("|"); 
		  <<"type">>         ->
		      TypeLen = width(chinese, Type),
		      ?DEBUG("StyleNumber ~p, TypeLen ~p", [StyleNumber, TypeLen]),
		      ?to_s(Type)
			  ++ pading(Width - TypeLen -1) ++ phd("|");
		  <<"color">>        ->
		      CId = 
			  case IsHand of
			      true ->
				  ?to_i(?v(<<"color_hand">>, Inv));
			      false ->
				  ?to_i(?v(<<"cid">>, Amount))
			  end,
		      Color = find_color(CId, ?v(<<"colors">>, Inv)),
		      %% ?DEBUG("CID ~p, Color ~p", [CId, Color]),
		      ?to_s(Color) ++ pading(Width - width(chinese, Color) -1) ++ phd("|"); 
		  <<"size_name">>    ->
		      [G1|GT] = string:tokens(?to_s(?v(<<"s_group">>, Inv)), ","),
		      N1 = ?to_s(find_size_name(?to_i(G1), SizeGroups)),
		      SizeName =
			  lists:foldl(
			    fun(G, Acc2) ->
				    Acc2 ++ "，" ++ ?to_s(find_size_name(G, SizeGroups))
			    end, N1, GT),
		      SizeName ++ pading(Width - width(chinese, SizeName) -1) ++ phd("|"); 
		  <<"size">>         ->
		      case PrintModel of
			  ?ROW -> [];
			  ?COLUMN ->
			      Size = size2name((?v(<<"size">>, Amount))),
			      ?to_s(Size) ++ pading(Width - width(chinese, Size) -1) ++ phd("|")
		      end;
		  <<"price">>        ->
		      CleanPrice = clean_zero(Price),
		      {Mh, Ml} = middle(?TABLE, Width, CleanPrice),
		      pading(Mh) ++ ?to_s(CleanPrice) ++ pading(Ml) ++ phd("|");
		  <<"discount">>     ->
		      {Mh, Ml} = middle(?TABLE, Width, Discount),
		      pading(Mh) ++ ?to_s(Discount) ++ pading(Ml) ++ phd("|"); 
		  <<"dprice">>       ->
		      CleanFPrice = clean_zero(FPrice),
		      {Mh, Ml} = middle(?TABLE, Width, CleanFPrice),
		      pading(Mh) ++ ?to_s(CleanFPrice) ++ pading(Ml) ++ phd("|"); 
		  <<"hand">>         ->
		      ?to_s(Hand) ++ pading(Width - width(latin1, Hand) -1) ++ phd("|"); 
		  <<"count">>        ->
		      {Mh, Ml} = middle(?TABLE, Width, Count),
		      pading(Mh) ++ ?to_s(Count) ++ pading(Ml) ++ phd("|");
		  <<"calc">>         ->
		      %% ?DEBUG("fprice ~p, count ~p", [FPrice, Count]),
		      CleanCalc = round(FPrice * Count),
		      {Mh, Ml} = middle(?TABLE, Width, CleanCalc),
		      pading(Mh) ++ ?to_s(CleanCalc) ++ pading(Ml) ++ phd("|")
	      end ++ Acc 
      end, [], Fields).


title(_Brand, _Model, 33, Title) ->
    T = "<CB>" ++ ?to_s(Title) ++ "</CB><BR>", 
    ?DEBUG("title ~ts", [?to_b(T)]),
    T;

title(Brand, Model, Column, Title) ->
    Start = (Column - ?f_print:width(chinese, Title) * 2) div 2, 
    T = 
	?f_print:left_pading(Brand, Model)
	++ ?f_print:pading(Start)
	++ decorate_data(bwh)
	++ ?to_s(Title)
	++ decorate_data(cancel_bwh) 
	++ ?f_print:br(Brand),
    ?DEBUG("title ~ts", [?to_b(T)]),
    T.

%% address

address(_Brand, _Model, 33, Address) ->
    "<CB>" ++ ?to_s(Address) ++ "</CB><BR>";

address(Brand, Model, Column, Address) ->
    Start = (Column - ?f_print:width(chinese, Address)) div 2,
    ?f_print:left_pading(Brand, Model)
	++ ?f_print:pading(Start)
	++ decorate_data(block)
	++ ?to_s(Address)
	++ decorate_data(cancel_block) 
	++ ?f_print:br(Brand).


head(<<"feie">> = Brand, <<"PIN76">> = Model, 33, RSN, Retailer, Employee, Date) ->
    ?DEBUG("feie head brand ~p", [Brand]),
    "单号：" ++ ?to_s(RSN)
	++ case 5 + length(?to_s(RSN)) + 17 =< 33 of
	       true -> ?f_print:pading(2);
	       false -> ?f_print:br(Brand)
	   end
	++ "日期：" ++ ?to_s(Date) ++ ?f_print:br(Brand)
	
	++ ?f_print:left_pading(Brand, Model) 
	++ "客户：" ++ ?to_s(Retailer)
	++ case 5 + ?f_print:width(chinese, Retailer)
	       + 2 + 5 + ?f_print:width(chinese, Employee) =< 33 of
	       true -> ?f_print:pading(2);
	       false -> ?f_print:br(Brand)
	   end 
	++ "店员：" ++ ?to_s(Employee) ++ ?f_print:br(Brand).
    
head(Brand, Model, 106, RSN, PRetailer, Retailer, Employee, Date) -> 
    RetailerName = ?v(<<"name">>, Retailer, []),
    ?f_print:left_pading(Brand, Model)
	++ "单号：" ++ ?to_s(RSN) ++ ?f_print:pading(4)
	++ "客户：" ++ ?to_s(RetailerName) ++ ?f_print:pading(20)
	++ "店员：" ++ ?to_s(Employee) ++ ?f_print:pading(10)
	++ ?f_print:pading(106
			   - (6 + length(?to_s(RSN)) + 4)
			   - (6 + ?f_print:width(chinese, RetailerName) + 20)
			   - (6 + ?f_print:width(chinese, Employee) + 10)
			   - 20 %% length of date
			  )
	++ "日期：" ++ ?to_s(Date) ++ ?f_print:br(Brand)
	++ case PRetailer of
	       ?YES ->
		   pading(6 + length(?to_s(RSN)) + 4 + 6)
		       ++ ?to_s(?v(<<"mobile">>, Retailer)) ++ br(Brand)
		       ++ pading(6 + length(?to_s(RSN)) + 4 + 6)
		       ++ ?to_s(?v(<<"address">>, Retailer)) ++ br(Brand);
	       ?NO ->
		   []
	   end;



head(Brand, Model, Column, RSN, PRetailer, Retailer, Employee, Date) ->
    RetailerName = ?v(<<"name">>, Retailer, []),
    ?f_print:left_pading(Brand, Model)
	++ "单号：" ++ ?to_s(RSN)
	++ ?f_print:pading(Column - 6 - length(?to_s(RSN)) - 16)
	++ "日期：" ++ ?to_s(Date) ++ ?f_print:br(Brand) %% length is 16
	++ ?f_print:left_pading(Brand, Model)

	++ "客户：" ++ ?to_s(RetailerName)
	++ ?f_print:pading(Column - 16 - 6 - ?f_print:width(chinese, RetailerName))
	++ "店员：" ++ ?to_s(Employee) ++ ?f_print:br(Brand)
	++ case PRetailer of
	       ?YES ->
		   pading(6)
		       ++ ?to_s(?v(<<"mobile">>, Retailer)) ++ br(Brand)
		       ++ pading(6)
		       ++ ?to_s(?v(<<"address">>, Retailer)) ++ br(Brand);
	       ?NO ->
		   []
	   end.

body_head(_Merchant, Brand, Model, 33) -> 
    ?f_print:left_pading(Brand, Model)
	++ "款号" ++ ?f_print:pading(14 - 4)
	++ "单价" ++ ?f_print:pading(6 - 4)
	++ "数量" ++ ?f_print:pading(6 - 4)
	++ "小计" ++ ?f_print:br(Brand).


body_head(?TABLE, ?COLUMN, Brand, Model, Fields) ->
    [{FName, _, _}|_T] = Fields,
    ?f_print:left_pading(Brand, Model)
	++ lists:foldr(
	     fun({Name, CName, Width}, Acc) when Name =:= FName ->
		     phd("|") ++ CName ++ pading(Width - width(chinese, CName) - 2)
			 ++ phd("|") ++ Acc;
		({_Name, CName, Width}, Acc) ->
		     CName ++ pading(Width - width(chinese, CName) - 1)
			 ++ phd("|") ++ Acc 
	     end, [], Fields)
	++ br(Brand) ++
	%% ?to_s(<<27, 51, 16>>) ++ 
	line(add_minus, ?TABLE, ?COLUMN, Fields) ++ br(Brand); 

body_head(?STRING, ?COLUMN, Brand, Model, Fields) ->
    ?f_print:left_pading(Brand, Model)
	++ lists:foldr(
	     fun({_Name, CName, Width}, Acc) ->
		     Len = width(chinese, CName), 
		     CName ++ pading(Width - Len) ++ Acc
	     end, [], Fields)
	++ ?f_print:br(Brand).

body_head(?TABLE, ?ROW, Brand, Model, Fields, SizeString) ->
    %% {LName, _, _} = lists:last(Fields),
    [{FName, _, _}|_T] = Fields,
    ?f_print:left_pading(Brand, Model)
	++ lists:foldr(
	     fun({<<"size">>, _, _}, Acc) -> 
		     SizeString ++ Acc;
		({Name, CName, Width}, Acc) when Name =:= FName ->
		     phd("|") ++ CName ++ pading(Width - width(chinese, CName) - 2)
			 ++ phd("|") ++ Acc;
		({_Name, CName, Width}, Acc) ->
		     CName ++ pading(Width - width(chinese, CName) - 1)
			 ++ phd("|") ++ Acc 
	     end, [], Fields)
	++ ?f_print:br(Brand);

body_head(?STRING, ?ROW, Brand, Model, Fields, SizeString) ->
    ?f_print:left_pading(Brand, Model)
	++ lists:foldr(
	     fun({<<"size">>, _, _}, Acc) -> 
		     SizeString ++ Acc;
		({_Name, CName, Width}, Acc) -> 
		     CName ++ pading(Width - width(chinese, CName)) ++ Acc
	     end, [], Fields)
	++ ?f_print:br(Brand).
    

body_stastic(_IsRound, Brand, Model, 33, Attrs) ->
    ?DEBUG("Brand ~p", [Brand]),
    LastBalance  = ?v(<<"balance">>, Attrs), 
    Cash         = ?v(<<"cash">>, Attrs, 0),
    Card         = ?v(<<"card">>, Attrs, 0),
    Wire         = ?v(<<"wire">>, Attrs, 0),
    VerifyPay    = ?v(<<"verificate">>, Attrs, 0),
    ShouldPay    = ?v(<<"should_pay">>, Attrs, 0),
    Total        = ?v(<<"total">>, Attrs, 0),
    Comment      = ?v(<<"comment">>, Attrs, []),
    Direct       = ?v(<<"direct">>, Attrs), 
    Debt         = ShouldPay - Cash - Card - Wire - VerifyPay,
    
    {DebtName, AccDet} = debt(Direct, LastBalance, Debt),

    ?f_print:left_pading(Brand, Model)
	++ ?f_print:pading(20) ++ ?to_s(Total)
	++ ?f_print:br(Brand)

	++ ?f_print:left_pading(Brand, Model) ++ ?f_print:line(minus, 33)
	++ ?f_print:br(Brand)

	++ ?f_print:left_pading(Brand, Model) ++ "总计：" ++ ?to_s(Total)
	++ ?f_print:pading(1) ++ "总金额：" ++ ?to_s(ShouldPay)
	++ ?f_print:pading(1) ++ "备注：" ++ ?to_s(Comment)
	++ ?f_print:br(Brand)

	++ ?f_print:left_pading(Brand, Model) ++ ?f_print:line(minus, 33)
	++ ?f_print:br(Brand)
	
	++ ?f_print:left_pading(Brand, Model) ++ "上次欠款："
	++ ?to_s(LastBalance) 
	++ ?f_print:br(Brand)
	
	++ ?f_print:left_pading(Brand, Model) ++ DebtName ++ ?to_s(Debt)
	++ ?f_print:br(Brand) 
	
	++ ?f_print:left_pading(Brand, Model) ++ "累计欠款：" ++ ?to_s(AccDet) 
	++ ?f_print:br(Brand);

body_stastic(IsRound, Brand, Model, 50, Attrs) ->
    LastBalance  = ?v(<<"balance">>, Attrs, 0), 
    Cash         = ?v(<<"cash">>, Attrs, 0),
    Card         = ?v(<<"card">>, Attrs, 0),
    Wire         = ?v(<<"wire">>, Attrs, 0),
    VerifyPay    = ?v(<<"verificate">>, Attrs, 0),
    ShouldPay    = ?v(<<"should_pay">>, Attrs, 0),
    Total        = ?v(<<"total">>, Attrs, 0),
    Comment      = ?v(<<"comment">>, Attrs, []),
    EPayType     = ?v(<<"e_pay_type">>, Attrs, -1),
    EPay         = ?v(<<"e_pay">>, Attrs, 0),
    Direct       = ?v(<<"direct">>, Attrs),
    %% EPayType     = ?v(<<"e_pay_type">>, Attrs, -1),
    %% EPay         = ?v(<<"e_pay">>, Attrs),

    %% HasPay    = Cash + Card + Wire + VerifyPay,
    HasPay    = Cash + Card + Wire,
    Debt      = ShouldPay + EPay - HasPay - VerifyPay,
    %% Debt         = ShouldPay - Cash - Card - Wire - VerifyPay,
    {DebtName, AccDet} = debt(Direct, LastBalance, Debt),

    %% ?DEBUG("Comment ~p", [Comment]),

    TotalSPay = ShouldPay + EPay,
    
    left_pading(Brand, Model) ++ "总计：" ++ ?to_s(Total)
	++ pading(2) ++ "总金额：" ++ round(IsRound, TotalSPay)
	++ pading(2) ++ "备注：" ++ ?to_s(Comment) 
	++ br(Brand)

	++ left_pading(Brand, Model) 
	++ "本次应付：" ++ round(IsRound, ShouldPay)
	++ extra_pay(EPayType, EPay) 
	++ br(Brand)
	
	++ left_pading(Brand, Model)
	++ "本次实付：" ++ decorate_data(block)
	++ round(IsRound, HasPay) ++ decorate_data(cancel_block)
	++ pay(Cash, Card, Wire, VerifyPay)
	++ br(Brand)
	
    %% ++ left_pading(Brand, Model)
    %% ++ line(minus, 50) ++ br(Brand)
	
	++ ?f_print:left_pading(Brand, Model)
	++ "上次欠款：" ++ decorate_data(block)
	++ round(IsRound, LastBalance) ++ decorate_data(cancel_block)
	
	++ pading(2) ++ DebtName ++ decorate_data(block) 
	++ round(IsRound, Debt) ++ decorate_data(cancel_block)
	
	++ pading(2) ++ "累计欠款：" ++ decorate_data(block) 
	++ round(IsRound, AccDet)  ++ decorate_data(cancel_block)
	++ br(Brand);

body_stastic(IsRound, Brand, Model, Column, Attrs) ->
    LastBalance  = ?v(<<"balance">>, Attrs, 0), 
    Cash         = ?v(<<"cash">>, Attrs, 0),
    Card         = ?v(<<"card">>, Attrs, 0),
    Wire         = ?v(<<"wire">>, Attrs, 0),
    VerifyPay    = ?v(<<"verificate">>, Attrs, 0),
    ShouldPay    = round(?v(<<"should_pay">>, Attrs, 0)),
    Total        = ?v(<<"total">>, Attrs, 0),
    Comment      = ?v(<<"comment">>, Attrs, []),
    EPayType     = ?v(<<"e_pay_type">>, Attrs, -1),
    EPay         = ?v(<<"e_pay">>, Attrs, 0),
    
    Direct       = ?v(<<"direct">>, Attrs), 

    %% HasPay    = Cash + Card + Wire + VerifyPay,
    HasPay    = Cash + Card + Wire, 
    Debt      = ShouldPay + EPay - HasPay - VerifyPay,
    {DebtName, AccDet} = debt(Direct, LastBalance, Debt),


    TotalSPay = ShouldPay + EPay, 
    
    left_pading(Brand, Model)
	++ "总计：" ++ ?to_s(Total)
	++ pading(2) ++ "总金额：" ++ round(IsRound, TotalSPay)
	++ pading(2) ++ "备注：" ++ ?to_s(Comment)
	++ br(Brand)

	
	++ left_pading(Brand, Model)
	++ "本次应付："
	++ round(IsRound, ShouldPay) 
	%% ++ ?f_print:pading(2) ++ "本次实付："
	%% ++ round(IsRound, HasPay)
	
	%% ++ pay(Cash, Card, Wire)
	++ extra_pay(EPayType, EPay)
	++ br(Brand)

	%% pay type
	++ left_pading(Brand, Model)
	++ "本次实付：" ++ decorate_data(block)
	++ round(IsRound, HasPay) ++ decorate_data(cancel_block)
	++ pay(Cash, Card, Wire, VerifyPay)
	++ br(Brand)
	
	
	%% ++ case Column -
	%%        (6 + length(?to_s(Total))
	%% 	+ 12 + length(?to_s(ShouldPay))
	%% 	+ 12 + length(?to_s(HasPay)) + 16
	%% 	+ 8 + ?f_print:width(chinese, Comment))
	%%        >= 14 + length(?to_s(LastBalance))
	%%        + 12 + length(?to_s(Debt))
	%%        + 12 + length(?to_s(LastBalance + Debt))
	%%    of
	%%        true -> ?f_print:pading(4);
	%%        false -> ?f_print:br(Model) ++ ?f_print:left_pading(Brand, Model)
	%%    end

	++ "上次欠款：" ++ decorate_data(block)
	++ round(IsRound, LastBalance) ++ decorate_data(cancel_block)
	
	++ ?f_print:pading(2) ++ DebtName ++ decorate_data(block)
	%% ++ ?to_s(?f_print:clean_zero(Debt)) ++ decorate_data(cancel_block)
	++ round(IsRound, Debt) ++ decorate_data(cancel_block)
	
	++ ?f_print:pading(2) ++ "累计欠款：" ++ decorate_data(block)
	++ round(IsRound, AccDet) ++ decorate_data(cancel_block)
	
	++ ?f_print:br(Brand) ++ ?f_print:line(minus, Column)
	++ ?f_print:br(Brand).

body_foot(Brand, Model, Column, Banks, Mobile, Setting) ->
    ?DEBUG("start to build body_foot", []), 
    Phone1 = ?v(<<"phone1">>, Setting, []),
    Phone2 = ?v(<<"phone2">>, Setting, []), 
    [CH|CT] = [?v(<<"comment1">>, Setting, []),
	       ?v(<<"comment2">>, Setting, []),
	       ?v(<<"comment3">>, Setting, [])],

    %% ?DEBUG("commetns ~p", [Comments]),
    {SBank, _} = 
	lists:foldr(
	  fun({Bank}, {S, L}) ->
		  N  = ?v(<<"name">>, Bank),
		  B  = ?v(<<"bank">>, Bank),
		  No = ?v(<<"no">>, Bank),

		  %% PL =  length(left_pading(Brand, Model)),
		  NL  =  width(chinese, N) + 4,
		  BL  =  width(chinese, B),
		  NoL =  width(chinese, No) + 2,

		  ?DEBUG("NL + BL + NoL ~p, L ~p", [NL + BL + NoL, L]),
		  case NL + BL + NoL =< L of 
		      true -> {S
			       ++ ?to_s(N) ++ pading(4) ++ ?to_s(B) 
			       ++ pading(2) ++ ?to_s(No), L - NL - BL - NoL};
		      false ->
			  {S ++ br(Brand)
			   ++ ?to_s(N) ++ pading(4) ++ ?to_s(B) 
			   ++ case NoL < Column - NL - BL of
			   	  true  -> pading(2);
			   	  false -> br(Brand)
			      end
			   ++ ?to_s(No), Column - NL - BL - NoL}
		  end

	  end, {[], Column}, Banks),
	
    %mobile
    SBank ++ br(Brand)
	++ left_pading(Brand, Model)
	++ "电话：" ++ ?to_s(Mobile)
	++ pading(2) ++ ?to_s(Phone1)
	
	++ case 6 + length(?to_s(Mobile))
	       + 2 + length(?to_s(Phone1))
	       + 2 + length(?to_s(Phone2)) - Column =< 0 of
	       true  -> pading(2);
	       false -> br(Brand) ++ left_pading(Brand, Model) ++ pading(6)
	   end
	++ ?to_s(Phone2) ++ br(Brand)
	
    %% comment
	++ left_pading(Brand, Model)
	++ "说明：" ++ ?to_s(CH) ++ br(Brand) 
	++ lists:foldr(
	     fun([], Acc) ->
		     Acc;
	     (M, Acc) ->
		     left_pading(Brand, Model)
			 ++ pading(6) ++ ?to_s(M) ++ br(Brand) ++ Acc
	     end, [], CT)
	++ left_pading(Brand, Model)
	++ pading(Column - 26)
	++ "打印日期：" ++ ?utils:current_time(format_localtime) 
	%% ++ br(Brand)
	%% ++ [27, 74, 144] ++ [27, 74, 144].
	++ ?f_print:br(forward, Brand, Model).

	


row({?TABLE, Brand, Model, TableLine}, FlatternAmounts) ->
    [H|T] = FlatternAmounts,
    left_pading(Brand, Model)
	++ TableLine ++ br(Brand) ++ H ++ br(Brand)
	++ lists:foldr(
	     fun(CInfo, Acc) ->
		     left_pading(Brand, Model)
			 ++ TableLine ++ br(Brand)
			 ++ CInfo ++ br(Brand) ++ Acc
	     end, "", T)
	%% ++ TableLine ++ br(Brand)
	++ TableLine ++ br(Brand); 

row({?STRING, Brand, Model, _Column}, FlatternAmounts) ->
    lists:foldr(
      fun(CInfo, Acc) ->
	      left_pading(Brand, Model)
		  %% ++ line(minus, Column) ++ br(Brand)
		  ++ CInfo ++ br(Brand) ++ Acc
      end, "", FlatternAmounts).

combine_with_size([], Combined) ->
    Combined;
combine_with_size([{struct, Inv}|T], Combined) ->

    StyleNumber = ?v(<<"style_number">>, Inv),
    Brand       = ?v(<<"brand_name">>, Inv),
    Type        = ?v(<<"type_name">>, Inv),
    SizeGroup   = ?v(<<"s_group">>, Inv),
    Colors      = ?v(<<"colors">>, Inv),
    FDiscount   = ?v(<<"fdiscount">>, Inv),
    FPrice      = ?v(<<"fprice">>, Inv),
    Amounts     = ?v(<<"amounts">>, Inv), 
    
    
    A1 = {[{<<"style_number">>, StyleNumber},
	   {<<"brand">>, Brand},
	   {<<"type">>, Type},
	   {<<"s_group">>, SizeGroup},
	   {<<"colors">>, Colors},
	   {<<"fdiscount">>, FDiscount},
	   {<<"fprice">>, FPrice},
	   {<<"amounts">>, Amounts}]},

    UsedSize = lists:foldr(fun({struct, M}, Acc)
			      -> [?v(<<"size">>, M)|Acc]
			   end, [], Amounts),
	
    %% SellTotal   = ?v(<<"sell_total">>, Inv),
    
    case [ A || {S, {_, A}} <- Combined, S =:= SizeGroup ] of
	[] ->
	    NewAmount = {SizeGroup, {UsedSize, [A1]}},
	    combine_with_size(T, [NewAmount|Combined]);
	[A] ->
	    {Sizes, _} = ?v(SizeGroup, Combined),
	    
	    NewAmount  = {SizeGroup, {lists:usort(Sizes ++ UsedSize), [A1|A]}},
	    NewCombined = proplists:delete(SizeGroup, Combined),
	    combine_with_size(T, [NewAmount|NewCombined])
    end.
	    

start_print(fcloud, SN, Key, Path, Body) ->
    ?DEBUG("fcloud with sn ~p, key ~p, path ~p, body~n~ts",
	   [SN, Key, Path, ?to_b(Body)]),
    
    UTF8Body = unicode:characters_to_list(?to_s(Body), utf8),
    
    FormatBody = lists:concat(["sn=", ?to_s(SN),
			       "&key=", ?to_s(Key),
			       "&printContent=", ?to_s(UTF8Body)]),

    %% ?DEBUG("format body ~ts", [?to_b(FormatBody)]),

    Response = httpc:request(
		 post,
		 {?to_s(Path), [], "application/x-www-form-urlencoded", FormatBody},
		 [], []),

    case Response of
	{ok, {{"HTTP/1.1", ReturnCode, ReturnState}, _Head, Result}} -> 
	    ?DEBUG("print http request return code ~p, state ~p~n"
		   "result ~ts", [ReturnCode, ReturnState, ?to_b(Result)]),
	    case mochijson2:decode(Result) of
		{struct, [{<<"responseCode">>, 0},
			  {<<"msg">>, _PMsg},
			  {<<"orderindex">>, OrderIndex}]} ->
		    {ok, {0, OrderIndex}};
		%% error
		{struct, [{<<"responseCode">>, PCode},
			  {<<"msg">>, _PMsg}]} ->
		    case PCode of
			1 -> {error, ?err(invalid_sn, SN)};
			2 -> {error, ?err(fail_to_process, SN)};
			3 -> {error, ?err(long_content, SN)};
			4 -> {error, ?err(invalid_params, SN)}

		    end
	    end;
	{error, Reason} ->
	    ?INFO("print http request failed: ~p", [Reason]),
	    {error, ?err(print_http_failed, Reason)}
    end.

start_print(rcloud, Brand, Model, Height, SN, Key, Path, {IsPage, Body})  ->
    ?DEBUG("print with brand ~p, Model ~p, Height ~p, sn ~p, key ~p, path ~p"
	   "IsPage ~p", [Brand, Model, Height, SN, Key, Path, IsPage]),
    lists:foreach(
      fun(B) ->
	      ?DEBUG("====== page content ====== ~n~ts", [?to_b(B)])
      end, Body),
    
    CureentTimeTicks = (?SECONDS_BEFOR_1970 + ?utils:current_time(timestamp)) * 10000,

    
    Head = ?f_print:decorate_data(head, ?to_a(Brand), ?to_a(Model), Height * 10), 
    Tail = ?f_print:decorate_data(tail, ?to_a(Brand), ?to_a(Model)),
    Len  = erlang:length(Body),
    
    try 
	%% query state 
	{ok, SN} = get_printer_state(Path, SN, Key, CureentTimeTicks), 
	
	%% ok, print
	{GBKBodys, _} = 
	    lists:foldr(
	      fun(B, {Acc, Lens}) ->
		      Utf8Data = unicode:characters_to_list(?to_s(B), utf8),
		      GBKData  = diablo_iconv:convert("utf-8", "gbk", Utf8Data),
		      Base64 =
			  case Lens + 1 =:= Len of
			      true -> 
				  case IsPage of
				      true ->
					  base64:encode_to_string(Head ++ GBKData ++ Tail);
				      false -> 
					  base64:encode_to_string(GBKData)
				  end;
			      false ->
				  base64:encode_to_string(GBKData)
			  end,
		      {[Base64|Acc], Lens + 1}
	      end,  {[], 0}, Body),

	%% ?DEBUG("gbk body ~p", [GBKBodys]),
	
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


multi_send(_SignHead, _Path, Device, [], {}) ->
    {ok, {0, Device}};
multi_send(_SignHead, _Path, _Device, [], Error) ->
    Error;
multi_send(SignHead, Path, Device, [H|T], _Result) ->
    ?DEBUG("start to print ..."),
    %% multi_send(SignHead, Path, Device, T, {}).
    Sign = bin2hex(sha1, crypto:hash(sha, SignHead ++ H)),
    case httpc:request(
    	   post, {?to_s(Path) ++ "?" ++ SignHead ++ "sign=" ++ ?to_s(Sign),
    		  [], "application/x-www-form-urlencoded", H}, [], []) of 
    	{ok, {{"HTTP/1.1", 200, "OK"}, _Head, Reply}} ->
    	    ?DEBUG("Reply ~ts", [Reply]),
	    case Reply of
		"!device not found." ->
		    Error = {error, ?err(printer_conn_not_found, Device)},
		    multi_send(SignHead, Path, Device, [], Error);
		_ ->
		    {struct, Status} = mochijson2:decode(Reply), 
		    case ?v(<<"state">>, Status) of
			<<"ok">> ->
			    multi_send(SignHead, Path, Device, T, {});
			<<"100">> ->
			    Error = {error, ?err(print_content_error, Device)}, 
			    multi_send(SignHead, Path, Device, [], Error)
		    end
    	    end;
    	{error, Reason} ->
    	    ?INFO("print http request failed: ~p", [Reason]),
    	    Error = {error, ?err(print_http_failed, Reason)},
    	    multi_send(SignHead, Path, Device, [], Error)
    end.

get_printer_state(Path, DeviceId, Key, TimeTicks) -> 
    State = lists:concat(
	      ["action=state&device_id=", ?to_s(DeviceId),
	       "&secretkey=", ?to_s(Key), "&timestamp=" ++ ?to_s(TimeTicks)]),
    Sign = bin2hex(sha1, crypto:hash(sha, State)),

    case httpc:request(
	   post, {?to_s(Path), [], "application/x-www-form-urlencoded",
		  State ++ "&sign=" ++ Sign}, [], []) of
	{ok, {{"HTTP/1.1", 200, "OK"}, _Head, Reply}} ->
	    ?DEBUG("reply ~p", [Reply]),
	    try 
		case mochijson2:decode(Reply) of
		    1 -> {ok, DeviceId};
		    %% 1 -> throw({printer_unconnect, DeviceId});
		    2 -> throw({printer_unconnect, DeviceId});
		    3 -> throw({printer_no_paper, DeviceId});
		    4 -> throw({printer_unkown_state, DeviceId})
		end
	    catch
		_:{case_clause, <<"!device not found.">>} ->
		    throw({printer_conn_not_found, DeviceId});
		<<"!", _/binary>> ->
		    throw({printer_unkown_state, DeviceId})
	    end;
	{error, Error} ->
	    ?INFO("print http request failed: ~p", [Error]),
	    throw({print_http_failed, Error})
    end.


multi_print(PrintInfo) ->
    multi_print(PrintInfo, [], []).

multi_print([], Succes, Failed) ->
    %% ?DEBUG("Succes ~p, Failed ~p", [Succes, Failed]),
    {Succes, Failed};
multi_print([{DeviceId, PrintFun}|T], Succes, Failed) ->
    case PrintFun() of
	{ok, _} ->
	    multi_print(T, [DeviceId|Succes], Failed);
	{error, {ECode, _}} ->
	    multi_print(T, Succes, [{DeviceId, ECode}|Failed])
    end. 
    
bin2hex(sha1, B) ->
    L = binary_to_list(B),
    LH0 = lists:map(fun(X)->integer_to_list(X,16) end, L),
    LH = lists:map(fun([X,Y])-> [X,Y];
		      %% add zero
		      ([X])   ->[$0,X]
		   end, LH0),
    lists:flatten(LH).

find_color(0, _) ->
    color2name(0);
find_color(_, []) ->
    color2name(0);
find_color(CId, [{struct, Color}|T]) ->
    case CId =:= ?v(<<"cid">>, Color) of
	true -> color2name(CId, Color);
	false -> find_color(CId, T)
    end.

color2name(0) ->
    <<"均色">>;
color2name(Color) ->
    Color.

color2name(0, _) ->
    <<"均色">>;
color2name(_, Color) ->
    ?v(<<"cname">>, Color).


size2name(<<"0">>) ->
    <<"均码">>;
size2name(S) ->
    S.

find_size_name(0, _) ->
    <<"均码">>;
find_size_name(_, []) ->
    <<"均码">>;
find_size_name(GID, [{Group}|T]) ->
    case ?to_i(GID) =:= ?v(<<"id">>, Group) of
	true  -> ?v(<<"name">>, Group) ;
	false -> find_size_name(GID, T)
    end.

%% sort_size_group([], Acc) ->
%%     Acc;
%% sort_size_group([G|T], Acc) ->
%%     sort_size_group(T, flattern_size(G) ++ Acc).

find_size(<<"0">>, _) ->
    [<<"0">>];
find_size(_, []) ->
    [<<"0">>];
find_size(SizeGroup, [{Group}|T]) ->
    case ?v(<<"id">>, Group) =:= ?to_i(SizeGroup) of
	true ->
	    flattern_size(Group); 
	false ->
	    find_size(SizeGroup, T)
    end.

flattern_size(G) ->
    F = fun(S) when S =:= <<>> -> [];
	   (S) when S =:= [] -> [];
	   (S) -> [S]
	end,
    SI   = ?v(<<"si">>, G),
    SII  = ?v(<<"sii">>, G),
    SIII = ?v(<<"siii">>, G),
    SIV  = ?v(<<"siv">>, G),
    SV   = ?v(<<"sv">>, G),
    SVI  = ?v(<<"svi">>, G),
    F(SI) ++ F(SII) ++ F(SIII) ++ F(SIV) ++ F(SV) ++ F(SVI).

server(1) ->
    rcloud;
server(2) ->
    fcloud.

detail(merchant, Merchant) ->
    case ?w_user_profile:get(merchant, Merchant) of
	{ok, []} ->
	    ?merchant:merchant(get, Merchant);
	{ok, Info} ->
	    {ok, Info}
    end;
detail(bank, Merchant) -> 
    case ?w_user_profile:get(bank, Merchant) of
	{ok, []} ->
	    ?w_base:bank_card(list, Merchant);
	{ok, Cards} ->
	    {ok, Cards}
    end;
detail(size_group, Merchant) ->
    case ?w_user_profile:get(size_group, Merchant) of
	{ok, []} ->
	    ?attr:size_group(list, Merchant);
	{ok, Groups} ->
	    {ok, Groups}
    end.

detail(print_format, Merchant, Shop) ->
    {ok, Formats} = ?w_user_profile:get(print_format, Merchant, Shop), 
    lists:foldr(
      fun(F, Acc) ->
	      case
		  lists:filter(
		    fun({Format}) -> 
			    ?v(<<"name">>, Format) =:= ?to_b(F)
				andalso ?v(<<"print">>, Format) =:= 1
				andalso ?v(<<"width">>, Format) =/= 0
		    end, Formats) of
		  [] -> Acc;
		  [{S}] ->
		      [{?v(<<"name">>, S),
			field_name(?v(<<"name">>, S)), ?v(<<"width">>, S)}|Acc]
	      end
      end, [], ?PRINT_FIELDS);

detail(base_setting, Merchant, Shop) ->
    ?DEBUG("base_setting with merhcant ~p, Shop ~p", [Merchant, Shop]),
    {ok, Settings} = ?w_user_profile:get(setting, Merchant, Shop), 
    {ok, lists:foldr(
	   fun({R}, Acc) ->
		   %% only use print setting
		   case ?v(<<"type">>, R) of
		       1 -> Acc;
		       0 -> EName = ?v(<<"ename">>, R),
			    Value = ?v(<<"value">>, R),
			    [{EName, Value}|Acc]
		   end
	   end, [], Settings)}.


field_name(<<"brand">>) -> "品牌";
field_name(<<"style_number">>) -> "款号";
field_name(<<"type">>)         -> "类型";
field_name(<<"color">>)        -> "颜色";
field_name(<<"size_name">>)    -> "尺码组";
field_name(<<"size">>)         -> "尺码";
field_name(<<"price">>)        -> "单价";
field_name(<<"discount">>)     -> "折扣";
field_name(<<"dprice">>)       -> "折后价";
field_name(<<"hand">>)         -> "手";
field_name(<<"count">>)        -> "数量";
field_name(<<"calc">>)         -> "小计".    

debt(Direct, Balance, Debt) ->
    case ?w_sale:direct(Direct) of
	wreject ->
	    { "本次退款：",  ?to_f(Balance + Debt)} ;
	_ ->
	    { "本次欠款：", ?to_f(Balance + Debt)}
    end.

extra_pay(-1, _Pay) ->
    [];
extra_pay(Type, Pay) ->
    pading(2) ++ extra_pay_type(Type) ++ "：" ++ ?to_s(Pay).
    
pay(Cash, Card, Wire, Veri) -> 
    Pays = [pay(cash, Cash), pay(card, Card), pay(wire, Wire), pay(veri, Veri)],

    lists:foldr(fun([], Acc) -> Acc;
		   (S, Acc) -> pading(2) ++ S ++ Acc
		end, [], Pays).
    %% case [P || P <- Pays, P =/= [] ] of
    %% 	[] -> []; 
    %% 	[H|T] ->
    %% 	    H ++ 
    %% 		lists:foldr(fun(S, Acc) ->
    %% 				    pading(2) ++ S ++ Acc
    %% 			    end, [], T)
    %% end.
		 

pay(card, Card) when Card == 0 -> []; 
pay(card, Card) -> "刷卡：" ++ ?to_s(Card);
pay(cash, Cash)  when Cash == 0-> [];
pay(cash, Cash) -> "现金：" ++ ?to_s(Cash);
pay(wire, Wire) when Wire == 0 -> [];
pay(wire, Wire) -> "汇款：" ++ ?to_s(Wire);
pay(veri, Veri) when Veri == 0-> [];
pay(veri, Veri) -> "核销：" ++ ?to_s(Veri).

extra_pay_type(0) -> "运费代付";
extra_pay_type(1) -> "样衣";
extra_pay_type(2) -> "少配饰";
extra_pay_type(3) -> "代付现金";
extra_pay_type(4) -> "初期欠款".

round(?YES, Money) ->
    ?to_s(f_round(Money));
round(?NO, Money) ->
    ?to_s(clean_zero(Money)).

    
