%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright diablo(C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 13 Sep 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_controller_login_request).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").
-export([action/2]).
-export([test_login/3]).


-define(LOGIN_USER_ACTIVE,
	"该用户已登录系统，是否继续登录？").
-define(LOGIN_EXECCED_USER,
	"超过在线最大用户数限制，是否强制登录？注意：系统将踢出未在线时间最长用户！！").
-define(LOGIN_NO_USER_FIRE, "没有用户可以踢出！！注意：管理员用户无法踢出，请确认管理员是否在线！！").
-define(INVALID_USER, "非法用户！！").
-define(WRONG_USER_PASSWD, "用户名或密码错误").


test_login(UserName, Passwd, Force) ->
    case ?login:login(UserName, Passwd) of	
	{ok, UserDetail}    ->
	    StartInfo = 
		case ?session:get_session(by_user, UserName) of
		    {ok, []} ->
			start_force(Force, new_user, UserDetail); 
		    {ok, {SessionId, Session}} ->
			start_force(Force, old_user, 
				    SessionId, Session, UserDetail)
		end,
	    case StartInfo of
		{ok, {Cookie, Path}} ->
		    ?DEBUG("ok, login with cookie ~p, path ~p", [Cookie, Path]);
		{error, Error} ->
		    ?DEBUG("error, login error ~p", [Error])
	    end; 
	{error, Error} ->
	    ?DEBUG("login error ~p", [Error]),
	    ?DEBUG("error,  login error ~p", [Error])
    end.

action(Req, login) ->
    action(Req, login, false);
action(Req, login_force) ->
    action(Req, login, true).

action(Req, login, Force) ->
    %% ?DEBUG("login with client ip:~n ~p", [Req:get(peer)]),
    %% Payload = Req:recv_body(),
    %% {struct, Condition} = mochijson2:decode(Payload),
    
    Post = Req:parse_post(),
    ?DEBUG("post data ~p", [Post]),
    UserName = ?v("username", Post, []),
    Passwd   = ?v("password", Post, []),
    %% Force     = ?to_a(?v("force", Post, false)),

    LoginResponseFun =
	fun(Error) ->
		{ok, HTML} = login:render([{show_error, "true"},
					   {login_error, Error}]),
		Req:respond({200, [{"Content-Type", "text/html"}], HTML})
	end,

    LoginForceFun =
	fun(Error) ->
		{ok, HTML} = login_force:render([{login_error, Error},
						 {username, UserName},
						 {password, Passwd}]),
		Req:respond({200, [{"Content-Type", "text/html"}], HTML})
	end,

    case UserName of
	[] -> ?utils:respond(200, Req, ?err(login_no_user, none));
	UserName ->
	    case Passwd of
		[] ->
		    LoginResponseFun(?WRONG_USER_PASSWD);
		%% ?utils:respond(200, Req, ?err(login_no_password, none));
		Passwd ->
		    case ?login:login(UserName, Passwd) of	
			{ok, UserDetail}    ->
			    StartInfo = 
				case ?session:get_session(by_user, UserName) of
				    {ok, []} ->
					start_force(Force, new_user, UserDetail); 
				    {ok, {SessionId, Session}} -> 
					start_force(Force, old_user, 
						    SessionId, Session, UserDetail);
				    {error, more_session} ->
					{error, {1109, more_session}}
				end,
			    case StartInfo of
				{ok, {Cookie, Path}} ->
				    response_with_cookie(Req, Cookie, Path, UserName);
				{error, {1105, _}} ->
				    LoginForceFun(?LOGIN_USER_ACTIVE); 
				{error, {1106, _}} ->
				    LoginForceFun(?LOGIN_EXECCED_USER); 
				{error, {1107, _}} ->
				    LoginForceFun(?LOGIN_NO_USER_FIRE); 
				{error, {1108, _}} ->
				    LoginResponseFun(?INVALID_USER);
				{error, {1109, _}} ->
				    LoginResponseFun(?INVALID_USER)
				    %% ?utils:respond(200, Req, Error)
			    end; 
			{error, _Error} ->
			    LoginResponseFun(?WRONG_USER_PASSWD) 
			    %% ?DEBUG("login error ~p", [Error]),
			    %% ?utils:respond(200, Req, Error)
		    end 
	    end
    end.
    
    
