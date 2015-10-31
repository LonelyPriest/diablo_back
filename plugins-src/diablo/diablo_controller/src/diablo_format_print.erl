-module(diablo_format_print).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-export([br/1, br/3, line/2, line/4, line/5, width/2, middle/3, line_space/1]).
-export([sort_amount/3, left_pading/2,
	 pading/1, size_pading/3, clean_zero/1, f_round/1]).
-export([pagination/2, pagination/3,
	 decorate_data/1, decorate_data/3, decorate_data/4, phd/1]).
-export([flattern/3, flattern/4, flattern/5]).
-export([field_len/4, field/2, column/3]).
%% -export([table_head/2, table_head/3, table_head/4]).


flattern(size, {IsTable, Width}, Sizes) ->
    flattern(size, {IsTable, Width}, Sizes, "");

flattern(amount_array, {IsTable, Column, SizeNum, Fields}, Amounts) ->
    flattern(
      amount_array, {IsTable, Column, SizeNum, Fields}, Amounts, [], 0, 0); 
flattern(amount, {IsTable, Column, SizeNum, Fields}, Amounts) ->
    flattern(amount, {IsTable,Column, SizeNum, Fields}, Amounts, [], 0, 0).

flattern(size, {_IsTable, _Width}, [], Flattern) ->
    Flattern;
flattern(size, {IsTable, Width}, [Size|T], Flattern) ->
    %% ?DEBUG("Size ~p", [Size]),
    {Name, SizeLen} = case Size =:= <<"0">> of
			  true -> {"均码", 4};
			  false -> {?to_s(Size), length(?to_s(Size))}
		      end,
    flattern(size, {IsTable, Width}, T, Flattern
	     ++ case IsTable of
		    ?TABLE ->
			Mh = (Width - SizeLen -1) div 2,
			Ml = (Width - SizeLen -1) rem 2,
			pading(Mh) ++ Name ++ pading(Mh + Ml) ++ phd("|");
		    ?STRING ->
			Name ++ size_pading(Width, Size, Name) end).


flattern(amount, {IsTable, Column, SizeNum, Fields}, [], Flattern, MTotals, MStastic) ->
    Stastic = column(stastic, {IsTable, SizeNum, Fields}, MTotals, MStastic),
    Flattern ++ Stastic
	++ case IsTable of
	       ?TABLE -> [];
	       ?STRING ->[line(minus, Column)] end;

flattern(amount, {IsTable, Column, SizeNum, Fields}, [H|T], Flattern, MTotals, MStastic) ->
    {A, Nums} = H,
    try 
	{true, Width} = field(size, Fields),
	{FlatternNums, Total} = flattern(nums, {IsTable, Width}, Nums, "", 0),
	case Total of
	    0 ->  flattern(amount, {IsTable, Column, SizeNum, Fields},
			   T, Flattern, MTotals, MStastic);
	    Total ->
		FPrice = ?v(<<"fprice">>, A),
		FDiscount = ?v(<<"fdiscount">>, A),
		Row = row(IsTable, A, Fields, FlatternNums, Total),
		flattern(amount, {IsTable, Column, SizeNum, Fields},
			 T,
			 Flattern ++ [Row],
			 Total + MTotals,
			 FPrice * Total * FDiscount * 0.01 + MStastic)
	end
    catch
	error:{badmatch, {false, _}}->
	    throw(size_not_include) 
    end.

flattern(nums, {?STRING, _Width}, [], Flattern, Total) ->
    %% ?DEBUG("Flattern Nums length ~p", [length(Flattern)]),
    {Flattern, Total};
flattern(nums, {?STRING, Width}, [Num|T], Flattern, Total) ->
    Pading = 
	case Num =:= 0 of
	    true -> pading(Width);
	    false -> ?to_s(Num) ++ size_pading(Width, Num, Num)
	end, 
    %% ?DEBUG("padding length ~p", [length(Pading)]),
    flattern(nums, {?STRING, Width}, T, Flattern ++ Pading, Total + Num);

