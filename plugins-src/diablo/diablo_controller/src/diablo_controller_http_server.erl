%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright SeasunGame(C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 20 Jun 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_controller_http_server).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-export([start/0,  dispatch/2]).

start() ->
    {file, Here} = code:is_loaded(?MODULE),
    BaseDir = filename:dirname(filename:dirname(Here)),
    Path = filename:join([BaseDir, "hdoc/"]),

    %% default 80
    Port =
	case application:get_env(diablo_controller, diablo_port) of
	    {ok, Any} -> Any;
	    _ -> 80
	end,

    Loop = fun(Req) -> ?MODULE:dispatch(Req, Path) end,
    
    HttpOpts = [{loop, Loop},
		{port, Port},
		{name, ?MODULE}],
    
    {ok, _Http} = mochiweb_http:start(HttpOpts),
    ?INFO("success to start http server on port, ~p", [Port]),
    ok.


valid_session(Req) ->
    case Req:get_cookie_value(?QZG_DY_SESSION) of
	undefined -> %% redirect to login page
	    {error, no_session};
	ESession ->
	    %% ?DEBUG("MSession ~p", [ESession]),
	    DSession = mochiweb_base64url:decode(ESession),
            case ?session:lookup(DSession) of
                {ok, []} -> %% session time out or lost
                    %% ?INFO("invalid session ~p", [DSession]),
                    {error, {invalid_session, {DSession, ESession}}};
                {ok, _} -> %% valid session
                    {ok, valid_session}
            end
	    %% case 
	    %% 	mochiweb_session:check_session_cookie(
	    %% 	  ?to_b(MSession), 3600 * 12, fun(A) -> A end, ?QZG_DY_SESSION) of
	    %% 	{true, [_, SessionId]} -> 
	    %% 	    case ?session:lookup(SessionId) of
	    %% 		{ok, []} -> %% session time out or lost
	    %% 		    %% ?INFO("invalid session ~p", [SessionId]),
	    %% 		    {error, {invalid_session, MSession}};
	    %% 		{ok, _} -> %% valid session 
	    %% 		    {ok, valid_session}
	    %% 	    end;
	    %% 	{false, []} ->
	    %% 	    {error, no_session};
	    %% 	{false, [_, SessionId]} ->
	    %% 	    ?INFO("failed to check session ~p", [SessionId]),
	    %% 	    {error, {invalid_session, MSession}}
	    %% end
    end.	    

dispatch(Req, DocRoot) ->
    %% check session
    "/" ++ Path = Req:get(path),
	%% try
	%%     "/" ++ PPath = Req:get(path),
	%%     PPath
	%% catch
	%%     _:_ -> unkown_path
	%% end,
				  
			      
		     
    %% ?DEBUG("Req ~p", [Req]),
    %% ?DEBUG("Path = ~p", [Path]),
    try
	case Req:get(method) of
	    Method when Method =:= 'GET'; Method =:= 'HEAD' ->
		case Path of
		    [] -> root(Req);
		    _ ->
			case url_dispatch(Req, ?http_route:url_match(get)) of
			    none ->
				%% ?DEBUG("Path ~p", [Path]),
				case filelib:is_file(
				       filename:join([DocRoot, Path])) of
				    true ->
					%% ?DEBUG("Req ~p", [Req]),
					Req:serve_file(Path, DocRoot);
				    false->
					Req:not_found()
				end;
			    Response ->
				Response
			end
		end;
	    Method when Method =:= 'POST' ->
		Payload = Req:recv_body(),
		?DEBUG("post data ~ts", [Payload]),
		case url_dispatch(Req, ?http_route:url_match(post, Payload)) of
		    none ->
			case filelib:is_file(
			       filename:join([DocRoot, Path])) of
			    true ->
				Req:serve_file(Path, DocRoot);
			    false->
				Req:not_found()
			end;
		    Response ->
			Response
		end;
	    Method when Method =:= 'DELETE' ->
		case url_dispatch(Req, ?http_route:url_match(delete)) of
		    none ->
			case filelib:is_file(
			       filename:join([DocRoot, Path])) of
			    true ->
				Req:serve_file(
				  Path, DocRoot,
				  [{'Cache-Control',"max-age=14400"}]);
			    false->
				Req:not_found()
			end;
		    Response ->
			Response
		end;
	    Method when Method =:= 'OPTIONS'; Method =:= 'TRACE' -> 
		case filelib:is_file(
		       filename:join([DocRoot, Path])) of
		    true ->
			Req:serve_file(Path, DocRoot);
		    false->
			Req:not_found()
		end 
	end
    catch
	exit:{timeout, What} ->
	    ?DEBUG("request timeout:~p", [What]),
	    Report = ["web request timeout",
                      {path, Path},
                      {what, What},
                      {trace, erlang:get_stacktrace()}],
	    ?ERROR("Request failed, timeout: ~p", [Report]),
	    Req:respond({596, [{"Content-Type", "text/plain"}],
                         "request timeout, sorry\n"});
        Type:What ->
	    ?DEBUG("request fialed: ~p:~p", [Type, What]),
            Report = ["web request failed",
                      {path, Path},
                      {type, Type}, {what, What},
                      {trace, erlang:get_stacktrace()}],
	    %% ?DEBUG("Request failed: ~p ", [Report]),
            ?ERROR("Request failed: ~p", [Report]),
            %% NOTE: mustache templates need \ because they are not awesome.
            Req:respond({500, [{"Content-Type", "text/plain"}],
                         "request failed, sorry\n"})
    end.

