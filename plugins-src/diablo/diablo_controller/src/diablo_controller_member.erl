%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@huawei.com>
%%% @copyright (C) 2013, buxianhui
%%% @doc
%%%
%%% @end
%%% Created :  1 Jan 2013 by buxianhui <buxianhui@huawei.com>
%%%-------------------------------------------------------------------
-module(diablo_controller_member).

%% -include("../../../../deps/erlang-mysql-driver-master/include/mysql.hrl").
-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_server).

%% API
-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-export([member/2, delete_member/2, member/3,
	 get_all_members/0, get_member/2]).

-export([exchange/3, exchange/4, score_details/1, score_details/2,
	 score_rule/1, score_rule/2]).

-define(SERVER, ?MODULE). 

-record(state, {}).

get_all_members()->
    gen_server:call(?MODULE, {all_members}).

get_member(condition, Condition)->
    gen_server:call(?MODULE, {get_member_by_condition, Condition}).

delete_member(condition, Condition)->
    gen_server:call(?MODULE, {delete_member_by_condition, Condition}).

member(update, Condition, Fields)->
    gen_server:call(?MODULE, {member_update, Condition, Fields}).
	
member(new, Attrs)->
    gen_server:call(?MODULE, {new_member, Attrs}).

exchange(money_to_score, Condition, Balance)->
    gen_server:call(?MODULE, {money_to_score, Condition, Balance}).

exchange(score_to_money, Condition, Score, Gift) ->
    gen_server:call(?MODULE, {score_to_money, Condition, Score, Gift}).

score_details(produced) ->
    gen_server:call(?MODULE, score_produced_detail);
score_details(consumed) ->
    gen_server:call(?MODULE, score_consumed_detail).


score_details(produced, Condition) ->
    gen_server:call(?MODULE, {score_produced_detail, Condition});
score_details(consumed, Condition) ->
    gen_server:call(?MODULE, {score_consumed_detail, Condition}).

score_rule(detail)->
    gen_server:call(?MODULE, {detail, rule_money_to_score}).
score_rule(modify, Rule)->
    gen_server:call(?MODULE, {modify, rule_money_to_score, Rule}).

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

