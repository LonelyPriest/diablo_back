-module(diablo_w_sale_request).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_request).

-export([action/2, action/3, action/4]).

-define(d, ?utils:seperator(csv)).


%%--------------------------------------------------------------------
%% @desc: GET action
%%--------------------------------------------------------------------
action(Session, Req) ->
    %% ?DEBUG("GET Req ~n~p", [Req]),
    %% ?DEBUG("login with client ip:~n ~p", [Req:get(peer)]),
    {ok, HTMLOutput} = wsale_frame:render(
			 [
			  {navbar, ?menu:navbars(?MODULE, Session)},
			  {basebar, ?menu:w_basebar(Session)},
			  {sidebar, sidebar(Session)}
			  %% {ngapp, "wsaleApp1"},
			  %% {ngcontroller, "ng-controller=wsaleCtrl"}
			  %% {baseapp, "baseApp"},
			  %% {basectrl, "baseCtrl"}
			 ]),
    Req:respond({200, [{"Content-Type", "text/html"}], HTMLOutput}).

action(Session, Req, {"get_w_print_content", RSN}) ->
    ?DEBUG("get_w_print_content with session ~p, rsn ~p", [Session, RSN]),
    Merchant = ?session:get(merchant, Session),
    try
	{ok, Sale}     = ?w_sale:sale(get_new, Merchant, RSN),
	{ok, Employee} = ?w_user_profile:get(employee, Merchant, ?v(<<"employ_id">>, Sale)),
	{ok, Retailer} = ?w_user_profile:get(retailer, Merchant, ?v(<<"retailer_id">>, Sale)),

	{ok, Details} = ?w_sale:sale(trans_detail, Merchant, {<<"rsn">>, ?to_b(RSN)}),
	%% {ok, Details}  = ?w_sale:rsn_detail(rsn, Merchant, {<<"rsn">>, ?to_b(RSN)}),
	
	{ok, MerchantInfo} = ?w_user_profile:get(merchant, Merchant),
	{ok, Banks} = ?w_user_profile:get(bank, Merchant),

	ShopId = ?v(<<"shop_id">>, Sale),
	{ok, PSetting} = ?w_user_profile:get(setting, Merchant, ShopId), 
	{ok, PFormat}  = ?w_user_profile:get(print_format, Merchant, ShopId), 
	{ok, ShopInfo} = ?w_user_profile:get(shop, Merchant, ShopId),

	?utils:respond(
	   200, object, Req,
	   {[{<<"ecode">>, 0},
	     {<<"sale">>, {[{<<"employee">>, ?v(<<"name">>, Employee)},
			    {<<"retailer">>, ?v(<<"name">>, Retailer)}
			    |Sale]}},
	     {<<"detail">>, Details},
	     {<<"psetting">>, PSetting},
	     {<<"merchant">>, {MerchantInfo}},
	     {<<"banks">>, Banks},
	     {<<"pformat">>, PFormat},
	     {<<"shop">>, ShopInfo}
	    ]})
    catch
	_:{badmatch, {error, Error}} ->
	    ?utils:respond(200, Req, Error)
    end;

	    
action(Session, Req, {"get_w_sale_new", RSN}) ->
    ?DEBUG("get_w_sale_new with session ~p, paylaod~n~p", [Session, RSN]),
    Merchant = ?session:get(merchant, Session),
    try
	{ok, Sale} = ?w_sale:sale(get_new, Merchant, RSN),
	%% ?DEBUG("sale ~p", [Sale]),
	{ok, Details} = ?w_sale:sale(trans_detail, Merchant, {<<"rsn">>, ?to_b(RSN)}),
	?DEBUG("details ~p", [Details]),
	
	%% sort by style_number and brand
	ShopId = ?v(<<"shop_id">>, Sale),

	{ok, [{Shop}]} = ?w_user_profile:get(shop, Merchant, ShopId),

	RealShop = 
	    case ?v(<<"repo">>, Shop) of
		-1 -> ShopId;
		RepoId -> RepoId
	    end, 
	
	Goods = lists:foldr(
		  fun({D}, Acc) ->
			  S =  {?v(<<"style_number">>, D),
				?v(<<"brand_id">>, D)},
			  case lists:member(S, Acc) of
			      true -> Acc;
			      false -> [S|Acc]
			  end
		  end, [], Details),

	{ok, Abstracts}
	    = case Goods of
		  [] -> {ok, []};
		  _ -> ?w_inventory:purchaser_inventory(abstract, Merchant, RealShop, Goods)
	      end,

	?utils:respond(
	   200, object, Req,
	   {[{<<"ecode">>, 0},
	     {<<"sale">>, {Sale}},
	     {<<"detail">>, Details},
	     {<<"inv">>, Abstracts}]}) 
    catch
	_:{badmatch, {error, Error}} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"get_w_sale_note", RSN}) ->
    ?DEBUG("get_w_sale_note with session ~p, paylaod~n~p", [Session, RSN]),
    Merchant = ?session:get(merchant, Session),
    case ?w_sale:sale(trans_detail, Merchant, {<<"rsn">>, ?to_b(RSN)}) of
	{ok, Notes} ->
	    ?utils:respond(
	       200, object, Req,
	       {[{<<"ecode">>, 0},
		 {<<"data">>, Notes}]});
	Error ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, _Req, Action) ->
    ?DEBUG("receive unkown action ~p with session ~p", [Action, Session]).