flattern(nums, {?TABLE, _Width}, [], Flattern, Total) ->
    %% ?DEBUG("Flattern Nums length ~p", [length(Flattern)]),
    {Flattern, Total};
flattern(nums, {?TABLE, Width}, [Num|T], Flattern, Total) ->
    Pading = 
	case Num =:= 0 of
	    true -> pading(Width -1) ++ phd("|");
	    false ->
		{Mh, Ml} = middle(?TABLE, Width, Num),
		pading(Mh) ++ ?to_s(Num) ++ pading(Ml) ++ phd("|")
		%% ?to_s(Num)
		%% 	 ++ size_pading(Width -1, Num, Num) ++ "|"
	end, 
    %% ?DEBUG("padding length ~p", [length(Pading)]),
    flattern(nums, {?TABLE, Width}, T, Flattern ++ Pading, Total + Num). 

sort_amount(CId, Sizes, Amounts)->
   sort_amount(CId, Sizes, Amounts, []).

sort_amount(_CId, [], _Amounts, Counts)->
    lists:reverse(Counts);
sort_amount(CId, [Size|T], Amounts, Counts)->
    C = get_amount(CId, Size, Amounts),
    sort_amount(CId, T, Amounts, [C|Counts]).

get_amount(_CId, _Size, []) ->
    0;
get_amount(CId, Size, [{struct, Amount}|T]) ->
    case ?v(<<"cid">>, Amount) =:= CId
	andalso ?to_s(?v(<<"size">>, Amount)) =:= ?to_s(Size) of
	true ->
	    case ?w_sale:direct(?v(<<"direct">>, Amount)) of
		wreject -> ?v(<<"reject_count">>, Amount);
		_ ->       ?v(<<"sell_count">>, Amount)
	    end;
	false ->
	    get_amount(CId, Size, T)
    end.


size_pading(Width, <<"0">>, Name) -> 
    pading(Width - width(chinese, Name));
size_pading(Width, _, Name) -> 
    pading(Width - width(latin1, Name)).

left_pading(<<"jolimark">>, <<"LQ-200KII/KIIF">>) ->
    pading(4); 
left_pading(<<"jolimark">>, _Model) ->
    "";
left_pading(_Brand, _Model) ->
    "".

pading(Len) when is_float(Len)->
    pading(round(Len), "");
pading(Len) ->
    pading(Len, "").
pading(0, Pading) ->
    %% ?DEBUG("finnal padding length ~p", [length(Pading)]),
    Pading;
pading(Len, Pading) when Len < 0 ->
    " " ++ Pading;
pading(Len, Pading) ->
    pading(Len - 1, " " ++ Pading).

br(Brand) when is_binary(Brand) ->
    br(?to_a(Brand));
br(feie) ->
    "<BR>";
br(_Brand) ->
    "\r\n".

line(equal, Column) ->
    lists:concat(lists:duplicate(Column, "="));
line(minus, Column) ->
    lists:concat(lists:duplicate(Column, "-"));
line(dot, Column) ->
    lists:concat(lists:duplicate(Column div 2, ".-")).

line(add_minus, ?TABLE, ?COLUMN, Fields) ->
    [{_,_,W1}|T] = Fields,
    "+" ++ line(minus, W1-2) ++ "+"
	++ 
	lists:foldr(
	  fun({_,_,W}, Acc) ->
		  line(minus, W-1) ++ "+" ++ Acc
	  end, [], T).

line(add_minus, ?TABLE, ?ROW, SizeNum, Fields) ->
    [{_,_,W1}|T] = Fields,
    "+" ++ line(minus, W1-2) ++ "+"
	++
    lists:foldr(
      fun({<<"size">>, _, W}, Acc) ->
	      lists:foldr(
		fun(_, Acc1) ->
			line(minus, W-1) ++ "+" ++ Acc1
		end, [], lists:duplicate(SizeNum, 0)) ++ Acc;
	 ({_, _, W}, Acc) ->
	      line(minus, W-1) ++ "+" ++ Acc
      end, [], T).


width(latin1, English) ->
    length(?to_s(English));
