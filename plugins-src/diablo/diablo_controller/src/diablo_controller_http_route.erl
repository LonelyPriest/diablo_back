%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright SeasunGame(C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 11 Aug 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_controller_http_route).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-export([url_match/1, url_match/2]).

register_e(Service, Module)->
    [{"^" ++ ?to_string(Service) ++ "?$",        fun(Args) -> gen_request:http(Module, Args) end},
     {"^" ++ ?to_string(Service) ++ "/(.+?)/?$", fun(Args) -> gen_request:http(Module, Args) end}
    ].

register_e(Service, Module, ExtraArgs)->
    [{"^" ++ ?to_string(Service) ++ "?$",
      fun(Args) -> gen_request:http(Module, Args, ExtraArgs) end},
     
     {"^" ++ ?to_string(Service) ++ "/(.+?)/?$",
      fun(Args) -> gen_request:http(Module, Args, ExtraArgs) end}
    ].

url_match(get) ->
	register_e(sale,          ?sale_request)
	++ register_e(shop,       ?shop_request)
	++ register_e(member,     ?member_request)
	++ register_e(merchant,   ?merchant_request)
	++ register_e(employ,     ?employ_request)
	++ register_e(inventory,  ?inventory_request)
	++ register_e(right,      ?right_request)
	++ register_e(supplier,   ?supplier_request)

    %% about wholesale
	++ register_e(wsale,      ?w_sale_request) 
	++ register_e(firm,       ?firm_request)
	++ register_e(purchaser,  ?w_inventory_request)
	++ register_e(wretailer,  ?w_retailer_request)
	++ register_e(wprint,     ?w_print_request) 
    %% wgood
	++ register_e(wgood,      ?w_good_request)
	++ register_e(wreport,    ?w_report_request)
    %% base setting
	++ register_e(wbase,      ?w_base_request)
	;

url_match(delete) ->
    register_e(sale,              ?sale_request)
	++ register_e(shop,       ?shop_request)
	++ register_e(member,     ?member_request)
	++ register_e(merchant,   ?merchant_request)
	++ register_e(employ,     ?employ_request)
	++ register_e(inventory,  ?inventory_request)
	++ register_e(right,      ?right_request)
	++ register_e(supplier,   ?supplier_request)
	
    %% about wholesale
	++ register_e(wsale,      ?w_sale_request)
	++ register_e(firm,       ?firm_request)
	++ register_e(purchaser,  ?w_inventory_request)
	++ register_e(wretailer,  ?w_retailer_request)
	++ register_e(wprint,     ?w_print_request) 
	++ register_e(wgood,      ?w_good_request)
	++ register_e(wreport,    ?w_report_request)
    %% base setting
	++ register_e(wbase,      ?w_base_request)
	.
    

url_match(post, Payload) ->
    %% register_e(login,           ?login_request, Payload)
    register_e(sale,     ?sale_request, Payload)
	++ register_e(shop,       ?shop_request, Payload)
	++ register_e(member,     ?member_request, Payload)
	++ register_e(merchant,   ?merchant_request, Payload)
	++ register_e(employ,     ?employ_request, Payload)
	++ register_e(inventory,  ?inventory_request, Payload)
	++ register_e(right,      ?right_request, Payload)
	++ register_e(supplier,   ?supplier_request, Payload)

    %% about wholesale
	++ register_e(wsale,      ?w_sale_request, Payload) 
	++ register_e(firm,       ?firm_request, Payload)
	++ register_e(purchaser,  ?w_inventory_request, Payload)
	++ register_e(wretailer,  ?w_retailer_request, Payload)
	++ register_e(wprint,     ?w_print_request, Payload) 
	++ register_e(wgood,      ?w_good_request, Payload)
	++ register_e(wreport,    ?w_report_request, Payload)
    %% base setting
	++ register_e(wbase,       ?w_base_request, Payload)
	.
    
