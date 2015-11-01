-module(diablo_controller_menu).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-compile(export_all).


titles() ->
    [{"/sale",      "销售",     ?sale_request},
     {"/member",    "会员",     ?member_request},
     {"/shop",      "店铺",     ?shop_request},
     %%case utils:get_role(Session) of
     {"/merchant",  "商家",     ?merchant_request},
     {"/employ",    "员工",     ?employ_request},
     {"/inventory", "库存",     ?inventory_request},
     {"/right",     "权限",     ?right_request},
     {"/supplier",  "供应商",   ?supplier_request}].

titles(Session) ->
    UserType = ?session:get(type, Session),
    case UserType of
	?SUPER ->
	    [{"/merchant",  "商家",     ?merchant_request},
	     {"/right",     "权限",     ?right_request}];
	_ ->
	    [{"/sale",      "销售",     ?sale_request},
	     {"/member",    "会员",     ?member_request},
	     {"/shop",      "店铺",     ?shop_request},
	     {"/employ",    "员工",     ?employ_request},
	     {"/inventory", "库存",     ?inventory_request},
	     {"/right",     "权限",     ?right_request},
	     {"/supplier",  "供应商",   ?supplier_request}]	
    end.

redirect_path(UserType) ->
    case UserType of
	?SUPER ->
	    "/merchant";
	_ ->
	    "/"
    end.

navbars(Module, Session) ->
    %% Titles = ?MODULE:titles(Session),
    %% Titles = 
    %% case ?session:get(type, Session) of
    %% 	?SUPER ->
    %% 	    ?right_auth:navbar(super);
    %% 	_ ->
    %% 	    ?right_auth:navbar(session, Session)
    %% end, 
    ?DEBUG("navbars with module ~p, session ~p", [Module, Session]),
    
    Merchant = ?session:get(merchant, Session),
    {ok, Titles} = ?w_user_profile:get(user_nav, Merchant, Session),
    ActiveTitles = lists:foldr(
		     fun({P, T, M, H}, Acc) when M =:= Module ->
			     [{P, T, true, H}|Acc];
			({P, T, _, H}, Acc) ->
			     [{P, T, false, H}|Acc]
		     end, [], Titles),
    navbar(ActiveTitles).

navbars(Module) ->
    Titles = ?MODULE:titles(),
    ActiveTitles = lists:foldr(
		     fun({P, T, M, H}, Acc) when M =:= Module ->
			     [{P, T, true, H}|Acc];
			({P, T, _, H}, Acc) ->
			     [{P, T, false, H}|Acc]
		     end, [], Titles),
    navbar(ActiveTitles).

navbar(Titles) ->
    lists:foldr(
      fun({Href, Title, Active, Hidden}, Acc) ->
	      ?DEBUG("href ~p hidden ~p", [Href, Hidden]), 
	      "<li name="
		  ++ string:strip(Href, both, $/)
		  ++ case Hidden of
			 true -> " class=\"hidden-xs hidden-sm\">";
			 false ->
			     case Active of
				 true -> "  class=\"start active\">";
				 false -> ">"
			     end
		     end
		  ++
		  "<a href=\""++ Href ++ "\">" ++ Title
		  ++ "<span class=\"selected\"></span>"
		  ++ "</a>"
		  ++ "</li>\n" ++ Acc
      end, "", Titles).

w_basebar(Session) ->
    w_basebar(undefined, Session). 
w_basebar(Module, Session) ->
    User = ?session:get(name, Session), 
    "<li class='dropdown'>"
	"<a href='javascript:;' class='dropdown-toggle'"
	" data-toggle='dropdown' data-hover='dropdown' data-close-others='true'>"
	"<i class='icon icon-cogs'></i><span class='badge'>"
	++ ?to_s(User) ++ "</span></a>"
	"<ul class='dropdown-menu' x-ng-controller='loginOutCtrl'>"
	%% ++ "<li id='loginOutApp' x-ng-app='loginOutApp' x-ng-controller='loginOutCtrl'>"
	%% ++ "<li x-ng-controller='loginOutCtrl'>"
	++ "<li>"
	"<a href=javascript:; x-ng-click='home()'>"
	"<i class='icon icon-signout fg-red'></i>注销</a>"
	"</li>\n" 
	++ case Module of
	    ?w_base_request -> [];
	       _ ->
		   case ?session:get(type, Session) of
		       ?SUPER -> [];
		       Type when Type =:= ?MERCHANT; Type =:= ?USER -> 
			   "<li>"
			       "<a href='/wbase'>"
			       "<i class='icon icon-cog fg-red'></i>用户设置</a>"
			       "</li>\n"
		   end
	   end 
    ++ "<li>"
	"<a id='trigger_fullscreen'"
	"href=javascript:;><i class='icon icon-fullscreen fg-red'></i>全屏</a>"
	"</li>\n"
    %% ++ "<li role='presentation' class='divider'></li>" 
	++ "</ul>"
	"</li>".