width(chinese, Chinese) ->
    %% ?DEBUG("Chinese ~p", [Chinese]),
    U16 = unicode:characters_to_binary(?to_b(Chinese), utf8, utf16),
    ?DEBUG("U16 ~p", [U16]),
    U = [ <<U>> || <<U>> <= U16, U =/= 0],
    %% ?DEBUG("lenght of chinese ~ts is ~p", [?to_b(Chinese), length(U)]),
    length(U).

middle(?TABLE, TotalWidth, Number) ->
    Width = width(latin1, Number),
    Mh = (TotalWidth - Width -1) div 2,
    Ml = (TotalWidth - Width -1) rem 2,
    {Mh, Mh + Ml}.

column(?TABLE, SizeNum, Fields) ->
    OffsetCalc = field_len(Fields, <<"calc">>, ?ROW, 0),
    %% {true, WidthCount} = field(count, Fields),
    {true, WidthSize}  = field(size, Fields),
    {true, WidthCalc}  = field(calc, Fields), 
    WidthSize * SizeNum + OffsetCalc + WidthCalc.

column(stastic, {IsTable, SizeNum, Fields}, Totals, Calcs) ->
    OffsetCount = field_len(Fields, <<"count">>, ?ROW, 0),
    {true, WidthCount} = field(count, Fields),
    {true, WidthSize}  = field(size, Fields),
    {true, WidthCalc}  = field(calc, Fields),

    Offset = WidthSize * SizeNum + OffsetCount,
    %% ?DEBUG("offestcount ~p, width count ~p, width size ~p"
    %% 	   ", offfest ~p, width calc ~p",
    %% 	   [OffsetCount, WidthCount, WidthSize, Offset, WidthCalc]),

    CleanCalc = ?to_s(clean_zero(Calcs)),
    %% CleanCalc = ?to_s(clean_zero(Calcs)),
    CleanTotal = ?to_s(Totals),

    case IsTable of
	?TABLE ->
	    {Mh, Ml}   = middle(?TABLE, WidthCount, CleanTotal),
	    {Mhc, Mlc} = middle(?TABLE, WidthCalc, CleanCalc),
	    [phd("|") ++ pading(Offset - 2) ++ phd("|")
	     ++ pading(Mh) ++ CleanTotal ++ pading(Ml) ++ phd("|")
	     ++ pading(Mhc) ++ CleanCalc ++ pading(Mlc) ++ phd("|")];
	?STRING ->
	    [pading(Offset) ++ CleanTotal
	     ++ pading(WidthCount - length(CleanTotal)) ++ CleanCalc]
    end.

row(?STRING, A, Fields, FlatternNums, Total) ->
    %% ?DEBUG("A ~p", [A]),
    Brand       = ?v(<<"brand">>, A),
    StyleNumber = ?v(<<"style_number">>, A),
    Type        = ?v(<<"type">>, A), 
    Color       = ?v(<<"color">>, A),
    Price       = ?v(<<"fprice">>, A), 
    Discount    = ?v(<<"fdiscount">>, A),
    FPrice      = Price * Discount * 0.01,

    Row = 
	lists:foldr(
	  fun({<<"brand">>, _, W}, Acc) ->
		  ?to_s(Brand) ++ pading(W - width(chinese, Brand)) ++ Acc;
	     ({<<"style_number">>, _, W}, Acc) ->
		  ?to_s(StyleNumber)
		      ++ pading(W - width(latin1, StyleNumber)) ++ Acc;
	     ({<<"type">>, _, W}, Acc) ->
		  ?to_s(Type) ++ pading(W - width(chinese, Type)) ++ Acc;
	     ({<<"color">>, _, W}, Acc) ->
		  ?to_s(Color) ++ pading(W - width(chinese, Color)) ++ Acc;
	     ({<<"size">>, _, _}, Acc) ->
		  FlatternNums ++ Acc;
	     ({<<"price">>, _, W}, Acc)->
		  CleanPrice = clean_zero(Price),
		  ?to_s(CleanPrice) ++ pading(W - width(latin1, CleanPrice)) ++ Acc;
	     ({<<"discount">>, _, W}, Acc)     ->
		  ?to_s(Discount) ++ pading(W - width(latin1, Discount)) ++ Acc;
	     ({<<"dprice">>, _, W}, Acc)       ->
		  CleanFPrice = clean_zero(FPrice),
		  ?to_s(CleanFPrice) ++ pading(W - width(latin1, CleanFPrice)) ++ Acc;
	     ({<<"count">>, _, W}, Acc) ->
		  ?to_s(Total) ++ pading(W - width(latin1, Total)) ++ Acc;
	     ({<<"calc">>, _, _W}, Acc) ->
		  %% ?DEBUG("round ~p", [?to_s(round(FPrice * Total))]),
		  ?to_s(clean_zero(FPrice * Total)) ++ Acc
	  end, [], Fields),
    ?DEBUG("row ~p", [Row]),
    Row;

