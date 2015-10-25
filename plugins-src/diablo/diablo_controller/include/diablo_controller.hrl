-define(NO, 0).
-define(YES, 1).

-define(SUCCESS, 0).

%% user type
-define(SUPER, 0).
-define(MERCHANT, 1).
-define(USER, 2).

%% shop
-define(SHOP_MASTER, 1).
-define(SHOP, 0).
-define(REPERTORY, 1).
-define(BAD_REPERTORY, 2).


%% merchant type
-define(SALER, 0).
-define(WHOLESALER, 1).

%% move state
-define(MOVING, 0).
-define(MOVED, 1).

%% check state
-define(CHECKING, 0).
-define(CHECKED, 1).

%% inventory action
-define(NEW_INVENTORY, 0).
-define(REJECT_INVENTORY, 1).

%% free size
-define(FREE_SIZE, 0).
%% free color
-define(FREE_COLOR, 0).

%% print
-define(COLUMN, 0).
-define(ROW, 1).
-define(START, 0).
-define(STOP, 1).
-define(TABLE, 1).
-define(STRING, 0).

%% pagination
-define(DEFAULT_ITEMS_PERPAGE, 5).

%% seconds begin 0 year, 0 month, 0 day to 1970.1.1
%% calendar:datetime_to_gregorian_seconds({{1970, 1, 1}, {0,0,0}}).
-define(SECONDS_BEFOR_1970, 62167219200).

%% session
-define(QZG_DY_SESSION, "qzg_dyty_session").

%% right module
-define(right_sale, 10000).
-define(right_inventory, 20000).
-define(right_member, 30000).
-define(right_shop, 40000).
-define(right_employe, 50000).
-define(right_right, 60000).
%% -define(right_right_sup, 60000).
-define(right_supplier, 70000).
-define(right_merchant, 80000).
%% -define(right_size_group, 90000).

%% about wholesale
-define(right_w_sale,      90000).
-define(right_w_inventory, 100000).
-define(right_w_firm,      110000).
-define(right_w_retailer,  120000). 
-define(right_w_print,     130000).
-define(right_w_good,      140000).
-define(right_w_report,    150000).

%% rainbow
-define(right_rainbow, 800000).

%% base setting
-define(right_w_base, 900000).


%% child functions
%% sale
-define(perment, ?right_sale + 1).
-define(list_sale_info, ?right_sale + 2).
-define(reject_and_exchange, ?right_sale + 3).
-define(list_reject_info, ?right_sale + 4).

%% inventory
-define(new_inventory,     ?right_inventory + 1).
-define(del_inventory,     ?right_inventory + 2).
-define(update_inventory,  ?right_inventory + 3).
-define(list_inventory,    ?right_inventory + 4).
-define(new_size_group,    ?right_inventory + 5).
-define(del_size_group,    ?right_inventory + 6).
-define(update_size_group, ?right_inventory + 7).
-define(list_size_group,   ?right_inventory + 8).
-define(check_inventory,   ?right_inventory + 9).
-define(move_inventory,    ?right_inventory + 10).
-define(do_move_inventory, ?right_inventory + 11).
-define(reject_inventory,  ?right_inventory + 12).
-define(import_inventory,  ?right_inventory + 13).
-define(export_inventory,  ?right_inventory + 14).
-define(adjust_price,      ?right_inventory + 15).


%% member
-define(new_member,              ?right_member + 1).
-define(del_member,              ?right_member + 2).
-define(update_member,           ?right_member + 3).
-define(list_member,             ?right_member + 4).
%%-define(acc_score,             ?right_member + 5).
-define(acc_score_detail,        ?right_member + 6).
-define(exchange_score,          ?right_member + 7).
-define(exchange_score_detail,   ?right_member + 8).
-define(query_score_stratege,    ?right_member + 9).
-define(update_score_stratege,   ?right_member + 10).
-define(get_member,              ?right_member + 11).

