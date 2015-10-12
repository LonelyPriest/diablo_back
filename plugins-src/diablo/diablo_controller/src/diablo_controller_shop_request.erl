-module(diablo_controller_shop_request).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_request).

-export([action/2, action/3, action/4]).

action(Session, Req) ->
    {ok, HTMLOutput} = shop_frame:render(
			 [
			  {navbar, ?menu:navbars(?MODULE, Session)},
			  {basebar, ?menu:w_basebar(Session)},
			  {sidebar, sidebar(Session)},
			  {ngapp, "shopApp"},
			  {ngcontroller, "shopCtrl"}]),
    Req:respond({200, [{"Content-Type", "text/html"}], HTMLOutput}).


%%--------------------------------------------------------------------
%% @desc: GET action
%%--------------------------------------------------------------------
action(Session, Req, {"list_shop"}) ->
    ?DEBUG("list_shop with session ~p", [Session]),
    Merchant = ?session:get(merchant, Session),
    ?utils:respond(batch, fun() -> ?shop:lookup(Merchant) end, Req);
%% {ok, M} = ?shop:lookup(?session:get(merchant, Session)),
%% ?utils:respond(200, batch, Req, M);

action(Session, Req, {"list_repo"}) ->
    ?DEBUG("list_repo with session ~p", [Session]),
    Merchant = ?session:get(merchant, Session),
    ?utils:respond(batch, fun() -> ?shop:repo(list, Merchant) end, Req);

action(Session, Req, {"list_badrepo"}) ->
    ?DEBUG("list_badrepo with session ~p", [Session]),
    Merchant = ?session:get(merchant, Session),
    ?utils:respond(batch, fun() -> ?shop:badrepo(list, Merchant) end, Req); 

%%--------------------------------------------------------------------
%% @desc: DELTE action
%%-------------------------------------------------------------------- 
action(Session, Req, {"delete_shop", Id}) ->
    ?DEBUG("delete_shop with session ~p, id ~p", [Session, Id]),
    
    Merchant = ?session:get(merchant, Session),
    ?utils:respond(normal,
		   fun()-> ?shop:shop(delete, Merchant, Id) end,
		   fun(ShopId)-> ?succ(delete_shop, ShopId) end,
		   Req).

    %% case ?shop:shop(delete, Merchant, ?to_i(Id)) of
    %% 	{ok, ShopId} ->
    %% 	    ?utils:respond(200, Req, ?succ(delete_shop, ShopId));
    %% 	{error, Error} ->
    %% 	    ?utils:respond(200, Req, Error)
    %% end. 

%% ================================================================================
%% POST
%% ================================================================================
action(Session, Req, {"new_shop"}, Payload) ->
    ?DEBUG("add a new shop with session ~p, paylaod ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    ?utils:respond(normal,
		   fun()-> ?shop:shop(new, Merchant, Payload) end,
		   fun(ShopId)-> ?succ(add_shop, ShopId) end,
		   Req);
    %% case ?shop:shop(new, [{<<"merchant">>, Merchant}|Payload]) of
    %% 	{ok, ShopId} ->
    %% 	    ?utils:respond(200, Req, ?succ(add_shop, ShopId));
    %% 	{error, Error} ->
    %% 	    ?utils:respond(200, Req, Error)
    %% end;

action(Session, Req, {"update_shop", Id}, Payload) ->
    ?DEBUG("update a shop with session ~p, id ~p, paylaod ~p",
	   [Session, Id, Payload]), 
    Merchant = ?session:get(merchant, Session),
    %% case ?shop:shop(update, Merchant, ?to_i(Id), Payload) of
    %% 	{ok, ShopId} ->
    %% 	    ?utils:respond(200, Req, ?succ(update_shop, ShopId));
    %% 	{error, Error} ->
    %% 	    ?utils:respond(200, Req, Error)
    %% end.
    ?utils:respond(normal,
		   fun()-> ?shop:shop(update, Merchant, Id, Payload) end,
		   fun(ShopId)-> ?succ(update_shop, ShopId) end,
		   Req);

%% repo
action(Session, Req, {"new_repo"}, Payload) ->
    Merchant = ?session:get(merchant, Session),
    ?utils:respond(normal,
		   fun()-> ?shop:repo(new,Merchant, Payload) end,
		   fun(RepoId)-> ?succ(add_repo, RepoId) end,
		   Req);

action(Session, Req, {"new_badrepo"}, Payload) ->
    Merchant = ?session:get(merchant, Session),
    ?utils:respond(normal,
		   fun()-> ?shop:badrepo(new,Merchant, Payload) end,
		   fun(RepoId)-> ?succ(add_repo, RepoId) end,
		   Req).

sidebar(Session) ->
    AuthenFun =
	fun(Actions) ->
		lists:foldr(
		  fun({Action, Detail}, Acc) ->
			  case ?right_auth:authen(Action, Session) of
			      {ok, Action} -> [Detail|Acc];
			      _ -> Acc
			  end 
		  end, [], Actions)
		
	end,

    ShopAuthen = AuthenFun(
		   [{?new_shop,
		     {"shop_new", "新增店铺", "glyphicon glyphicon-plus"}},
		    {?list_shop,
		     {"shop_detail", "店铺详情", "glyphicon glyphicon-book"}}
		   ]),

    RepoAuthen = AuthenFun(
		   [{?new_repo,
		     {"repo_new", "新增仓库", "glyphicon glyphicon-plus"}},
		    {?list_repo,
		     {"repo_detail", "仓库详情", "glyphicon glyphicon-book"}}
		   ]),

    BadRepoAuthen = AuthenFun(
		   [{?new_badrepo,
		     {"badrepo_new", "新增次品仓", "glyphicon glyphicon-plus"}},
		    {?list_badrepo,
		     {"badrepo_detail", "次品仓详情", "glyphicon glyphicon-book"}}
		   ]), 

    SidebarShop = 
	case ShopAuthen of
	    []   -> [];
	    Shop ->
		[{{"shop", "店铺", "icon icon-truck"}, Shop}] 
	end,

    SidebarRepo = 
	case RepoAuthen of
	    []   -> [];
	    Repo ->
		[{{"repo", "仓库", "icon icon-twitter"}, Repo}]
		%% ?menu:sidebar(level_1_menu, Sidebar)
		%% ?menu:sidebar(
		%%    level_2_menu,
		%%    [{{"shop", "店铺管理", "glyphicon glyphicon-shopping-cart"}, Shops}])
	end,

    SidebarBadRepo =
	case BadRepoAuthen of
	    []   -> [];
	    BadRepo ->
		[{{"repo", "次品仓", "glyphicon glyphicon-fire"}, BadRepo}]
		%% ?menu:sidebar(level_1_menu, Sidebar)
		%% ?menu:sidebar(
		%%    level_2_menu,
		%%    [{{"shop", "店铺管理", "glyphicon glyphicon-shopping-cart"}, Shops}])
	end,

    ?menu:sidebar(level_2_menu, SidebarShop ++ SidebarRepo ++ SidebarBadRepo).