sidebar(level_4_menu,
	{{Root, RootName}, {L1, L1Name},
	 [{{_Node, _NodeName}, [{_Leaf, _LeafName}|_]}|_] = Levels})->
    %% ?DEBUG("Levels ~p", [Levels]),
    "
 <li>
  <a class=\"active\" href=\"javascript:;\">
    <i class=\"glyphicon glyphicon-th-list\"></i>
    <span class=\"title\">" ++ Root ++ "</span>
    <span class=\"arrow\"> </span>
  </a>

  <ul class=\"sub-menu\">    
    <li>
      <a href=\"#\">" ++ L1 ++ "
        <span class=\"arrow\"> </span>
      </a>
      <ul class=\"sub-menu\">" ++
	lists:foldr(
	  fun({{Parent, PName}, Childrens}, Acc) ->
		  "<li> <a href=\"#\">"
		      ++ Parent
		      ++ "<span class=\"arrow\"></span> </a>"
		      ++ "<ul class=\"sub-menu\">"
		      ++ lists:foldr(
			   fun({Child, CName}, Acc1)->
				   "<li> <a href=/"
				       ++ filename:join(
					    [RootName, L1Name, PName, CName])
				       ++">"
				       ++ Child ++ "</a></li>\n" ++ Acc1
			   end, [], Childrens) ++ "</ul>"
		      ++ Acc ++ "</li> \n"
	    end, [], Levels) ++ 
      "
     </ul>
    </li>
  </ul>
</li>
";

sidebar(level_3_menu,
	{{Root, RootName},
	 [{{_Node, _NodeName}, [{_Leaf, _LeafName}|_]}|_] = Levels})->
    %% ?DEBUG("Levels ~p", [Levels]),
"
<li>
  <a class=\"active\" href=\"javascript:;\">
    <i class=\"fa fa-leaf\"></i>
    <span class=\"title\">" ++ Root ++ "</span>
    <span class=\"arrow\"> </span>
  </a>

  <ul class=\"sub-menu\">" ++
	lists:foldr(
	  fun({{Parent, PName}, Childrens}, Acc) ->
		  "<li> <a href=\"#\">"
		      ++ Parent
		      ++ "<span class=\"arrow\"></span> </a>"
		      ++ "<ul class=\"sub-menu\">"
		      ++ lists:foldr(
			   fun({Child, CName}, Acc1)->
				   "<li> <a href=/"
				       ++ filename:join(
					    [RootName, PName, CName])
				       ++">"
				       ++ Child ++ "</a></li>\n" ++ Acc1
			   end, [], Childrens) ++ "</ul>"
		      ++ Acc ++ "</li> \n"
	    end, [], Levels) ++ 
      "
  </ul>    
</li>
";

sidebar(level_2_menu, LevelNodes) when is_list(LevelNodes)->
    sidebar(level_2_menu, LevelNodes,  "");
sidebar(level_2_menu, {{_Parent, PName}, []}) -> 
    sidebar(level_2_menu, {{_Parent, PName, none}, []});    
sidebar(level_2_menu, {{_Parent, PName, PIcon}, []}) ->
    "
<li><a href=\"javascript:;\">" ++ 
	case PIcon of
	    none ->
		"<i class=\"glyphicon glyphicon-th-large fg-lightOrange\"></i>";
	    PIcon ->
		"<i class=\"" ++ PIcon ++ " fg-lightOrange\"></i>"
	end ++ 
	"<span class=\"title\">" ++ PName ++ "</span>
    <span class=\"arrow\"></span>
  </a></li \n>";

%% [child, child_name, icon] = children
%% [child, child_name] = children
sidebar(level_2_menu, {{Parent, PName}, Childrens})->
    sidebar(level_2_menu, {{Parent, PName, none},  Childrens});

