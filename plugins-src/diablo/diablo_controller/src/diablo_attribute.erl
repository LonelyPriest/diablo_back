%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2015, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 23 Apr 2015 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_attribute).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_server).

%% API
-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-export([color_type/1, color/2, color/3]).
-export([size_group/2, size_group/3]).
-export([brand/2, brand/4]).
-export([type/2, type/3]).

-define(SERVER, ?MODULE). 

-record(state, {}).

%%%===================================================================
%%% API
%%%===================================================================
color_type(list) ->
    gen_server:call(?MODULE, list_w_color_type).

color(w_list, Merchant) ->
    gen_server:call(?MODULE, {list_w_color, Merchant}). 
color(w_new, Merchant, Attrs) ->
    gen_server:call(?MODULE, {new_w_clolor, Merchant, Attrs});
color(w_update, Merchant, Attrs) ->
    gen_server:call(?MODULE, {update_w_clolor, Merchant, Attrs});
color(w_delete, Merchant, ColorId) ->
    gen_server:call(?MODULE, {delete_w_clolor, Merchant, ColorId});
color(w_list, Merchant, ColorIds) ->
    gen_server:call(?MODULE, {list_w_color, Merchant, ColorIds}). 

size_group(list, Merchant) ->
    gen_server:call(?MODULE, {list_size_group, Merchant}).
size_group(new, Merchant, Attrs) ->
    gen_server:call(?MODULE, {new_size_group, Merchant, Attrs});
size_group(delete, Merchant, GId) ->
    gen_server:call(?MODULE, {delete_size_group, Merchant, GId});
size_group(update, Merchant, Attrs) ->
    gen_server:call(?MODULE, {update_size_group, Merchant, Attrs}).

brand(new, Merchant, Brand, Firm) ->
    gen_server:call(?MODULE, {new_brand, Merchant, Brand, Firm}).
brand(list, Merchant) ->
    gen_server:call(?MODULE, {list_brand, Merchant}).

type(new, Merchant, Type)->
    gen_server:call(?MODULE, {new_type, Merchant, Type}).
type(list, Merchant) ->
    gen_server:call(?MODULE, {list_type, Merchant}).



start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================