root(Req) ->
    %% ?INFO("start login...", []),
    {ok, HTMLOutput} = login:render([{show_error,   "false"}]),
    Req:respond({200, [{"Content-Type", "text/html"}], HTMLOutput}).

url_dispatch(_, []) ->
    none;
url_dispatch(Req, [{Regexp,  Function}|T]) ->
    "/" ++ Path = Req:get(path),
    Method = Req:get(method),
    Match = re:run(Path, Regexp, [global, {capture, all_but_first, list}]),

    %% ?DEBUG("Path ~p, Method ~p, Math ~p", [Path, Method, Match]),

    case {Match, Method, Path} of
	{ {match, [[]]}, 'GET', "wechat" } ->
	    ?wechat_request:action(Req);
	{ {match, [MatchList]}, _Method, _Path } ->
	    %% ?DEBUG("MatchList ~p", [MatchList]),
	    case valid_session(Req) of
		{ok, _} ->
		    case length(MatchList) of
			0 ->
			    %% No any URL param
			    Function({Method, Req});
			Length when Length > 0 ->
			    Function({Method, Req, MatchList})
		    end;
		%% {error, _} when Path =:= "login"->
		%%     %% Function({Method, Req, [["login"]]});
		%%     ?login_request:action(Req, login);
		{error, _Error} ->
		    ?INFO("failed to check session of url ~p,"
		    	  "reseaon ~p, redirect to login...", [Path, _Error]),
		    %% {ECode, Error} = ?err(operation_invalid_session, Error),
		    %% Req:respond({599,
		    %% 		 [{"Content-Type", "application/json"}],
		    %% 		 ejson:encode({[{<<"ecode">>, ?to_i(ECode)},
		    %% 				{<<"einfo">>, ?to_b(Error)}]})})
		    %% case length(string:tokens(Path, "/")) of
		    %% 	1 ->
		    case _Error of
			no_session ->
			    Req:respond({302, [{"Location", "/"},
					       {"Content-Type", "text/html; charset=UTF-8"}],
					 "Redirecting /"});
			{invalid_session, {DSession, ESession}} -> 
			    ?DEBUG("invalid session ~p", [ESession]),
			    Cookie = mochiweb_cookies:cookie(
                                       ?QZG_DY_SESSION,
                                       DSession,
                                       [{max_age, 0}, {path, "/"}]),
			    Req:respond({302,
					 [{"Location", "/"},
					  {"Content-Type", "text/html; charset=UTF-8"}, Cookie],
					 "Redirecting /"})
			    %% login(invalid_session, Req, SessionId)
		    end;
		_ ->
		    Req:respond({599, [{"Content-Type", "text/plain"}],
				 "请求失败，非法访问\n"})
	    end;
	{nomatch, _Method,  "login"} ->
	    ?login_request:action(Req, login);
	%% nomatch when Path =:= "login_force" ->
	{nomatch, _Method, "login_force"}->
	    ?login_request:action(Req, login_force);
	%% nomatch when Path =:= "login_redirect" ->
	%%     %% Payload = Req:recv_body(),
	%%     %% {struct, P} = mochijson2:decode(Payload),
	%%     %% RedirectPath = ?v(<<"redirect">>, P),
	%%     ?utils:respond(200, Req, {0, success}); 
	_ ->
	    url_dispatch(Req, T)		
    end.


%% login(invalid_session, Req, SessionId) ->
%%     {ok, HTMLOutput} =
%% 	login:render(
%% 	  [{show_error, "true"},
%% 	   {login_error, "用户会话非法，请重新登录！！"}]),
%%     try
%% 	Cookie = mochiweb_cookies:cookie(
%% 		   ?QZG_DY_SESSION,
%% 		   SessionId,
%% 		   [{max_age, 0}]), 
%% 	Req:respond({200,
%% 		     [{"Content-Type", "text/html"}, Cookie],
%% 		     HTMLOutput})
%%     catch
%% 	_:_Error ->
%% 	    Req:respond({200, [{"Content-Type", "text/html"}], HTMLOutput})
%%     end.