%%--------------------------------------------------------------------
%% @desc: POST action
%%--------------------------------------------------------------------
action(Session, Req, {"list_w_sale_new"}, Payload) ->
    ?DEBUG("list_w_sale_new with session ~p, paylaod~n~p", [Session, Payload]), 
    Merchant = ?session:get(merchant, Session), 
    batch_responed(
      fun() -> ?w_sale:sale(list_new, Merchant, Payload) end, Req); 

action(Session, Req, {"get_last_sale"}, Payload) ->
    ?DEBUG("get_last_sale with session ~p, paylaod~n~p", [Session, Payload]), 
    Merchant = ?session:get(merchant, Session),

    case ?w_sale:sale(last, Merchant, Payload) of
	{ok, Last} ->
	    %% ?DEBUG("last ~p", [Last]),
	    ?utils:respond(200, batch, Req, Last);
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"filter_w_sale_new"}, Payload) ->
    ?DEBUG("filter_w_sale_new with session ~p, paylaod~n~p", [Session, Payload]), 
    Merchant = ?session:get(merchant, Session),
    
    ?pagination:pagination(
       fun(Match, Conditions) ->
	       ?w_sale:filter(total_news, ?to_a(Match), Merchant, Conditions)
       end,
       fun(Match, CurrentPage, ItemsPerPage, Conditions) ->
	       ?w_sale:filter(
		  news, Match, Merchant, CurrentPage, ItemsPerPage, Conditions)
       end, Req, Payload);

action(Session, Req, {"filter_w_sale_image"}, Payload) ->
    ?DEBUG("filter_w_sale_image with session ~p, payload~n~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    %% inventory
    {struct, F} = ?v(<<"fields">>, Payload),
    NewPayload = [{<<"fields">>, {struct, proplists:delete(<<"retailer">>, F)}},
		  {<<"page">>, ?v(<<"page">>, Payload)},
		  {<<"count">>, ?v(<<"count">>, Payload)}],
    Result = 
	?pagination:pagination(
	   no_response,
	   fun(Match, Conditions) ->
		   ?w_inventory:filter(total_groups, Match, Merchant, Conditions)
	   end,
	   fun(Match, CurrentPage, ItemsPerPage, Conditions) ->
		   ?w_inventory:filter(
		      groups, Match, Merchant, CurrentPage, ItemsPerPage, Conditions)
	   end, NewPayload),

    case Result of
	{ok, Total, []} ->
	    ?utils:respond(
	       200, object, Req,
	       {[{<<"ecode">>, 0}, {<<"total">>, Total}, {<<"data">>, []}]});
	{ok, Total, Data} ->
	    ?utils:respond(
	       200, object, Req,
	       {[{<<"ecode">>, 0},
		 {<<"total">>, Total},
		 {<<"data">>, Data},
		 {<<"history">>, []}]}); 
	    %% view history of the retailer
	    %% Retailer = ?v(<<"retailer">>, F),
	    %% Goods = lists:foldr(
	    %% 	      fun({Good}, Acc) ->
	    %% 		      [{?v(<<"style_number">>, Good),
	    %% 			?v(<<"brand_id">>, Good)}|Acc]
	    %% 	      end, [], Data),
	    
	    %% case ?w_sale:sale(history_retailer, Merchant, Retailer, Goods) of 
	    %% 	{ok, Histories} ->
	    %% 	    ?utils:respond(
	    %% 	       200, object, Req,
	    %% 	       {[{<<"ecode">>, 0},
	    %% 		 {<<"total">>, Total},
	    %% 		 {<<"data">>, Data},
	    %% 		 {<<"history">>, Histories}]}); 
	    %% 	{error, _Error} ->
	    %% 	    ?utils:respond(200, Req, ?err(wsale_history_failed, Retailer))
	    %% end;
	    
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"new_w_sale"}, Payload) ->
    ?DEBUG("new_w_sale with session ~p, paylaod~n~p", [Session, Payload]),
    
    Merchant = ?session:get(merchant, Session),
    Invs            = ?v(<<"inventory">>, Payload, []),
    {struct, Base}  = ?v(<<"base">>, Payload),
    {struct, Print} = ?v(<<"print">>, Payload),

    ImmediatelyPrint = ?v(<<"im_print">>, Print, ?YES),

    NewInvs = case ?v(<<"sort">>, Base, ?NO) of
		 ?YES -> sort_inventory(onsale, Invs, []);
		 ?NO  -> Invs
	     end,

    ShouldPay = ?v(<<"should_pay">>, Base),
    Round = ?v(<<"round">>, Base),
    
    %% ?DEBUG("NewInvs ~p", [NewInvs]), 
    %% check invs
    case check_inventory(oncheck, Round, 0, ShouldPay, NewInvs) of
	{ok, _} ->
	    case ?w_sale:sale(new, Merchant, NewInvs, Base) of 
		{ok, RSN} ->
		    case ImmediatelyPrint of
			?YES ->
			    SuccessRespone =
				fun(PCode, PInfo) ->
					?utils:respond(
					   200, Req, ?succ(new_w_sale, RSN),
					   [{<<"rsn">>, ?to_b(RSN)},
					    {<<"pcode">>, PCode},
					    {<<"pinfo">>, PInfo}])
				end,
			    print(RSN, Merchant, SuccessRespone);
			?NO ->
			    ?utils:respond(200, Req, ?succ(new_w_sale, RSN),
					   [{<<"rsn">>, ?to_b(RSN)}])
		    end;
		    %% delete draft
		%% ?w_sale_draft:delete(wsale_draft, Merchant, Base);
		{invalid_balance, {Retailer, CurrentBalance, LastBalance}} ->
		    ?utils:respond(200,
				   Req,
				   ?err(wsale_invalid_retailer_balance, Retailer),
				   [{<<"cbalance">>, CurrentBalance},
				    {<<"lbalance">>, LastBalance}]);
		{error, Error} ->
		    ?utils:respond(200, Req, Error)
	    end;
	{error, EInv} ->
	    StyleNumber = ?v(<<"style_number">>, EInv),
	    ?utils:respond(
	       200,
	       Req,
	       ?err(wsale_invalid_inv, StyleNumber),
	       [{<<"style_number">>, StyleNumber},
		{<<"order_id">>, ?v(<<"order_id">>, EInv)}]);
	{error, Moneny, ShouldPay} ->
	    ?utils:respond(
	       200,
	       Req,
	       ?err(wsale_invalid_pay, Moneny))
    end;

