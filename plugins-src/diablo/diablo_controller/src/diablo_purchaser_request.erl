-module(diablo_purchaser_request).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_request).

-export([action/2, action/3, action/4]).
-export([authen/2, authen_shop_action/2, filter_condition/3]).

-define(d, ?utils:seperator(csv)).

%%--------------------------------------------------------------------
%% @desc: GET action
%%--------------------------------------------------------------------
action(Session, Req) ->
    %% ?DEBUG("GET Req ~n~p", [Req]),
    {ok, HTMLOutput} = purchaser_frame:render(
			 [
			  {navbar, ?menu:navbars(?MODULE, Session)},
			  {basebar, ?menu:w_basebar(Session)},
			  {sidebar, sidebar(Session)},
			  {ngapp, "purchaserApp"},
			  {ngcontroller, "purchaserCtrl"}]),
    Req:respond({200, [{"Content-Type", "text/html"}], HTMLOutput}).

%%--------------------------------------------------------------------
%% @desc: GET action
%%--------------------------------------------------------------------
action(Session, Req, {"get_w_inventory_new", RSN}) ->
    ?DEBUG("get_w_inventory_new whith Session ~p, RSN ~p", [Session, RSN]),
    Merchant = ?session:get(merchant, Session), 
    object_responed(
      fun() -> ?w_inventory:purchaser_inventory(get_new, Merchant, RSN) end, Req);
    
action(Session, _Req, Unkown) ->
    ?DEBUG("receive unkown message ~p with session~n~p", [Unkown, Session]).


%% =============================================================================
%% new
%% =============================================================================
action(Session, Req, {"new_w_inventory"}, Payload) ->
    ?DEBUG("new purchaser inventory with session ~p, paylaod~n~p",
	   [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    Invs = ?v(<<"inventory">>, Payload, []),
    {struct, Base} = ?v(<<"base">>, Payload),
    
    case ?w_inventory:purchaser_inventory(
	    new, Merchant, lists:reverse(Invs), Base) of
    	{ok, RSn} -> 
    	    ?utils:respond(
	       200,
	       Req,
	       ?succ(add_purchaser_inventory, RSn),
	       {<<"rsn">>, ?to_b(RSn)});
    	{error, Error} ->
    	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"update_w_inventory"}, Payload) ->
    ?DEBUG("update purchaser inventory with session~n~p, paylaod~n~p",
	   [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    Invs = ?v(<<"inventory">>, Payload, []),
    {struct, Base} = ?v(<<"base">>, Payload),

    case ?w_inventory:purchaser_inventory(
	    update, Merchant, lists:reverse(Invs), Base) of
    	{ok, RSn} -> 
    	    ?utils:respond(
	       200,
	       Req,
	       ?succ(update_w_inventory, RSn),
	       {<<"rsn">>, ?to_b(RSn)});
    	{error, Error} ->
    	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"check_w_inventory"}, Payload) ->
    ?DEBUG("check_w_inventory with session ~p, paylaod~n~p",
	   [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    RSN = ?v(<<"rsn">>, Payload, []),
    
    case ?w_inventory:purchaser_inventory(check, Merchant, RSN) of
    	{ok, RSN} -> 
    	    ?utils:respond(
	       200,
	       Req,
	       ?succ(check_w_inventory, RSN),
	       {<<"rsn">>, ?to_b(RSN)});
    	{error, Error} ->
    	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"filter_w_inventory_new"}, Payload) -> 
    ?DEBUG("filter_w_inventory_new with session ~p, paylaod~n~p",
	   [Session, Payload]),
    
    Merchant = ?session:get(merchant, Session),
    ?pagination:pagination(
       fun(Match, Conditions) ->
	       ?w_inventory:filter(
		  total_news, ?to_a(Match), Merchant, Conditions)
       end,
       fun(Match, CurrentPage, ItemsPerPage, Conditions) ->
	       ?w_inventory:filter(
		  news, Match, Merchant, CurrentPage, ItemsPerPage, Conditions)
       end, Req, Payload);


action(Session, Req, {"filter_w_inventory_new_rsn_group"}, Payload) ->
    ?DEBUG("filter_w_inventory_new_rsn_group with session ~p, paylaod~n~p",
	   [Session, Payload]),

    Merchant  = ?session:get(merchant, Session),
    %% first, get rsn
    %% {struct, NewConditions} = ?v(<<"fields">>, Payload),

    %% {ok, Q} = ?w_inventory:purchaser_inventory(get_inventory_new_rsn, Merchant, NewConditions),
    %% FilterConditions =
    %% 	filter_condition(trans_note, [?v(<<"rsn">>, Rsn) || {Rsn} <- Q], NewConditions),

    %% case FilterConditions of
    %% 	[] -> ?utils:respond(
    %% 		 200, object, Req, {[{<<"ecode">>, 0}, {<<"total">>, 0}, {<<"data">>, []}]});
    %% 	_ -> 
    %% 	    NewPayload = FilterConditions ++ proplists:delete(<<"fields">>, Payload), 
    %% 	     ?pagination:pagination(
    %% 		fun(Match, Conditions) ->
    %% 			?w_inventory:filter(
    %% 			   total_new_rsn_groups, ?to_a(Match), Merchant, Conditions)
    %% 		end,
    %% 		fun(Match, CurrentPage, ItemsPerPage, Conditions) ->
    %% 			?w_inventory:filter(
    %% 			   new_rsn_groups, Match, Merchant,
    %% 			   CurrentPage, ItemsPerPage, Conditions)
    %% 		end, Req, NewPayload)
    %% end;

    ?pagination:pagination(
       fun(Match, Conditions) ->
	       ?w_inventory:filter(
		  total_new_rsn_groups, ?to_a(Match), Merchant, Conditions)
       end,
       fun(Match, CurrentPage, ItemsPerPage, Conditions) ->
	       ?w_inventory:filter(
		  new_rsn_groups, Match, Merchant,
		  CurrentPage, ItemsPerPage, Conditions)
       end, Req, Payload);

