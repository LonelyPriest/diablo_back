-module(diablo_controller_inventory_request).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_request).

-export([action/2, action/3, action/4]).
-export([get_shops/1, shop_action/2]).

%% -export([sort_inventory/2, seperator/2]).

action(Session, Req) ->
    {ok, HTMLOutput} = inventory_frame:render(
			 [
			  {navbar, ?menu:navbars(?MODULE, Session)},
			  {sidebar, sidebar(Session)},
			  {ngapp, "inventoryApp"},
			  {ngcontroller, "inventoryCtrl"}]),
    Req:respond({200, [{"Content-Type", "text/html"}], HTMLOutput}).


%%--------------------------------------------------------------------
%% @desc: GET action
%%--------------------------------------------------------------------
action(Session, Req, {"list_color"}) ->
    ?DEBUG("list_color with session ~p", [Session]),
    Merchant = ?session:get(merchant, Session),
    Colors = ?inventory:inventory(color, Merchant),
    ?utils:respond(200, batch, Req, Colors);

action(Session, Req, {"list_brand"}) ->
    ?DEBUG("list_brand with session ~p", [Session]),
    Merchant = ?session:get(merchant, Session),
    Brands = ?supplier:lookup(brand, {<<"merchant">>, Merchant}),
    %% Brands = ?inventory:inventory(brand, Merchant),
    ?utils:respond(200, batch, Req, Brands);

action(Session, Req, {"list_type"}) ->
    ?DEBUG("list_type with session ~p", [Session]),
    Merchant = ?session:get(merchant, Session),
    Types = ?inventory:inventory(type, Merchant),
    ?utils:respond(200, batch, Req, Types);

action(Session, Req, {"list_shop"}) ->
    ?DEBUG("list_shop with session ~p", [Session]),
    Merchant = ?session:get(merchant, Session),
    {ok, Shops} = ?shop:lookup(Merchant),
    ?utils:respond(200, batch, Req, Shops);
    
action(Session, Req, {"list_inventory"}) ->
    ?DEBUG("list_inventory with session ~p", [Session]),
    Merchant = ?session:get(merchant, Session),
    Inventories = 
	case ?session:get(type, Session) of
	    ?MERCHANT ->
		?inventory:lookup(by_merchant, Merchant);
	    ?USER ->
		ShopIds = shops(user, Session),
		?inventory:lookup(by_shop, ShopIds, Merchant)
	end,

    %% Sorted = sort_inventory(Inventories, []),
    %% ?DEBUG("sorted inventory~n~p", [Sorted]),
    %% ordered
    ?utils:respond(200, batch, Req, Inventories);

action(Session, Req, {"list_inventory", ShopId}) ->
    ?DEBUG("list_inventory with session ~p, ShopId ~p", [Session, ShopId]),
    Merchant = ?session:get(merchant, Session),
    Inventories = ?inventory:lookup(by_shop, ?to_integer(ShopId), Merchant),

    %% Sorted = sort_inventory(Inventories, []),

    %% add seperator of sorted inventories
    %% Seperator = seperator(Sorted, []),
    %% ?DEBUG("sorted sepertor ~n~p", [Seperator]),
    
    ?utils:respond(200, batch, Req, Inventories);

action(Session, Req, {"list_move_inventory"}) ->
    ?DEBUG("list_move_inventory with session ~p", [Session]),
    Merchant = ?session:get(merchant, Session),
    Inventories = ?inventory:lookup(move, Merchant),
    ?utils:respond(200, batch, Req, Inventories);

action(Session, Req, {"list_reject_inventory"}) ->
    ?DEBUG("list_reject_inventory with session ~p", [Session]),
    Merchant = ?session:get(merchant, Session),
    Inventories = ?inventory:lookup(reject, Merchant),
    ?utils:respond(200, batch, Req, Inventories);

action(Session, Req, {"list_by_style_number", StyleNumber})->
    ?DEBUG("list_inventory_by_style_number with session ~p, styleNumber ~p",
	   [Session, StyleNumber]),
    Merchant = ?session:get(merchant, Session),
    Inventories = ?inventory:lookup(by_style_number, StyleNumber, Merchant),
    ?utils:respond(200, batch, Req, Inventories);

action(Session, Req, {"list_style_number"}) ->
    ?DEBUG("list_style_number with session ~p", [Session]),
    Merchant = ?session:get(merchant, Session),
    case ?session:get(type, Session) of
	?MERCHANT ->
	    Numbers =  ?inventory:lookup(style_number, Merchant),
	    ?utils:respond(200, batch, Req, Numbers);
	?USER ->
	    ShopIds = shops(user, Session),
	    Numbers = ?inventory:lookup(style_number_with_shop, Merchant, ShopIds),
	    ?utils:respond(200, batch, Req, Numbers)
    end;
    
