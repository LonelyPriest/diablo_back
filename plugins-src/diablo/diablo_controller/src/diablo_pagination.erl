-module(diablo_pagination).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-export([pagination/4]).

pagination(no_response, TotalFun, PageFun, Payload) ->
    Match                = ?value(<<"match">>, Payload, 'and'),
    {struct, Conditions} =
	case ?value(<<"fields">>, Payload) of
	    undefined -> {struct, []};
	    Any -> Any
	end,

    CurrentPage          = ?value(<<"page">>, Payload), 
    ItemsPerPage         = ?value(<<"count">>, Payload, ?DEFAULT_ITEMS_PERPAGE),

    case page(Conditions, CurrentPage, fun(C) -> TotalFun(?to_a(Match), C) end) of
	{error, Error} -> {error, Error};
	{Total, _} -> 
	    case Total =:= 0 andalso CurrentPage =:= 1 of
		true ->
		    {ok, Total, []}; 
		false ->
		    case PageFun(?to_a(Match), CurrentPage, ItemsPerPage, Conditions) of
			{ok, Details} ->
			    {ok, Total, Details}; 
			{error, Error} ->
			    {error, Error}
		    end
	    end
    end;

pagination(TotalFun, PageFun, Req, Payload) ->
    Match                = ?value(<<"match">>, Payload, 'and'),
    {struct, Conditions} =
	case ?value(<<"fields">>, Payload) of
	    undefined ->
		case ?value(<<"condition">>, Payload) of
		    undefined -> {struct, []};
		    Any -> Any
		end;
	    Any -> Any
	end,

    ?DEBUG("conditions ~p", [Conditions]),
    CurrentPage          = ?value(<<"page">>, Payload), 
    ItemsPerPage         = ?value(<<"count">>, Payload, ?DEFAULT_ITEMS_PERPAGE),
    

    case page(Conditions, CurrentPage, fun(C) -> TotalFun(?to_a(Match), C) end) of
	{error, Error} ->
	    ?utils:respond(200, Req, Error);
	{Total, Others} -> 
	    case Total =:= 0 andalso CurrentPage =:= 1 of
		true ->
		    ?utils:respond(
		       200, object, Req, {[{<<"ecode">>, 0},
					   {<<"total">>, Total},
					   {<<"data">>, []}]}); 
		false ->
		    case PageFun(?to_a(Match), CurrentPage, ItemsPerPage, Conditions) of
			{ok, Details} ->
			    ?utils:respond(
			       200, object, Req, {[{<<"ecode">>, 0},
						   {<<"total">>, Total},
						   {<<"data">>, Details}] ++ Others}); 
			{error, Error} ->
			    ?utils:respond(200, Req, Error) 
		    end
	    end
    end.


page([], 1, _TotalFun) ->
    {0, []};
page(Conditions, 1, TotalFun) ->
    case TotalFun(Conditions) of
	{ok, []} ->
	    {0, []};
	{ok, R} ->
	    {?v(<<"total">>, R), proplists:delete(<<"total">>, R)};
	Error ->
	    Error
    end;
page(_, _, _TotalFun) ->
    {0, []}.