row(?TABLE, A, Fields, FlatternNums, Total) ->
    %% ?DEBUG("A ~p", [A]),
    Brand       = ?v(<<"brand">>, A),
    StyleNumber = ?v(<<"style_number">>, A),
    Type        = ?v(<<"type">>, A), 
    Color       = ?v(<<"color">>, A),
    Price       = ?v(<<"fprice">>, A), 
    Discount    = ?v(<<"fdiscount">>, A),
    FPrice      = Price * Discount * 0.01,

    [{FirstName, _, _}|_] = Fields,
    %% ?DEBUG("FirstName ~p",[FirstName]),
    Row = 
	lists:foldr(
	  fun({<<"brand">> = Name, _, W}, Acc) when Name =:= FirstName->
		  phd("|") ++ ?to_s(Brand)
		      ++ pading(W - width(chinese, Brand) -2 )
		      ++ phd("|") ++ Acc;
	     ({<<"style_number">> = Name, _, W}, Acc) when Name=:=FirstName->
		  phd("|") ++ ?to_s(StyleNumber)
		      ++ pading(W - width(latin1, StyleNumber) -2)
		      ++ phd("|") ++ Acc;
	     ({<<"style_number">>, _, W}, Acc)->
		  ?to_s(StyleNumber)
		      ++ pading(W - width(latin1, StyleNumber) -1)
		      ++ phd("|") ++ Acc;
	     ({<<"type">>, _, W}, Acc) ->
		  ?to_s(Type) ++ pading(W - width(chinese, Type) -1 )
		      ++ phd("|") ++ Acc;
	     ({<<"color">>, _, W}, Acc) ->
		  ?to_s(Color) ++ pading(W - width(chinese, Color) -1 )
		      ++ phd("|") ++ Acc;
	     ({<<"size">>, _, _}, Acc) ->
		  FlatternNums ++ Acc;
	     ({<<"price">>, _, W}, Acc)->
		  CleanPrice = clean_zero(Price),
		  {Mh, Ml} = middle(?TABLE, W, CleanPrice),
		  pading(Mh) ++ ?to_s(CleanPrice) ++ pading(Ml)
		      ++ phd("|") ++ Acc;
	     ({<<"discount">>, _, W}, Acc)     ->
		  {Mh, Ml} = middle(?TABLE, W, Discount),
		  pading(Mh) ++ ?to_s(Discount) ++ pading(Ml)
		      ++ phd("|") ++ Acc;
	     ({<<"dprice">>, _, W}, Acc)       ->
		  CleanFPrice = clean_zero(FPrice),
		  {Mh, Ml} = middle(?TABLE, W, CleanFPrice),
		  pading(Mh) ++ ?to_s(CleanFPrice) ++ pading(Ml)
		      ++ phd("|") ++ Acc;
	     ({<<"count">>, _, W}, Acc) ->
		  {Mh, Ml} = middle(?TABLE, W, Total),
		  pading(Mh) ++ ?to_s(Total) ++ pading(Ml)
		      ++ phd("|") ++ Acc;
	     ({<<"calc">>, _, W}, Acc) ->
		  CleanCalc = FPrice * Total,
		  {Mh, Ml} = middle(?TABLE, W, CleanCalc),
		  pading(Mh) ++ ?to_s(CleanCalc) ++ pading(Ml)
		      ++ phd("|") ++ Acc
	  end, [], Fields),
    %% ?DEBUG("row ~p", [Row]),
    Row.