%% shop
-define(new_shop,       ?right_shop + 1).
-define(del_shop,       ?right_shop + 2).
-define(update_shop,    ?right_shop + 3).
-define(list_shop,      ?right_shop + 4).
-define(new_repo,       ?right_shop + 5).
-define(del_repo,       ?right_shop + 6).
-define(update_repo,    ?right_shop + 7).
-define(list_repo,      ?right_shop + 8).
-define(new_badrepo,    ?right_shop + 9).
-define(del_badrepo,    ?right_shop + 10).
-define(update_badrepo, ?right_shop + 11).
-define(list_badrepo,   ?right_shop + 12).

%% employ
-define(new_employe,    ?right_employe + 1).
-define(del_employe,    ?right_employe + 2).
-define(update_employe, ?right_employe + 3).
-define(list_employe,   ?right_employe + 4).

%% right
-define(new_role,       ?right_right + 1).
-define(del_role,       ?right_right + 2).
-define(update_role,    ?right_right + 3).
-define(list_role,      ?right_right + 4).
-define(new_account,    ?right_right + 5).
-define(del_account,    ?right_right + 6).
-define(update_account, ?right_right + 7).
-define(list_account,   ?right_right + 8).

%% supplier
-define(new_supplier,       ?right_supplier + 1).
-define(del_supplier,       ?right_supplier + 2).
-define(update_supplier,    ?right_supplier + 3).
-define(list_supplier,      ?right_supplier + 4).
-define(new_brand,          ?right_supplier + 5).
-define(del_brand,          ?right_supplier + 6).
-define(update_brand,       ?right_supplier + 7).
-define(list_brand,         ?right_supplier + 8).
-define(connect_brand,      ?right_supplier + 9).

%% merchant
-define(new_merchant,       ?right_merchant + 1).
-define(del_merchant,       ?right_merchant + 2).
-define(update_merchant,    ?right_merchant + 3).
-define(list_merchant,      ?right_merchant + 4).


%%
%% wholesale
%%

%% sale
-define(new_w_sale,         ?right_w_sale + 1).
-define(reject_w_sale,      ?right_w_sale + 2).
-define(list_reject_w_sale, ?right_w_sale + 3).
-define(print_w_sale,       ?right_w_sale + 4).
-define(update_w_sale,      ?right_w_sale + 5).
-define(check_w_sale,       ?right_w_sale + 6).

%% inventory
-define(new_w_order,    ?right_w_inventory + 1).
-define(del_w_order,    ?right_w_inventory + 2).
-define(list_w_order,   ?right_w_inventory + 3). 

-define(new_w_inventory,             ?right_w_inventory + 4).
-define(del_w_inventory,             ?right_w_inventory + 5).
-define(update_w_inventory,          ?right_w_inventory + 6).
-define(update_w_inventory_price,    ?right_w_inventory + 7). 
-define(list_w_inventory,            ?right_w_inventory + 8).
-define(list_new_w_inventory,        ?right_w_inventory + 9).
-define(reject_w_inventory,          ?right_w_inventory + 10).
-define(fix_w_inventory,             ?right_w_inventory + 11).
-define(filter_fix_w_inventory,      ?right_w_inventory + 12).
-define(check_w_inventory,           ?right_w_inventory + 13).



%% firm
-define(new_w_firm,    ?right_w_firm + 1).
-define(del_w_firm,    ?right_w_firm + 2).
-define(update_w_firm, ?right_w_firm + 3).
-define(list_w_firm,   ?right_w_firm + 4).

%% wretailer
-define(new_w_retailer,    ?right_w_retailer + 1).
-define(del_w_retailer,    ?right_w_retailer + 2).
-define(update_w_retailer, ?right_w_retailer + 3).
-define(list_w_retailer,   ?right_w_retailer + 4).

%% wprint
-define(new_w_print_server,  ?right_w_print + 1).
-define(del_w_print_server,  ?right_w_print + 2).
-define(list_w_print_server, ?right_w_print + 3).

-define(new_w_printer,    ?right_w_print + 4).
-define(del_w_printer,    ?right_w_print + 5).
-define(update_w_printer, ?right_w_print + 6).
-define(list_w_printer,   ?right_w_print + 7).


