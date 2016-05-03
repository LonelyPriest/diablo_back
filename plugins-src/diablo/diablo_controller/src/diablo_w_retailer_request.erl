-module(diablo_w_retailer_request).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_request).

-export([action/2, action/3, action/4]).


-import(?f_print,
	[width/2, middle/3, middle/4,
	 pading/1, clean_zero/1, br/1,
	 line/2, phd/1, line_space/1]).

%%--------------------------------------------------------------------
%% @desc: GET action
%%--------------------------------------------------------------------
action(Session, Req) ->
    ?DEBUG("GET Req ~n~p", [Req]),
    {ok, HTMLOutput} = wretailer_frame:render(
			 [
			  {navbar, ?menu:navbars(?MODULE, Session)},
			  {basebar, ?menu:w_basebar(Session)},
			  {sidebar, sidebar(Session)},
			  {ngapp, "wretailerApp"},
			  {ngcontroller, "wretailerCtrl"}]),
    Req:respond({200, [{"Content-Type", "text/html"}], HTMLOutput}).


action(Session, Req, {"list_w_retailer"}) ->
    ?DEBUG("list w_retailer with session ~p", [Session]), 
    Merchant = ?session:get(merchant, Session),
    
    %% ?utils:respond(
    %%    batch, fun() -> ?w_retailer:retailer(list, Merchant) end, Req);
    ?utils:respond(
       batch, fun() -> ?w_user_profile:get(retailer, Merchant) end, Req);

action(Session, Req, {"list_w_province"}) ->
    ?DEBUG("list w_province with session ~p", [Session]),
    Merchant = ?session:get(merchant, Session),
    ?utils:respond(
       batch, fun() -> ?w_retailer:province(list, Merchant) end, Req);

action(Session, Req, {"list_w_city"}) ->
    ?DEBUG("list w_city with session ~p", [Session]),
    Merchant = ?session:get(merchant, Session),
    ?utils:respond(batch, fun() -> ?w_retailer:city(list, Merchant) end, Req);

action(Session, Req, {"del_w_retailer", Id}) ->
    ?DEBUG("delete_w_retailer with session ~p, Id ~p", [Session, Id]),

    Merchant = ?session:get(merchant, Session),
    case ?w_retailer:retailer(delete, Merchant, Id) of
	{ok, RetailerId} ->
	    ?utils:respond(200, Req, ?succ(delete_w_retailer, RetailerId));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end.

%%--------------------------------------------------------------------
%% @desc: POST action
%%--------------------------------------------------------------------
action(Session, Req, {"new_w_retailer"}, Payload) ->
    ?DEBUG("new wretailer with session ~p~npaylaod ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session), 
    Province = ?v(<<"province">>, Payload),
    %% City     = ?v(<<"city">>, Payload),

    City =
	case ?v(<<"city">>, Payload) of
	    undefined -> {ok, -1};
	    C -> ?w_retailer:city(new, Merchant, C, Province)
	end,
    
    case City of
	{ok, CityId} ->
	    ?DEBUG("cityid  ~p", [CityId]),
	    case ?w_retailer:retailer(
		    new,
		    Merchant,
		    [{<<"city">>, CityId}
		     |proplists:delete(<<"city">>, Payload)]) of {ok, RId} ->
		    ?utils:respond(
		       200, Req, ?succ(add_w_retailer, RId), {<<"id">>, RId});
		{error, Error} ->
		    ?utils:respond(200, Req, Error)
	    end;
	Error ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"update_w_retailer", Id}, Payload) ->
    ?DEBUG("update_w_retailer with Session ~p~npaylaod ~p", [Session, Payload]),
    
    Merchant = ?session:get(merchant, Session),
    Province = ?v(<<"province">>, Payload),

    UpdateFun =
	fun(Update, CId) ->
		case ?w_retailer:retailer(update, Merchant, Id, Update) of
		    {ok, RId} ->
			?utils:respond(200,
				       Req,
				       ?succ(update_w_retailer, RId),
				       {<<"cid">>, CId});
		    {error, Error} ->
			?utils:respond(200, Req, Error)
		end 
	end,
    
    case ?v(<<"city">>, Payload, []) of
    	[]   ->
    	    UpdateFun(Payload, -1);
    	City ->
    	    case ?w_retailer:city(new, Merchant, City, Province) of
		{ok, CityId} -> 
		    NewPayload = [{<<"city">>, CityId}
				  |proplists:delete(<<"city">>, Payload)],
		    UpdateFun(NewPayload, CityId);
		Error ->
		    ?utils:respond(200, Req, Error)
	    end
    end;
		