action(Session, Req, {"list_style_number_of_shop", ShopId}) ->
    ?DEBUG("list_style_number_of_shop with session ~p, ShopId ~p",
	   [Session, ShopId]),
    Merchant = ?session:get(merchant, Session),    
    Numbers = ?inventory:lookup(style_number_with_shop, Merchant, ?to_i(ShopId)),
    ?utils:respond(200, batch, Req, Numbers);


action(Session, Req, {"list_size_group"}) ->
    ?DEBUG("list_size_group with session ~p", [Session]),
    Merchant = ?session:get(merchant, Session),    
    Groups = ?inventory:lookup(size_group, Merchant),
    ?utils:respond(200, batch, Req, Groups);

%%--------------------------------------------------------------------
%% @desc: DELETE action
%%--------------------------------------------------------------------
action(Session, Req, {"delete_inventory", Id}) ->
    ?DEBUG("delete_inventory with session ~p, Id ~p", [Session, Id]),
    case ?inventory:inventory(delete, {<<"id">>, ?to_integer(Id)}) of
	ok ->
	    ?utils:respond(200, Req, ?succ(delete_inventory, Id));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end.

%% ================================================================================
%% POST
%% ================================================================================
action(Session, Req, {"new_inventory"}, Payload) ->
    ?DEBUG("new_inventory with session ~p, paylaod ~tp",
	   [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    case ?inventory:inventory(new, [{<<"merchant">>, Merchant}|Payload]) of
	{ok, Number} ->
	    ?utils:respond(200, Req, ?succ(add_inventory, Number));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"update_inventory"}, Payload) ->
    ?DEBUG("update_inventory with session ~p, payload ~p", [Session, Payload]),
    %% ColorId = 
    %% 	case ?value(<<"color">>, Payload) of
    %% 	    undefined -> undefined;
    %% 	    ColorName ->
    %% 		?inventory:inventory(get_color_id, ColorName)
    %% 	end,

    %% Attrs =
    %% 	case ColorId of
    %% 	    undefined -> Payload;
    %% 	    ColorId ->
    %% 		[{<<"color">>, ColorId}|proplists:delete(<<"color">>, Payload)]
    %% 	end,

    Merchant = ?session:get(merchant, Session),
    case ?inventory:inventory(update, [{<<"merchant">>, Merchant}|Payload]) of
	ok ->
	    ?utils:respond(
	       200, Req, ?succ(update_inventory, ?v(<<"style_number">>, Payload)));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