field_len([], _F, _PModel, Len) ->
    Len;
field_len([{<<"size">>, _, Width}|T], F, PModel, Len) ->
    case PModel of
	?ROW    ->
	    case F =:= <<"size">> of
		true -> Len;
		false -> field_len(T, F, PModel, Len)
	    end;
	?COLUMN ->
	    case F =:= <<"size">> of
		true -> Width + Len;
		false -> field_len(T, F, PModel, Width + Len)
	    end
    end;
field_len([{Name, _, _}|_], F, _, Len) when Name =:= F ->
    Len;
field_len([{_Name, _, Width}|T], F, PModel, Len) ->
    field_len(T, F, PModel, Width + Len).

field(_, []) ->
    {false, 0};
field(F, [{Name, _, Width}|T]) ->
    case ?to_b(F) =:= Name of
	true  -> {true, Width};
	false -> field(F, T)
    end.

%% field_distance([], _F, _PModel, Len) ->
%%     Len;
%% field_distance([{<<"size">>, _, _}|T], F, PModel, Len) ->
%%     case PModel of
%% 	?ROW    ->  field_len(T, F, PModel, Len);
%% 	?COLUMN ->  field_len(T, F, PModel, Len + 1)
%%     end;
%% field_distance([{Name, _, _}|_], F, _, Len) when Name =:= F ->
%%     Len;
%% field_distance([{_Name, _, _}|T], F, PModel, Len) ->
%%     %% ?DEBUG("filed_len Name ~p, F ~p", [_Name, F]),
%%     field_distance(T, F, PModel, Len + 1).

clean_zero(V) when is_integer(V) -> V;
clean_zero(V) when is_float(V), round(V) == V -> round(V);
clean_zero(V) when is_float(V)-> V.

f_round(V) when is_integer(V) -> V;
f_round(V) when is_float(V) -> round(V).

%% =============================================================================
%% printer
%% =============================================================================
decorate_data(bwh) ->
    decorate_data(block)
	++ decorate_data(width) ++ decorate_data(height);
decorate_data(cancel_bwh) ->
    decorate_data(cancel_block)
	++ decorate_data(cancel_width) ++ decorate_data(cancel_height);