%% good
-define(new_w_good,     ?right_w_good + 1).
-define(del_w_good,     ?right_w_good + 2).
-define(update_w_good,  ?right_w_good + 3).
-define(list_w_good,    ?right_w_good + 4).

-define(new_w_size,     ?right_w_good + 5).
-define(del_w_size,     ?right_w_good + 6).
-define(update_w_size,  ?right_w_good + 7).

-define(new_w_color,    ?right_w_good + 8).
-define(del_w_color,    ?right_w_good + 9).
-define(update_w_color, ?right_w_good + 10).

%% report
-define(daily_wreport,   ?right_w_report + 1).
-define(weekly_wreport,  ?right_w_report + 2).
-define(monthly_wreport, ?right_w_report + 3).
-define(quarter_wreport, ?right_w_report + 4).
-define(half_wreport,    ?right_w_report + 5).
-define(year_wreport,    ?right_w_report + 6).


%% -----------------------------------------------------------------------------
%% rainbow
%% -----------------------------------------------------------------------------
-define(inventory_fifo, ?right_rainbow + 1).

%% =============================================================================
%% base setting
%% =============================================================================
-define(new_w_bank_card,    ?right_w_base + 1). 
-define(del_w_bank_card,    ?right_w_base + 2). 
-define(update_w_bank_card, ?right_w_base + 3).
-define(list_w_bank_card,   ?right_w_base + 4).
-define(new_w_printer_conn,    ?right_w_base + 5).
-define(del_w_printer_conn,    ?right_w_base + 6).
-define(update_w_printer_conn, ?right_w_base + 7).
-define(list_w_printer_conn,   ?right_w_base + 8).

%% member
-define(MAX_EMPLOYEE_ID, 8).
-define(member_request, diablo_controller_member_request).
-define(member, diablo_controller_member).


%% public
-define(http_route, diablo_controller_http_route).
-define(mysql, diablo_controller_mysql).
-define(utils, diablo_controller_utils).
-define(menu, diablo_controller_menu).

-define(sql_utils, diablo_sql_utils).
-define(pagination, diablo_pagination).

%% login
-define(login_request, diablo_controller_login_request).
-define(login, diablo_controller_login).
-define(session, diablo_controller_session_manager).

%% sale
-define(sale_request, diablo_controller_sale_request).
-define(sale, diablo_controller_sale).

%% shop
-define(shop_request, diablo_controller_shop_request).
-define(shop, diablo_controller_shop).

%% merchant
-define(merchant_request, diablo_controller_merchant_request).
-define(merchant, diablo_controller_merchant).

%% emmploy
-define(employ_request, diablo_controller_employ_request).
-define(employ, diablo_controller_employ).

%% inventory
-define(inventory_request, diablo_controller_inventory_request).
-define(inventory, diablo_controller_inventory).
-define(inventory_sn, diablo_controller_inventory_sn).

%% right
-define(right_init, diablo_controller_right_init).
-define(right_auth, diablo_controller_authen).
-define(tree, diablo_controller_tree).
-define(right_request, diablo_controller_right_request).
-define(right, diablo_controller_right).

%% supplier
-define(supplier_request, diablo_controller_supplier_request).
-define(supplier, diablo_controller_supplier).

%% size group
%% -define(size_group_request, diablo_controller_size_group_request).
%% -define(size_group, diablo_controller_size_group).

%% about whole sale
-define(firm_request, diablo_firm_request).
-define(firm, diablo_firm).


%% sale
-define(w_sale_request, diablo_w_sale_request).
-define(w_sale, diablo_w_sale).
-define(w_sale_draft, diablo_w_sale_draft).

%% saler
-define(w_retailer_request, diablo_w_retailer_request).
-define(w_retailer, diablo_w_retailer).

%% inventory
-define(w_inventory_request, diablo_purchaser_request).
-define(w_inventory, diablo_purchaser).