%%
%% size group
%%
action(Session, Req, {"new_size_group"}, Payload) ->
    ?DEBUG("new_size_group with session ~p, paylaod ~tp",
	   [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    case ?inventory:size_group(new, [{<<"merchant">>, Merchant}|Payload]) of
	ok ->
	    ?utils:respond(200, Req, ?succ(add_size_group, none));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"update_size_group"}, Payload) ->
    ?DEBUG("new_size_group with session ~p, paylaod ~tp",
	   [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    case ?inventory:size_group(update, [{<<"merchant">>, Merchant}|Payload]) of
	ok ->
	    ?utils:respond(
	       200, Req, ?succ(update_size_group, ?value(<<"gid">>, Payload)));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"del_size_group"}, Payload) ->
    ?DEBUG("del_size_group with session ~p, paylaod ~tp",
	   [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    case ?inventory:size_group(delete, [{<<"merchant">>, Merchant}|Payload]) of
	ok ->
	    ?utils:respond(
	       200, Req, ?succ(delete_size_group, ?value(<<"gid">>, Payload)));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

%%
%% check
%%
action(Session, Req, {"check_inventory"}, Payload) ->
    ?DEBUG("check_inventory with session ~p~npaylaod ~p",
	   [Session, Payload]),
    Merchant = ?session:get(merchant, Session),

    %% color Id
    %% ColorId = 
    %% 	case ?value(<<"color">>, Payload) of
    %% 	    undefined -> undefined;
    %% 	    ColorName ->
    %% 		?inventory:inventory(get_color_id, ColorName)
    %% 	end,
    
    Attrs = [{<<"check_date">>, ?to_b(?utils:current_time(localtime))},
	     {<<"check_state">>, 1},
	     {<<"merchant">>, Merchant}|Payload],
    
    
    case ?inventory:inventory(check, Attrs) of
	ok ->
	    ?utils:respond(200, Req,
			   ?succ(check_inventory, ?session:get(name, Session)));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"move_inventory"}, Payload) ->
    ?DEBUG("move_inventory with session ~p~npayload ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    case ?inventory:inventory(pre_move, [{<<"merchant">>, Merchant}|Payload]) of
	{ok, Sn} ->
	    ?utils:respond(200, Req, ?succ(pre_move_inventory, Sn));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"do_move_inventory"}, Payload) ->
    ?DEBUG("do_move_inventory with session ~p~npayload ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    Sn = ?value(<<"sn">>, Payload),
    %% inventory has been moved
    case ?inventory:lookup(
	    move, Merchant, [{<<"sn">>, ?to_binary(Sn)}, {<<"state">>, ?MOVING}]) of
	[] ->
	    ?utils:respond(200, Req, ?err(move_inventory_moved, Sn));
	_ ->
	    case ?inventory:inventory(
		    do_move, [{<<"merchant">>, Merchant}|Payload]) of
		{ok, Sn} ->
		    ?utils:respond(200, Req, ?succ(do_move_inventory, Sn));
		{error, Error} ->
		    ?utils:respond(200, Req, Error)
	    end	
    end;

action(Session, Req, {"reject_inventory"}, Payload) ->
    ?DEBUG("reject inventory with session ~p~npayload ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    case ?inventory:inventory(
	    do_reject, [{<<"merchant">>, Merchant}|Payload]) of
	{ok, Sn} ->
	    ?utils:respond(200, Req, ?succ(do_reject_inventory, Sn));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;


action(Session, Req, {"list_by_style_number_and_shop"}, Payload)->
    ?DEBUG("list_by_style_number_and_shop with~nsession ~p~n, payload ~p",
	   [Session, Payload]),
    Merchant    = ?session:get(merchant, Session),
    StyleNumber = ?value(<<"style_number">>, Payload),
    Shop        = ?value(<<"shop">>, Payload),
    Inventories
	= ?inventory:lookup(by_style_number_and_shop, Merchant, StyleNumber, Shop),
    ?utils:respond(200, batch, Req, Inventories);

action(Session, Req, {"list_inventory_by_group"}, Payload)->
    ?DEBUG("list_by_group with~nsession ~p~n, payload ~p", [Session, Payload]),
    Merchant    = ?session:get(merchant, Session),
    %% StyleNumber = ?v(<<"style_number">>, Payload),
    %% Brand       = ?v(<<"brand">>, Payload),
    %% Shop        = ?v(<<"shop">>, Payload),
    Inventories = ?inventory:lookup(by_group, Merchant, Payload),
    ?utils:respond(200, batch, Req, Inventories);

action(Session, Req, {"list_unchecked_inventory_group"}, Payload) ->
    ?DEBUG("list_unchecked with~nsession ~p~n, payload ~p",
	   [Session, Payload]),
    Merchant    = ?session:get(merchant, Session),
    Shop        = ?value(<<"shop">>, Payload),
    %% SizeGroup   = ?value(<<"group">>, Payload),    
    Inventories = ?inventory:lookup(unchecked, Shop, Merchant),
    ?utils:respond(200, batch, Req, Inventories);

%%
%% adjust price
%%
action(Session, Req, {"list_inventory_with_condition"}, Payload) ->
    ?DEBUG("list_inventory_with_condition with session~p~npayload ~p",
	   [Session, Payload]),
    Merchant    = ?session:get(merchant, Session),
    Field = ?value(<<"name">>, Payload),
    Value = ?value(<<"value">>, Payload),
    Inventories = 
	?inventory:lookup(by_condition, {?to_b(Field), Value}, Merchant),
    ?utils:respond(200, batch, Req, Inventories);

action(Session, Req, {"adjust_price"}, Payload) ->
    ?DEBUG("addjust_price with session ~p~npayload ~p", [Session, Payload]),
    Merchant    = ?session:get(merchant, Session),
    Price = case ?value(<<"price">>, Payload) of
		undefined -> [];
		P0 -> [{<<"plan_price">>, P0}]
	    end,
    Discount = case ?value(<<"discount">>, Payload) of
		   undefined -> [];
		   P1 -> [{<<"discount">>, P1}]
	       end,
    
    {struct, Style} = ?value(<<"style">>, Payload),
    case ?inventory:inventory(
	    adjust_price, Price ++ Discount,
	    [{<<"merchant">>, Merchant},
	     {?value(<<"name">>, Style), ?value(<<"value">>, Style)}]) of
	ok -> ?utils:respond(
		 200, Req, ?succ(adjust_price, ?value(<<"name">>, Style)));
	{error, Error} ->
	    ?utils:respond(200, Req, ?succ(adjust_price, Error))
    end;
    
%% =============================================================================
%% pagination
%% =============================================================================
action(Session, Req, {"list_by_pagination"}, Payload) ->
    ?DEBUG("list_by_pagination with~nsession ~p~n, payload ~p",
	   [Session, Payload]),
    %% page settings
    CurrentPage  = ?value(<<"page">>, Payload),
    CountPerPage = ?value(<<"count">>, Payload),
    Shop         = ?value(<<"shop">>, Payload),

    Merchant = ?session:get(merchant, Session),
    Inventories = 
	case ?session:get(type, Session) of
	    ?MERCHANT ->
		case Shop of
		    undefined ->
			?inventory:pagination(
			   by_merchant, CurrentPage, CountPerPage, Merchant);
		    Shop ->
			?inventory:pagination(
			   by_shop, CurrentPage, CountPerPage, Shop, Merchant)
		end;
	    ?USER ->
		?inventory:pagination(
		   by_shop, CurrentPage, CountPerPage, Shop, Merchant)
	end,

    %% Sorted = sort_inventory(Inventories, []),
    %% ?DEBUG("sorted inventory~n~p", [Sorted]),
    %% ordered
    ?utils:respond(200, batch, Req, Inventories);

action(Session, Req, {"filter_inventory"}, Payload) ->
    ?DEBUG("filter_inventory with session ~p~n, payload ~p", [Session, Payload]),
    Merchant           = ?session:get(merchant, Session),
    Pattern            = ?value(<<"pattern">>, Payload),
    {struct, Fields}   = ?value(<<"fields">>, Payload),
    CurrentPage        = ?value(<<"page">>, Payload),
    CountPerPage       = ?value(<<"count">>, Payload),

    NewFields =
	case ?session:get(type, Session) of
	    ?MERCHANT ->
		Fields;
	    ?USER ->
		case ?value(<<"shop">>, Fields) of
		    undefined ->
			[{<<"shop">>, shops(user, Session)}|Fields];
		    _ ->
			Fields
			%% [{<<"shop">>, ShopIds}|proplists:delete(<<"shop">>, Fields)]
		end
	end,
    
    %% the first page, get total number of inventories
    Total = case CurrentPage of 1
		-> ?inventory:do_filter(
		      total_with_filter, ?to_a(Pattern), Merchant, NewFields);
		_ -> 0
	    end,
    Inventories = ?inventory:do_filter(pagination, CurrentPage, CountPerPage,
				       ?to_a(Pattern), Merchant, NewFields),
    
    ?utils:respond(200, object, Req, {[{<<"ecode">>, 0},
				       {<<"total">>, Total},
				       {<<"data">>, Inventories}]});


action(Session, Req, {"get_total_inventories"}, Payload) ->
    ?DEBUG("get_total_pagination with~nsession ~p~n, payload ~p",
	   [Session, Payload]),
    %% page settings
    Merchant = ?session:get(merchant, Session),
    Shop     = ?value(<<"shop">>, Payload),
    
    Conditions = 
	case ?session:get(type, Session) of
	    ?MERCHANT ->
		case Shop of
		    undefined ->
		       [{<<"merchant">>, Merchant}];
		    Shop ->
			[{<<"shop">>, Shop}, {<<"merchant">>, Merchant}]
		end;
	    ?USER ->
		[{<<"shop">>, Shop}, {<<"merchant">>, Merchant}]
	end,
    
    Total = ?inventory:inventory(total, Conditions),
    %% Sorted = sort_inventory(Inventories, []),
    %% ?DEBUG("sorted inventory~n~p", [Sorted]),
    %% ordered
    ?utils:respond(200, object, Req, Total).


%% =============================================================================
%% sidebar
%% =============================================================================
sidebar(Session) ->
    Shops = get_shops(Session),

    %% detail
    InventroyDetail =
	case lists:foldr(fun({Id, Name, _}, Acc) ->
				 S = {?to_string(Id), ?to_string(Name)},
				 case lists:member(S, Acc) of
				     true -> Acc;
				     false -> [S|Acc]
				 end
			 end, [], Shops) of
	    [] -> [];
	    Details ->
		[{{"inventory_detail", "库存详情", "glyphicon glyphicon-shopping-cart"}, Details}]
	end,

    %% new
    InventroyNew = 
	case shop_action(?new_inventory, Shops) of
	    [] ->
		[];
	    News ->
		[{{"inventory_new", "新增库存", "glyphicon glyphicon-map-marker"}, News}]
	end,

    %% check
    Inventorycheck =
	case shop_action(?check_inventory, Shops) of
	    [] ->
		[];
	    Checks ->
		[{{"inventory_check", "库存审核", "glyphicon glyphicon-log-in"}, Checks}]
	end,

    %% moving
    Move =
	case ?right_auth:authen(?move_inventory, Session) of
	    {ok, ?move_inventory} ->
		[{"move", "移仓"}];
	    _ -> []
	end,
    
    InventoryMove = [{{"inventory_move", "移仓", "glyphicon glyphicon-random"},
		      Move ++ [{"detail", "移仓详情"}]}],

    %% reject
    Reject =
	case ?right_auth:authen(?reject_inventory, Session) of
	    {ok, ?reject_inventory} ->
		[{"reject", "退货"}];
	    _ -> []
	end,
    InventoryReject = [{{"inventory_reject", "退货", "glyphicon glyphicon-transfer"},
			Reject ++ [{"detail", "退货详情"}]}],

    %% import and export
    Import =
	case ?right_auth:authen(?import_inventory, Session) of
	    {ok, ?import_inventory} ->
		[{"import", "导入"}];
	    _ -> []
	end,

    Export =
	case ?right_auth:authen(?export_inventory, Session) of
	    {ok, ?export_inventory} ->
		[{"export", "导出"}];
	    _ -> []
	end,

    IM = 
    case Import ++ Export of
	[] -> [];
	_IM -> [{{"inventory_im", "导入/导出", "glyphicon glyphicon-map-marker"}, _IM}]
    end,
    
    %% size group
    SizeGroup = [{"size_group", "尺码组", "glyphicon glyphicon-text-width"}],

    %% adjust price 
    AdjustPrice =
	case ?right_auth:authen(?adjust_price, Session) of
	    {ok, ?adjust_price} ->
		[{"adjust_price", "调价", "glyphicon glyphicon-sort"}];
	    _ -> []
	end,

    L1 = ?menu:sidebar(level_1_menu, SizeGroup ++ AdjustPrice),
	
    
    L2 = ?menu:sidebar(level_2_menu,
		       InventroyDetail ++ InventroyNew ++ Inventorycheck
		       ++ InventoryMove ++ InventoryReject ++ IM),

    L2 ++ L1.

shop_action(Action, Shops) ->
    lists:foldr(
      fun({Id, Name, FunId, RepoId, Type}, Acc) ->
	      {ok, Children} =
		  ?right_init:get_children([{<<"id">>, FunId}]),

	      %% ?DEBUG("Children ~p", [Children]),

	      case [Child || {Child} <- Children,
			     ?value(<<"id">>, Child) =:= Action] of
		  [] -> Acc;
		  _ ->
		      [{Id, Name, RepoId, Type}|Acc]
	      end
      end, [], Shops).
    
get_shops(Session) ->
    Shops = 
	case ?session:get(type, Session) of
	    ?SUPER ->
		?shop:lookup();
	    ?MERCHANT ->
		{ok, S0} = ?shop:lookup(?session:get(merchant, Session)),
		lists:foldr(fun({AShop}, Acc) ->
				    [{[{<<"shop_id">>, ?value(<<"id">>, AShop)},
				       {<<"name">>,     ?value(<<"name">>, AShop)},
				       {<<"func_id">>,
					case ?session:get(mtype, Session) of
					    ?SALER -> ?right_inventory;
					    ?WHOLESALER -> ?right_w_inventory
					end}]}|Acc]
			    end, [], S0);
	    ?USER ->
		?right_auth:get_user_shop(Session)
	end,
    %% ?DEBUG("shops ~p", [Shops]),

    SortShops = 
	lists:foldr(
	  fun({Shop}, Acc) ->
		  Id =   ?value(<<"shop_id">>, Shop),
		  Name = ?value(<<"name">>, Shop),
		  FunId = ?value(<<"func_id">>, Shop),
		  S = {Id, Name, FunId},
		  case lists:member(S, Acc) of
		      true  ->  Acc;
		      false -> [S|Acc]
		  end
		  %% [{?to_string(Id), ?to_string(Name)}|Acc]
	  end, [],  Shops),
    ?DEBUG("sort shops ~p", [SortShops]),
    SortShops.


%% =============================================================================
%% @desc: get all of ids of shop by user session
%% =============================================================================
shops(user, Session) ->
    Shops = ?right_auth:get_user_shop(Session),
    ShopIds =
	lists:foldr(
	  fun({Shop}, Acc) ->
		  ShopId = ?value(<<"shop_id">>, Shop),
		  case lists:member(ShopId, Acc) of
		      true -> Acc;
		      false -> [ShopId|Acc]
		  end
	  end, [], Shops),
    ShopIds.