decorate_data(block) ->
    ?to_s(<<16#1b, 16#45>>);
decorate_data(cancel_block) ->
    ?to_s(<<16#1b, 16#46>>);
decorate_data(width) ->
    ?to_s(<<16#1b, 16#57, 16#01>>);
decorate_data(cancel_width) ->
    ?to_s(<<16#1b, 16#57, 16#00>>);
decorate_data(height) ->
    ?to_s(<<16#1b, 16#77, 16#01>>);
decorate_data(cancel_height) ->
    ?to_s(<<16#1b, 16#77, 16#00>>).
phd(_D) ->
    "|".
    %% ?to_s(<<16#1b, 16#77, 16#01>>) ++ D ++ ?to_s(<<16#1b, 16#77, 16#00>>).

line_space('1/9') ->
    [27, 51, 16];
line_space('1/8') ->
    [27, 51, 18];
line_space('1/6') ->
    [27, 50];
line_space(default) ->
    [27, 64].

br(forward, <<"epson">>, <<"LQ55K">>) ->
    br(<<"epson">>) ++ br(<<"epson">>) ++ br(<<"epson">>)
	++ br(<<"epson">>) ++ br(<<"epson">>) ++ br(<<"epson">>)
	++ br(<<"epson">>) ++ br(<<"epson">>) ++ br(<<"epson">>)
	++ br(<<"epson">>) ++ br(<<"epson">>) ++ br(<<"epson">>);
br(forward, Brand, _Model) ->
    br(Brand).

    

%% decorate_data(head, jolimark, 'LQ-200KIII', PaperHeight) ->
%%     decorate_data(head, jolimark, none, PaperHeight);
%% decorate_data(head, jolimark, 'LQ-200KII/KIIF', PaperHeight)->
%%     decorate_data(head, jolimark, none, PaperHeight);
decorate_data(head, jolimark, _Brand, PaperHeight) ->
    %% ?DEBUG("PaperHeight ~p", [PaperHeight]),
    RoundHeight = round(PaperHeight * 36 / 2.54), 
    Head = <<16#1b, 16#1d, 16#1e, 16#06, 16#01, 16#01, 16#1b, 16#0d, 16#1f, 16#1b,
	     16#40, 16#1b, 16#74, 16#01, 16#1b, 16#36, 16#52, 16#00, 16#1b, 16#72,
	     16#00, 16#01, 16#1b, 16#28, 16#55, 16#01, 16#00, 16#0a, 16#1b, 16#19,
	     16#30, 16#1b, 16#28, 16#43, 16#02, 16#00, RoundHeight:16/little,
	     16#0d, 16#0d>>, 
    ?to_s(Head);

decorate_data(head, fujitsu, Brand, PaperHeight) ->
    decorate_data(head, epson, Brand, PaperHeight);
decorate_data(head, epson, _Brand, PaperHeight) ->
    %% ?DEBUG("PaperHeight ~p", [PaperHeight]),
    RoundHeight = round(PaperHeight * 36 / 2.54),
    %% ?DEBUG("roundHeight ~p", [RoundHeight]),
    %% ?DEBUG("roundHeight ~p", [<<RoundHeight:16/little>>]),
    Head = <<16#1b, 16#40, 16#0d, 16#1b, 16#28, 16#55, 16#01, 16#00, 16#0a,
	     16#1b, 16#28, 16#43, 16#02, 16#00, RoundHeight:16/little>>,
    %% ?DEBUG("head ~p", [Head]),
    ?to_s(Head).


%% decorate_data(tail, jolimark, 'LQ-200KIII') ->
%%     decorate_data(tail, jolimark, 'LQ-200KII/KIIF');
%% decorate_data(tail, jolimark, 'LQ-200KII/KIIF') ->
%%     decorate_data(tail, jolimark, 'LQ-200KII/KIIF');
decorate_data(tail, jolimark, _Brand) ->
    ?to_s(<<16#0d, 16#0c, 16#1b, 16#40, 16#1b, 16#1d, 16#1e,
	    16#06, 16#01, 16#00, 16#1b, 16#1d, 16#1f>>);

decorate_data(tail, fujitsu, Brand) ->
    decorate_data(tail, epson, Brand); 
decorate_data(tail, epson, _Brand) ->
    ?to_s(<<16#0c, 16#1b, 16#40, 16#0d>>).

    
pagination(just, PaperHeight, Body) ->
    Tokens = string:tokens(Body, "\r\n"),
    ?DEBUG("tokens len ~p", [length(Tokens)]),
    case 9 + 4.5 * length(Tokens) + 9 > PaperHeight of
	true ->
	    %% 15k, use 6 not 8
	    PackageSize = 15 * 1024 * 6,
	    case bit_size(?to_b(Body)) =< PackageSize of
		true ->
		    {false, [?to_b(Body)]};
		false ->
		    {false, do_package(PackageSize, 0, Tokens, <<>>, [])}
	    end;
	false ->
	    {true, [?to_b(Body)]}
    end;

pagination(auto, PaperHeight, Body) ->
    Tokens = string:tokens(Body, "\r\n"),
    ?DEBUG("tokens len ~p", [length(Tokens)]),
    case 9 + 4.5 * length(Tokens) + 9 > PaperHeight of
	true ->
	    {false, start_pagination(PaperHeight - 18, 0, Tokens, <<>>, [])};
	%% {false, [?to_b(Body)]};
	false ->
	    {true, [?to_b(Body)]}
    end.


pagination(PaperHeight, Body) ->
    Tokens = string:tokens(Body, "\r\n"),
    ?DEBUG("tokens len ~p", [length(Tokens)]),
    
    case 9 + 4.5 * length(Tokens) + 9 > PaperHeight of
	true ->
	    {true, start_pagination(PaperHeight - 18, 0, Tokens, <<>>, [])};
	false ->
	    {true, [?to_b(Body)]} 
    end.

start_pagination(_Height, _ContentHeight, [], Page, Pages)->
    %% ?DEBUG("Page ~p, pages ~p", [Page, Pages]), 
    Pages ++ [Page];
    %% [Page];
    
start_pagination(Height, ContentHeight, [H|T], Page, Pages)->
    %% ?DEBUG("CH ~p, H ~p, Page ~p, pages ~p", [ContentHeight, H, Page, Pages]),
    case ContentHeight + 4.5 > Height of
	true -> 
	    BinH = ?to_b(H),
	    start_pagination(Height, 4.5, T,
			     <<BinH/binary, <<"\r\n">>/binary>>, Pages ++ [Page]);
	false ->
	    BinH = ?to_b(H), 
	    start_pagination(Height, ContentHeight + 4.5, T,
			     <<Page/binary, BinH/binary, <<"\r\n">>/binary>>, Pages)
    end.


do_package(_PackSize, _ContenSize, [], Page, Pages)->
    Pages ++ [Page];

do_package(PackSize, ContentSize, [H|T], Page, Pages)->
    %% ?DEBUG("CH ~p, H ~p, Page ~p, pages ~p", [ContentHeight, H, Page, Pages]),
    BinH = ?to_b(H), 
    case ContentSize > PackSize of
	true -> 
	    do_package(PackSize, 0, T, <<BinH/binary, <<"\r\n">>/binary>>, Pages ++ [Page]);
	false ->
	    do_package(PackSize, ContentSize + bit_size(BinH), T,
		       <<Page/binary, BinH/binary, <<"\r\n">>/binary>>, Pages)
    end.
    
	    
	    
    

%% table_head(?COLUMN, Fields) ->
%%     ?DEBUG("table_head fields ~p", [Fields]),
%%     TC = <<16#1b, 16#44>>,
%%     TH = table_head(?COLUMN, Fields, 0, <<>>),
%%     TB = <<TC/binary, TH/binary, 16#00>>,
%%     ?DEBUG("table_head ~p", [TB]),
%%     ?to_s(TB).
    
%% table_head(?COLUMN, [], _Distance, THead) ->
%%     THead;
%% table_head(?COLUMN, [{_Name, _, Width}|T], Distance, THead) ->
%%     Len = Distance + Width,
%%     HexLen = mochihex:to_int(mochihex:to_hex(Len)),
%%     table_head(?COLUMN, T, Len, <<THead/binary, HexLen>>).



%% table_head(?ROW, Fields, Sizes) ->
%%     ?DEBUG("table_head fields ~p", [Fields]),
%%     TC = <<16#1b, 16#44>>,
%%     TH = table_head(?ROW, Fields, 0, Sizes, <<>>),
%%     TB = <<TC/binary, TH/binary, 16#00>>,
%%     ?DEBUG("table_head ~p", [TB]),
%%     ?to_s(TB).

%% table_head(?ROW, [], _Fields, _Distance, THead) ->
%%     THead;
%% table_head(?ROW, [{<<"size">>, _, Width}|T], Distance, Sizes, THead) ->
%%     %% ?DEBUG("width ~p, Thead ~p", [Width, THead]),
%%     {SHead, NewDistance} =
%% 	lists:foldl(fun(_S, {H, D})->
%% 			    %% ?DEBUG("Len ~p", [D + Width]),
%% 			    HexLen = mochihex:to_int(mochihex:to_hex(D + Width)),
%% 			    {<<H/binary, HexLen>>, D + Width}
%% 		    end, {THead, Distance}, Sizes),
%%     table_head(?ROW, T, NewDistance, Sizes, SHead); 
%% table_head(?ROW, [{_Name, _, Width}|T], Distance, Sizes, THead) ->
%%     Len = Distance + Width,
%%     HexLen = mochihex:to_int(mochihex:to_hex(Len)),
%%     %% ?DEBUG("name ~p, HexLen ~p", [Name, HexLen]),
%%     table_head(?ROW, T, Len, Sizes, <<THead/binary, HexLen>>).



    

    