response_with_cookie(Req, Cookie, Path, _UserName) ->
    %% Req:respond(
    %%   {200,
    %%    [{"Content-Type", "application/json"}, Cookie],
    %%    ejson:encode(
    %% 	 {[{<<"ecode">>, ?SUCCESS},
    %% 	   {<<"path">>,  ?to_b(Path)},
    %% 	   {<<"user">>,  UserName}]})}).
    Req:respond({301, [{"Location", Path},
		       {"Content-Type", "text/html; charset=UTF-8"},
		       Cookie],
		 "Redirecting " ++ Path}).

start_force(false, new_user, UserDetail) ->
    case ?v(<<"type">>, UserDetail) of
	?SUPER ->
	    {ok, start(with_new_session, UserDetail)};
	_ ->
	    UserName = ?v(<<"name">>, UserDetail),
	    case ?login:get(max_user, UserName) of
		{ok, {Merchant, MaxUser}} -> 
		    {ok, NowUsers} = ?session:get_user(number, Merchant),
		    case NowUsers + 1 > MaxUser of
			true ->
			    ?DEBUG("excedd max user of merchant ~p,now ~p,"
				   "max ~p", [Merchant, NowUsers, MaxUser]),
			    {error, ?err(login_exceed_user, Merchant)}; 
			false ->
			    {ok, start(with_new_session, UserDetail)}
		    end;
		{error, login_invalid_user} ->
		    {error, ?err(login_invalid_user, UserName)}
	    end
    end;

start_force(true, new_user, UserDetail) ->
    %% fire user that unused longest
    UserName = ?v(<<"name">>, UserDetail),
    {ok, {Merchant, _MaxUser}} = ?login:get(max_user, UserName),
    case ?session:delete(longest_unused, Merchant) of
	{error, no_users} ->
	    {error, ?err(login_no_user_fire, Merchant)};
	ok -> {ok, start(with_new_session, UserDetail)}
    end.

start_force(false, old_user, SessionId, Session, UserDetail) ->
    Now = ?utils:current_time(timestamp),
    case Now - ?session:get(time, Session) > 3600 * 2 of
	true -> %% more than half an hour, login direct 
	    ?session:delete(SessionId),
	    {ok, start(with_new_session, UserDetail)};
	false ->
	    {error, ?err(login_user_active, ?v(<<"id">>, UserDetail))}
    end;

start_force(true, old_user, SessionId, _Session, UserDetail) ->
    ?session:delete(SessionId),
    {ok, start(with_new_session, UserDetail)}.


start(with_new_session, UserDetail) ->
    ?DEBUG("new session ~p", [?v(<<"name">>, UserDetail)]),
    %% first, get login user role
    UserId = ?v(<<"id">>, UserDetail),
    Merchant = ?v(<<"merchant">>, UserDetail),

    %% create a new session
    {ok, SessionId} = ?session:new(UserDetail),

    CookieData = mochiweb_session:generate_session_data(
		   3600 * 12, SessionId, fun(A) -> A end, ?QZG_DY_SESSION),

    Cookie = mochiweb_cookies:cookie(
    	       ?QZG_DY_SESSION, CookieData, [{max_age, 3600 * 24 * 2}]),

    %% Cookie = mochiweb_cookies:cookie(
    %% 	       ?QZG_DY_SESSION, CookieData, [{max_age, -1}]),

    %% Cookie = mochiweb_cookies:cookie(?QZG_DY_SESSION, CookieData),

    %% Cookie = mochiweb_cookies:cookie(
    %% 	       "id", CookieDate,
    %% 	       [{path, "/"},
    %% 		{max_page, 20000},
    %% 		{local_time, calendar:universal_time_to_local_time(
    %% 			       calendar:universal_time())}
    %% 	       ]),

    %% Cookie = mochiweb_session:generate_session_cookie(
    %% 	       0, SessionId, fun(A) -> A end, ?QZG_DY_SESSION),

    %% use the first navigation
    [{Path, _Name, _Module, _Hidden}|_] =
	case ?v(<<"type">>, UserDetail) of
	    ?SUPER -> %% super login directly
		?right_auth:navbar(super);
	    _ ->
		?right_auth:navbar(user, UserId)
	end,

    %% create the right of this login user
    case ?v(<<"type">>, UserDetail) of
	?SUPER ->
	    ok;
	_Type ->
	    ok = ?right_auth:cache(right, UserId),
	    {ok, Merchant} = ?w_user_profile:new(Merchant),
	    {ok, Merchant, SessionId} = ?w_user_profile:new(Merchant, SessionId),
	    ok
    end,

    {Cookie, Path}. 
