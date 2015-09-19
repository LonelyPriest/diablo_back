%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2015, buxianhui
%%% @doc
%%%
%%% @end
%%% Created :  3 Mar 2015 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_w_print).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_server).

%% API
-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-export([server/1, server/2]).
-export([printer/1, printer/2, printer/3, printer/4]).
-export([format/2, format/3, format/4]).

-define(SERVER, ?MODULE). 

-record(state, {}).

%%%===================================================================
%%% API
%%%===================================================================
server(list) ->
    gen_server:call(?SERVER, list_server).
server(new, Attrs) ->
    gen_server:call(?SERVER, {new_server, Attrs}).

printer(list) ->
    gen_server:call(?SERVER, list_printer);
printer(list_conn) ->
    printer(list_conn, []).
			   
printer(new, Attrs) ->
    gen_server:call(?SERVER, {new_printer, Attrs});
printer(delete_conn, PId) ->
    gen_server:call(?SERVER, {delete_printer_conn, PId});
printer(list_conn, Merchant) ->
    gen_server:call(?SERVER, {list_printer_conn, Merchant}).

printer(new_conn, Merchant, Attrs) -> 
    gen_server:call(?SERVER, {new_printer_conn, Merchant, Attrs}).
printer(update_conn, Merchant, PId, Attrs) ->
    gen_server:call(?SERVER, {update_printer_conn, Merchant, PId, Attrs}).


format(list, Merchant) ->
    gen_server:call(?SERVER, {list_printer_format, Merchant}). 
format(add_to_shop, Merchant, Shop) ->
    gen_server:call(?SERVER, {add_format_to_shop, Merchant, Shop}). 
format(update, Merchant, Id, Attrs) ->
    gen_server:call(?SERVER, {update_printer_format, Merchant, Id, Attrs}).



start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

