-module(diablo_w_print_request).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_request).

-export([action/2, action/3, action/4]).


%%--------------------------------------------------------------------
%% @desc: GET action
%%--------------------------------------------------------------------
action(Session, Req) ->
    ?DEBUG("GET Req ~n~p", [Req]),
    {ok, HTMLOutput} = wprint_frame:render(
			 [
			  {navbar, ?menu:navbars(?MODULE, Session)},
			  {basebar, ?menu:w_basebar(Session)},
			  {sidebar, sidebar(Session)},
			  {ngapp, "wprintApp"},
			  {ngcontroller, "wprintCtrl"}]),
    Req:respond({200, [{"Content-Type", "text/html"}], HTMLOutput}).


action(Session, Req, {"list_w_print_server"}) ->
    ?DEBUG("list_w_print_server with session ~p", [Session]), 
    {ok, Servers} = ?w_print:server(list),
    ?utils:respond(200, batch, Req, Servers);


action(Session, Req, {"list_w_printer"}) ->
    ?DEBUG("list_w_printer with session ~p", [Session]), 
    ?utils:respond(batch, fun() -> ?w_print:printer(list) end, Req); 

action(Session, Req, {"list_w_printer_conn"}) ->
    ?DEBUG("list_w_printer_conn with session ~p", [Session]),
    Fun = 
	case ?session:get(type, Session) of
	    ?SUPER -> fun() -> ?w_print:printer(list_conn) end;
	    _ ->
		Merchant = ?session:get(merchant, Session),
		fun() -> ?w_print:printer(list_conn, Merchant) end
	end,
    ?utils:respond(batch, Fun, Req); 

action(Session, Req, {"del_w_printer_conn", Id}) ->
    ?DEBUG("delete_w_printer_conn with session ~p, Id ~p", [Session, Id]),

    case ?w_print:printer(delete_conn, Id) of
	{ok, PId} ->
	    ?utils:respond(200, Req, ?succ(delete_wprinter_conn, PId));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"list_w_printer_format"}) ->
    ?DEBUG("list_w_print_format with session ~p", [Session]),
    Merchant = ?session:get(merchant, Session),
    ?utils:respond(batch, fun() -> ?w_print:format(list, Merchant) end, Req).

%%--------------------------------------------------------------------
%% @desc: POST action
%%--------------------------------------------------------------------
action(Session, Req, {"new_w_print_server"}, Payload) ->
    ?DEBUG("new wprint_server with session ~p~npaylaod ~p", [Session, Payload]),

    case ?w_print:server(new, Payload) of
	{ok, Name} ->
	    ?utils:respond(200, Req, ?succ(new_wprint_server, Name));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"new_w_printer"}, Payload) ->
    ?DEBUG("new_w_printer with session ~p~npaylaod ~p", [Session, Payload]),

    case ?w_print:printer(new, Payload) of
	{ok, PId} ->
	    ?utils:respond(200, Req, ?succ(new_wprinter, PId));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"new_w_printer_conn"}, Payload) ->
    ?DEBUG("new_w_printer_conn with session ~p~npaylaod ~p", [Session, Payload]),

    Merchant = case ?v(<<"merchant">>, Payload) of
		   undefined ->
		       ?session:get(merchant, Session);
		   M -> M
	       end,

    case ?w_print:printer(new_conn, Merchant, Payload) of
	{ok, SN} ->
	    ?utils:respond(200, Req, ?succ(new_wprinter_conn, SN));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"update_w_printer_conn", Id}, Payload) ->
    ?DEBUG("update_w_printer_conn with id ~p, session ~p, paylaod ~p",
	   [Id, Session, Payload]),

    Merchant = case ?v(<<"merchant">>, Payload) of
		   undefined ->
		       ?session:get(merchant, Session);
		   M -> M
	       end,
    
    case ?w_print:printer(update_conn, Merchant, ?to_i(Id), Payload) of
	{ok, DeviceId} ->
	    ?utils:respond(200, Req, ?succ(update_wprinter_conn, DeviceId));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"update_w_printer_format", Id}, Payload) ->
    Merchant = ?session:get(merchant, Session),
    case ?w_print:format(update, Merchant, Id, Payload) of
	{ok, Name} ->
	    ?utils:respond(200, Req, ?succ(update_wprinter_format, Name));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"add_w_printer_format_to_shop"}, Payload) ->
    Merchant = ?session:get(merchant, Session),
    Shop     = ?v(<<"shop">>, Payload),
    case ?w_print:format(add_to_shop, Merchant, Shop) of
	{ok, Shop} ->
	    ?utils:respond(200, Req, ?succ(add_wprinter_format_to_shop, Shop));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;


action(Session, Req, {"test_w_printer", PId}, Payload) ->
    ?DEBUG("test_w_printer with PId ~p session ~p~npayload ~p", [PId, Session, Payload]),
    Merchant = ?v(<<"merchant">>, Payload),
    Shop     = ?v(<<"shop">>, Payload),
    
    try ?wifi_print:print(test, Merchant, Shop, PId) of
	{error, {ECode, _}} ->
	    EInfo = [{[{<<"ecode">>, ECode}]}],
	    ?utils:respond(200, object, Req, {[{<<"ecode">>, ECode},
					       {<<"einfo">>, EInfo}]});
	{Success, []} ->
	    ?utils:respond(200, object, Req, {[{<<"ecode">>, 0},
					       {<<"device">>, Success}]});
	{[], Failed} ->
	    EInfo = [{[{<<"device">>, DeviceId}, {<<"ecode">>, ECode}]}
		     || {DeviceId, ECode} <- Failed],
	    ?utils:respond(200, object, Req, {[{<<"ecode">>, 1},
					       {<<"einfo">>, EInfo}]})
	%% {_Success, Failed} ->
	%%     EInfo = [{[{<<"device">>, DeviceId}, {<<"ecode">>, ECode}]}
	%% 	     || {DeviceId, ECode} <- Failed],
	%%     ?utils:respond(200, object, Req, {[{<<"ecode">>, 2},
	%% 				       {<<"einfo">>, EInfo}]}) 
    catch
	EType:What ->
	    ?INFO("failed to test print ~p", [What]),
	    Report = ["print failed...",
		      {type, EType}, {what, What},
		      {trace, erlang:get_stacktrace()}],
	    ?ERROR("print failed: ~p", [Report]),
	    ?utils:respond(200, object, Req, {[{<<"ecode">>, 9999}]}) 
    end;

action(Session, Req, {"list_shop_by_merchant"}, Payload) ->
    ?DEBUG("list_shop_by_merchant with session ~p~npaylaod ~p", [Session, Payload]),

    Merchant = ?v(<<"merchant">>, Payload),
    {ok, Shops} = ?shop:lookup(Merchant),
    ?utils:respond(200, batch, Req, Shops). 


sidebar(_Session) -> 
    ?menu:sidebar(level_2_menu,
    		  [
    		   {{"server", "打印中心", "glyphicon glyphicon-home"},
    		    [{"new",       "新增服务器", "glyphicon glyphicon-plus"},
    		     {"detail",    "服务器详情", "glyphicon glyphicon-briefcase"}]
    		   },

    		   {{"printer", "打印机管理", "glyphicon glyphicon-print"}, 
    		    [
		     {"new",    "新增打印机", "glyphicon glyphicon-plus"},
		     {"detail", "打印机详情", "glyphicon glyphicon-briefcase"},
		     {"connect_new",    "关联打印机", "glyphicon glyphicon-plus"},
    		     {"connect_detail", "关联详情", "glyphicon glyphicon-briefcase"}]}
    		  ]).