%% print
-define(w_print_request, diablo_w_print_request).
-define(w_print, diablo_w_print).
-define(wifi_print, diablo_http_print).
-define(f_print, diablo_format_print).

%% good
-define(w_good_request, diablo_w_good_request).
-define(w_good, diablo_w_good).
-define(w_good_sql, diablo_purchaser_sql).

%% report
-define(w_report_request, diablo_w_report_request).
-define(w_report, diablo_w_report).
-define(w_report_sql, diablo_w_report_sql).


%% base setting
-define(w_base_request, diablo_w_base_request).
-define(w_base, diablo_w_base).

%% base attribute
-define(attr, diablo_attribute).

%% profile
-define(w_user_profile, diablo_wuser_profile).

%% pool
-define(wpool, diablo_work_pool_sup).

-define(value(Key, Proplists), diablo_controller_utils:value_from_proplists(Key, Proplists)).
-define(value(Key, Proplists, Default), proplists:get_value(Key, Proplists, Default)).
-define(v(K, L), ?value(K, L)).
-define(v(K, L, D), ?value(K, L, D)).

-define(split_url(S),  erlang:list_to_tuple(string:tokens(S, "/"))).

-define(err(Err, Key), diablo_controller_error:error(Err, Key)).
-define(succ(Action, Key), diablo_controller_error:success(Action, Key)). 

-define(SESSION, tbl_session).
-record(session, {
	  id          = <<>>  :: binary(),
	  user_id     = -1    :: integer(), %% user id
	  user_name   = ""    :: string(),  %% user name
	  user_type   = -1    :: integer(), %% user level, 0:super, 1:merchant, 2:user
	  merchant    = -1    :: integer(), %% which merchant belong to
	  mtype       = -1    :: integer(), %% merhcant type 0: saler, 1: wholesaler
	  login_time          :: string()   %% start time of login
	 }).

-define(WSALE_DRAFT, tbl_wsale_draft).
-record(wsale_draft, {
	  merchant   = -1 :: integer(),
	  shop       = -1 :: integer(),
	  employee   = -1 :: integer(),
	  attrs      = [] :: list(),
	  invs       = [] :: list()
	 }).

-define(WFIX_DRAFT, tbl_wsale_draft).
-record(wfix_draft, {
	  merchant   = -1 :: integer(),
	  shop       = -1 :: integer(),
	  employee   = -1 :: integer(),
	  attrs      = [] :: list(),
	  invs       = [] :: list()
	 }).

-define(WUSER_PROFILE, tbl_wuser_profile).
-record(wuser_profile, {
	  merchant    = -1 :: integer(), 
	  info        = [] :: list(),
	  shop        = [] :: list(), %% all shop of merchant
	  repo        = [] :: list(), %% all repository of merchant
	  print       = [] :: list(),
	  pformat     = [] :: list(),
	  bank        = [] :: list(), %% all bank of merchant
	  setting     = [] :: list(),
	  size_groups = [] :: list(),
	  itype       = [] :: list(), %% type of inventory
	  brand       = [] :: list(), %% brand of inventory
	  retailer    = [] :: list(), %% all retailer of merchant
	  employee    = [] :: list(), %% all employee of merchant
	  firm        = [] :: list(), %% all firms of merchant
	  color_type  = [] :: list(),
	  color       = [] :: list(), 
	  good        = [] :: list()
	  %% login_right = [] :: list(),
	  %% login_shop  = [] :: list()
	 }).

-define(WUSER_SESSION_PROFILE, tbl_wuser_session_profile).
-record(wuser_session_profile, {
	  merchant = -1 :: integer(),
	  user     = -1 :: integer(),
	  type     = -1 :: integer(),
	  right = [] :: list(),
	  shop  = [] :: list(),
	  nav   = [] :: list()
	 }).


-record(diablo_node,
       {
	 id       = -1  :: integer(),
	 name           :: string(),
	 action   = ""  :: string(),
	 parent   = -1  :: integer(),
	 children = []
       }).
-type tree() :: #diablo_node{}.


