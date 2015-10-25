-module(diablo_controller_utils).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-compile(export_all).


%%--------------------------------------------------------------------
%% @desc : get current time
%% @return: format yyyymmddhhmmsss
%%--------------------------------------------------------------------
current_time(localtime) ->
    {{Year, Month, Date}, {Hour, Minute, Second}} =
	calendar:now_to_local_time(erlang:now()),
    
    lists:flatten(
      io_lib:format("~4..0w~2..0w~2..0w~2..0w~2..0w~2..0w",
		    [Year, Month, Date, Hour, Minute, Second]));

current_time(format_localtime) ->
    {{Year, Month, Date}, {Hour, Minute, _Second}} =
	calendar:now_to_local_time(erlang:now()),

    lists:flatten(
      io_lib:format("~4..0w-~2..0w-~2..0w ~2..0w:~2..0w",
		    [Year, Month, Date, Hour, Minute]));

current_time(localdate) ->
    {{Year, Month, Date}, {_, _, _}} = calendar:now_to_local_time(erlang:now()),
    lists:flatten(io_lib:format("~4..0w-~2..0w-~2..0w", [Year, Month, Date]));

current_time(year) ->
    {{Year, _, _}, {_, _, _}} = calendar:now_to_local_time(erlang:now()),
    lists:flatten(io_lib:format("~4..0w", [Year]));

current_time(timestamp) ->
    {M, S, _} = erlang:now(),
    
    M * 1000000 + S;

current_time(db) ->
    "CURRENT_TIMESTAMP()";

current_time(db_unix_timestamp) ->
    "UNIX_TIMESTAMP()".

respond(batch, Fun, Req) ->
    case Fun() of
	{ok, Values} ->
	    ?MODULE:respond(200, batch, Req, Values);
	{error, _Error} ->
	    ?MODULE:respond(200, batch, Req, [])
    end; 
respond(object, Fun, Req) ->
    case Fun() of
	{ok, Value} ->
	    ?utils:respond(200, object, Req, {Value});
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

respond(200, Req, {ECode, Error}) ->
    Req:respond({200,
		 [{"Content-Type", "application/json"}],
		 ejson:encode({[{<<"ecode">>, ?to_i(ECode)},
				{<<"einfo">>, ?to_b(Error)}]})});

respond(200, _Req, Unkown) ->
    ?DEBUG("unexpect response: ~p", [Unkown]);

respond(StatusCode, Req, {ECode, Error}) ->
    Req:respond({StatusCode,
		 [{"Content-Type", "application/json"}],
		 ejson:encode({[{<<"ecode">>, ?to_i(ECode)},
				{<<"einfo">>, ?to_b(Error)}]})}).

error_respond(list, Req, {ECode, EInfo}) ->
    Req:respond({200,
		 [{"Content-Type", "application/json"}],
		 ejson:encode([{[{<<"ecode">>, ?to_i(ECode)},
				{<<"einfo">>, ?to_b(EInfo)}]}])}).

respond(200, batch, Req, Content) ->
    Req:respond({200,
		 [{"Content-Type", "application/json"}],
		 ejson:encode(?to_tl(Content))});

respond(200, object, Req, Content) ->
    Req:respond({200,
		 [{"Content-Type", "application/json"}],
		 ejson:encode(Content)});

respond(200, Req, {ECode, EInfo}, Extra) when is_tuple(Extra)->
    respond(200, Req, {ECode, EInfo}, [Extra]); 

respond(200, Req, {ECode, EInfo}, Extra) when is_list(Extra)->
    Req:respond({200,
		 [{"Content-Type", "application/json"}],
		 ejson:encode({[{<<"ecode">>, ?to_i(ECode)},
				{<<"einfo">>, ?to_b(EInfo)}] ++ Extra}
			     )});

respond(200, Headers, Req, {ECode, EInfo}) ->
    Req:respond({200,
		 [{"Content-Type", "application/json"},
		  Headers],
		 ejson:encode({[{<<"ecode">>, ?to_i(ECode)},
				{<<"einfo">>, ?to_b(EInfo)}]})});

respond(normal, Fun, Success, Req) ->
    case Fun() of
	{ok, Ok} ->
	    ?MODULE:respond(200, Req, Success(Ok));
	{error, Error} ->
	    ?MODULE:respond(200, Req, Error)
    end.


%% -----------------------------------------------------------------------------
%% @desc:   string present as a binary, to distinguish the number and string,
%%          such as 123 and "123"
%% @params: V -> list should be format [1, 2, 3],
%%               string should be format <<"123">>
%%               integer should be format 123
%% -----------------------------------------------------------------------------
to_sqls(proplists, {K, V}) when is_list(V)->
    S = lists:foldr(
	  fun(E, Acc)->
		  [case is_integer(E) of
		       true -> ?to_s(E);
		       false ->
			   case is_binary(E) of
			       true -> "\'" ++ ?to_s(E) ++ "\'";
			       false -> ?to_s(E)
			   end
		   end|Acc] end, [], V),
    case S of
	[] -> [];
	_  -> ?to_s(K) ++ " in(" ++ string:join(S, ",") ++ ")"
    end;
	
%% string
to_sqls(proplists, {K, V}) when is_binary(V) ->
    ?to_string(K) ++ "=" ++ "\'" ++ ?to_s(V) ++ "\'";

