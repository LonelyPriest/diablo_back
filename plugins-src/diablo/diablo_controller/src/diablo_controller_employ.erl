%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 17 Sep 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_controller_employ).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_server).

%% API
-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-export([employ/2, employ/3, employ/4]).

-define(SERVER, ?MODULE). 
-define(tbl_employ, "employees").


-record(state, {}).

%%%===================================================================
%%% API
%%%===================================================================
employ(new, Props) ->
    gen_server:call(?MODULE, {new_employee, Props});
employ(list, Merchant) ->
    employ(list, Merchant, []).

employ(delete, Merchant, EmployeeId) ->
    gen_server:call(?MODULE, {delete_employee, Merchant, EmployeeId}); 
employ(list, Merchant, Conditions) ->
    gen_server:call(?MODULE, {list_employee, Merchant, Conditions}).

employ(update, Merchant, EmployeeId, Attrs) ->
    gen_server:call(?MODULE, {update_employee, Merchant, EmployeeId, Attrs}).




start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
init([]) ->
    {ok, #state{}}.

handle_call({new_employee, Props}, _From, State)->
    ?DEBUG("new employ with props ~p", [Props]),
    Name     = ?v(<<"name">>, Props),
    %% NamePy   = ?v(<<"name_py">>, Props),
    Sex      = ?v(<<"sex">>, Props),
    Mobile   = ?v(<<"mobile">>, Props),
    Address  = ?v(<<"address">>, Props),
    Entry    = ?v(<<"entry">>, Props),
    Merchant = ?v(<<"merchant">>, Props),

    %% name can not be same
    Sql = "select " ++ fields()
	++ " from " ++ ?tbl_employ
	++ " where "
	++ " name=" ++ "\"" ++ ?to_s(Name) ++ "\""
	%% %% ++ " or "
	%% ++ " mobile = " ++ "\"" ++ ?to_s(Mobile) ++ "\""
	++ " and merchant=" ++ ?to_s(Merchant),
    
    case ?sql_utils:execute(s_read, Sql) of
	{ok, []} ->
	    Number = ?utils:pack_string(new_number(Merchant), 0),
	    Sql1 = "insert into " ++ ?tbl_employ
		++ "(number, name, sex, mobile, address, entry, merchant)"
		++ " values ("
		++ "\"" ++ ?to_s(Number) ++ "\","
		++ "\"" ++ ?to_s(Name) ++ "\","
		++ ?to_s(Sex) ++ ","
		++ "\"" ++ ?to_s(Mobile) ++ "\","
		++ "\"" ++ ?to_s(Address) ++ "\","
		++ "\"" ++ ?to_s(Entry) ++ "\","
		++ ?to_s(Merchant) ++ ");",
		
	    ?DEBUG("sql to employ ~ts", [?to_b(Sql1)]),
	    Reply = ?sql_utils:execute(write, Sql1, Name),
	    ?w_user_profile:update(employee, Merchant),
	    {reply, Reply, State};
	    %% case ?mysql:fetch(write, Sql1) of
	    %% 	{ok, _} ->
	    %% 	    {reply, {ok, Name}, State};
	    %% 	{error, {ECode, _}} ->
	    %% 	    {reply, {error, ?err(db_error, ECode)}, State}
	    %% end;
	{ok, _Any} ->
	    %% ?DEBUG("merchant ~p has been exist", [Name]),
	    {reply, {error, ?err(employ_exist, Name)}, State};
	Error ->
	    {reply, Error, State}
    end;

handle_call({delete_employee, Merchant, EmployeeId}, _From, State) ->
    ?DEBUG("delete_employee with merchant ~p, employeeId",
	   [Merchant, EmployeeId]), 
    Sql = "delete from employees where id=" ++ ?to_s(EmployeeId)
	++ " and merchant=" ++ ?to_s(Merchant),
    
    case ?mysql:fetch(write, Sql) of
	{ok, _} ->
	    {reply, {ok, EmployeeId}, State};
	{error, {_, Err}} ->
	    {reply, {error, ?err(db_error, Err), State}}
    end; 

handle_call({update_employee, Merchant, EmployeeId, Attrs}, _From, State) ->
    ?DEBUG("Update employee with merchant ~p, employeeId ~p~n, attrs ~p",
	   [Merchant, EmployeeId, Attrs]),

    Name    = ?v(<<"name">>, Attrs),
    Sex     = ?v(<<"sex">>, Attrs),
    Mobile  = ?v(<<"mobile">>, Attrs),
    Address = ?v(<<"address">>, Attrs),
    
    NameExist =
	case Name of
	    undefined -> {ok, []} ;
	    Name ->
		Sql = "select id, name from employees"
		    " where name=" ++ "\'" ++ ?to_s(Name) ++ "\'"
		    ++ " and merchant=" ++ ?to_s(Merchant)
		    ++ " and deleted=" ++ ?to_s(?NO),
		case ?mysql:fetch(read, Sql) of
		    {ok, R} -> {ok, R};
		    {error, {_, Err}} ->
			{error, ?err(db_error, Err)}
		end
	end,

    case NameExist of
	{ok, []} ->
	    Updates = ?utils:v(name, string, Name)
		++ ?utils:v(sex, integer, Sex)
		++ ?utils:v(mobile, string, Mobile)
		++ ?utils:v(address, string, Address),

	    Sql1 = "update employees set "
		++ ?utils:to_sqls(proplists, comma, Updates)
		++ " where id=" ++ ?to_s(EmployeeId)
		++ " and merchant=" ++ ?to_s(Merchant),

	    case ?mysql:fetch(write, Sql1) of
		{ok, _} -> {reply, {ok, EmployeeId}, State};
		{error, {_, Error}} ->
		    {reply, {error, ?err(db_error, Error)}, State}
	    end;
	{error, Error} ->
	    {reply, {error, Error}, State}
    end;

handle_call({list_employee, Merchant, Conditions}, _From, State) ->
    ?DEBUG("list_employee with Merchant ~p, Conditions ~p", [Merchant, Conditions]),
    Sql = "select " ++ fields()
	++ " from " ++ ?tbl_employ
	++ " where " ++
	case Conditions of
	    [] -> [];
	    Conditions ->
		?utils:to_sqls(proplists, Conditions)
		    ++ " and "
	end
	++ "merchant=" ++ ?to_s(Merchant)
	++ " and deleted=" ++ ?to_s(?NO),
    
    case ?mysql:fetch(read, Sql) of
	{ok, Employees} ->
	    {reply, {ok, Employees}, State};
	{error, {_, Error}} ->
	    {reply, ?err(db_error, Error), State}
    end;

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
fields() ->
    "id, number, name, sex, entry, position, mobile, address".

new_number(Merchant) ->
    ?inventory_sn:sn(member, Merchant). 
    