init([]) ->
    {ok, #state{}}.

handle_call({new_server, Attrs}, _From, State) ->
    ?DEBUG("new_server with attrs ~p", [Attrs]),
    Name = ?v(<<"name">>, Attrs),
    Path = ?v(<<"path">>, Attrs),

    Sql0 = "select id from w_print_server"
	" where path=" ++ "\'" ++ ?to_s(Path) ++ "\'",

    case ?sql_utils:execute(s_read, Sql0) of
	{ok, []} ->
	    Sql1 = "insert into w_print_server(name, path, entry_date) values("
		++ "\'" ++ ?to_s(Name) ++ "\'"
		++ ", \'" ++ ?to_s(Path) ++ "\'"
		++ ", \'" ++ ?utils:current_time(localdate) ++ "\')",
	    Reply = ?sql_utils:execute(insert, Sql1),
	    {reply, Reply, State}; 
	{ok, E} ->
	    ?DEBUG("print server with path ~p has been exist", [Path]),
	    {reply, {error, ?err(wprint_server_exist, ?v(<<"id">>, E))}, State};
	Error ->
	    {reply, Error, State}
    end;

handle_call(list_server, _From, State) ->
    Sql = "select id, name, path, entry_date from w_print_server"
	" where deleted=" ++ ?to_s(?NO) ++ ";",
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({new_printer, Attrs}, _From, State) ->
    ?DEBUG("new_printer with attrs ~p", [Attrs]),
    Brand  = ?v(<<"brand">>, Attrs),
    Model  = ?v(<<"model">>, Attrs),
    %% Column = ?v(<<"column">>, Attrs),

    Sql0 = "select id from w_printer"
	" where brand=" ++ "\'" ++ ?to_s(Brand) ++ "\'"
	++ " and model=" ++ "\'" ++ ?to_s(Model) ++ "\'"
	%% ++ " and col_width=" ++ ?to_s(Column)
	++ " and deleted=" ++ ?to_s(?NO),

    case ?sql_utils:execute(s_read, Sql0) of
	{ok, []} ->
	    Sql1 = "insert into w_printer(brand, model, entry_date)"
		" values("
		++ "\'" ++ ?to_s(Brand) ++ "\',"
		++ "\'" ++ ?to_s(Model) ++ "\',"
		%% ++ ?to_s(Column) ++ ","
		++ "\'" ++ ?utils:current_time(localdate) ++ "\')",
	    Reply = ?sql_utils:execute(insert, Sql1),
	    {reply, Reply, State};
	{ok, E} ->
	    {reply, {error, ?err(wprinter_exist, ?v(<<"id">>, E))}, State};
	Error ->
	    {reply, Error, State}
    end;

handle_call(list_printer, _From, State) ->
    Sql = "select id, brand, model"
	", entry_date from w_printer"
	" where deleted=" ++ ?to_s(?NO) ++ ";",
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({new_printer_conn, Merchant, Attrs}, _From, State) ->
    ?DEBUG("new_printer_conn with merchant ~p, attrs ~p", [Merchant, Attrs]),
    Column  = ?v(<<"column">>, Attrs),
    Height   = ?v(<<"height">>, Attrs),
    SN       = ?v(<<"sn">>, Attrs),
    Key      = ?v(<<"key">>, Attrs),
    Printer  = ?v(<<"printer">>, Attrs),
    PServer  = ?v(<<"pserver">>, Attrs),
    %% Merchant = ?v(<<"merchant">>, Attrs),
    Shop     = ?v(<<"shop">>, Attrs, -1),

    Sql0 = "select id, sn, code from w_printer_conn"
	" where sn=" ++ "\'" ++ ?to_s(SN) ++ "\'"
	++ " and code=" ++ "\'" ++ ?to_s(Key) ++ "\'",

    case ?sql_utils:execute(s_read, Sql0) of
	{ok, []} ->
	    Sql1 = "insert into w_printer_conn("
		"printer, paper_column, paper_height"
		", server, sn, code, shop, merchant, entry_date)"
		" values("
		++ ?to_s(Printer) ++ ","
		++ ?to_s(Column) ++ ","
		++ ?to_s(Height) ++ ","
		++ ?to_s(PServer) ++ ","
		++ "\'" ++ ?to_s(SN) ++ "\',"
		++ "\'" ++ ?to_s(Key) ++ "\',"
		++ ?to_s(Shop) ++ "," 
		++ ?to_s(Merchant) ++ "," 
		++ "\'" ++ ?utils:current_time(localdate) ++ "\')", 
	    Reply = ?sql_utils:execute(insert, Sql1),
	    {reply, Reply, State}; 
	{ok, E} ->
	    ?DEBUG("printer_conn ~p does exist", [?v(<<"id">>, E)]),
	    {reply, {error, ?err(wprinter_conn_exist, ?v(<<"id">>, E))}, State};
	Error ->
	    {reply, Error, State}
    end;

handle_call({delete_printer_conn, PId}, _From, State) ->
    Sql = "delete from w_printer_conn"
	++ " where id=" ++ ?to_s(PId), 
    Reply = ?sql_utils:execute(write, Sql, PId),
    {reply, Reply, State};

handle_call({update_printer_conn, Merchant, Id, Attrs}, _From, State) ->
    ?DEBUG("update_printer_conn with id ~p, attrs ~p", [Id, Attrs]),
    Id       = ?v(<<"id">>, Attrs),
    SN       = ?v(<<"sn">>, Attrs),
    Key      = ?v(<<"key">>, Attrs),
    Printer  = ?v(<<"printer">>, Attrs),
    Column   = ?v(<<"column">>, Attrs),
    Height   = ?v(<<"height">>, Attrs),
    PServer  = ?v(<<"pserver">>, Attrs),
    Shop     = ?v(<<"shop">>, Attrs),
    Status   = ?v(<<"status">>, Attrs),

    PrinterExist =
	case SN of
	    undefined -> {ok, []} ;
	    SN ->
		Sql = "select id, sn from w_printer_conn"
		    " where sn=" ++ "\'" ++ ?to_s(SN) ++ "\'"
		    ++ " and deleted=" ++ ?to_s(?NO),
		?sql_utils:execute(s_read, Sql)
	end,

    case PrinterExist of
	{ok, []} -> 
	    Updates = ?utils:v(printer, integer, Printer)
		++ ?utils:v(paper_column, integer, Column)
		++ ?utils:v(paper_height, integer, Height)
		++ ?utils:v(server, integer, PServer)
		++ ?utils:v(sn, string, SN)
		++ ?utils:v(code, string, Key)
		++ ?utils:v(shop, integer, Shop)
		++ ?utils:v(status, integer, Status) 
		++ ?utils:v(entry_date, string, ?utils:current_time(localtime)),
	    Sql1 = "update w_printer_conn set "
		++ ?utils:to_sqls(proplists, comma, Updates)
		++ " where id=" ++ ?to_s(Id),
	    case Merchant of
		undefined -> ok;
		Merchant -> ?w_user_profile:update(print, Merchant)
	    end,
	    Reply = ?sql_utils:execute(write, Sql1, SN),
	    {reply, Reply, State};
	{ok, _} ->
	    {reply, {error, ?err(wprinter_conn_used, SN)}, State};
	{error, Error} ->
	    {reply, {error, Error}, State}
    end;

handle_call({list_printer_conn, Merchant}, _From, State) ->
    ?DEBUG("list_printer_conn with merchant ~p", [Merchant]),
    Sql = "select a.id, a.printer as printer_id, a.paper_column as pcolumn"
	", a.paper_height as pheight, a.server as server_id"
	", a.sn, a.code, a.shop as shop_id, a.merchant as merchant_id"
	", a.status, a.entry_date"
	", b.brand, b.model"
	", c.id as server_id, c.name as server, c.path as server_path"
	", d.name as merchant"
	", e.name as shop"
	" from w_printer_conn a"
	" left join w_printer b on a.printer=b.id"
	" left join w_print_server c on a.server=c.id"
	" left join merchants d on a.merchant=d.id"
	" left join shops e on a.shop=e.id"
	" where "
	++ case Merchant of
	       [] -> [];
	       _ -> "a.merchant=" ++ ?to_s(Merchant) ++ " and "
	   end
	++ "a.deleted=" ++ ?to_s(?NO)
	++ " order by a.id",
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({list_printer_format, Merchant}, _From, State) ->
    Sql = "select id, name, print, shop, width, entry_date"
	" from w_print_format"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and deleted=" ++ ?to_s(?NO),
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({add_format_to_shop, Merchant, Shop}, _From, State) ->
    ?DEBUG("add_format_to_shop with merchant ~p, shop ~p", [Merchant, Shop]),
    Now = ?utils:current_time(localdate),
    
    Formats = [{"brand",           "0",  "0"},
	       {"style_number",    "0",  "0"},
	       {"type",            "0",  "0"},
	       {"color",           "0",  "0"},
	       {"size_name",       "0",  "0"}, 
	       {"size",            "0",  "0"},
	       {"price",           "0",  "0"},
	       {"discount",        "0",  "0"},
	       {"dprice",          "0",  "0"},
	       {"hand",            "0",  "0"},
	       {"count",           "0",  "0"},
	       {"calc",            "0",  "0"}
	      ], 

    Sqls = lists:foldr(
	     fun({Name, Print, Width}, Acc) ->
		     Sql01 = "select id, name, print from w_print_format"
			 " where name=\'" ++ Name ++ "\'"
			 ++ " and shop=" ++ ?to_s(Shop)
			 ++ " and merchant=" ++ ?to_s(Merchant),
		     case ?sql_utils:execute(s_read, Sql01) of
			 {ok, []} ->
			     ["insert into w_print_format("
			      "name, print, width"
			      ", shop, merchant, entry_date) values("
			      "\'" ++ Name ++ "\',"
			      ++ Print ++ ","
			      ++ Width  ++ ","
			      ++ ?to_s(Shop) ++ "," 
			      ++ ?to_s(Merchant) ++ "," 
			      "\'" ++ Now ++ "\');"|Acc];
			 {ok, _} ->
			     Acc
		     end
	     end, [], Formats),
    Reply = ?sql_utils:execute(transaction, Sqls, Shop),
    ?w_user_profile:update(print_format, Merchant),
    {reply, Reply, State};


handle_call({update_printer_format, Merchant, Id, Attrs}, _From, State) ->
    ?DEBUG("update_printer_format with id ~p~n, attrs ~p", [Id, Attrs]),
    Name     = ?v(<<"name">>, Attrs),
    Print    = ?v(<<"print">>, Attrs),
    Width    = ?v(<<"width">>, Attrs),
    Shop     = ?v(<<"shop">>, Attrs),
    %% Fish     = ?v(<<"fish">>, Attrs),

    Updates = ?utils:v(print, integer, Print)
	++ ?utils:v(width, integer, Width)
	++ ?utils:v(entry_date, string, ?utils:current_time(localtime)), 

    UpdateSql = "update w_print_format set "
	++ ?utils:to_sqls(proplists, comma, Updates)
	++ " where id=" ++ ?to_s(Id)
    	++ " and name=\'" ++ ?to_s(Name) ++ "\'"
    	++ " and shop=" ++ ?to_s(Shop)
    	++ " and merchant=" ++ ?to_s(Merchant),
    
    Reply = ?sql_utils:execute(write, UpdateSql, Name), 
    %% refresh profiel
    ?w_user_profile:update(print_format, Merchant),
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

%%%===================================================================
%%% Internal functions
%%%===================================================================