%% integer
to_sqls(proplists, {K, V}) when is_integer(V) ->
    ?to_string(K) ++ "=" ++ ?to_s(V);

%% float
to_sqls(proplists, {K, V}) when is_float(V)->
    ?to_string(K) ++ "=" ++ ?to_s(V);
	
%% -----------------------------------------------------------------------------
%% concat tuple list to a sql with 'and', such as
%% [{<<"a">>, 1}, {<<"b">, 2}] => a = 1 and b = 2
%% -----------------------------------------------------------------------------
to_sqls(proplists, Proplists) when is_list(Proplists)->
    L = lists:filter(fun({_, V}) ->
			     V =/= [] andalso V =/= undefined
		     end, Proplists),
    to_sqls(proplists, L, "").

to_sqls(proplists, [], SQL) ->
    SQL;
to_sqls(proplists, [Proplist], SQL) ->
    SQL ++ to_sqls(proplists, Proplist);
to_sqls(proplists, [Proplist|T], SQL) ->
    to_sqls(proplists, T, SQL ++ to_sqls(proplists, Proplist) ++ " and ");


%% -----------------------------------------------------------------------------
%% concat tuple list to a sql with ',', such as
%% [{<<"a">>, 1}, {<<"b">, 2}] => a = 1 , b = 2
%% -----------------------------------------------------------------------------
to_sqls(proplists, comma, Proplists) when is_list(Proplists)->
    to_sqls(proplists, comma, Proplists, "").
to_sqls(proplists, comma, [Proplist], SQL) ->
    SQL ++ to_sqls(proplists, Proplist);
to_sqls(proplists, comma, [H|T], SQL) ->
    to_sqls(proplists, comma, T, SQL ++ to_sqls(proplists, H) ++ ",").



%% -----------------------------------------------------------------------------
%% @desc: correct conditions with special prefix
%% @param: prefx -> such as "a."
%% @Conditions: the key-value tuple or list, sucha {<<"id">>, 1}
%% @return:    {<<"a.id">>, 1}
%% -----------------------------------------------------------------------------
correct_condition(Prefix, Conditions) when is_tuple(Conditions) ->
    correct_condition(Prefix, [Conditions], []);
correct_condition(Prefix, Conditions) ->
    correct_condition(Prefix, Conditions, []).
correct_condition(_Prefix, [], Conditions) ->
    lists:reverse(Conditions);
correct_condition(Prefix, [{K, V}|T], Conditions) ->
    correct_condition(Prefix, T,
		      [{<<Prefix/binary, K/binary>>, V}|Conditions]).

%% -----------------------------------------------------------------------------
%% @desc: set db value by key
%% @params: key -> table property name of db,
%%          keyType -> type, such as float, string, integer
%% @params: value -> value of key
%% 
%% -----------------------------------------------------------------------------
v(_Key, _KeyType, []) ->
    [];
v(_Key, _KeyType, undefined) ->
    [];
%% v(_Key, _KeyType, <<>>) ->
%%     [];
v(Key, KeyType, Value) ->
    [{?to_b(Key), case KeyType of
		      float   -> ?to_f(Value);
		      string  -> ?to_b(Value);
		      integer -> ?to_i(Value)
		  end
     }].

value_from_proplists(Key, {Proplists}) ->
    proplists:get_value(Key, Proplists); 
value_from_proplists(Key, Proplists) ->
    proplists:get_value(Key, Proplists).

pack_string(String, Pack) ->
    SS = ?to_string(String),
    pack_string(SS, ?to_string(Pack), length(SS)).
pack_string(String, _Pack, ?MAX_EMPLOYEE_ID) ->
    String;
pack_string(String, Pack, Length) ->
    pack_string(Pack ++ String, Pack, Length + length(Pack)).

%% =============================================================================
%% @desc: add the sequence number of lists
%% @param: lists  -> [ {[{<<"a1", 1>>}, {<<"a2">>, 2}]}, ...]
%% @return: lists -> [ {[{<<"order_id">>, 1}, {<<"a1", 1>>}, {<<"a2">>, 2}]}, ...]
%% =============================================================================
%% order(Lists) ->
%%     order(Lists, 1, []).
%% order([], _, OrderedLists) ->
%%     lists:reverse(OrderedLists);
%% order([{H}|T], Inc, OrderedLists) ->
%%     order(T, Inc + 1, [{[{<<"order_id">>, Inc}|H]}|OrderedLists]).
seperator(csv) ->",".

create_export_file(Prefix, Merchant, UserId)->
    {file, Here} = code:is_loaded(?MODULE),
    ExportDir = filename:join(
		  [filename:dirname(filename:dirname(Here)),
		   "hdoc", "export", ?to_s(Merchant)]),
    ?DEBUG("export dir ~p", [ExportDir]),
    UUID = knife_uuid:v5(string, ?to_s(UserId)),

    File = Prefix ++ "-" ++ UUID ++ ".csv",
    ExportFile = filename:join([ExportDir, File]),
    Url = filename:join(["export", ?to_s(Merchant), File]),

    case filelib:ensure_dir(ExportFile) of
	ok -> ok; 
	{error, _} -> ok = file:make_dir(ExportDir)
    end, 
    {ok, ExportFile, Url}.

write(Fd, Content) ->
    case file:write(Fd, Content) of
	ok -> ok;
	{error, Error} ->
	    throw({error, Error})
    end.