init([]) ->
    {ok, #state{}}.

handle_call(list_w_color_type, _Form, State) ->
    ?DEBUG("list_w_color_type", []),
    Sql = "select id, name from color_type"
	++ " where deleted=" ++ ?to_string(?NO) ++ ";",
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({new_w_clolor, Merchant, Attr}, _From, State) ->
    ?DEBUG("new color with merchant ~p, attr ~p ", [Merchant, Attr]),
    Name     = ?v(<<"name">>, Attr),
    Type     = ?v(<<"type">>, Attr),
    Remark   = ?v(<<"remark">>, Attr, "NULL"),
    
    Sql0 = "select id, name from colors"
	" where name=" ++ "\"" ++ ?to_s(Name) ++ "\""
	" and merchant=" ++ ?to_s(Merchant),

    Reply = 
	case ?sql_utils:execute(s_read, Sql0) of
	    {ok, []} -> 
		Sql1 = "insert into colors(name, type, remark, merchant)"
		    " values("
		    ++ "\"" ++ ?to_s(Name) ++ "\","
		    ++ ?to_s(Type) ++ ","
		    ++ "\"" ++ ?to_s(Remark) ++ "\","
		    ++ ?to_s(Merchant) ++ ");",
		?sql_utils:execute(insert, Sql1); 
	    {ok, Color} ->
		{error, ?err(color_exist, ?v(<<"id">>, Color))};
	    Error ->
		Error
	end,
    {reply, Reply, State};

handle_call({update_w_color, Merchant, Attrs}, _From, State) ->
    ?DEBUG("update_w_color with Merchant, attrs ~p", [Merchant, Attrs]),
    ColorId  = ?v(<<"color_id">>, Attrs),
    Name     = ?v(<<"name">>, Attrs),
    Type     = ?v(<<"type">>, Attrs),
    Remark   = ?v(<<"remark">>, Attrs),

    Updates = ?utils:v(name, string, Name)
	++ ?utils:v(type, integer, Type)
	++ ?utils:v(Remark, string, Remark), 

    ?DEBUG("updates ~p", [Updates]),

    Sql  = "update colors set "
	++ ?utils:to_sqls(proplists, comma, Updates)
	++ " where merchant=" ++ ?to_s(Merchant)
	++ " and id=" ++ ?to_s(ColorId), 
    Reply = ?sql_utils:execute(write, Sql, ColorId),
    {reply, Reply, State};

handle_call({delete_w_color, Merchant, ColorId}, _From, State) ->
    ?DEBUG("delete_w_color with merchant ~p, colorId ~p", [Merchant, ColorId]), 
    Sql  = "update colors set deleted=" ++ ?to_s(?YES)
	++ " where=id" ++ ?to_s(ColorId)
	++ " and merchant=" ++ ?to_s(Merchant),

    Reply = ?sql_utils:execute(write, Sql, ColorId),
    {reply, Reply, State};

handle_call({list_w_color, Merchant}, _Form, State) ->
    ?DEBUG("list colors with merchant ~p", [Merchant]),
    Sql = "select a.id, a.name, a.type as tid, a.remark, b.name as type"
	++ " from colors a, color_type b"
	++ " where a.deleted = " ++ ?to_string(?NO)
	++ " and a.merchant=" ++ ?to_s(Merchant)
	++ " and a.type=b.id;",

    Reply = ?sql_utils:execute(read, Sql),
    ?DEBUG("reply ~p", [Reply]),
    {reply, Reply, State};

handle_call({list_w_color, Merchant, ColorIds}, _Form, State) ->
    ?DEBUG("list colors with merchant ~p, colorIds ~p", [Merchant, ColorIds]), 
    Sql = "select id, name from colors"
	" where " ++ ?utils:to_sqls(proplists, [{<<"id">>, ColorIds}])
	++ " and merchant=" ++ ?to_s(Merchant)
	++ " and deleted=" ++ ?to_s(?NO) ++ ";", 
    Reply = ?sql_utils:execute(read, Sql),
    ?DEBUG("reply ~p", [Reply]),
    {reply, Reply, State};


handle_call({new_size_group, Merchant, Attrs}, _From, State) ->
    ?DEBUG("new_size_group with merchant ~p, attrs ~p", [Merchant, Attrs]),
    Name     = ?value(<<"name">>, Attrs),
    
    Sql0 = "select id, name from size_group"
	" where name=\"" ++ ?to_s(Name) ++ "\""
	" and merchant=" ++ ?to_s(Merchant),
    
    Reply = 
	case ?sql_utils:execute(s_read, Sql0) of
	    {ok, []} ->
		Name = ?v(<<"name">>, Attrs),
		SI   = ?v(<<"si">>, Attrs, ""),
		SII  = ?v(<<"sii">>, Attrs, ""),
		SIII = ?v(<<"siii">>, Attrs, ""),
		SIV  = ?v(<<"siv">>, Attrs, ""),
		SV   = ?v(<<"sv">>, Attrs, ""),
		SVI  = ?v(<<"svi">>, Attrs, ""),

		Sql1 = "insert into size_group("
		    "name, si, sii, siii, siv, sv, svi, merchant) values("
		    "\'" ++ ?to_s(Name) ++ "\',"
		    "\'" ++ ?to_s(SI) ++ "\',"
		    "\'" ++ ?to_s(SII) ++ "\',"
		    "\'" ++ ?to_s(SIII) ++ "\',"
		    "\'" ++ ?to_s(SIV) ++ "\',"
		    "\'" ++ ?to_s(SV) ++ "\',"
		    "\'" ++ ?to_s(SVI) ++ "\',"
		    ++ ?to_s(Merchant) ++ ")", 
		?sql_utils:execute(insert, Sql1); 
	    {ok, Group} ->
		{error, ?err(size_group_exist, ?v(<<"id">>, Group))};
	    Error ->
		Error
	end,

    {reply, Reply, State};

handle_call({delete_size_group, Merchant, GId}, _From, State) ->
    ?DEBUG("delete_size_group with merchant ~p, GId ~p", [Merchant, GId]), 
    Sql  = "update size_group set deleted=" ++ ?to_s(?YES)
	++ " where merchant=" ++ ?to_s(Merchant)
	++ " and id=" ++ ?to_s(GId) ++ ";", 
    Reply = ?sql_utils:execute(write, Sql, GId),
    {reply, Reply, State};

handle_call({update_size_group, Merchant, Attrs}, _From, State) ->
    ?DEBUG("update_size_group with merchant ~p, attrs ~p", [Merchant, Attrs]),
    Gid      = ?v(<<"gid">>, Attrs),
    SI       = ?v(<<"si">>, Attrs),
    SII      = ?v(<<"sii">>, Attrs),
    SIII     = ?v(<<"siii">>, Attrs),
    SIV      = ?v(<<"siv">>, Attrs),
    SV       = ?v(<<"sv">>, Attrs),
    SVI      = ?v(<<"svi">>, Attrs),

    Updates = ?utils:v(si, string, SI)
	++ ?utils:v(sii, string, SII)
	++ ?utils:v(siii, string, SIII)
	++ ?utils:v(siv, string, SIV)
	++ ?utils:v(sv, string, SV)
	++ ?utils:v(svi, string, SVI),

    ?DEBUG("updates ~p", [Updates]),

    Sql  = "update size_group set "
	++ ?utils:to_sqls(proplists, comma, Updates)
	++ " where id=" ++ ?to_s(Gid)
	++ "and merchant=" ++ ?to_s(Merchant),

    Reply = ?sql_utils:execute(write, Sql, Gid),
    {reply, Reply, State};

handle_call({list_size_group, Merchant}, _From, State) ->
    ?DEBUG("lookup size group with merchant ~p", [Merchant]),
    Sql = "select id, name, si, sii, siii, siv, sv, svi"
	++ " from size_group"
	++ " where merchant = " ++ ?to_string(Merchant)
	++ " and deleted = " ++ ?to_string(?NO) ++ ";",

    Reply = ?sql_utils:execute(read, Sql), 
    {reply, Reply, State};


%% =============================================================================
%% brand
%% =============================================================================
handle_call({new_brand, Merchant, Brand, Firm}, _From, State) ->
    ?DEBUG("new_brand with merchant ~p, brand ~p, firm ~p",
	   [Merchant, Brand, Firm]),
    Sql = "select id, name, supplier from brands"
	++ " where name=" ++ "\'" ++ ?to_s(Brand) ++ "\'"
	++ " and supplier=" ++ ?to_s(Firm)
	++ " and merchant =" ++ ?to_s(Merchant) ++ ";",

    Reply = 
	case ?sql_utils:execute(s_read, Sql) of
	    {ok, []} ->
		Sql1 = 
		    "insert into brands"
		    ++"(name, supplier, merchant) values("
		    ++ "\"" ++?to_s(Brand) ++ "\","
		    ++ ?to_s(Firm) ++ ","
		    ++ ?to_s(Merchant) ++ ");",
		R = ?sql_utils:execute(insert, Sql1),
		?w_user_profile:update(brand, Merchant),
		R;
	    {ok, R} -> 
		{ok, ?v(<<"id">>, R)};
	    Error ->
		Error
	end,
    {reply, Reply, State};

handle_call({list_brand, Merchant}, _From, State) ->
    ?DEBUG("list_brand with merchant ~p", [Merchant]),
    Sql = "select a.id, a.name, a.supplier as supplier_id"
	", b.name as supplier"
	++ " from brands a"
	++ " left join suppliers b on a.supplier=b.id"
	++ " where a.merchant=" ++ ?to_s(Merchant)
	++ " and a.deleted = " ++ ?to_string(?NO) ++ ";",
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};