init([]) ->
    {ok, #state{}}.

handle_call({all_members}, _From, State)->
    ?DEBUG("Query all members with no condition", []),
    SQL = "select " ++ member_fields(fields)
	++ " from members "
	++ " where deleted = " ++ ?to_string(?NO) ++ ";", 
    {ok, Members}  = ?mysql:fetch(read, ?to_binary(SQL)), 
    {reply, Members, State};

handle_call({get_member_by_condition, Condition}, _From, State)->
    ?DEBUG("Query member with condtion: Condition ~p", [Condition]),
    
    SQL = "select "
	++ member_fields(fields)
	++ " from members "
	++ " where " ++ ?utils:to_sqls(proplists, Condition)
	++ " and deleted = " ++ ?to_string(?NO) ++ ";", 
    {ok, Member}  = ?mysql:fetch(read, ?to_binary(SQL)),
    {reply, Member, State};

handle_call({delete_member_by_condition, Condition}, _From, State)->
    ?DEBUG("Delete member with condtion ~p", [Condition]),
    C = ?utils:to_sqls(proplists, Condition),
    SQL = "update members set deleted = " ++ ?to_string(?YES)
	++ "where " ++  C ++ ";",
    {ok, _} = ?mysql:fetch(write, ?to_binary(SQL)),
    {reply, ok, State};

handle_call({member_update, Condition, Fields}, _From, State)->
    ?DEBUG("Update member with condtion: condition ~p, fields ~p", [Condition, Fields]),
    C = ?utils:to_sqls(proplists, Condition),
    ?DEBUG("C ~p", [C]),

    U = ?utils:to_sqls(proplists, Fields),
    ?DEBUG("U ~p", [U]),
    
    Sql = "update members set " ++ U ++ " where " ++ C ++ ";",    
    ?DEBUG("sql ~p", [Sql]),
    {ok, _} = ?mysql:fetch(write, Sql),
    {reply, ok, State};
    
handle_call({new_member, Attrs}, _From, State)->
    ?DEBUG("New member with attrs ~p", [Attrs]),

    Number    = ?value(<<"number">>, Attrs),
    Name      = ?value(<<"name">>, Attrs),
    Sex       = ?value(<<"sex">>, Attrs),
    Birthday  = ?value(<<"birthday">>, Attrs),
    Mobile    = ?value(<<"mobile">>, Attrs),
    SLA       = ?value(<<"sla">>, Attrs),
    Balance   = ?value(<<"balance">>, Attrs),
    Merchant  = ?value(<<"merchant">>, Attrs),
    
    QuerySql = "select " ++ member_fields(important) ++ " from members"
	++ " where "
	++ "mobile = " ++ "\'" ++ ?to_string(Mobile) ++ "\';",
    
    case ?mysql:fetch(read, QuerySql) of
	{ok, []} ->
	    %% get rules that how much money to exchange one score	    
	    case new_number(Number, Merchant) of
		{ok, NewNumber} ->
		    Score = rules(money_to_score, Balance),
		    Sql1 = member_sql(
			     insert, {NewNumber, Name, Sex, Birthday,
				      SLA, Mobile, Score, Balance, Merchant}),
		    ?DEBUG("Table member insert Sql ~ts", [Sql1]),
		    {ok, _} = ?mysql:fetch(write, Sql1),
		    
		    Sql2 = money_to_score_sql(
			     insert, {NewNumber, Sex, Mobile, Score, Balance}),
		    ?DEBUG("Table money_to_score_sql insert Sql ~p", [Sql2]),
		    {ok, _} = ?mysql:fetch(write, Sql2),
		{reply, {ok, Score}, State};
		{error, Error} ->
		    {reply, {error, Error}, State}
		end;
	{ok, _Any} ->
	    ?DEBUG("member with mobile ~p has been exist", [Mobile]),
	    {reply, {error, ?err(member_exist, Mobile)}, State}
    end;

handle_call({money_to_score, Condition, Balance}, _From, State)->
    ?DEBUG("money_to_score with parameters: condition=~p, update=~p", [Condition, Balance]),
    
    QuerySql =  "select " ++ member_fields(important) ++ " from members"
	++ " where "
	++ ?utils:to_sqls(proplists, Condition) ++ ";",
    
    case ?mysql:fetch(read, ?to_binary(QuerySql)) of
	{ok, []} ->
	    {reply, {error, {<<"1002">>, <<"member_not_exist">>}}, State};
	{ok, {Record}} ->
	    Score = rules(money_to_score, ?to_integer(Balance)),
	    Sql1 = "update members set total_score "
		++ " = total_score + " ++ ?to_string(Score)
		++ " where "
		++ ?utils:to_sqls(proplists, Condition) ++ ";",
	    ?DEBUG("Table member insert Sql=~p", [Sql1]),
	    {ok, _} = ?mysql:fetch(write, Sql1),

	    Number = ?value(<<"number">>, Record),
	    %% Name = ?value(<<"name">>, Record),
	    Sex = ?value(<<"sex">>, Record),
	    Mobile = ?value(<<"mobile">>, Record),
	    OldScore = ?value(<<"total_score">>, Record),
	    
	    Sql2 = money_to_score_sql(insert, {Number, Sex, Mobile, Score, Balance}),
	    ?DEBUG("Table money_to_score insert Sql=~p", [Sql1]),
	    {ok, _} = ?mysql:fetch(write, Sql2),
	    	    
	    {reply, {ok, Score + OldScore}, State}
    end;

handle_call({score_to_money, {_, V} = Condition, ConsumeScore, Gift}, _From, State)->
    ?DEBUG("score_to_money with paramters: condition ~p, Score ~p gift ~p",
	   [Condition, ConsumeScore, Gift]),

    C = ?utils:to_sqls(proplists, ?to_tuplelist(Condition)),
    ?DEBUG("C ~p", [C]),
    
    QuerySql = "select " ++ member_fields(important) ++ ", exchange_score from members"
	++ " where " ++ C ++ ";" ,
    
    case ?mysql:fetch(read, ?to_binary(QuerySql)) of
	{ok, []} ->
	    {reply, ?err(member_not_exist, V), State};
	{ok, {Value}} ->
	    TotalScore = ?value(<<"total_score">>, Value),
	    %% Name = ?value(<<"name">>, Value),
	    Number = ?value(<<"number">>, Value),
	    ExchangedScore = ?value(<<"exchange_score">>, Value),
	    Sex = ?value(<<"sex">>, Value),
	    Mobile = ?value(<<"mobile">>, Value),
	    
	    case TotalScore < ?to_integer(ConsumeScore) of
		true ->
		    {reply, ?err(not_enough_score, Number), State};
		false ->
		    Sql1 = "update members set total_score = "
			++ ?to_string(TotalScore) ++ ","
			++ "exchange_score = "
			++ ?to_string(ExchangedScore + ?to_integer(ConsumeScore))
			++ " where " ++ C ++  ";",
		    
		    ?DEBUG("Table member insert Sql=~p", [Sql1]),
		    {ok, _} = ?mysql:fetch(write, Sql1),

		    Sql2 = score_to_money_sql(
			     insert,
			     {Number, Sex, Mobile, ConsumeScore, Gift}),
		    ?DEBUG("Table score_to_money insert Sql=~ts", [Sql2]),
		    {ok, _} = ?mysql:fetch(write, Sql2),

		    {reply, {ok, TotalScore - ?to_integer(ConsumeScore)}, State}
	    end
    end;

handle_call(score_produced_detail, _From, State)->
    QuerySql = "select a.id, a.number, a.sex, b.name,"
	++ "a.mobile, a.produced_score, a.consumed_balance, a.produced_date" 
	++ " from  money_to_score a"
	++ " left join members b on a.number = b.number;",
    {ok, Members}  = ?mysql:fetch(read, ?to_binary(QuerySql)), 
    {reply, Members, State};

handle_call(score_consumed_detail, _From, State)->
    QuerySql = "select a.id, a.number, b.name, a.sex, a.mobile, a.consumed_score,"
	++ "a.gift, a.consumed_date"
	++ " from score_to_money a"
	++ " left join members b on a.number = b.number;",
    {ok, Members}  = ?mysql:fetch(read, ?to_binary(QuerySql)), 
    {reply, Members, State};

handle_call({score_produced_detail, Condition}, _From, State)->
    ?DEBUG("score_produced_detail with condtion ~p", [Condition]),
    NewCondtion = ?utils:correct_condition(<<"b.">>, Condition),
    Sql = "select a.id, a.number, a.sex, b.name,"
	++ "a.mobile, a.produced_score, a.consumed_balance, a.produced_date" 
	++ " from  money_to_score a"
	++ " left join members b on a.number = b.number"
	++ " and " ++ ?utils:to_sqls(proplists, NewCondtion) ++ ";",
    {ok, Details}  = ?mysql:fetch(read, ?to_binary(Sql)), 
    {reply, Details, State};

handle_call({score_consumed_detail, Condition}, _From, State)->
    ?DEBUG("score_consumed_detail with condtion ~p", [Condition]),
    NewCondtion = ?utils:correct_condition(<<"b.">>, Condition),
    Sql = "select a.id, a.number, b.name, a.sex, a.mobile, a.consumed_score,"
	++ "a.gift, a.consumed_date"
	++ " from score_to_money a"
	++ " left join members b on a.number = b.number"
	++ " and " ++ ?utils:to_sqls(proplists, NewCondtion) ++ ";",
    {ok, Details}  = ?mysql:fetch(read, ?to_binary(Sql)), 
    {reply, Details, State};

handle_call({detail, rule_money_to_score}, _From, State)->
    ?DEBUG("Score rule with money to score"),
    Sql = "select id, money, produced_score from rule_money_to_score;",
    {ok, Rule} = ?mysql:fetch(read, ?to_binary(Sql)),
    {reply, Rule, State};

handle_call({modify_rule_money_to_score, Values}, _Form, State)->
    ?FORMAT("Modify score rule with money to score with parameters: value=~p", [Values]),
    ?DEBUG("Modify score rule with money to score with parameters: value=~p", [Values]),
    
    [{<<"money">>, Balance}, {<<"produced_score">>, Score}] = Values,
    Sql1 = pandora_utils:construct_sqls(update_single_no_condition, {Values, "rule_money_to_score"}),
    ?FORMAT("Table rule_money_to_score insert sql=~p", [Sql1]),
    ?DEBUG("Table rule_money_to_score insert sql=~p", [Sql1]),
    
    Sql2 = rule_score_history_sql(insert, {Balance, Score, "0", "admin"}),
    ?FORMAT("Table rule_score_history insert sql=~p", [Sql2]),
    ?DEBUG("Table rule_score_history insert sql=~p", [Sql2]),

    Sqls = pandora_utils:combine_sql_from_list([{Sql1}], [{Sql2}], []),
    {reply, diablo_controller_mysql:fetch(batch_write_transaction, Sqls), State};
    
handle_call(_Request, _From, State) ->
    ?DEBUG("receive unkown message ~p~n", [_Request]),
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

new_number(Number, Merchant)->
    case Number of
	undefined ->
	    %% no number input, generator a new one
	    Sn = ?to_string(?inventory_sn:sn(member, Merchant)),
	    {ok, ?utils:pack_string(Sn, 0)};
	Seq ->
	    Sql = "select number from members where number = "
		++ "\"" ++ ?to_string(Seq) ++ "\";",
	    case ?mysql:fetch(read, Sql) of
		{ok, []} -> {ok, Number};
		_AnySeq  -> {error, ?err(number_exist, Number)}
	    end
    end.

rules(money_to_score, Money)->
    SQL = "select money, produced_score from rule_money_to_score;",
    case ?mysql:fetch(read, SQL) of
	{ok, []} ->
	    %% defalut one money to one score
	     ?to_integer(Money);
	{ok, {[{<<"money">>, Scale}, {<<"produced_score">>, ProducedScore}]}}->
	   ?to_integer(Money) div round(Scale) * ProducedScore
    end.

member_fields(fields)->
    "id, number, name, sex, entry_date, birthday, sla,"
	++ " mobile, total_score, exchange_score, total_balance";
member_fields(important) ->
    "number, name, sex, mobile, total_score".

member_sql(insert, {Number, Name, Sex, Birthday, SLA,
		    Mobile, Score, Balance, Merchant})->
    "insert into "
	++ "members("
	++ "number, name, sex, entry_date, birthday, SLA, "
	++ "mobile, total_score, total_balance, merchant)"
	++ " values ("
	++ "\"" ++ ?to_string(Number) ++ "\", "
	++ "\"" ++ ?to_string(Name) ++ "\", "
	++ "\"" ++ ?to_string(Sex) ++ "\", "
	++ "\"" ++ ?utils:current_time(localtime) ++ "\", "
	++ "\"" ++ ?to_string(Birthday) ++ "\", "
	++ ?to_string(SLA) ++ ", "
	++ "\"" ++ ?to_string(Mobile) ++ "\", "
	++ ?to_string(Score) ++ ", "
	++ ?to_string(Balance) ++ ", "
	++ ?to_string(Merchant)
	++ ");".

money_to_score_sql(insert, {Number, Sex, Mobile, ProducedScore, ConsumedBalance})->
    "insert into money_to_score"
	++ "(number, sex, mobile, produced_score, consumed_balance, produced_date)"
	++ " values("
	++ "\"" ++ ?to_string(Number) ++ "\", "
	++ "\"" ++ ?to_string(Sex) ++ "\", "
	++ "\"" ++ ?to_string(Mobile) ++ "\", "
	++ ?to_string(ProducedScore) ++ ", "
	++ ?to_string(ConsumedBalance) ++ ", "
	++ "\"" ++ ?utils:current_time(localtime) ++ "\");".

score_to_money_sql(insert, {Number, Sex, Mobile, ConsumedScore, undefined})->
    score_to_money_sql(insert, {Number, Sex, Mobile, ConsumedScore, "null"});

score_to_money_sql(insert, {Number, Sex, Mobile, ConsumedScore, Gift})->
    "insert into score_to_money "
	++ "(number, sex, mobile, consumed_score, gift, consumed_date)"
	++ "values("
	++ "\"" ++ ?to_string(Number) ++ "\","
	%% ++ "\"" ++ ?to_string(Name) ++ "\","
	++ ?to_string(Sex) ++ ","
	++ "\"" ++ ?to_string(Mobile) ++ "\","
	++  ?to_string(ConsumedScore) ++ ","
	++ "\"" ++ ?to_string(Gift) ++ "\","
	++ "\"" ++ ?utils:current_time(localtime) ++ "\");".

rule_score_history_sql(insert, {Money, Score, Rule, Operator})->
    "insert into rule_score_history"
	++ "(money, score, modify_date, rule, operator)"
	++ "values("
	++ Money ++ ","
	++ Score ++ ","
	++ "\"" ++ ?utils:current_time(localtime) ++ "\","
	++ Rule ++ ","
	++ "\"" ++ Operator ++ "\");".
