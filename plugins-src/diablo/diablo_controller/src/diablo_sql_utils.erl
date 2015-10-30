-module(diablo_sql_utils).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-compile(export_all).


cut(fields_no_prifix, Fields) ->
    StartTime = ?value(<<"start_time">>, Fields),
    EndTime   = ?value(<<"end_time">>, Fields),

    CutFields = proplists:delete(
		  <<"end_time">>,
		  proplists:delete(<<"start_time">>, Fields)), 
    {StartTime, EndTime, CutFields};

cut(fields_with_prifix, Fields) ->
    StartTime = ?value(<<"start_time">>, Fields),
    EndTime   = ?value(<<"end_time">>, Fields),

    CutFields = proplists:delete(
		  <<"end_time">>,
		  proplists:delete(<<"start_time">>, Fields)),

    NewFields = ?utils:correct_condition(<<"a.">>, CutFields),
    {StartTime, EndTime, NewFields}.


fix_condition(time, Fix, Start, End) ->
    case condition(Fix, Start, End) of
	[] -> []; 
	TimeSql -> " and " ++ TimeSql
    end.

condition(time_no_prfix, undefined, undefined) ->
    [];
condition(time_no_prfix, Start, undefined) ->
    time_condition(Start, "entry_date", ge);
condition(time_no_prfix, undefined, End) ->
    time_condition(End, "entry_date", le);
condition(time_no_prfix, Start, End) ->
    time_condition(Start, "entry_date", ge)
	++ " and " ++ time_condition(End, "entry_date", le);

condition(time_with_prfix, undefined, undefined) ->
    [];
condition(time_with_prfix, Start, undefined) ->
    time_condition(Start, "a.entry_date", ge);
condition(time_with_prfix, undefined, End) ->
    time_condition(End, "a.entry_date", le);
condition(time_with_prfix, Start, End) ->
    time_condition(Start, "a.entry_date", ge)
	++ " and " ++ time_condition(End, "a.entry_date", le);

condition(page_desc, CurrentPage, ItemsPerPage) ->
    " order by id desc"
	++ " limit " ++ ?to_s((CurrentPage-1)*ItemsPerPage)
    	++ ", " ++ ?to_s(ItemsPerPage).

condition(page_desc, use_id, CurrentPage, ItemsPerPage) ->
    condition(page_desc, CurrentPage, ItemsPerPage);
condition(page_desc, use_sell, CurrentPage, ItemsPerPage) ->
    " order by sell desc"
	++ " limit " ++ ?to_s((CurrentPage-1)*ItemsPerPage)
    	++ ", " ++ ?to_s(ItemsPerPage).


condition(proplists, []) ->
    [];
condition(proplists, Conditions) -> 
    case ?utils:to_sqls(proplists, Conditions) of
	[] -> [];
	Sql -> " and " ++ Sql
    end;

condition(proplists_suffix, []) ->
    [];
condition(proplists_suffix, Conditions) ->
    case ?utils:to_sqls(proplists, Conditions) of
	[] -> [];
	SQL -> SQL ++ " and "
    end.
				 

time_condition(Time, TimeField, ge) ->
    case Time of
	undefined -> [];
	Time ->
	    ?to_s(TimeField) ++ ">=\"" ++ ?to_s(Time) ++ "\""
    end;
time_condition(Time, TimeField, le) ->
    case Time of
	undefined -> [];
	Time ->
	    ?to_s(TimeField) ++ "<=\"" ++ ?to_s(Time) ++ "\""
    end.

count_table(Table, Merchant, Conditions) ->
    count_table(Table, "count(*) as total", Merchant, Conditions).
count_table(Table, CountSql, Merchant, Conditions) -> 
    {StartTime, EndTime, NewConditions} = cut(fields_no_prifix, Conditions),
    
    Sql = "select " ++ CountSql ++ " from " ++ ?to_s(Table)
	++ " where " ++ condition(proplists_suffix, NewConditions) 
	++ " merchant="++ ?to_s(Merchant)
	++ " and " ++ condition(time_no_prfix, StartTime, EndTime),
    Sql.


execute(write, Sql, OkReturn) ->
    case ?mysql:fetch(write, Sql) of
	{ok, _} ->
	    {ok, OkReturn};
	{error, timeout} ->
	    {error, ?err(db_timeout, timeout)};
	{error, {_, Error}} ->
	    {error, ?err(db_error, Error)}
    end;

execute(transaction, Sqls, OkReturn) ->
    case ?mysql:fetch(transaction, Sqls) of
	{ok, _} ->
	    {ok, OkReturn};
	{error, timeout} ->
	    {error, ?err(db_timeout, timeout)};
	{error, Error} ->
	    {error, ?err(db_error, Error)} 
    end.
    
execute(read, Sql) ->
    case ?mysql:fetch(read, Sql) of
	{ok, Results} ->
	    {ok, ?to_tl(Results)};
	{error, timeout} ->
	    {error, ?err(db_timeout, timeout)};
	{error, {_, Error}} ->
	    {error, ?err(db_error, Error)}
    end;

execute(s_read, Sql) -> 
    case ?mysql:fetch(read, Sql) of
	{ok, []} ->
	    {ok, []};
	{ok, {Results}} ->
	    %% ?DEBUG("s_read sql result ~p", [Results]),
	    {ok, Results};
	{error, timeout} ->
	    {error, ?err(db_timeout, timeout)};
	{error, {_, Error}} ->
	    {error, ?err(db_error, Error)}
    end;

execute(insert, Sql) ->
    case ?mysql:fetch(insert, Sql) of
	{ok, InsertId} ->
	    {ok, InsertId};
	{error, timeout} ->
	    {error, ?err(db_error, timeout)}; 
	{error, {_, Error}} ->
	    {error, ?err(db_error, Error)}
    end.
	    
