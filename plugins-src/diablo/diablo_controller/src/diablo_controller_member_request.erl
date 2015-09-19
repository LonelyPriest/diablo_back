%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright SeasunGame (C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 11 Aug 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_controller_member_request).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_request).

-export([action/2, action/3, action/4]).

action(Session, Req) ->
    ?DEBUG("GET Req ~n~p", [Req]),
    {ok, HTMLOutput} = member_frame:render(
			 [
			  {navbar, ?menu:navbars(?MODULE, Session)},
			  {sidebar, sidebar(Session)},
			  {ngapp, "memberApp"},
			  {ngcontroller, "memberCtrl"}]),
    Req:respond({200, [{"Content-Type", "text/html"}], HTMLOutput}).
    %% Req:ok({"text/html", HTMLOutput});

%%--------------------------------------------------------------------
%% @desc: GET, DELETE request
%%--------------------------------------------------------------------
action(Session, Req, {"list_member"}) ->
    ?DEBUG("member list all with session ~p", [Session]),
    Merchant = ?session:get(merchant, Session),
    Members = ?member:get_member(condition, {<<"merchant">>, Merchant}),
    ?DEBUG("get members ~p", [Members]),
    ?utils:respond(200, batch, Req, Members);

%%--------------------------------------------------------------------
%% @desc: GET action
%%--------------------------------------------------------------------
action(Session, Req, {"acc_score_detail"}) ->
    ?DEBUG("acc_score_detail with session ~p", [Session]),
    Merchant = ?session:get(merchant, Session),
    Members = ?member:score_details(produced, {<<"merchant">>, Merchant}),
    ?utils:respond(200, batch, Req, Members);

action(Session, Req, {"exchange_score_detail"}) ->
    ?DEBUG("ex_score_detail with session ~p", [Session]),
    Merchant = ?session:get(merchant, Session),
    Members = ?member:score_details(consumed, {<<"merchant">>, Merchant}),
    ?utils:respond(200, batch, Req, Members);

action(Session, Req, {"query_score_strategy"}) ->
    ?DEBUG("score_strategy with session ~p", [Session]),
    Rule = ?member:score_rule(detail),
    ?utils:respond(200, batch, Req, [Rule]);

action(Session, Req, {"get_member_by_number", Number}) ->
    ?DEBUG("get_member_by_number with session ~p,  Number ~p", [Session, Number]),
    Member = ?member:get_member(condition, {"number", ?to_binary(Number)}),
    ?utils:respond(200, object, Req, Member);

action(Session, Req, {"delete_member", Number}) ->
    ?DEBUG("delete_member with session ~p,  Number ~p", [Session, Number]),
    ok = ?member:delete_member(condition, {"number", ?to_binary(Number)}),
    ?utils:respond(200, Req, ?succ(delete_member, Number)).


%%--------------------------------------------------------------------
%% @desc: POST action
%%--------------------------------------------------------------------
action(Session, Req, {"exchange_score", Number}, Payload) ->
    ?DEBUG("consumed_socre with session ~p,  Number ~p, payload",
	   [Session, Number, Payload]),
    ConsumedScore = ?value(<<"consumed_score">>, Payload),
    Gift = ?value(<<"gift">>, Payload),
    %% modify the member info
    {ok, _} = ?member:exchange(
		 score_to_money,
		 {"number", ?to_binary(Number)},
		 ?to_integer(ConsumedScore),
		 Gift),
    
    %% record this action
    ?utils:respond(200, Req, ?succ(score_to_money, Number));

action(Session, Req, {"new_member"}, Payload) ->
    ?DEBUG("new_member with session ~p, payload ~p", [Session, Payload]),
    action(Session, Req, {"new_member", undefined}, Payload);
