-module(diablo_w_base_request).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_request).

-export([action/2, action/3, action/4]).


%%--------------------------------------------------------------------
%% @desc: GET action
%%-------------------------------------------------------------------- 
action(Session, Req) ->
    ?DEBUG("GET Req ~n~p", [Req]),
    {ok, HTMLOutput} = sys_frame:render(
			 [
			  {navbar, ?menu:navbars(?MODULE, Session)},
			  {basebar, ?menu:w_basebar(?MODULE, Session)},
			  {sidebar, sidebar(Session)},
			  {ngapp, "baseApp"},
			  {ngcontroller, "baseCtrl"}]),
    Req:respond({200, [{"Content-Type", "text/html"}], HTMLOutput}).


action(Session, Req, {"list_w_bank_card"}) ->
    ?DEBUG("list_w_bank_card with session ~p", [Session]),

    Merchant = ?session:get(merchant, Session),
    {ok, Cards}    = ?w_base:bank_card(list, Merchant),
    ?utils:respond(200, batch, Req, Cards);

action(Session, Req, {"list_base_setting"}) ->
    ?DEBUG("list_base_setting with session ~p", [Session]), 
    Merchant = ?session:get(merchant, Session),
    {ok, S}    = ?w_user_profile:get(setting, Merchant),
    %% {ok, S}    = ?w_base:setting(list, Merchant),
    ?utils:respond(200, batch, Req, S).

%%--------------------------------------------------------------------
%% @desc: POST action
%%--------------------------------------------------------------------
action(Session, Req, {"new_w_bank_card"}, Payload) ->
    ?DEBUG("new_w_bank_card with session ~p~npaylaod ~p", [Session, Payload]),

    Merchant = ?session:get(merchant, Session),
    case ?w_base:bank_card(new, Merchant, Payload) of
	{ok, CardNo} ->
	    %% refresh profile
	    ?w_user_profile:update(bank, Merchant),
	    ?utils:respond(200, Req, ?succ(base_new_card, CardNo));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"del_w_bank_card"}, Payload) ->
    ?DEBUG("del_w_bank_card with session ~p~npaylaod ~p", [Session, Payload]),

    Merchant = ?session:get(merchant, Session),
    CardId   = ?v(<<"id">>, Payload),
    case ?w_base:bank_card(delete, Merchant, CardId) of
	{ok, CardId} ->
	    ?w_user_profile:update(bank, Merchant),
	    ?utils:respond(200, Req, ?succ(base_delete_card, CardId));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"update_w_bank_card"}, Payload) ->
    ?DEBUG("update_w_bank_card with session ~p~npaylaod ~p", [Session, Payload]),

    Merchant = ?session:get(merchant, Session),
    case ?w_base:bank_card(update, Merchant, Payload) of
	{ok, CardNo} ->
	    ?w_user_profile:update(bank, Merchant),
	    ?utils:respond(200, Req, ?succ(base_update_card, CardNo));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

%%
%% base setting 
%%
action(Session, Req, {"list_base_setting"}, Payload) ->
    ?DEBUG("list_base_setting with session ~p", [Session]), 
    Merchant = ?session:get(merchant, Session),
    {ok, S}    = ?w_base:setting(list, Merchant, Payload),
    ?utils:respond(200, batch, Req, S);

action(Session, Req, {"add_base_setting"}, Payload) ->
    ?DEBUG("add_base_setting with session ~p", [Session]),
    Merchant = ?session:get(merchant, Session),
    case ?w_base:setting(add, Merchant, Payload) of
	{ok, EName}  ->
	    ?w_user_profile:update(setting, Merchant),
	    ?utils:respond(200, Req, ?succ(base_add_setting, EName));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;
    
action(Session, Req, {"update_base_setting"}, Payload) ->
    ?DEBUG("update_base_setting with session ~p", [Session]), 
    Merchant = ?session:get(merchant, Session),
    case ?w_base:setting(update, Merchant, Payload) of
	{ok, EName}  ->
	    ?utils:respond(200, Req, ?succ(base_update_setting, EName));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"add_shop_setting"}, Payload) ->
    ?DEBUG("add_shop_setting with session ~p", [Session]),
    Merchant = ?session:get(merchant, Session),
    Shop     = ?v(<<"shop">>, Payload),
    case ?w_base:setting(add_to_shop, Merchant, Shop) of
	{ok, Shop}  ->
	    ?w_user_profile:update(setting, Merchant),
	    ?utils:respond(200, Req, ?succ(base_add_shop_setting, Shop));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

%%
%% passwd
%%
action(Session, Req, {"update_user_passwd"}, Payload) ->
    ?DEBUG("update_user_passwd with session ~p", [Session]),
    Account = ?session:get(name, Session),
    case ?right:right(update_account_passwd, Account, Payload) of
	{ok, Account} ->
	    ?utils:respond(200, Req, ?succ(base_update_passwd, Account));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

%%
%% login out
%% 
action(Session, Req, {"destroy_login_user"}, Payload) ->
    ?DEBUG("destroy_login_user with session ~p, payload ~p",
	   [Session, Payload]),
    User = ?session:get(name, Session), 
    %% SessionId = Req:get_cookie_value("session"),
    ok = ?session:delete(Session#session.id),
    ?utils:respond(200, Req, ?succ(destroy_login_user, User)).

sidebar(Session) -> 
    Card = 
	case ?right_auth:authen(?new_w_bank_card, Session) of
	    {ok, ?new_w_bank_card} ->
		[{"new_bank_card", "新增银行卡", "glyphicon glyphicon-plus"},
		 {"bank_card_detail", "银行卡详情", "glyphicon glyphicon-briefcase"}];
	    _ ->
		[{"bank_card_detail", "银行卡详情", "glyphicon glyphicon-briefcase"}]
	end, 

    Print =
	case ?right_auth:authen(?new_w_printer_conn, Session) of
	    {ok, ?new_w_printer_conn} ->
		[
		 {"connect_new",    "打印机绑定", "glyphicon glyphicon-plus"},
		 {"connect_detail", "绑定详情", "glyphicon glyphicon-briefcase"}];
	    _ ->
		[{"connect_detail", "绑定详情", "glyphicon glyphicon-leaf"}]
	end,

    SBase = [{{"bank", "银行卡设置", "glyphicon glyphicon-credit-card"}, Card},
	     {{"printer", "打印机", "glyphicon glyphicon-print"}, Print},
	     {{"setting", "基本设置", "glyphicon glyphicon-cog"},
	      [{"print_option", "系统设置", "glyphicon glyphicon-wrench"},
	       {"print_format", "打印格式", "glyphicon glyphicon-text-width"}
	       %% {"print_task", "打印任务",  "glyphicon glyphicon-tasks"}
	       %% {"table_detail", "表单", "glyphicon glyphicon-list-alt"}
	      ]
	     }],
    
    Passwd = [{"passwd", "重置密码", "glyphicon glyphicon-user"}],

    %% STable = [{{"table", "表格设置", "glyphicon glyphicon-scale"},
    %% 		[{"row_num", "表格行数"}]}],

    
    ?menu:sidebar(level_2_menu, SBase) ++ ?menu:sidebar(level_1_menu, Passwd).