action(Session, Req, {"w_inventory_new_rsn_detail"}, Payload) ->
    ?DEBUG("w_inventory_rsn_detail with session ~p, paylaod~n~p",
	   [Session, Payload]),

    Merchant = ?session:get(merchant, Session),
    %% RSn = ?v(<<"rsn">>, Payload),
    case ?w_inventory:rsn_detail(new_rsn, Merchant, Payload) of 
    	{ok, Details} ->
	    ?utils:respond(200, object, Req, {[{<<"ecode">>, 0},
					       {<<"data">>, Details}]}); 
    	{error, Error} ->
    	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"get_w_inventory_new_amount"}, Payload) ->
    ?DEBUG("get_new_amount_detail with session ~p, paylaod~n~p",
	   [Session, Payload]),

    Merchant = ?session:get(merchant, Session),
    %% RSn = ?v(<<"rsn">>, Payload),
    case ?w_inventory:purchaser_inventory(
	    get_new_amount, Merchant, Payload) of 
    	{ok, Details} ->
	    ?utils:respond(200, object, Req, {[{<<"ecode">>, 0},
					       {<<"data">>, Details}]}); 
    	{error, Error} ->
    	    ?utils:respond(200, Req, Error)
    end;

    
%% =============================================================================
%% reject
%% =============================================================================
action(Session, Req, {"reject_w_inventory"}, Payload) ->
    ?DEBUG("reject purchasr inventory with session ~p, paylaod~n~p",
	   [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    Invs = ?v(<<"inventory">>, Payload),
    {struct, Base} = ?v(<<"base">>, Payload),
    case ?w_inventory:purchaser_inventory(
	    reject, Merchant, lists:reverse(Invs), Base) of 
    	{ok, RSn} ->
	    ?utils:respond(
	       200,
	       Req,
	       ?succ(reject_w_inventory, RSn),
	       {<<"rsn">>, ?to_b(RSn)});
    	{error, Error} ->
    	    ?utils:respond(200, Req, Error)
    end;

%% action(Session, Req, {"filter_w_inventory_reject"}, Payload) -> 
%%     ?DEBUG("filter_w_inventory_reject with session ~p, paylaod~n~p", [Session, Payload]),

%%     Merchant = ?session:get(merchant, Session),
%%     ?pagination:pagination(
%%        fun(Match, Conditions) ->
%% 	       ?w_inventory:filter(total_rejects, ?to_a(Match), Merchant, Conditions)
%%        end,
%%        fun(Match, CurrentPage, ItemsPerPage, Conditions) ->
%% 	       ?w_inventory:filter(
%% 		  rejects, Match, Merchant, CurrentPage, ItemsPerPage, Conditions)
%%        end, Req, Payload); 

%% action(Session, Req, {"filter_w_inventory_reject_rsn_group"}, Payload) ->
%%     ?DEBUG("filter_w_inventory_reject_rsn_group with session ~p, paylaod~n~p",
%% 	   [Session, Payload]),

%%     Merchant  = ?session:get(merchant, Session),
%%     ?pagination:pagination(
%%        fun(Match, Conditions) ->
%% 	       ?w_inventory:filter(total_reject_rsn_groups, ?to_a(Match), Merchant, Conditions)
%%        end,
%%        fun(Match, CurrentPage, ItemsPerPage, Conditions) ->
%% 	       ?w_inventory:filter(
%% 		  reject_rsn_groups, Match, Merchant, CurrentPage, ItemsPerPage, Conditions)
%%        end, Req, Payload);


%% action(Session, Req, {"w_inventory_reject_rsn_detail"}, Payload) ->
%%     ?DEBUG("w_inventory_rsn_detail with session ~p, paylaod~n~p", [Session, Payload]),

%%     Merchant = ?session:get(merchant, Session),
%%     %% RSn = ?v(<<"rsn">>, Payload),
%%     case ?w_inventory:rsn_detail(reject_rsn, Merchant, Payload) of 
%%     	{ok, Details} ->
%% 	    ?utils:respond(200, object, Req, {[{<<"ecode">>, 0},
%% 					       {<<"data">>, Details}]}); 
%%     	{error, Error} ->
%%     	    ?utils:respond(200, Req, Error)
%%     end;

%% =============================================================================
%% inventory
%% ============================================================================= 
action(Session, Req, {"filter_w_inventory_group"}, Payload) -> 
    ?DEBUG("filter_w_inventory_group with session ~p, paylaod~n~p", [Session, Payload]), 
    Merchant = ?session:get(merchant, Session),
    Mode     = ?v(<<"mode">>, Payload, 0),
    
    ?pagination:pagination(
       fun(Match, Conditions) ->
	       ?w_inventory:filter(total_groups, Match, Merchant, Conditions)
       end,
       fun(Match, CurrentPage, ItemsPerPage, Conditions) ->
	       ?w_inventory:filter(
		  {groups, mode(Mode)}, Match, Merchant,
		  CurrentPage, ItemsPerPage, Conditions)
       end, Req, Payload); 

action(Session, Req, {"list_w_inventory"}, Payload) ->
    ?DEBUG("list purchaser inventory with session ~p, paylaod~n~p",
	   [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    batch_responed(
      fun() -> ?w_inventory:purchaser_inventory(list, Merchant, Payload) end, Req);

%% =============================================================================
%% fix
%% =============================================================================
action(Session, Req, {"fix_w_inventory"}, Payload) ->
    ?DEBUG("fix_w_inventory with session ~p, paylaod~n~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    Invs = ?v(<<"inventory">>, Payload, []),
    {struct, Base} = ?v(<<"base">>, Payload),
    case ?w_inventory:purchaser_inventory(fix, Merchant, lists:reverse(Invs), Base) of 
    	{ok, RSn} ->
	    ?utils:respond(200, Req, ?succ(fix_w_inventory, RSn), {<<"rsn">>, ?to_b(RSn)});
    	{error, Error} ->
    	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"filter_fix_w_inventory"}, Payload) -> 
    ?DEBUG("filter_fix_w_inventory with session ~p, paylaod~n~p", [Session, Payload]),

    Merchant = ?session:get(merchant, Session),
    ?pagination:pagination(
       fun(Match, Conditions) ->
	       ?w_inventory:filter(total_fix, ?to_a(Match), Merchant, Conditions)
       end,
       fun(Match, CurrentPage, ItemsPerPage, Conditions) ->
	       ?w_inventory:filter(
		  fix, Match, Merchant, CurrentPage, ItemsPerPage, Conditions)
       end, Req, Payload);

action(Session, Req, {"filter_w_inventory_fix_rsn_group"}, Payload) ->
    ?DEBUG("filter_w_inventory_fix_rsn_group with session ~p, paylaod~n~p",
	   [Session, Payload]),

    Merchant  = ?session:get(merchant, Session),
    
    ?pagination:pagination(
       fun(Match, Conditions) ->
	       ?w_inventory:filter(total_fix_rsn_groups, ?to_a(Match), Merchant, Conditions)
       end,
       fun(Match, CurrentPage, ItemsPerPage, Conditions) ->
	       ?w_inventory:filter(
		  fix_rsn_groups, Match, Merchant, CurrentPage, ItemsPerPage, Conditions)
       end, Req, Payload);
    

action(Session, Req, {"w_inventory_fix_rsn_detail"}, Payload) ->
    ?DEBUG("w_inventory_rsn_detail with session ~p, paylaod~n~p", [Session, Payload]),

    Merchant = ?session:get(merchant, Session),
    %% RSn = ?v(<<"rsn">>, Payload),
    case ?w_inventory:rsn_detail(fix_rsn, Merchant, Payload) of 
    	{ok, Details} ->
	    ?utils:respond(200, object, Req, {[{<<"ecode">>, 0},
					       {<<"data">>, Details}]}); 
    	{error, Error} ->
    	    ?utils:respond(200, Req, Error)
    end;


%% =============================================================================
%% transfer
%% =============================================================================
action(Session, Req, {"transfer_w_inventory"}, Payload) ->
    ?DEBUG("transfer purchasr inventory with session~n~p, paylaod~n~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    Invs = ?v(<<"inventory">>, Payload),
    {struct, Base} = ?v(<<"base">>, Payload),
    case ?w_inventory:purchaser_inventory(transfer, Merchant, lists:reverse(Invs), Base) of 
    	{ok, RSn} ->
	    ?utils:respond(200, Req, ?succ(transfer_w_inventory, RSn), {<<"rsn">>, ?to_b(RSn)});
    	{error, Error} ->
    	    ?utils:respond(200, Req, Error)
    end;


action(Session, Req, {"filter_transfer_w_inventory"}, Payload) -> 
    ?DEBUG("filter_transfer_w_inventory with session ~p, paylaod~n~p", [Session, Payload]),

    Merchant = ?session:get(merchant, Session),
    ?pagination:pagination(
       fun(Match, Conditions) ->
	       ?w_inventory:filter(total_transfer, ?to_a(Match), Merchant, Conditions)
       end,
       fun(Match, CurrentPage, ItemsPerPage, Conditions) ->
	       ?w_inventory:filter(
		  transfer, Match, Merchant, CurrentPage, ItemsPerPage, Conditions)
       end, Req, Payload);


action(Session, Req, {"filter_transfer_rsn_w_inventory"}, Payload) ->
    ?DEBUG("filter_transfer_rsn_w_inventory with session ~p~n, paylaod~n~p",
	   [Session, Payload]),

    Merchant  = ?session:get(merchant, Session),

    ?pagination:pagination(
       fun(Match, Conditions) ->
	       ?w_inventory:filter(total_transfer_rsn_groups,
				   ?to_a(Match), Merchant, Conditions)
       end,
       fun(Match, CurrentPage, ItemsPerPage, Conditions) ->
	       ?w_inventory:filter(
		  transfer_rsn_groups,
		  Match, Merchant, CurrentPage, ItemsPerPage, Conditions)
       end, Req, Payload);


action(Session, Req, {"w_inventory_transfer_rsn_detail"}, Payload) ->
    ?DEBUG("w_inventory_transfer_rsn_detail with session ~p~n, paylaod~n~p",
	   [Session, Payload]),

    Merchant = ?session:get(merchant, Session),
    %% RSn = ?v(<<"rsn">>, Payload),
    case ?w_inventory:rsn_detail(transfer_rsn, Merchant, Payload) of 
    	{ok, Details} ->
	    ?utils:respond(200, object, Req, {[{<<"ecode">>, 0},
					       {<<"data">>, Details}]}); 
    	{error, Error} ->
    	    ?utils:respond(200, Req, Error)
    end;


action(Session, Req, {"check_w_inventory_transfer"}, Payload) ->
    ?DEBUG("check_w_inventory_transfer with session ~p, paylaod~n~p",
	   [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    %% RSN = ?v(<<"rsn">>, Payload),
    %% TShop = ?v(<<"tshop">>, Payload),

    case ?w_inventory:purchaser_inventory(
	    check_transfer, Merchant, Payload) of
    	{ok, RSN} -> 
    	    ?utils:respond(
	       200,
	       Req,
	       ?succ(check_w_inventory_transfer, RSN),
	       {<<"rsn">>, ?to_b(RSN)});
    	{error, Error} ->
    	    ?utils:respond(200, Req, Error)
    end;
%% =============================================================================
%% match
%% =============================================================================
action(Session, Req, {"match_all_w_inventory"}, Payload) ->
    ?DEBUG("match_all_w_inventory with session ~p, paylaod~n~p",
	   [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    Shop     = ?v(<<"shop">>, Payload),
    NewPayload = proplists:delete(<<"shop">>, Payload),
    batch_responed(
      fun() -> ?w_inventory:match(inventory, all_inventory, Merchant, Shop, NewPayload) end, Req);

action(Session, Req, {"match_all_reject_w_inventory"}, Payload) ->
    ?DEBUG("match_all_reject_w_inventory with session ~p, paylaod~n~p",
	   [Session, Payload]),
    Merchant   = ?session:get(merchant, Session),
    Shop       = ?v(<<"shop">>, Payload),
    Firm       = ?v(<<"firm">>, Payload, []),
    QType      = ?v(<<"type">>, Payload, 0),
    StartTime  = ?v(<<"start_time">>, Payload),

    batch_responed(
      fun() -> ?w_inventory:match(
		  all_reject_inventory, QType, Merchant, Shop, Firm, StartTime) end, Req);


action(Session, Req, {"match_w_inventory"}, Payload) ->
    ?DEBUG("match_w_inventory with session ~p~npayload ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    StyleNumber = ?v(<<"prompt">>, Payload),
    Shop        = ?v(<<"shop">>, Payload),
    Firm        = ?v(<<"firm">>, Payload),
    QType       = ?v(<<"type">>, Payload, 0),

    Match = fun() when Firm =:= undefined->
		    ?w_inventory:match(
		       inventory, QType, Merchant, StyleNumber, Shop);
	       () ->
		    ?w_inventory:match(
		       inventory, QType, Merchant, StyleNumber, Shop, Firm)
	    end,
    
    batch_responed(Match, Req);

action(Session, Req, {"w_inventory_export"}, Payload) ->
    ?DEBUG("w_inventory_export with session ~p, paylaod ~n~p", [Session, Payload]),
    Merchant    = ?session:get(merchant, Session),
    UserId      = ?session:get(id, Session),
    ExportType  = export_type(?v(<<"e_type">>, Payload, 0)),

    {struct, Conditions} = ?v(<<"condition">>, Payload),

    ExportColor = case ?w_user_profile:get(setting, Merchant, -1, <<"e_color">>) of
		      {ok, []} -> false;
		      {ok, _} -> true
		  end,

    NewConditions = 
	case ExportType of
	    trans_note ->
		{struct, CutConditions} = ?v(<<"condition">>, Payload),
		{ok, Q} = ?w_inventory:purchaser_inventory(
			     get_inventory_new_rsn, Merchant, CutConditions),
		{struct, C} =
		    ?v(<<"fields">>,
		       filter_condition(
			 trans_note, [?v(<<"rsn">>, Rsn) || {Rsn} <- Q], CutConditions)),
		C;
	    trans -> Conditions;
	    stock -> [{<<"export_color">>, ExportColor}|Conditions]
	end,


    case ?w_inventory:export(ExportType, Merchant, NewConditions) of
	{ok, []} ->
	    ?utils:respond(200, Req, ?err(wsale_export_none, Merchant));
	{ok, Transes} -> 
	    %% write to file
	    %% ?DEBUG("export transes ~p", [Transes]),
	    {ok, ExportFile, Url}
		= ?utils:create_export_file("itrans", Merchant, UserId),
	    
	    case file:open(ExportFile, [append, raw]) of
		{ok, Fd} -> 
		    try
			DoFun = fun(C) -> ?utils:write(Fd, C) end,
			case ExportType of
			    stock ->
				ExportSizes = export_size_group(Merchant),
				%% ?DEBUG("export sizes ~p", [ExportSizes]),
				{ok, Colors} = ?w_user_profile:get(color, Merchant),

				NewTranses = sort_stock(Transes, ExportColor, []),
				%% ?DEBUG("newTranses ~p", [NewTranses]),
				csv_head(stock, ExportColor, ExportSizes, DoFun),
				case ExportColor of
				    true ->
					do_write(stock, ExportSizes, Colors,
						 DoFun, NewTranses);
				    false ->
					do_write(stock, DoFun, NewTranses)
				end;
			    _ ->
				csv_head(ExportType, DoFun),
				do_write(ExportType, DoFun, Transes)
			end,
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
    case ?right_request:get_shops(Session, inventory) of
	[] ->
	   ?menu:sidebar(level_1_menu,[]);
	Shops ->
	    %% Order = 
	    %% 	case ?inventory_request:shop_action(?new_w_order, Shops) of
	    %% 	    [] -> [];
	    %% 	    _ ->
	    %% 		[] 
	    %% 	end,

	    
	    Record = authen_shop_action(
		       {?new_w_inventory,
			"inventory_new",
			"采购入库",
			"glyphicon glyphicon-shopping-cart"}, Shops),

	    Reject = authen_shop_action(
		       {?reject_w_inventory,
			"inventory_reject",
			"采购退货",
			"glyphicon glyphicon-arrow-left"},
		       Shops),

	    TransR = [{"inventory_new_detail",
		       "采购记录",
		       "glyphicon glyphicon-download"}],
	    TransD = [{"inventory_rsn_detail",
		       "采购明细",
		       "glyphicon glyphicon-map-marker"}],

	    InvDetail = [{"inventory_detail",
			  "库存详情",
			  "glyphicon glyphicon-book"}], 
	    
	    %% Record =
	    %% 	[{{"record", "采购入库", "glyphicon glyphicon-shopping-cart"},
	    %% 	  authen_shop_action(
	    %% 	    {?new_w_inventory, "inventory_new", "入库", "glyphicon glyphicon-plus"}, Shops)
	    %% 	  ++ [{"inventory_new_detail", "入库详情", "glyphicon glyphicon-briefcase"},
	    %% 	      {"inventory_rsn_detail/new", "入库明细", "glyphicon glyphicon-map-marker"}] 
	    %% 	 }],

	    %% Reject = 
	    %% 	[{{"record", "采购退货", "glyphicon glyphicon-plane"}, 
	    %% 	  authen_shop_action(
	    %% 	    {?reject_w_inventory,
	    %% 	     "inventory_reject", "退货", "glyphicon glyphicon-arrow-left"}, Shops)
	    %% 	  ++ [{"inventory_reject_detail",
	    %% 	       "退货详情", "glyphicon glyphicon-briefcase"},
	    %% 	      {"inventory_rsn_detail/reject",
	    %% 	       "退货明细", "glyphicon glyphicon-map-marker"}]
	    %%  }],

	    Transfer =
		[
		 {{"inventory", "库存转移", "glyphicon glyphicon-transfer"},
		  authen_shop_action(
		    {?transfer_w_inventory,
		     "inventory_transfer",
		     "移仓",
		     "glyphicon glyphicon-transfer"},
		    Shops) 
		  ++ [{"inventory_transfer_from_detail",
		       "调出记录",
		       "glyphicon glyphicon-circle-arrow-left"},
		      {"inventory_transfer_to_detail",
		       "调入记录",
		       "glyphicon glyphicon-circle-arrow-right"},

		      {"inventory_rsn_detail/transfer_from",
		       "调出明细",
		       "glyphicon glyphicon-superscript"},
		      {"inventory_rsn_detail/transfer_to",
		       "调入明细",
		       "glyphicon glyphicon-subscript"}
		      ] 
		 }],

	    %% Transfer = authen_shop_action(
	    %% 		 {?transfer_w_inventory,
	    %% 		  "inventory_transfer",
	    %% 		  "库存转移",
	    %% 		  "glyphicon glyphicon-transfer"},
	    %% 		 Shops),
	    
	    InvMgr =
		[
		 {{"inventory", "库存盘点", "glyphicon glyphicon-check"},
		  authen_shop_action(
		       {?fix_w_inventory,
			"inventory_fix",
			"盘点",
			"glyphicon glyphicon-check"},
		    Shops) 
		  ++ [{"inventory_fix_detail",
		       "盘点记录",
		       "glyphicon glyphicon-tasks"},
		      {"inventory_rsn_detail/fix",
		       "盘点明细",
		       "glyphicon glyphicon-leaf"}] 
		 }],

	    Level1 = ?menu:sidebar(
			level_1_menu,
			Record
			++ Reject
			++ TransR
			++ TransD
			++ InvDetail),
	    
	    Level2 = ?menu:sidebar(level_2_menu, Transfer ++ InvMgr),
	    Level1 ++ Level2
	    %% ?menu:sidebar(level_2_menu, Order ++ Record ++ Reject ++ InvMgr) 
    end.

authen_shop_action({Action, Path, Name}, Shops) ->
    case ?inventory_request:shop_action(Action, Shops) of
	[] -> [];
	_  -> [{Path, Name}]
    end;

authen_shop_action({Action, Path, Name, Icon}, Shops) ->
    case ?inventory_request:shop_action(Action, Shops) of
	[] -> [];
	_  -> [{Path, Name, Icon}]
    end.

authen(Actions, Session) ->
    authen(Actions, Session, []).
authen([], _Session, Acc) ->
    lists:reverse(Acc);
authen([Action|T], Session, Acc) ->
    {Id, Path, Desc} = Action,
    case ?right_auth:authen(Id, Session) of
	{ok, Id} ->
	    authen(T, Session, [{Path, Desc}|Acc]);
	_ ->
	    authen(T, Session, Acc)
    end.

batch_responed(Fun, Req) ->
    case Fun() of
	{ok, Values} ->
	    ?utils:respond(200, batch, Req, Values);
	{error, _Error} ->
	    ?utils:respond(200, batch, Req, [])
    end.

object_responed(Fun, Req) ->
    case Fun() of
	{ok, Value} ->
	    ?utils:respond(200, object, Req, {Value});
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end.

filter_condition(trans_note, [], _Conditions) ->
    [];
filter_condition(trans_note, Rsns, Conditions) ->
    [{<<"fields">>, {
	  struct, [{<<"rsn">>, Rsns}]
	  ++ lists:foldr(
	       fun({<<"style_number">>, _}=S, Acc) ->
		       [S|Acc];
		  ({<<"brand">>, _}=B, Acc) ->
		       [B|Acc];
		  ({<<"firm">>, _}=F, Acc) ->
		       [F|Acc];
		  ({<<"type">>, _}=T, Acc) ->
		       [T|Acc];
		  ({<<"year">>, _}=Y, Acc) ->
		       [Y|Acc];
		  (_, Acc) ->
		       Acc
	       end, [], Conditions)}}].


csv_head(trans, Do) ->
    Do("序号,单号,厂商,门店,入单员,采购,数量,现金,刷卡,汇款,核销,费用,帐户欠款,应付,实付,本次欠款,备注,日期");
csv_head(trans_note, Do) ->
    Do("序号,单号,厂商,门店,店员,交易类型,款号,品牌,类型,折扣,数量,日期").
csv_head(stock, _ExportColor = true, Sizes, Do) ->
    StringSizes = 
	lists:foldr(
	  fun(S, Acc) ->
		  case S =:= 0 of
		      true -> "均码";
		      false -> ?to_s(S)
		  end ++ "," ++ Acc
	  end, [], Sizes),
    
    Do("品牌,款号,类别,颜色," ++ StringSizes ++ "数量,批发价,金额");
csv_head(stock, _ExportColor = false, _Sizes, Do) ->
    Do("品牌,款号,类别,厂商,数量,进价,金额").


do_write(ExportType, Do, Transes) ->
    do_write(ExportType, Do, 1, 0, 0, Transes).
do_write(trans, _Do, _Count, _Amount, _Calc, [])->
    ok;
do_write(trans, Do, Count, Amount, Calc, [H|T]) ->
    Rsn       = ?v(<<"rsn">>, H),
    Firm      = ?v(<<"firm">>, H),
    Shop      = ?v(<<"shop">>, H),
    Employee  = ?v(<<"employee">>, H),
    Type      = ?v(<<"type">>, H), 
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
	++ ?to_s(Firm) ++ ?d
	++ ?to_s(Shop) ++ ?d
	++ ?to_s(Employee) ++ ?d
	++ purchaser_type(Type) ++ ?d 
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
    do_write(trans, Do, Count + 1, Amount, Calc, T);

do_write(trans_note, _Do, _Count, _Amount, _Calc, [])->
    ok;
do_write(trans_note, Do, Count, Amount, Calc, [H|T]) ->
    Rsn         = ?v(<<"rsn">>, H),
    Firm        = ?v(<<"firm">>, H), 
    Shop        = ?v(<<"shop">>, H),
    Employee    = ?v(<<"employee">>, H),
    InType        = ?v(<<"in_type">>, H),

    StyleNumber = ?v(<<"style_number">>, H),
    Brand       = ?v(<<"brand">>, H), 
    Type        = ?v(<<"type">>, H),
    Total       = ?v(<<"total">>, H), 

    %% Color       = ?v(<<"color">>, H),
    %% Size        = ?v(<<"size">>, H),
    Discount   = ?v(<<"discount">>, H),
    %% FPrice      = ?v(<<"fprice">>, H),

    %% Comment   = ?v(<<"comment">>, H),
    Date      = ?v(<<"entry_date">>, H),

    L = "\r\n"
	++ ?to_s(Count) ++ ?d
	++ ?to_s(Rsn) ++ ?d
	++ ?to_s(Firm) ++ ?d
	++ ?to_s(Shop) ++ ?d
	++ ?to_s(Employee) ++ ?d
	++ purchaser_type(InType) ++ ?d
	
	++ ?to_s(StyleNumber) ++ ?d
	++ ?to_s(Brand) ++ ?d
	++ ?to_s(Type) ++ ?d
	
    %% ++ ?to_s(Color) ++ ?d
    %% ++ ?to_s(Size) ++ ?d
    %% ++ ?to_s(FPrice) ++ ?d 
    %% ++ ?to_s(FDiscount) ++ ?d
	++ ?to_s(Discount) ++ ?d 
	++ ?to_s(Total) ++ ?d
    %% ++ ?to_s(Calc) ++ ?d 
    %% ++ ?to_s(Comment) ++ ?d
	++ ?to_s(Date),
    %% ++ ?to_s(Date),
    Do(L),
    do_write(trans_note, Do, Count + 1, Amount, Calc, T);

do_write(stock, Do, _Count, Amount, Calc, [])->
    ?DEBUG("amount ~p, calc ~p", [Amount, Calc]),
    L = "\r\n" ++ csv(space, [], 4)
	++ ?to_s(Amount) ++ ?d
	++ csv(space, [], 1)
	++ ?to_s(round(Calc)),
    Do(L);
do_write(stock, Do, Count, Amount, Calc, [H|T]) ->
    ?DEBUG("do_write stock count ~p", [Count]),
    StyleNumber = ?v(<<"style_number">>, H),
    Brand       = ?v(<<"brand">>, H), 
    Type        = ?v(<<"type">>, H),
    Firm        = ?v(<<"firm">>, H),
    OrgPrice    = ?v(<<"org_price">>, H),
    %% TagPrice    = ?v(<<"tag_price">>, H),
    %% PkgPrice    = ?v(<<"pkg_price">>, H),
    %% Discount    = ?v(<<"discount">>, H),
    Total       = ?v(<<"total">>, H),

    L = "\r\n"
	++ ?to_s(Brand) ++ ?d
	++ " \"" ++ string:strip(?to_s(StyleNumber)) ++ "\"" ++ ?d
	++ ?to_s(Type) ++ ?d
	++ ?to_s(Firm) ++ ?d
	++ ?to_s(Total) ++ ?d
	++ ?to_s(OrgPrice) ++ ?d
	++ ?to_s(OrgPrice * Total) ++ ?d,
	
	
    Do(L),
    do_write(stock, Do, Count + 1, Amount + Total, Calc + OrgPrice * Total, T).
    
do_write(stock,  _ExportSizes, _AllColors, _Do, [])->
    ok;
do_write(stock, ExportSizes, AllColors, Do, [{struct, H}|T]) -> 
    %% ?DEBUG("H ~p", [H]),
    StyleNumber = ?v(<<"style_number">>, H),
    Brand       = ?v(<<"brand">>, H), 
    Type        = ?v(<<"type">>, H),
    %% Color       = color(name, ?v(<<"color_id">>, H), AllColors),
    %% Size        = ?v(<<"size">>, H),
    PkgPrice    = ?v(<<"pkg_price">>, H), 
    %% Total       = ?v(<<"total">>, H),

    Amounts     = ?v(<<"amounts">>, H),
    ColorIds    = ?v(<<"color_ids">>, H),

    Sorts = 
	lists:foldr(
	  fun(CId, Acc)->
		  [{CId, sort_by_color(CId, ExportSizes, Amounts)}|Acc]
	  end, [], ColorIds),
    %% ?DEBUG("sorts ~p", [Sorts]),

    lists:foreach(
      fun({CId, Counts})-> 
	      {Total1, Row} =
		  lists:foldr(
		    fun(C, {Calc1, Acc1})->
			    {C + Calc1, case C =:= 0 of
					    true -> "\"\"" ++ ?d;
					    false -> ?to_s(C) ++ ?d
					end ++ Acc1}
		    end, {0, []}, Counts),

	      NewRow = 
		  "\r\n"
		  ++ ?to_s(Brand) ++ ?d 
		  ++ " \"" ++ string:strip(?to_s(StyleNumber)) ++ "\"" ++ ?d
		  ++ ?to_s(Type) ++ ?d
		  ++ color(name, CId, AllColors) ++ ?d
		  ++ Row
		  ++ ?to_s(Total1) ++ ?d
		  ++ ?to_s(PkgPrice) ++ ?d
		  ++ ?to_s(Total1 * PkgPrice),

	      Do(NewRow)
      end, Sorts),
    
    do_write(stock, ExportSizes, AllColors, Do, T).

sort_stock([], _ExportColor, Sorts) ->
    Sorts;
sort_stock(Transe, ExportColor=false, _Sorts) ->
    sort_stock([], ExportColor, Transe);
sort_stock([{Inv}|T], ExportColor=true, Sorts) ->
    case in_sort(Inv, Sorts) of
	false  ->
	    StyleNumber = ?v(<<"style_number">>, Inv),
	    BrandId     = ?v(<<"brand_id">>, Inv),
	    Brand       = ?v(<<"brand">>, Inv),
	    
	    
	    Type        = ?v(<<"type">>, Inv),
	    ColorId     = ?v(<<"color_id">>, Inv), 
	    Size        = ?v(<<"size">>, Inv),
	    Count       = ?v(<<"total">>, Inv),

	    ColorIds    = [ColorId],
	    
	    PkgPrice    = ?v(<<"pkg_price">>, Inv),

	    Amounts = [{struct, [{<<"cid">>, ColorId},
				 {<<"size">>, Size},
				 {<<"count">>, Count}]}], 

	    NewInv = {struct, [{<<"style_number">>, StyleNumber},
			       {<<"brand_id">>, BrandId},
			       %% {<<"brand_name">>, ?v(<<"brand">>, Inv)},
			       {<<"brand">>, Brand},
			       {<<"type">>,  Type},
			       {<<"pkg_price">>, PkgPrice},
			       {<<"color_ids">>, ColorIds},
			       {<<"amounts">>,    Amounts}]},
	    %% ?DEBUG("new inv ~p", [NewInv]),
	    sort_stock(T, ExportColor, [NewInv|Sorts]);
	true ->
	    NewSorts = combine_inventory(Inv, Sorts, []),
	    sort_stock(T, ExportColor, NewSorts)
    end.

in_sort(_Inv, []) ->
    false;
in_sort(Inv, [{struct, H}|T]) ->
    StyleNumber = ?v(<<"style_number">>, H),
    BrandId     = ?v(<<"brand_id">>, H),
    case ?v(<<"style_number">>, Inv) =:= StyleNumber
	andalso ?v(<<"brand_id">>, Inv) =:= BrandId of
	true ->
	    true;
	false ->
	    in_sort(Inv, T)
    end.
                                                    
combine_inventory(_Inv, [], Combines) ->
    Combines;
combine_inventory(Inv, [{struct, H}|T], Combines) ->
    %% ?DEBUG("combine inv ~p", [Inv]),
    StyleNumber = ?v(<<"style_number">>, H),
    BrandId     = ?v(<<"brand_id">>, H),

    case ?v(<<"style_number">>, Inv) =:= StyleNumber
	andalso ?v(<<"brand_id">>, Inv) =:= BrandId of
	true -> 
	    ColorId = ?v(<<"color_id">>, Inv),
	    Size    = ?v(<<"size">>, Inv),
	    Count   = ?v(<<"total">>, Inv),


	    ColorIds = ?v(<<"color_ids">>, H), 
	    NewColorIds = case lists:member(ColorId, ColorIds) of
			      true -> ColorIds;
			      false -> [ColorId|ColorIds]
			  end,
	    %% ?DEBUG("new color Ids ~p", [NewColorIds]),

	    Amounts = ?v(<<"amounts">>, H),
	    
	    {Found, FoundAmounts} = 
		lists:foldr(fun({struct, A}, {F, Acc})->
				    case ?v(<<"cid">>, A) =:= ColorId
					andalso ?v(<<"size">>, A) =:= Size of
					true ->
					    {true, [{struct,
						     [{<<"cid">>, ColorId},
						      {<<"size">>, Size}, 
						      {<<"count">>,
						       Count + ?v(<<"count">>, A)}
						     ]}|Acc]};
					false ->
					    {F, [{struct, A}|Acc]}
				    end
			    end, {false, []}, Amounts),

	    %% ?DEBUG("found ~p, FoundAmounts ~p", [Found, FoundAmounts]),
	    
	    NewAmounts = case Found of
			     true -> FoundAmounts;
			     false ->
				 [{struct, [{<<"cid">>, ColorId},
					    {<<"size">>, Size}, 
					    {<<"count">>, Count}]}
				  |Amounts]
			 end,

	    combine_inventory(Inv, T,
	      [{struct, [{<<"style_number">>, StyleNumber},
			 {<<"brand_id">>, BrandId},
			 %% {<<"brand_name">>, ?v(<<"brand">>, Inv)},
			 {<<"brand">>,      ?v(<<"brand">>, H)},
			 {<<"type">>,       ?v(<<"type">>, H)},
			 {<<"pkg_price">>,  ?v(<<"pkg_price">>, H)},
			 {<<"color_ids">>,  NewColorIds},
			 {<<"amounts">> ,   NewAmounts}]}|Combines]);
	false ->
	    combine_inventory(Inv, T, [{struct, H}|Combines])
    end.

sort_by_color(CId, Sizes, Amounts)->
    sort_by_color(CId, Sizes, Amounts, []).

sort_by_color(_CId, [], _Amounts, Counts)->
    lists:reverse(Counts);
sort_by_color(CId, [Size|T], Amounts, Counts)->
    C = get_amount(CId, Size, Amounts),
    sort_by_color(CId, T, Amounts, [C|Counts]).

get_amount(_CId, _Size, []) ->
    0;
get_amount(CId, Size, [{struct, Amount}|T]) ->
    case ?v(<<"cid">>, Amount) =:= CId
	andalso ?to_s(?v(<<"size">>, Amount)) =:= ?to_s(Size) of
	true -> 
	       ?v(<<"count">>, Amount);
	false ->
	    get_amount(CId, Size, T)
    end.

export_type(0) -> trans;
export_type(1) -> trans_note;
export_type(2) -> stock.

purchaser_type(0) -> "入库";
purchaser_type(1)-> "退货".

%% sex(0) ->"女"; 
%% sex(1) ->"男".

%% season(0) -> "春";
%% season(1) -> "夏";
%% season(2) -> "秋";
%% season(3) -> "冬".

mode(0) -> use_id;
mode(1) -> use_sell.

csv(space, S, 0) ->
    S;
csv(space, S, Num) ->
    csv(space, "\"\"" ++ ?d ++ S, Num -1).


export_size_group(Merchant) ->
    {ok, BaseSettings} = ?w_user_profile:get(setting, Merchant),
    ExportGroups = 
	lists:foldr(
	  fun({S}, Acc) ->
		  case ?v(<<"ename">>, S) =:= <<"e_sgroup1">>
		      orelse ?v(<<"ename">>, S) =:= <<"e_sgroup2">> of
		      true ->
			  [?v(<<"value">>, S)|Acc];
		      false ->
			  Acc
		  end
	  end, [], BaseSettings),

    F = fun(S) when S =:= <<>> -> [];
	   (S) when S =:= [] -> [];
	   (S) -> [S]
	end,

    FlatternSizes = 
	lists:foldr(
	  fun(G, Acc)->
		  {ok, Size} = ?w_user_profile:get(size_group, Merchant, ?to_i(G)),
		  ?DEBUG("size ~p", [Size]),
		  case Size of
		      [] -> Acc;
		      _ ->
			  SI   = ?v(<<"si">>, Size),
			  SII  = ?v(<<"sii">>, Size),
			  SIII = ?v(<<"siii">>, Size),
			  SIV  = ?v(<<"siv">>, Size),
			  SV   = ?v(<<"sv">>, Size),
			  SVI  = ?v(<<"svi">>, Size),
			  F(SI) ++ F(SII) ++ F(SIII)
			      ++ F(SIV) ++ F(SV) ++ F(SVI) ++ Acc
		  end
	  end, [], ExportGroups),

    %% ?DEBUG("flattern sizes ~p", [FlatternSizes]),
    case FlatternSizes of
	[] -> [0];
	_ -> lists:usort(FlatternSizes)
    end.

color(name, _ColorId, []) ->
    []; 
color(name, ColorId, [{H}|T]) ->
    case ?v(<<"id">>, H) =:= ColorId of
	true -> ?to_s(?v(<<"name">>, H));
	false -> color(name, ColorId, T)
    end.
	    