action(Session, Req, {"bill_w_retailer"}, Payload) ->
    ?DEBUG("bill wretailer with session ~p~npaylaod ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    Retailer = ?v(<<"retailer">>, Payload),

    case ?w_retailer:bill(check, Merchant, Payload) of
	{ok, SN} ->
	    ?w_user_profile:update(retailer, Merchant), 
	    ?utils:respond(200,
			   Req,
			   ?succ(bill_w_retailer, Retailer),
			   [{<<"rsn">>, ?to_b(SN)}]); 
	Error ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"print_w_retailer_trans"}, Payload) ->
    ?DEBUG("print_w_retailer_trans with session ~p~npaylaod ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    Retailer = ?v(<<"retailer">>, Payload),

    {ok, RetailerInfo} = ?w_user_profile:get(retailer, Merchant, Retailer),
    RetailerName = ?v(<<"name">>, RetailerInfo),
    
    case ?w_retailer:print_trans(Merchant, Payload) of
	{ok, []} ->
	    ?utils:respond(200, Req, ?err(print_w_retailer_no_transe, Retailer));
	{ok, Rs} ->
	    %% ?DEBUG("print rs ~p", [Rs]),
	    RsLength = erlang:length(Rs),
	    [ShopId|_]   = ?v(<<"shop">>, Payload),
	    ResponseFun =
		fun(PCode, PInfo) ->
			?utils:respond(200, Req, ?succ(print_wreport, ShopId),
				       [{<<"pcode">>, PCode},
					{<<"pinfo">>, PInfo}])
		end,
	    
	    {VPrinters, ShopInfo} = ?wifi_print:get_printer(Merchant, ShopId),
	    {ok, MerchantInfo} = ?wifi_print:detail(merchant, Merchant), 
	    {ok, Banks}        = ?wifi_print:detail(bank, Merchant), 
	    {Setting, Phones}  = ?wifi_print:detail(base_setting, Merchant, ShopId),

	    ShopAddr = ?v(<<"address">>, ShopInfo), 
	    Mobile   = ?v(<<"mobile">>, MerchantInfo),

	    case VPrinters of
		[] ->
		    ?utils:respond(200, Req, ?err(shop_not_printer, ShopId));
		_  -> 
		    Head = ?to_s(?v(<<"name">>, ShopInfo))
			++ "－" ++ ?to_s(RetailerName) ++ "（对帐单）",

		    PrintInfo = 
			lists:foldr(
			  fun(P, Acc) ->
				  SN     = ?v(<<"sn">>, P),
				  Key    = ?v(<<"code">>, P),
				  Path   = ?v(<<"server_path">>, P),

				  Brand  = ?v(<<"brand">>, P),
				  Model  = ?v(<<"model">>, P),

				  Column = ?v(<<"pcolumn">>, P),
				  Height = ?v(<<"pheight">>, P),

				  %% ?DEBUG("P ~p", [P]),
				  Server = ?wifi_print:server(?v(<<"server_id">>, P)), 

				  Title = ?wifi_print:title(Brand, Model, Column, Head)
				      ++ ?wifi_print:address(
					    Brand, Model, Column, ShopAddr, Setting)
				      ++ br(Brand) ++ line(minus, 99) ++ br(Brand), 

				  TableHead = phd(c) ++ "序号" ++ phd(c)
				      ++ pading(7) ++ "单号" ++ pading(7) ++ phd(c)
				      ++ pading(1) ++ "数量" ++ pading(1) ++ phd(c)
				      ++ "帐户欠款" ++ phd(c)
				      ++ pading(1) ++ "应付" ++ pading(1) ++ phd(c)
				      ++ pading(1) ++ "费用" ++ pading(1) ++ phd(c)
				      ++ pading(1) ++ "核销" ++ pading(1) ++ phd(c)
				      ++ pading(1) ++ "实付" ++ pading(1) ++ phd(c)
				      ++ "本次欠款" ++ phd(c)
				      ++ pading(8) ++ "日期" ++ pading(8) ++ phd(c)
				      ++ br(Brand) ++ line(minus, 99),

				  {Body, _} = lists:foldr(
					   fun({R}, {Acc1, No})->
						   {br(Brand)
						    ++ phd(c) ++ m(latin1, 4, No) ++ phd(c)
						    ++ row(print, R)
						    ++ br(Brand)
						    ++ line(minus, 99)
						    ++ Acc1, No - 1}
					   end, {[], RsLength}, Rs),
				  %% ?DEBUG("body ~p", [Body]),

				  PrintContent = Title 
				      ++ TableHead
				      ++ Body
				      ++ br(Brand)
				      ++ case ?to_i(?v(<<"pccmix">>, Setting, 0)) of
					     0 ->
						 ?wifi_print:body_foot(
						    format_default,
						    Brand,
						    Model,
						    Column,
						    Banks,
						    Mobile,
						    Phones);
					     1 ->
					      ?wifi_print:body_foot(
						format_column,
						 Brand,
						 Model,
						 Column,
						 Banks,
						 [{<<"phone">>, Mobile, []}|Phones],
						 [])
					 end
				      ++ pading(99 - 16)
				      ++ ?utils:current_time(format_localtime),
				  
				  NoUpgradeDevices =
				      ["1004", "1001", "1002", "1003", "1023"],

				  DBody = 
				      case lists:member(
					     ?to_s(SN), NoUpgradeDevices) of
					  true ->
					      %% auto page
					      ?f_print:pagination(
						 auto, Height * 10, PrintContent);
					  false ->
					      %% no page
					      ?f_print:pagination(
						 just_size, Height * 10, PrintContent)
				      end, 
				  ?DEBUG("server ~p", [Server]),
				  [{SN, fun() when Server =:= rcloud ->
						?wifi_print:start_print(
						   rcloud, Brand, Model, Height,
						   SN, Key, Path, DBody);
					   () when Server =:= fcloud ->
						?wifi_print:start_print(
						   fcloud, SN, Key, Path, PrintContent) 
					end}|Acc] 
			  end, [], VPrinters),

		    case ?wifi_print:multi_print(PrintInfo) of
			{Success, []} ->
			    ResponseFun(0, Success); 
			{[], Failed} ->
			    PInfo = [{[{<<"device">>, DeviceId}, {<<"ecode">>, ECode}]}
				     || {DeviceId, ECode} <- Failed],
			    ResponseFun(1, PInfo); 
			{_Success, Failed} when is_list(Failed)->
			    PInfo = [{[{<<"device">>, DeviceId}, {<<"ecode">>, ECode}]}
				     || {DeviceId, ECode} <- Failed],
			    ResponseFun(2, PInfo);
			{error, {ECode, _EInfo}} ->
			    ResponseFun(ECode, [])
		    end
	    end,
	    
	    ?utils:respond(200,
			   Req,
			   ?succ(print_w_retailer_trans, Retailer)); 
	Error ->
	    ?utils:respond(200, Req, Error)
    end.
    

sidebar(Session) -> 
    S1 = [{"wretailer_detail", "零售商详情", "glyphicon glyphicon-book"}
	  %%  {"wretailer_top", "零售商分布", "glyphicon glyphicon-map-marker"}
	 ],
    
    S2 = 
	case ?right_auth:authen(?new_w_retailer, Session) of
	    {ok, ?new_w_retailer} ->
		[{"wretailer_new", "新增零售商", "glyphicon glyphicon-plus"}];
	    _ ->
		[]
	end,

    S3 = 
	case ?right_auth:authen(?bill_w_retailer, Session) of
	    {ok, ?bill_w_retailer} ->
		[{{"wretailer", "零售商结账", "glyphicon glyphicon-check"},
		  [{"bill", "结帐", "glyphicon glyphicon-check"}
		  %% {"bill_detail", "结帐详情", "glyphicon glyphicon-leaf"}
		  ]
		 }];
	    _ ->
		[]
	end,

    %% ?menu:sidebar(
       %% level_2_menu,
       %% [{{"wretailer", "零售商管理", "glyphicon glyphicon-map-marker"}, S1 ++ S2}]).
    ?menu:sidebar(level_1_menu, S2 ++ S1) ++ ?menu:sidebar(level_2_menu, S3).
       

m(latin1, Width, Number) ->
    Length = width(latin1, Number),
    Mh = (Width - Length) div 2,
    Ml = Width - Length - Mh, 
    pading(Mh) ++ ?to_s(Number) ++ pading(Ml).

row(print, Sale) ->
    SN = ?v(<<"rsn">>, Sale),
    Total = ?v(<<"total">>, Sale),
    LBalance = ?v(<<"balance">>, Sale, 0),
    SPay = ?v(<<"should_pay">>, Sale, 0),
    EPay = ?v(<<"e_pay">>, Sale, 0),
    VPay = ?v(<<"verificate">>, Sale, 0),
    HPay = ?v(<<"has_pay">>, Sale, 0),
    EDate = ?v(<<"entry_date">>, Sale),

    CBalance = LBalance + SPay + EPay - HPay,
    pading(1) ++ ?to_s(SN) ++ pading(17 - width(latin1, SN)) ++ phd(c)
	++ m(latin1, 6, Total) ++ phd(c)
	++ m(latin1, 8, clean_zero(LBalance)) ++ phd(c)
	++ m(latin1, 6, clean_zero(SPay)) ++ phd(c)
	++ m(latin1, 6, clean_zero(EPay)) ++ phd(c)
	++ m(latin1, 6, clean_zero(VPay)) ++ phd(c)
	++ m(latin1, 6, clean_zero(HPay)) ++ phd(c)
	++ m(latin1, 8, clean_zero(CBalance)) ++ phd(c)
	++ ?to_s(EDate) ++ pading(20 - width(latin1, EDate)) ++ phd(c).
	       