handle_call({new_type, Merchant, Type}, _From, State) ->
    ?DEBUG("new_type with merchant ~p, type ~p", [Merchant, Type]),
    
    Sql = "select id, name from inv_types"
	++ " where name=" ++ "\"" ++ ?to_s(Type) ++ "\""
	++ " and merchant=" ++ ?to_s(Merchant) ++ ";",

    Reply = 
	case ?sql_utils:execute(s_read, Sql) of
	    {ok, []} ->
		Sql1 = 
		    "insert into inv_types"
		    ++"(name, merchant) values("
		    ++ "\"" ++?to_s(Type) ++ "\","
		    ++ ?to_s(Merchant) ++ ");",
		R = ?sql_utils:execute(insert, Sql1),
		?w_user_profile:update(type, Merchant),
		R;
	    {ok, R} -> 
		{ok, ?v(<<"id">>, R)};
	    Error ->
		Error
	end,
    {reply, Reply, State};

handle_call({list_type, Merchant}, _From, State) ->
    ?DEBUG("list_type with merchant ~p", [Merchant]),
    Sql = "select id, name from inv_types"
	++ " where "
	++ " merchant = " ++ ?to_string(Merchant)
	++ " and deleted = " ++ ?to_string(?NO) ++ ";",
    Reply = ?sql_utils:execute(read, Sql),
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