sidebar(level_2_menu, {{Parent, PName, PIcon}, Childrens})->
    %% ?DEBUG("Parent ~p", [Parent]),
"
 <li>
  <a href=\"javascript:;\">" ++ 
	case PIcon of
	    none ->
		"<i class=\"glyphicon glyphicon-th-large fg-lightOrange\"></i>";
	    PIcon ->
		"<i class=\"" ++ PIcon ++ " fg-lightOrange\"></i>"
	end ++ 
    "<span class=\"title\">" ++ PName ++ "</span>
    <span class=\"selected\"> </span>
    <span class=\"arrow open\"> </span>
  </a>

  <ul class=\"sub-menu\">" ++
	lists:foldr(
	  fun({Child, ChildName}, Acc) ->
		  %% ?DEBUG("child ~ts", [?to_binary(ChildName)]),
		  "\n<li id=" ++ Parent ++ "-" ++ Child ++ ">"
		      "\n<a href=\"javascript:;\""
		      "onclick=\"diablo_sidebar_goto_page\("
		      ++ "\'" ++ Parent ++ "/" ++ Child ++  "\'"
		      ++ ",'#/" ++ Parent ++ "/" ++ Child ++ "'\)\">"
		      %% " onclick=\"window.location='#/" ++ Parent ++ "/" ++ Child ++"'\">" 
		      "\n<i class=\"glyphicon glyphicon-apple fg-darkRed\"></i>"
		      %% "\n<i class=\"fa fa-sitmap\"> </i>"
		      "\n<span class=\"title\">" ++ ChildName ++  "</span>"
		      "\n<span class=\"selected\"></span>"
		      "</a>\n</li> \n" ++ Acc;
	     ({Child, ChildName, CICon}, Acc) ->
		  "\n<li id=" ++ Parent ++ "-" ++ Child ++ ">"
		      "\n<a href=\"javascript:;\""
		      "onclick=\"diablo_sidebar_goto_page\("
		      ++ "\'" ++ Parent ++ "/" ++ Child ++  "\'"
		      ++ ",'#/" ++ Parent ++ "/" ++ Child ++ "'\)\">"
		      %% " onclick=\"window.location='#/" ++ Parent ++ "/" ++ Child ++"'\">" 
		      "\n<i class=\"" ++ CICon ++ " fg-darkRed\"></i>"
		  %% "\n<i class=\"fa fa-sitmap\"> </i>"
		      "\n<span class=\"title\">" ++ ChildName ++ "</span>"
		      "\n<span class=\"selected\"></span>"
		      "</a>\n</li> \n" ++ Acc
	    end, [], Childrens) ++ 
      "
  </ul>    
</li \n>
";

sidebar(level_1_menu, []) ->
    "";    
sidebar(level_1_menu,  Nodes) ->
    %% "<li>" ++
	lists:foldr(
	  fun({Action, Title, Icon}, Acc) ->
		  
		  %% "<a href=\"javascript:;\" onclick=\"window.location='#/" ++ Action ++ "'\">"
		  "<li id=" ++ Action ++ ">"
		      "<a href=\"javascript:;\""
		      "onclick=\"diablo_sidebar_goto_page\("
		      ++ "\'" ++ Action ++ "\'"
		      ++ ",'#/" ++ Action ++ "'\)\">"
		  %% "<a href=\"" ++ Action  ++ "\">"
		      "\n<i class=\" " ++ Icon ++ " fg-darkRed\"></i>"
		      "\n<span class=\"title\">" ++ Title ++ "</span>"
		      "\n<span class=\"selected\"></span>" 
		      "</a>"
		      "</li\n>" ++ Acc
	  end, [], Nodes).
	%% "</li \n>".

sidebar(level_1_menu, [], Levels) ->
    Levels;
sidebar(level_1_menu, [Node|T], Levels) ->
    L = sidebar(level_1_menu, Node),
    sidebar(level_1_menu, T, Levels ++ L);

sidebar(level_2_menu, [], Levels)->
    Levels;
sidebar(level_2_menu, [Node|T], Levels)->
    L = sidebar(level_2_menu, Node),
    sidebar(level_2_menu, T, Levels ++ L);

sidebar(level_3_menu, [], Levels)->
    Levels;
sidebar(level_3_menu, [Node|T], Levels)->
    L = sidebar(level3_menu, Node),
    sidebar(level_3_menu, T, Levels ++ L).