action(Session, Req, {"new_member", Number}, Payload) ->
    ?DEBUG("new_member with session ~p, number ~p, payload ~p",
	   [Session, Number, Payload]),
    %% Number    = ?value(<<"number">>, P),
    %% Name      = ?value(<<"name">>, Payload),
    %% Sex       = ?value(<<"sex">>, Payload),
    %% Birthday  = ?value(<<"birthday">>, Payload),
    Mobile    = ?value(<<"mobile">>, Payload),
    Merchant  = ?session:get(merchant, Session),
    %% SLA       = ?value(<<"sla">>, Payload),
    %% Balance   = ?value(<<"balance">>, Payload),
    case ?member:member(new, [{<<"number">>, Number},
			      {<<"merchant">>, Merchant}|Payload]) of
	{ok, _Score} ->
	    ?utils:respond(200, Req, ?succ(add_member, Mobile));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"update_member", Number}, Payload) ->
    ?DEBUG("update_member with session ~p, number ~p, payload ~p",
	   [Session, Number, Payload]),
    %% Number = ?value(<<"number">>, P),
    Fields = proplists:delete(<<"number">>, Payload),
    ok = ?member:member(update, {<<"number">>, ?to_binary(Number)}, Fields),
    ?utils:respond(200, Req, ?succ(update_member, Number)).

sidebar(Session) ->
    %% sidebar(level_4_menu,
    %% 	    {
    %% 	      {"Virtual Machine", "virtual_machine"},
    %% 	      {"Rooms", "rooms"},
    %% 	      [{{"GuangDong", "guangdong"},
    %% 		[{"JianXia_1", "JianXia1"}, {"JianXia_2", "JixanXia2"}]}]
    %% 	    }).

    %% sidebar(level_3_menu,
    %% 	    {
    %% 	      {"Virtual Machine", "virtual_machine"},
    %% 	      [{{"GuangDong", "guangdong"},
    %% 		[{"JianXia_1", "JianXia1"}, {"JianXia_2", "JixanXia2"}]}]
    %% 	    }).

    S1 = 
	case ?right_auth:authen(?list_member, Session) of
	    {ok, ?list_member} ->
		[{"list_member", "会员详情"}];
	    _ ->
		[]
	end,

    S2 = 
	case ?right_auth:authen(?new_member, Session) of
	    {ok, ?new_member} ->
		[{"new_member", "新增会员"}];
	    _ ->
		[]
	end,


    S3 = 
	case ?right_auth:authen(?acc_score_detail, Session) of
	    {ok, ?acc_score_detail} ->
		[{"acc_score_detail", "累计积分详情"}];
	    _ ->
		[]
	end,

    S4 = 
	case ?right_auth:authen(?exchange_score_detail, Session) of
	    {ok, ?exchange_score_detail} ->
		[{"ex_score_detail", "兑换积分详情"}];
	    _ ->
		[]
	end,

    S5 = 
	case ?right_auth:authen(?query_score_stratege, Session) of
	    {ok, ?query_score_stratege} ->
		[{"score_strategy", "积分策略"}];
	    _ ->
		[]
	end,

    MemberSidebar = 
	case S1 ++ S2 of
	    [] -> [];
	    S12 ->
		[{{"member", "会员管理", "glyphicon glyphicon-user"}, S12}]
	end,
    ScoreSidebar = 
	case S3 ++ S4 of
	    [] -> [];
	    S34 ->
		[{{"score", "积分管理", "glyphicon glyphicon-gift"}, S34}]
	end,

    StratgeBar = 
	case S5 of
	    [] -> [];
	    S5 ->
		[{{"strategy", "策略管理", "glyphicon glyphicon-cog"},S5}]
	end,

    ?menu:sidebar(
       level_2_menu, MemberSidebar ++ ScoreSidebar ++ StratgeBar).
    
    %% ?menu:sidebar(
    %%    level_2_menu,
    %%    [
    %% 	{{"member", "会员管理"}, S1 ++ S2},
	
    %% 	{{"score", "积分管理"}, S3 ++ S4},
	
    %% 	{{"strategy", "策略管理"},S5}
    %%    ]).