action(Session, Req, {"update_w_sale"}, Payload) ->
    ?DEBUG("update_w_sale with session ~p~npaylaod ~p", [Session, Payload]),

    Merchant = ?session:get(merchant, Session),
    Invs            = ?v(<<"inventory">>, Payload, []),
    {struct, Base}  = ?v(<<"base">>, Payload),
    
    case ?w_sale:sale(update, Merchant, lists:reverse(Invs), Base) of
    	{ok, RSN} -> 
    	    ?utils:respond(
	       200, Req, ?succ(update_w_sale, RSN), {<<"rsn">>, ?to_b(RSN)});
    	{error, Error} ->
    	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"check_w_sale"}, Payload) ->
    ?DEBUG("chekc_w_sale with session ~p, paylaod~n~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    RSN = ?v(<<"rsn">>, Payload, []),

    case ?w_sale:sale(check, Merchant, RSN) of
    	{ok, RSN} -> 
    	    ?utils:respond(
	       200, Req, ?succ(check_w_sale, RSN), {<<"rsn">>, ?to_b(RSN)});
    	{error, Error} ->
    	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"uncheck_w_sale"}, Payload) ->
    ?DEBUG("uncheck_w_inventory with session ~p, paylaod~n~p",
	   [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    RSN = ?v(<<"rsn">>, Payload, []), 
    case ?w_sale:sale(uncheck, Merchant, RSN) of
    	{ok, RSN} -> 
    	    ?utils:respond(
	       200,
	       Req,
	       ?succ(uncheck_w_inventory, RSN), {<<"rsn">>, ?to_b(RSN)});
    	{error, Error} ->
    	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"check_w_sale_all"}, Payload) ->
    ?DEBUG("check_w_wsale_all with session ~p, paylaod~n~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    Match = ?v(<<"match">>, Payload),
    {struct, Conditions} = ?v(<<"condition">>, Payload, []),

    case ?w_sale:sale(check_all, Merchant, {?to_a(Match), Conditions}) of
    	{ok, Merchant} -> 
    	    ?utils:respond(
	       200,
	       Req,
	       ?succ(check_w_sale_all, Merchant));
    	{error, Error} ->
    	    ?utils:respond(200, Req, Error)
    end;
    
    
action(Session, Req, {"print_w_sale"}, Payload) ->
    ?DEBUG("print_w_sale with session ~p, paylaod ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    RSN      = ?v(<<"rsn">>, Payload),
    
    %% try
    %% 	{ok, Sale} = ?w_sale:sale(get_new, Merchant, RSN),
    %% 	?DEBUG("sale ~p", [Sale]),
    %% 	{ok, Details} =
    %% 	    ?w_sale:sale(trans_detail, Merchant, {<<"rsn">>, ?to_b(RSN)}),
    %% 	%% {ok, Details} = ?w_sale:rsn_detail(rsn, Merchant, {<<"rsn">>, RSN}),
    %% 	?DEBUG("details ~p", [Details]),

    %% 	{ok, Retailer} = ?w_user_profile:get(
    %% 			    retailer, Merchant, ?v(<<"retailer_id">>, Sale)),
    %% 	{ok, Employee} = ?w_user_profile:get(
    %% 			    employee, Merchant, ?v(<<"employ_id">>, Sale)),
    %% 	{ok, Brands}   = ?w_user_profile:get(brand, Merchant),

    %% 	GetBrand =
    %% 	    fun(BrandId)->
    %% 		    case ?w_user_profile:filter(Brands, <<"id">>, BrandId) of
    %% 			[] -> [];
    %% 			FindBrand -> ?v(<<"name">>, FindBrand)
    %% 		    end
    %% 	    end,
	    
    %% 	SortInvs = sort_inventory(Merchant, GetBrand, Details, []),
    %% 	%% ?DEBUG("sorts ~p", [SortInvs]),
    %% 	RSNAttrs = [{<<"shop">>,       ?v(<<"shop_id">>, Sale)},
    %% 		    {<<"datetime">>,   ?v(<<"entry_date">>, Sale)},
    %% 		    {<<"balance">>,    ?v(<<"balance">>, Sale)},
    %% 		    {<<"cash">>,       ?v(<<"cash">>, Sale)},
    %% 		    {<<"card">>,       ?v(<<"card">>, Sale)},
    %% 		    {<<"wire">>,       ?v(<<"wire">>, Sale)},
    %% 		    {<<"verificate">>, ?v(<<"verificate">>, Sale)},
    %% 		    {<<"should_pay">>, ?v(<<"should_pay">>, Sale)},
    %% 		    {<<"total">>,      ?v(<<"total">>, Sale)},
    %% 		    {<<"comment">>,    ?v(<<"comment">>, Sale)},
    %% 		    {<<"e_pay_type">>, ?v(<<"e_pay_type">>, Sale)},
    %% 		    {<<"e_pay">>,      ?v(<<"e_pay">>, Sale)},
    %% 		    {<<"direct">>,     ?v(<<"type">>, Sale)}],

	
    %% 	%% ?DEBUG("retailer ~p", [Retailer]),
    %% 	%% ?DEBUG("employee ~p", [Employee]),
    %% 	PrintAttrs = [{<<"retailer">>, ?v(<<"name">>, Retailer)},
    %% 		      {<<"retailer_id">>, ?v(<<"retailer_id">>, Sale)},
    %% 		      {<<"employ">>, ?v(<<"name">>, Employee)}], 

    %% 	SuccessRespone =
    %% 	    fun(PCode, PInfo) ->
    %% 		    ?utils:respond(200, Req, ?succ(print_w_sale, RSN),
    %% 		       [{<<"rsn">>, ?to_b(RSN)},
    %% 			{<<"pcode">>, PCode},
    %% 			{<<"pinfo">>, PInfo}])
    %% 	    end,

    %% 	print(RSN, Merchant, SortInvs, RSNAttrs, PrintAttrs, SuccessRespone)
	
    %% 	%% ?utils:respond(
    %% 	%%    200, Req, ?succ(print_w_sale, RSN), {<<"rsn">>, ?to_b(RSN)}) 
    %% catch
    %% 	_:{badmatch, {error, Error}} ->
    %% 	    ?utils:respond(200, Req, Error)
    %% end;

    SuccessRespone =
	fun(PCode, PInfo) ->
		?utils:respond(200, Req, ?succ(print_w_sale, RSN),
			       [{<<"rsn">>, ?to_b(RSN)},
				{<<"pcode">>, PCode},
				{<<"pinfo">>, PInfo}])
	end,
    print(RSN, Merchant, SuccessRespone);


action(Session, Req, {"get_w_sale_print_content"}, Payload) ->
    ?DEBUG("get_w_sale_print_content with session ~p, Payload ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    RSN      = ?v(<<"rsn">>, Payload),
    case ?wifi_print:print(get_content, RSN, Merchant) of
	{ok, Content} ->
	    ?utils:respond(200, Req, ?succ(print_w_sale, RSN),
			   [{<<"content">>, ?to_b(Content)}]);
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

%% =============================================================================
%% draft
%% =============================================================================
action(Session, Req, {"new_w_sale_draft"}, Payload) ->
    ?DEBUG("new_w_sale_draft with session ~p, paylaod~n~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    Invs = ?v(<<"inventory">>, Payload),
    {struct, Base} = ?v(<<"base">>, Payload),

    {ok, SN} = ?w_sale_draft:new(wsale_draft, Merchant, Base, Invs),
    ?utils:respond(200, Req, ?succ(new_w_sale_draft, SN), {<<"rsn">>, ?to_b(SN)});

action(Session, Req, {"list_w_sale_draft"}, Payload) ->
    ?DEBUG("list_w_sale_draft with session ~p, paylaod~n~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    Shop = ?v(<<"shop">>, Payload),
    %% {ok, Drafts} = ?w_sale_draft:lookup(wsale_draft, Merchant, Shop),
    %% ?utils:respond(200, batch, Req, Drafts);
    batch_responed(
      fun() -> ?w_sale_draft:lookup(wsale_draft, Merchant, Shop) end, Req);


action(Session, Req, {"get_w_sale_draft"}, Payload) ->
    ?DEBUG("list_w_sale_draft with session ~p, paylaod~n~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    SN = ?v(<<"sn">>, Payload),

    case ?w_sale_draft:get(wsale_draft, Merchant, SN) of
	{ok, []} ->
	    ?utils:respond(200, Req, ?err(w_sale_draft_not_exist, SN));
	{ok, {Shop, Invs}} ->
	    ?DEBUG("shop ~p, Invs ~p", [Shop, Invs]),

	    %% refrehs inv
	    try
		RefreshInvs = 
		    lists:foldr(
		      fun({struct, Inv}, Acc)->
			      StyleNumber = ?v(<<"style_number">>, Inv),
			      Brand       = ?v(<<"brand">>, Inv),
			      {ok, Total} =
				  ?w_inventory:purchaser_inventory(
				     amount, Merchant, Shop, StyleNumber, Brand),
			      [{struct, Total ++ Inv}|Acc] 
		      end, [], Invs),
		
		{ECode, EInfo} = ?succ(get_w_sale_draft, SN),
		Req:respond({200,
			     [{"Content-Type", "application/json"}],
			     mochijson2:encode(
			       {[{<<"ecode">>, ?to_i(ECode)},
				 {<<"einfo">>, ?to_b(EInfo)},
				 {<<"invs">>, RefreshInvs}]}
			      )})
	    catch
		_:{badmatch, {error, Error}} ->
		    ?utils:respond(200, Req, Error)
	    end 
	    
    end;
	    
%% =============================================================================
%% reject
%% =============================================================================
action(Session, Req, {"reject_w_sale"}, Payload) ->
    ?DEBUG("reject_w_sale with session ~p, paylaod~n~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    Invs = ?v(<<"inventory">>, Payload),
    {struct, Base}   = ?v(<<"base">>, Payload),
    {struct, Print}  = ?v(<<"print">>, Payload),
    ImmediatelyPrint = ?v(<<"im_print">>, Print, ?YES),
    
    ShouldPay = ?v(<<"should_pay">>, Base),
    Round = ?v(<<"round">>, Base),

    case check_inventory(oncheck, Round, 0, ShouldPay, Invs) of
	{ok, _} -> 
	    case ?w_sale:sale(reject, Merchant, lists:reverse(Invs), Base) of 
		{ok, RSN} ->
		    case ImmediatelyPrint of
			?YES ->
			    SuccessRespone =
				fun(PCode, PInfo) ->
					?utils:respond(200, Req, ?succ(reject_w_sale, RSN),
						       [{<<"rsn">>, ?to_b(RSN)},
							{<<"pcode">>, PCode},
							{<<"pinfo">>, PInfo}])
				end,
			    print(RSN, Merchant, SuccessRespone);
			?NO ->
			    ?utils:respond(200, Req, ?succ(reject_w_sale, RSN),
					   [{<<"rsn">>, ?to_b(RSN)}])
		    end;
		{invalid_balance, {Retailer, CurrentBalance, LastBalance}} ->
		    ?utils:respond(200,
				   Req,
				   ?err(wsale_invalid_retailer_balance, Retailer),
				   [{<<"cbalance">>, CurrentBalance},
				    {<<"lbalance">>, LastBalance}]);
		{error, Error} ->
		    ?utils:respond(200, Req, Error)
	    end;
	{error, EInv} ->
	    StyleNumber = ?v(<<"style_number">>, EInv),
	    ?utils:respond(
	       200,
	       Req,
	       ?err(wsale_invalid_inv, StyleNumber),
	       [{<<"style_number">>, StyleNumber},
		{<<"order_id">>, ?v(<<"order_id">>, EInv)}]);
	{error, Moneny, ShouldPay} ->
	    ?utils:respond(
	       200,
	       Req,
	       ?err(wsale_invalid_pay, Moneny))
    end;

action(Session, Req, {"filter_w_sale_rsn_group"}, Payload) ->
    ?DEBUG("filter_w_sale_rsn_group with session ~p, paylaod~n~p", [Session, Payload]), 
    Merchant           = ?session:get(merchant, Session),
    
    %% first, get rsn
    %% {struct, NewConditions} = ?v(<<"fields">>, Payload), 
    
    %% {ok, Q} = ?w_sale:sale(get_rsn, Merchant, NewConditions),
    %% FilterConditions =
    %% 	?w_inventory_request:filter_condition(
    %% 	  trans_note, [?v(<<"rsn">>, Rsn) || {Rsn} <- Q], NewConditions),
    
    %% case FilterConditions of
    %% 	    [] -> ?utils:respond(
    %% 		     200, object, Req, {[{<<"ecode">>, 0},
    %% 					 {<<"total">>, 0},
    %% 					 {<<"data">>, []}]});
    %% 	_ -> 
    %% 	    NewPayload = FilterConditions ++ proplists:delete(<<"fields">>, Payload), 
    
    %% 	    ?pagination:pagination(
    %% 	       fun(Match, Conditions) ->
    %% 		       ?w_sale:filter(total_rsn_group, ?to_a(Match), Merchant, Conditions)
    %% 	       end,
    %% 	       fun(Match, CurrentPage, ItemsPerPage, Conditions) ->
    %% 		       ?w_sale:filter(
    %% 			  rsn_group, Match, Merchant, CurrentPage, ItemsPerPage, Conditions)
    %% 	       end, Req, NewPayload)
    %% end;

    ?pagination:pagination(
       fun(Match, Conditions) ->
    	       ?w_sale:filter(total_rsn_group,
    			      ?to_a(Match), Merchant, Conditions)
       end,
       fun(Match, CurrentPage, ItemsPerPage, Conditions) ->
    	       ?w_sale:filter(
    		  rsn_group,
    		  Match, Merchant, CurrentPage, ItemsPerPage, Conditions)
       end, Req, Payload);

action(Session, Req, {"w_sale_rsn_detail"}, Payload) ->
    ?DEBUG("w_sale_rsn_detail with session ~p, paylaod~n~p", [Session, Payload]),
    
    Merchant = ?session:get(merchant, Session),
    %% RSn = ?v(<<"rsn">>, Payload),
    case ?w_sale:rsn_detail(rsn, Merchant, Payload) of 
    	{ok, Details} ->
	    ?utils:respond(200, object, Req, {[{<<"ecode">>, 0},
					       {<<"data">>, Details}]}); 
    	{error, Error} ->
    	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"w_sale_export"}, Payload) ->
    ?DEBUG("w_sale_export with session ~p, paylaod ~n~p", [Session, Payload]),
    Merchant    = ?session:get(merchant, Session),
    UserId      = ?session:get(id, Session),
    ExportType  = export_type(?v(<<"e_type">>, Payload, 0)),
    
    {struct, Conditions} = ?v(<<"condition">>, Payload),


    %% NewConditions = 
    %% 	case ExportType of
    %% 	    trans_note ->
    %% 		{struct, CutConditions} = ?v(<<"condition">>, Payload),
    %% 		{ok, Q} = ?w_sale:sale(get_rsn, Merchant, CutConditions),
    %% 		{struct, C} =
    %% 		    ?v(<<"fields">>,
    %% 		       ?w_inventory_request:filter_condition(
    %% 			  trans_note, [?v(<<"rsn">>, Rsn) || {Rsn} <- Q], CutConditions)),
    %% 		C;
    %% 	    trans -> Conditions
    %% 	end,
	    
    
    case ?w_sale:export(ExportType, Merchant, Conditions) of
	{ok, []} ->
	    ?utils:respond(200, Req, ?err(wsale_export_no_date, Merchant));
	{ok, Transes} -> 
	    %% write to file 
	    {ok, ExportFile, Url} = ?utils:create_export_file("otrans", Merchant, UserId), 
	    case file:open(ExportFile, [append, raw]) of
		{ok, Fd} -> 
		    try
			DoFun = fun(C) -> ?utils:write(Fd, C) end,
			csv_head(ExportType, DoFun),
			do_write(ExportType, DoFun, 1, Transes),
			ok = file:datasync(Fd),
			ok = file:close(Fd)
		    catch
			T:W -> 
			    file:close(Fd),
			    ?DEBUG("trace export:T ~p, W ~p~n~p", [T, W, erlang:get_stacktrace()]),
			    ?utils:respond(200, Req, ?err(wsale_export_error, W)) 
		    end,
		    ?utils:respond(200, object, Req,
				   {[{<<"ecode">>, 0},
				     {<<"url">>, ?to_b(Url)}]}); 
		{error, Error} ->
		    ?utils:respond(200, Req, ?err(wsale_export_error, Error))
	    end; 
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end. 

sidebar(Session) -> 
    case ?right_request:get_shops(Session, sale) of
	[] ->
	    ?menu:sidebar(level_2_menu, []);
	Shops ->
	    WSale = ?w_inventory_request:authen_shop_action(
		       {?new_w_sale, "new_wsale", "销售开单", "glyphicon glyphicon-usd"}, Shops),
	    
	    SSale = case ?session:get(type, Session) of
			?MERCHANT ->
			    case ?right_auth:authen(?new_s_sale, Session) of
				{ok, ?new_s_sale} -> 
				    [{"new_ssale", "零售开单", "glyphicon glyphicon-yen"}];
				_ -> []
			    end;
			?USER ->
			    ?w_inventory_request:authen_shop_action(
			       {?new_s_sale, "new_ssale", "零售开单", "glyphicon glyphicon-yen"}, Shops)
		    end,

	    WReject = ?w_inventory_request:authen_shop_action(
			 {?reject_w_sale,
			  "reject_wsale", "销售退货", "glyphicon glyphicon-arrow-left"}, Shops), 

	    SaleR =
		[{"new_wsale_detail", "交易记录", "glyphicon glyphicon-download"}],
	    
	    SaleD =
		[{"wsale_rsn_detail", "交易明细", "glyphicon glyphicon-map-marker"}],

	    L1 = ?menu:sidebar(level_1_menu, WSale ++ SSale ++ WReject ++ SaleR ++ SaleD),
	    %% L2 = ?menu:sidebar(level_1_menu, SaleDetail),

	    L1
		
    end. 

%% =============================================================================
%% internal
%% =============================================================================
print(RSN, Merchant, ResponseFun) ->
    %% ResponseFun(0, [{[{<<"device">>, DeviceId}, {<<"ecode">>, 0}]} || DeviceId <- [1] ]).
    case ?wifi_print:print(RSN, Merchant) of 
    	{Success, []} ->
	    PInfo = [{[{<<"device">>, DeviceId}, {<<"ecode">>, 0}]}
    		     || DeviceId <- Success],
    	    ResponseFun(0, PInfo); 
    	{[], Failed} ->
    	    PInfo = [{[{<<"device">>, DeviceId}, {<<"ecode">>, ECode}]}
    		     || {DeviceId, ECode} <- Failed],
    	    ResponseFun(1, PInfo); 
    	{error, {ECode, _EInfo}} ->
    	    ?DEBUG("error, ecode ~p, einfo ~p", [ECode, _EInfo]),
    	    ResponseFun(ECode, []);
    	{_Success, Failed} when is_list(Failed)->
    	    ?DEBUG("Success ~p, Failed ~p", [_Success, Failed]),
    	    PInfo = [{[{<<"device">>, DeviceId}, {<<"ecode">>, ECode}]}
    		     || {DeviceId, ECode} <- Failed],
    	    ResponseFun(2, PInfo)
    end.
    


batch_responed(Fun, Req) ->
    case Fun() of
	{ok, Values} ->
	    ?utils:respond(200, batch, Req, Values);
	{error, _Error} ->
	    ?utils:respond(200, batch, Req, [])
    end.

%% filter_condition(trans_note, [], _Conditions) ->
%%     [];
%% filter_condition(trans_note, Rsns, Conditions) ->
%%     [{<<"fields">>, {
%% 	  struct, [{<<"rsn">>, Rsns}]
%% 	  ++ lists:foldr(
%% 	       fun({<<"style_number">>, _}=S, Acc) ->
%% 		       [S|Acc];
%% 		  ({<<"brand">>, _}=B, Acc) ->
%% 		       [B|Acc];
%% 		  ({<<"firm">>, _}=F, Acc) ->
%% 		       [F|Acc];
%% 		  ({<<"type">>, _}=T, Acc) ->
%% 		       [T|Acc];
%% 		  ({<<"year">>, _}=Y, Acc) ->
%% 		       [Y|Acc];
%% 		  (_, Acc) ->
%% 		       Acc
%% 	       end, [], Conditions)}}].

%% object_responed(Fun, Req) ->
%%     case Fun() of
%% 	{ok, Value} ->
%% 	    ?utils:respond(200, object, Req, {Value});
%% 	{error, Error} ->
%% 	    ?utils:respond(200, Req, Error)
%%     end.

csv_head(trans, Do) ->
    Do("序号,单号,交易类型,门店,店员,客户,数量,现金,刷卡,汇款,核销,费用,帐户欠款,应付,实付,本次欠款,备注,开单日期");
csv_head(trans_note, Do) ->
    Do("序号,单号,交易类型,门店,客户,款号,品牌,类型,厂商,数量,价格,折扣,小计,备注,日期").


do_write(trans, _Do, _Count, [])->
    ok;
do_write(trans, Do, Count, [H|T]) ->
    Rsn       = ?v(<<"rsn">>, H),
    Type      = ?v(<<"type">>, H),
    Shop      = ?v(<<"shop">>, H),
    Employee  = ?v(<<"employee">>, H),
    Retailer  = ?v(<<"retailer">>, H), 
    Total     = ?v(<<"total">>, H),
    Cash      = ?v(<<"cash">>, H),
    Card      = ?v(<<"card">>, H),
    Wire      = ?v(<<"wire">>, H),
    Verify    = ?v(<<"verificate">>, H),
    EPay      = ?v(<<"e_pay">>, H),
    LBalance  = ?to_f(?v(<<"balance">>, H)),
    ShouldPay = ?v(<<"should_pay">>, H),
    HasPay    = ?v(<<"has_pay">>, H), 
    Comment   = ?v(<<"comment">>, H),
    Date      = ?v(<<"entry_date">>, H),

    CBalance  = ?to_f(LBalance + ShouldPay + EPay - HasPay),
    %% ?DEBUG("CBalance ~p", [CBalance]),

    L = "\r\n"
	++ ?to_s(Count) ++ ?d
	++ ?to_s(Rsn) ++ ?d
	++ sale_type(Type) ++ ?d
	++ ?to_s(Shop) ++ ?d
	++ ?to_s(Employee) ++ ?d
	++ ?to_s(Retailer) ++ ?d
	++ ?to_s(Total) ++ ?d
	++ ?to_s(Cash) ++ ?d
	++ ?to_s(Card) ++ ?d 
	++ ?to_s(Wire) ++ ?d
	++ ?to_s(Verify) ++ ?d
	++ ?to_s(EPay) ++ ?d
	++ ?to_s(LBalance) ++ ?d
	++ ?to_s(ShouldPay) ++ ?d
	++ ?to_s(HasPay) ++ ?d
	++ ?to_s(CBalance) ++ ?d
	++ ?to_s(Comment) ++ ?d
	++ ?to_s(Date),
	%% ++ ?to_s(Date),
    Do(L),
    do_write(trans, Do, Count + 1, T);

do_write(trans_note, _Do, _Count, [])->
    ok;
do_write(trans_note, Do, Count, [H|T]) ->
    Rsn         = ?v(<<"rsn">>, H),
    SType        = ?v(<<"sell_type">>, H),
    Shop        = ?v(<<"shop">>, H),
    %% Employee    = ?v(<<"employee">>, H),
    Retailer    = ?v(<<"retailer">>, H),
    StyleNumber = ?v(<<"style_number">>, H),
    Brand       = ?v(<<"brand">>, H), 
    Type        = ?v(<<"type">>, H),
    Firm        = ?v(<<"firm">>, H),
    
    Total       = ?v(<<"total">>, H), 
    FPrice      = ?v(<<"fprice">>, H), 
    FDiscount   = ?v(<<"fdiscount">>, H),

    %% ?DEBUG("FDiscount ~p, FPrice ~p, Total ~p, rsn ~p", [FDiscount, FPrice, Total, Rsn]),
    Calc        = ?to_f(case FDiscount of
			    <<>> -> 100;
			    _ -> FDiscount
			end * FPrice * Total * 0.01), 
    Comment   = ?v(<<"comment">>, H),
    Date      = ?v(<<"entry_date">>, H),
    
    L = "\r\n"
	++ ?to_s(Count) ++ ?d
	++ ?to_s(Rsn) ++ ?d
	++ sale_type(SType) ++ ?d
	++ ?to_s(Shop) ++ ?d
	%% ++ ?to_s(Employee) ++ ?d
	++ ?to_s(Retailer) ++ ?d
	++ ?to_s(StyleNumber) ++ ?d
	++ ?to_s(Brand) ++ ?d
	++ ?to_s(Type) ++ ?d
	++ ?to_s(Firm) ++ ?d
	++ ?to_s(Total) ++ ?d 
	%% ++ ?to_s(Color) ++ ?d
	%% ++ ?to_s(Size) ++ ?d
	++ ?to_s(FPrice) ++ ?d 
	++ ?to_s(FDiscount) ++ ?d
	++ ?to_s(Calc) ++ ?d 
	++ ?to_s(Comment) ++ ?d
	++ ?to_s(Date),
    %% ++ ?to_s(Date),
    Do(L),
    do_write(trans_note, Do, Count + 1, T).
    
sale_type(0) -> "开单";
sale_type(1) -> "退货";
sale_type(2) -> "零售".

export_type(0) -> trans;
export_type(1) -> trans_note.


sort_inventory(onsale, [], Sorts) ->
    Sorts;
sort_inventory(onsale, [{struct, Inv}|T], Sorts) ->
    %% ?DEBUG("Inv ~p~n, sorts ~p", [Inv, Sorts]),
    NewSorts =
	case in_sort(onsale, Inv, Sorts) of
	    false ->
		[{struct, Inv}|Sorts];
	    true ->
		lists:foldr(
		  fun({struct, S}, Acc)->
			  StyleNumber     = ?v(<<"style_number">>, Inv),
			  Brand           = ?v(<<"brand">>, Inv),
			  Amounts         = ?v(<<"amounts">>, Inv),
			  SellTotal       = ?v(<<"sell_total">>, Inv),

			  SortStyleNumber = ?v(<<"style_number">>, S),
			  SortBrand       = ?v(<<"brand">>, S),
			  SortAmounts     = ?v(<<"amounts">>, S),
			  SortSellTotal   = ?v(<<"sell_total">>, S),

			  case StyleNumber =:= SortStyleNumber
			      andalso Brand =:= SortBrand of
			      true ->
				  NewAmounts = 
				      lists:foldr(
					fun({struct, A}, _Acc) -> 
						%% ?DEBUG("A ~p, SortAmounts ~p", [A, SortAmounts]),
						sort_amount(onsale, A, SortAmounts, [])
					end, [], Amounts),

				  %% ?DEBUG("newamounts ~p", [NewAmounts]),
				  NewInv =
				      [{<<"sell_total">>, SortSellTotal + SellTotal},
				       {<<"amounts">>, NewAmounts}]
				      ++ proplists:delete(<<"sell_total">>,
							  proplists:delete(<<"amounts">>, S)),
				  [{struct, NewInv}|Acc];
			      false ->
				  [{struct, S}|Acc]
			  end
		  end, [], Sorts)
	end,
    %% NewSorts = in_sort(onsale, Inv, Sorts, []),
    %% ?DEBUG("newsorts ~p", [NewSorts]),
    sort_inventory(onsale, T, NewSorts).

in_sort(onsale, _Inv, []) ->
    false;
in_sort(onsale, Inv, [{struct, Sorted}|T]) ->
    StyleNumber     = ?v(<<"style_number">>, Inv),
    Brand           = ?v(<<"brand">>, Inv),
    %% Amounts         = ?v(<<"amounts">>, Inv),
    %% SellTotal       = ?v(<<"sell_total">>, Inv),
    
    SortStyleNumber = ?v(<<"style_number">>, Sorted),
    SortBrand       = ?v(<<"brand">>, Sorted),
    %% SortAmounts     = ?v(<<"amounts">>, Sorted),
    %% SortSellTotal   = ?v(<<"sell_total">>, Sorted), 
    case StyleNumber =:= SortStyleNumber
	andalso Brand =:= SortBrand of
	true  -> true; 
	false -> in_sort(onsale, Inv, T)
    end.

sort_amount(onsale, [], [], Acc) ->
    Acc;
sort_amount(onsale, Amount, [], Acc) ->
    [{struct, Amount}|Acc];
sort_amount(onsale, [], [{struct, Sorted}|T],  Acc) ->
    sort_amount(onsale, [], T, [{struct, Sorted}|Acc]);
sort_amount(onsale, Amount, [{struct, Sorted}|T], Acc) ->
    Cid   = ?v(<<"cid">>, Amount),
    Size  = ?v(<<"size">>, Amount),
    Count = ?v(<<"sell_count">>, Amount),

    SCid   = ?v(<<"cid">>, Sorted),
    SSize  = ?v(<<"size">>, Sorted),
    SCount = ?v(<<"sell_count">>, Sorted),

    case Cid =:= SCid andalso Size =:= SSize of
	true  ->
	    sort_amount(onsale, [], T,
			[{struct, [{<<"cid">>, SCid},
				   {<<"size">>, SSize},
				   {<<"sell_count">>, Count + SCount}
				  ]}|Acc]);
	false ->
	    sort_amount(onsale, Amount, T, [{struct, Sorted}|Acc])
    end.

    
check_inventory(oncheck, _Round, Moneny, ShouldPay, []) ->
    ?DEBUG("Moneny ~p, ShouldPay, ~p", [Moneny, ShouldPay]),
    case round(Moneny) == ShouldPay of
	true -> {ok, none};
	false -> {error, round(Moneny), ShouldPay}
    end;
check_inventory(oncheck, Round, Money, ShouldPay, [{struct, Inv}|T]) ->
    Amounts = ?v(<<"amounts">>, Inv), 
    Count = ?v(<<"sell_total">>, Inv),
    StyleNumber = ?v(<<"style_number">>, Inv),
    DCount = lists:foldr(
	      fun({struct, A}, Acc)->
		      case ?w_sale:direct(?v(<<"direct">>, A)) of
			  wreject ->  ?v(<<"reject_count">>, A) + Acc;
			  _ -> ?v(<<"sell_count">>, A) + Acc
		     end
	      end, 0, Amounts),
    
    FDiscount = ?v(<<"fdiscount">>, Inv),
    FPrice = ?v(<<"fprice">>, Inv),
    Calc = case Round of
	       1 -> round(FDiscount * FPrice * Count / 100);
	       0 -> FDiscount * FPrice * Count / 100;
	       undefined -> FDiscount * FPrice * Count / 100
	   end,
    
    case Count =:= DCount andalso StyleNumber =/= undefined of
	true -> check_inventory(oncheck, Round, Money + Calc, ShouldPay, T); 
	false -> {error, Inv}
    end.	    
	    

    
    
						    
