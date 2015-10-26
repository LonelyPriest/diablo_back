%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2015, buxianhui
%%% @doc
%%%
%%% @end
%%% Created :  9 Apr 2015 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_wuser_profile).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_server).

%% API
-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-export([new/1, new/2, get/1, get/2, get/3, update/2, set_default/1]).
-export([filter/3]).

-define(SERVER, ?MODULE). 

-record(state, {}).

%%%===================================================================
%%% API
%%%===================================================================

new(Merchant) ->
    gen_server:call(?SERVER, {new_profile, Merchant}).
new(Merchant, SessionId) ->
    gen_server:call(?SERVER, {new_profile, Merchant, SessionId}).

get(Merchant) ->
    gen_server:call(?SERVER, {get_profile, Merchant}).

%% about print
get(merchant, Merchant) ->
    gen_server:call(?SERVER, {get_merchant_profile, Merchant});
get(bank, Merchant) ->
    gen_server:call(?SERVER, {get_bank_profile, Merchant});
get(setting, Merchant) ->
    gen_server:call(?SERVER, {get_setting_profile, Merchant});
get(size_group, Merchant) ->
    gen_server:call(?SERVER, {get_size_group_profile, Merchant});
get(shop, Merchant) ->
    gen_server:call(?SERVER, {get_shop_profile, Merchant});
get(repo, Merchant) ->
    gen_server:call(?SERVER, {get_repo_profile, Merchant});
get(print, Merchant) ->
    gen_server:call(?SERVER, {get_print_profile, Merchant});
get(print_format, Merchant) ->
    gen_server:call(?SERVER, {get_print_format_profile, Merchant});
get(type, Merchant) ->
    gen_server:call(?SERVER, {get_type_profile, Merchant});
get(retailer, Merchant) ->
    gen_server:call(?SERVER, {get_retailer_profile, Merchant});
get(firm, Merchant) ->
    gen_server:call(?SERVER, {get_firm_profile, Merchant});
get(employee, Merchant) ->
    gen_server:call(?SERVER, {get_employee_profile, Merchant});
get(brand, Merchant) ->
    gen_server:call(?SERVER, {get_brand_profile, Merchant});
get(color_type, Merchant) ->
    gen_server:call(?SERVER, {get_color_type_profile, Merchant});
get(color, Merchant) ->
    gen_server:call(?SERVER, {get_color_profile, Merchant}).


get(shop, Merchant, Shop) ->
    gen_server:call(?SERVER, {get_shop_profile, Merchant, Shop});
get(repo, Merchant, Repo) ->
    gen_server:call(?SERVER, {get_repo_profile, Merchant, Repo});
get(print, Merchant, Shop) ->
    gen_server:call(?SERVER, {get_print_profile, Merchant, Shop});
get(print_format, Merchant, Shop) ->
    gen_server:call(?SERVER, {get_print_format_profile, Merchant, Shop});
get(setting, Merchant, Shop) ->
    gen_server:call(?SERVER, {get_setting_profile, Merchant, Shop}); 
get(size_group, Merchant, GId) ->
    gen_server:call(?SERVER, {get_size_group_profile, Merchant, GId});
get(type, Merchant, TypeId) ->
    gen_server:call(?SERVER, {get_type_profile, Merchant, TypeId});
get(retailer, Merchant, Retailer) ->
    gen_server:call(?SERVER, {get_retailer_profile, Merchant, Retailer});
get(employee, Merchant, Employee) ->
    gen_server:call(?SERVER, {get_employee_profile, Merchant, Employee});
get(brand, Merchant, BrandId) ->
    gen_server:call(?SERVER, {get_brand_profile, Merchant, BrandId});
get(color, Merchant, ColorId) ->
    gen_server:call(?SERVER, {get_color_profile, Merchant, ColorId});

%% about right of login user
get(user_right, Merchant, Session) ->
    gen_server:call(?SERVER, {get_user_right, Merchant, Session});
get(user_shop, Merchant, Session) ->
    gen_server:call(?SERVER, {get_user_shop, Merchant, Session});
get(user_nav, Merchant, Session) ->
    gen_server:call(?SERVER, {get_user_nav, Merchant, Session});
get(user, Merchant, UserId) ->
    gen_server:call(?SERVER, {get_user_profile, Merchant, UserId}).


set_default(Merchant) ->
    gen_server:call(?SERVER, {set_default, Merchant}).

update(good, Merchant) ->
    gen_server:cast(?SERVER, {update_good, Merchant}); 
update(setting, Merchant) ->
    gen_server:cast(?SERVER, {update_setting, Merchant});
update(bank, Merchant) ->
    gen_server:cast(?SERVER, {update_bank, Merchant});
update(shop, Merchant) ->
    gen_server:cast(?SERVER, {update_shop, Merchant});
update(employee, Merchant) ->
    gen_server:cast(?SERVER, {update_employee, Merchant});
update(print, Merchant) ->
    gen_server:cast(?SERVER, {update_print, Merchant});
update(type, Merchant) ->
    gen_server:cast(?SERVER, {update_type, Merchant});
update(brand, Merchant) ->
    gen_server:cast(?SERVER, {update_brand, Merchant});
update(print_format, Merchant) ->
    gen_server:cast(?SERVER, {update_print_format, Merchant});
update(firm, Merchant) ->
    gen_server:cast(?SERVER, {update_firm_format, Merchant});
update(retailer, Merchant) ->
    gen_server:cast(?SERVER, {update_retailer_format, Merchant}).



start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

init([]) ->
    ets:new(?WUSER_PROFILE, [set, private, named_table]),
    ets:new(?WUSER_SESSION_PROFILE, [set, private, named_table]), 
    {ok, #state{}}.


handle_call({new_profile, Merchant}, _From, State) ->
    ?DEBUG("new profile of merchant ~p", [Merchant]),

    try
	{ok, MerchantInfo} = ?merchant:merchant(get, Merchant),
	{ok, Shops} = ?shop:lookup(Merchant),
	{ok, Repoes} = ?shop:repo(list, Merchant),
	
	{ok, Cards} = ?w_base:bank_card(list, Merchant), 
	%% base stting
	{ok, Setting}      = ?w_base:setting(list, Merchant),
	{ok, SizeGroups}   = ?attr:size_group(list, Merchant),
	{ok, Types}        = ?attr:type(list, Merchant),
	{ok, Prints}       = ?w_print:printer(list_conn, Merchant),
	{ok, PFormats}     = ?w_print:format(list, Merchant),

	{ok, Retailers}    = ?w_retailer:retailer(list, Merchant),
	{ok, Employees}    = ?employ:employ(list, Merchant),
	{ok, Brands}       = ?attr:brand(list, Merchant),
	{ok, Firms}        = ?supplier:supplier(w_list, Merchant),
	{ok, ColorTypes}   = ?attr:color_type(list),
	{ok, Colors}       = ?attr:color(w_list, Merchant),
	
	%% good
	%% Goods = ?w_inventory:purchaser_good(lookup, Merchant), 
	true = ets:insert(?WUSER_PROFILE,
			  {?to_i(Merchant), #wuser_profile{
				  merchant    = ?to_i(Merchant), 
				  info        = MerchantInfo,
				  shop        = Shops,
				  repo        = Repoes,
				  print       = Prints,
				  pformat     = PFormats,
				  bank        = ?to_tl(Cards),
				  setting     = ?to_tl(Setting),
				  size_groups = ?to_tl(SizeGroups),
				  itype       = Types,
				  retailer    = Retailers,
				  firm        = Firms,
				  employee    = Employees,
				  brand       = Brands,
				  color_type  = ColorTypes,
				  color       = Colors
				  %% good     = ?to_tl(Goods)
				 }
			  })
    catch _:_ ->
	    {ok, Merchant}
    end,
    
    {reply, {ok, Merchant}, State};

handle_call({new_profile, Merchant, SessionId}, _From, State) ->
    ?DEBUG("=== new session profile of merchant ~p, session ~p === ",
	   [Merchant, SessionId]),
    try
	{ok, Session} = ?session:lookup(SessionId),
	{ok, Catlogs} = ?right_request:login_user(right, Session),
	Shops = ?right_request:login_user(shop, Session),

	Navs = user_nav(Session), 
	UserId = ?session:get(id, Session),
	UserType = ?session:get(type, Session),
	true = ets:insert(?WUSER_SESSION_PROFILE,
			 {{Merchant, UserId},
			 #wuser_session_profile{
			    merchant = Merchant,
			    user     = UserId,
			    type     = UserType,
			    right    = Catlogs,
			    shop     = Shops,
			    nav      = Navs
			   }})
    catch _:_ ->
	    {ok, Merchant, SessionId}
    end,

    {reply, {ok, Merchant, SessionId}, State};

handle_call({get_user_profile, Merchant, UserId}, _From, State) ->
    ?DEBUG("get_user_profile merchant ~p, user ~p", [Merchant, UserId]),
    MS = ms(Merchant, UserId, user), 
    case ets:select(?WUSER_PROFILE, MS) of
	[] ->
	    {reply, {ok, []}, State};
	[Profile] ->
	    ?DEBUG("user profile of merchant ~p~n~p", [Merchant, Profile]),
	    {reply, {ok, Profile}, State}
    end;

handle_call({get_user_right, Merchant, Session}, _From, State) ->
    ?DEBUG("get_user_right merchant ~p, session ~p", [Merchant, Session]),
    UserId = ?session:get(id, Session),
    MS = ms(Merchant, UserId, user),
    Select = select(user, MS, fun()-> ?right_request:login_user(right, Session) end),
    case is_record(Select, wuser_session_profile) of
	true -> {reply, {ok, Select#wuser_session_profile.right}, State};
	false -> {reply, {ok, Select}, State}
    end;
    %% case ets:select(?WUSER_PROFILE, MS) of
    %% 	[] ->
    %% 	    {reply, {ok, []}, State};
    %% 	[Profile] ->
    %% 	    ?DEBUG("user profile of merchant ~p~n~p", [Merchant, Profile]),
    %% 	    {reply, {ok, Profile#wuser_session_profile.right}, State}
    %% end;

handle_call({get_user_shop, Merchant, Session}, _From, State) ->
    ?DEBUG("get_login_user_shop merchant ~p, select ~p", [Merchant, Session]),
    UserId = ?session:get(id, Session),
    MS = ms(Merchant, UserId, user),
    Select = select(user, MS, fun()-> {ok, ?right_request:login_user(shop, Session)} end),
    case is_record(Select, wuser_session_profile) of
	true -> {reply, {ok, Select#wuser_session_profile.shop}, State};
	false -> {reply, {ok, Select}, State}
    end; 

handle_call({get_user_nav, Merchant, Session}, _From, State) ->
    ?DEBUG("get_login_user_nav merchant ~p, select ~p", [Merchant, Session]),
    UserId = ?session:get(id, Session),
    MS = ms(Merchant, UserId, user),
    %% TryFun = fun() ->
    %% 		     case ?session:get(type, Session) of
    %% 			 ?SUPER ->
    %% 			     ?right_auth:navbar(super);
    %% 			 _ ->
    %% 			     ?right_auth:navbar(session, Session)
    %% 		     end
    %% 	     end,
    Select = select(user, MS, fun()-> {ok, user_nav(Session)} end),
    case is_record(Select, wuser_session_profile) of
	true -> {reply, {ok, Select#wuser_session_profile.nav}, State};
	false -> {reply, {ok, Select}, State}
    end;

handle_call({get_profile, Merchant}, _From, State) ->
    ?DEBUG("get_profile of merchant ~p", [Merchant]),
    MS = [{{'$1', '$2'},
	   [{'==', '$1', ?to_i(Merchant)}],
	   ['$2']
	  }],

    case ets:select(?WUSER_PROFILE, MS) of
	[] ->
	    {reply, {ok, []}, State};
	[Profile] ->
	    ?DEBUG("user profile of merchant ~p~n~p", [Merchant, Profile]),
	    {reply, {ok, Profile}, State}
    end;

handle_call({get_merchant_profile, Merchant}, _From, State) ->
    ?DEBUG("get_merchant_profile of merchant ~p", [Merchant]),
    MS = [{{'$1', #wuser_profile{merchant='$1', info='$2', _='_'}},
	   [{'==', '$1', ?to_i(Merchant)}],
	   ['$2']
	  }],

    case ets:select(?WUSER_PROFILE, MS) of
	[] ->
	    {reply, {ok, []}, State};
	[Info] ->
	    ?DEBUG("info ~p of merchant ~p", [Info, Merchant]),
	    {reply, {ok, Info}, State}
    end;


handle_call({get_bank_profile, Merchant}, _From, State) ->
    ?DEBUG("get_bank_profile of merchant ~p", [Merchant]),
    MS = [{{'$1', #wuser_profile{merchant='$1', bank='$2', _='_'}}, 
	   [{'==', '$1', ?to_i(Merchant)}],
	   ['$2']
	  }],

    case ets:select(?WUSER_PROFILE, MS) of
	[] ->
	    {reply, {ok, []}, State};
	[Bank] ->
	    ?DEBUG("bank ~p of merchant ~p", [Bank, Merchant]),
	    {reply, {ok, Bank}, State}
    end;

%%
%% Setting
%%
handle_call({get_setting_profile, Merchant}, _From, State) ->
    ?DEBUG("get_setting_profile of merchant ~p", [Merchant]),
    MS = ms(Merchant, setting),

    Select = select(MS, fun() -> ?w_base:setting(list, Merchant) end), 
    {reply, {ok, Select}, State};
    %% case ets:select(?WUSER_PROFILE, MS) of
    %% 	[] ->
    %% 	    {ok, Setting} = ?w_base:setting(list, Merchant),
    %% 	    {reply, {ok, Setting}, State};
    %% 	[Setting] ->
    %% 	    ?DEBUG("base setting ~p of merchant ~p", [Setting, Merchant]),
    %% 	    {reply, {ok, Setting}, State}
    %% end;

handle_call({get_setting_profile, Merchant, Shop}, _From, State) ->
    MS = ms(Merchant, setting),
    Select = select(MS, fun() -> ?w_base:setting(list, Merchant) end),
    Setting = 
	case filter(Select, <<"shop">>, Shop) of
	    [] -> filter(Select, <<"shop">>, -1);
	    S  -> S
	end,
    {reply, {ok, Setting}, State};


handle_call({get_size_group_profile, Merchant}, _From, State) ->
    ?DEBUG("get_size_group_profile of merchant ~p", [Merchant]),
    Select = select(ms(Merchant, size_group), fun() -> ?attr:size_group(list, Merchant) end), 
    {reply, {ok, Select}, State};

handle_call({get_size_group_profile, Merchant, GId}, _From, State) ->
    ?DEBUG("get_size_group_profile of merchant ~p, GId ~p", [Merchant, GId]), 
    Select = select(ms(Merchant, size_group), fun() -> ?attr:size_group(list, Merchant) end), 
    SelectGroup = filter(Select, <<"id">>, ?to_i(GId)),
    {reply, {ok, SelectGroup}, State}; 

handle_call({get_shop_profile, Merchant}, _From, State) ->
    ?DEBUG("get_shop_profile of merchant ~p", [Merchant]),
    MS = [{{'$1', #wuser_profile{merchant='$1', shop='$2', _='_'}},
	   [{'==', '$1', ?to_i(Merchant)}],
	   ['$2']
	  }],

    case ets:select(?WUSER_PROFILE, MS) of
	[] ->
	    {ok, Shops} = ?shop:lookup(Merchant),
	    {reply, {ok, Shops}, State};
	[Shops] ->
	    %% ?DEBUG("shop ~p of merchant ~p", [Shops, Merchant]),
	    {reply, {ok, Shops}, State}
    end;


handle_call({get_shop_profile, Merchant, Shop}, _From, State) ->
    ?DEBUG("get_shop_profile of merchant ~p, shop ~p", [Merchant, Shop]),
    MS = [{{'$1', #wuser_profile{merchant='$1', shop='$2', _='_'}},
	   [{'==', '$1', ?to_i(Merchant)}],
	   ['$2']
	  }],
    GetShop = fun(Shops) ->
		      lists:foldr(
			fun({S}, Acc) ->
				case ?v(<<"id">>, S) =:= ?to_i(Shop) of
				    true ->
					[{S}|Acc];
				    false -> Acc
				end
			end, [], Shops)
	      end,

    %% R = ets:select(?WUSER_PROFILE, MS),
    %% ?DEBUG("R ~p", [R]),
    NewShops = 
	case ets:select(?WUSER_PROFILE, MS) of
	    [] ->
		{ok, Shops} = ?shop:lookup(Merchant, {<<"id">>, Shop}),
		GetShop(Shops);
	    [Shops] ->
		?DEBUG("shop ~p of merchant ~p", [Shops, Merchant]),
		GetShop(Shops) 
	end,
   
	
    {reply, {ok, NewShops}, State};


handle_call({get_repo_profile, Merchant}, _From, State) ->
    ?DEBUG("get_repo_profile of merchant ~p", [Merchant]),
    MS = [{{'$1', #wuser_profile{merchant='$1', repo='$2', _='_'}},
	   [{'==', '$1', ?to_i(Merchant)}],
	   ['$2']
	  }],

    case ets:select(?WUSER_PROFILE, MS) of
	[] ->
	    {ok, Repoes} = ?shop:repo(list, Merchant),
	    {reply, {ok, Repoes}, State};
	[Repoes] ->
	    ?DEBUG("repo ~p of merchant ~p", [Repoes, Merchant]),
	    {reply, {ok, Repoes}, State}
    end;


handle_call({get_repo_profile, Merchant, Repo}, _From, State) ->
    ?DEBUG("get_repo_profile of merchant ~p, Repo ~p", [Merchant, Repo]),
    MS = [{{'$1', #wuser_profile{merchant='$1', repo='$2', _='_'}},
	   [{'==', '$1', ?to_i(Merchant)}],
	   ['$2']
	  }],

    GetFun =
	fun(Repoes) ->
		lists:foldr(
		  fun({R}, Acc) ->
			  case ?v(<<"id">>, R) =:= ?to_i(Repo) of
			      true ->
				  [{R}|Acc];
			      false -> Acc
			  end
		  end, [], Repoes)
	     end,

    NewRepoes = 
	case ets:select(?WUSER_PROFILE, MS) of
	    [] ->
		{ok, Repoes} = ?shop:repo(list, Merchant, Repo),
		GetFun(Repoes); 
	    [Repoes] ->
		?DEBUG("repo ~p of merchant ~p", [Repoes, Merchant]),
		GetFun(Repoes)
	end, 
    {reply, {ok, NewRepoes}, State};

handle_call({get_print_profile, Merchant}, _From, State) ->
    ?DEBUG("get_print_profile of merchant ~p", [Merchant]),
    MS = [{{'$1', #wuser_profile{merchant='$1', print='$2', _='_'}},
	   [{'==', '$1', ?to_i(Merchant)}],
	   ['$2']
	  }],

    case ets:select(?WUSER_PROFILE, MS) of
	[] ->
	    {ok, Prints} = ?w_print:printer(list_conn, Merchant),
	    {reply, {ok, Prints}, State};
	[Prints] ->
	    ?DEBUG("print ~p of merchant ~p", [Prints, Merchant]),
	    {reply, {ok, Prints}, State}
    end;

handle_call({get_print_profile, Merchant, Shop}, _From, State) ->
    ?DEBUG("get_print_profile of merchant ~p, shop ~p", [Merchant, Shop]),
    MS = [{{'$1', #wuser_profile{merchant='$1', print='$2', _='_'}},
	   [{'==', '$1', ?to_i(Merchant)}],
	   ['$2']
	  }],

    GetPrint = fun(Prints) ->
		       lists:foldr(
			 fun({P}, Acc) ->
				 case ?v(<<"shop_id">>, P) =:= ?to_i(Shop)
				     andalso ?v(<<"status">>, P) =:= ?START of
				     true ->
					 [{P}|Acc];
				     false -> Acc
				 end
			 end, [], Prints)
	       end,
    
    NewPrints = 
	case ets:select(?WUSER_PROFILE, MS) of
	    [] ->
		{ok, Prints} = ?w_print:printer(list_conn, Merchant),
		GetPrint(Prints);
	    [Prints] ->
		?DEBUG("print ~p of merchant ~p", [Prints, Merchant]),
		GetPrint(Prints) 
	end, 
    {reply, {ok, NewPrints}, State};

%%
%% formater options of print
%%
handle_call({get_print_format_profile, Merchant}, _From, State) ->
    ?DEBUG("get_print_format_profile of merchant ~p", [Merchant]),
    Select = select(ms(Merchant, pformat), fun() -> ?w_print:format(list, Merchant) end),
    {reply, {ok, Select}, State};

handle_call({get_print_format_profile, Merchant, Shop}, _From, State) ->
    ?DEBUG("get_print_format_profile of merchant ~p", [Merchant]),
    Select = select(ms(Merchant, pformat), fun() -> ?w_print:format(list, Merchant) end),
    Format = 
	case filter(Select, <<"shop">>, Shop) of
	    [] -> filter(Select, <<"shop">>, -1);
	    F  -> F
	end,
    {reply, {ok, Format}, State};

%%
%% type of inventory
%%
handle_call({get_type_profile, Merchant}, _From, State) ->
    ?DEBUG("get_type_profile of merchant ~p", [Merchant]),
    MS = ms(Merchant, itype),
    Select = select(MS, fun() -> ?attr:type(list, Merchant) end),
    {reply, {ok, Select}, State};

handle_call({get_type_profile, Merchant, TypeId}, _From, State) ->
    ?DEBUG("get_type_profile of merchant ~p, TypeId ~p", [Merchant, TypeId]),
    MS = ms(Merchant, itype),
    Select = select(MS, fun() -> ?attr:type(list, Merchant) end),

    SelectType = lists:filter(fun({Type}) ->
				      ?v(<<"id">>, Type) =:= TypeId
			      end, Select), 
    
    {reply, {ok, SelectType}, State};

%%
%% retailer
%%
handle_call({get_retailer_profile, Merchant}, _From, State) ->
    ?DEBUG("get_retailer_profile of merchant ~p", [Merchant]),
    MS = ms(Merchant, retailer),
    Select = select(MS, fun() -> ?w_retailer:retailer(list, Merchant) end),
    {reply, {ok, Select}, State};

handle_call({get_retailer_profile, Merchant, RetailerId}, _From, State) ->
    ?DEBUG("get_retailer_profile of merchant ~p, Retailer ~p", [Merchant, RetailerId]),
    MS = ms(Merchant, retailer),
    Select = select(MS, fun() -> ?w_retailer:retailer(list, Merchant) end), 
    SelectRetailer = filter(Select, <<"id">>, RetailerId), 
    {reply, {ok, SelectRetailer}, State};


%%
%% firm
%%
handle_call({get_firm_profile, Merchant}, _From, State) ->
    ?DEBUG("get_firm_profile of merchant ~p", [Merchant]),
    MS = ms(Merchant, firm),
    Select = select(MS, fun() -> ?supplier:supplier(w_list, Merchant) end),
    {reply, {ok, Select}, State};

%%
%% employee
%%
handle_call({get_employee_profile, Merchant}, _From, State) ->
    ?DEBUG("get_employee_profile of merchant ~p", [Merchant]),
    MS = ms(Merchant, employee),
    Select = select(MS, fun() -> ?employ:employ(list, Merchant) end),
    {reply, {ok, Select}, State};

handle_call({get_employee_profile, Merchant, EmpId}, _From, State) ->
    ?DEBUG("get_employee_profile of merchant ~p, empid ~p", [Merchant, EmpId]),
    MS = ms(Merchant, employee),
    Select = select(MS, fun() -> ?employ:employ(list, Merchant) end), 
    SelectEmployee = filter(Select, <<"number">>, EmpId), 
    {reply, {ok, SelectEmployee}, State};


%%
%% employee
%%
handle_call({get_brand_profile, Merchant}, _From, State) ->
    ?DEBUG("get_brand_profile of merchant ~p", [Merchant]),
    MS = ms(Merchant, brand),
    Select = select(MS, fun() -> ?attr:brand(list, Merchant) end),
    {reply, {ok, Select}, State};

handle_call({get_brand_profile, Merchant, BrandId}, _From, State) ->
    ?DEBUG("get_brand_profile of merchant ~p, Brand ~p", [Merchant, BrandId]),
    MS = ms(Merchant, brand),
    Select = select(MS, fun() -> ?attr:brand(list, Merchant) end), 
    SelectEmployee = filter(Select, <<"id">>, BrandId), 
    {reply, {ok, SelectEmployee}, State};

%%
%% color
%%
handle_call({get_color_type_profile, Merchant}, _From, State) ->
    ?DEBUG("get_color_type_profile of merchant ~p", [Merchant]),
    MS = ms(Merchant, color_type),
    Select = select(MS, fun() -> ?attr:color_type(list) end),
    {reply, {ok, Select}, State};
handle_call({get_color_profile, Merchant}, _From, State) ->
    MS = ms(Merchant, color),
    Select = select(MS, fun() -> ?attr:color(w_list, Merchant) end),
    {reply, {ok, Select}, State};
handle_call({get_color_profile, Merchant, ColorId}, _From, State) ->
    MS = ms(Merchant, color),
    Select = select(MS, fun() -> ?attr:color(w_list, Merchant) end),
    SelectColor = lists:filter(fun({Color}) ->
				       ?v(<<"id">>, Color) =:= ColorId
			      end, Select), 
    {reply, {ok, SelectColor}, State}; 

handle_call({set_default, Merchant}, _From, State) ->
    ?DEBUG("set default value of merchant ~p", [Merchant]),
    %% base setting
    Now = ?utils:current_time(localdate),
    
    %% one month default
    {M, S, T} = erlang:now(), 
    {{YY, MM, DD}, _} = calendar:now_to_datetime({M, S - 86400 * 30, T}),
    DefaultDate = lists:flatten(io_lib:format("~4..0w-~2..0w-~2..0w", [YY, MM, DD])),
    
    %%         ename,           cname,            value,type
    Values = [{"pum",           "打印份数",       "1",  "0"},
	      {"ptype",         "打印方式",       "1",  "0"}, %% 0: front; 1:backend 
	      {"pformat",       "打印格式",       "1",  "0"},
	      {"ptable",        "表格打印",       "0",  "0"},
	      {"pretailer",     "打印零售商",     "0",  "0"},
	      {"pround",        "四舍五入",       "0",  "0"},
	      {"ptrace_price",  "价格跟踪",       "0",  "0"},
	      {"prompt",        "提示数目",       "8",  "0"},
	      {"pim_print",     "立即打印",       "0",  "0"},
	      
	      {"qtime_start",   "查询开始时间",   DefaultDate,  "0"},
	      {"qtime_length",  "查询跨度",       "30",  "0"},
	      {"qtypeahead",    "提示方式",       "1",   "0"}, %% 0: front; 1:backend
	      
	      {"reject_negative", "零库存退货",    "0",  "0"},
	      {"check_sale",      "检测库存销售",  "1",  "0"},
	      {"show_discount",   "开单显示折扣",  "1",  "0"},
	      {"se_pagination",   "顺序翻页",      "0",  "0"},
	      {"stock_alarm",     "库存告警",      "0",  "0"}
	     ],
    
    
    Sql0 = lists:foldr(
	    fun({EName, CName, Value, Type}, Acc) ->
		    Sql00 = "select id, ename, value from w_base_setting"
			" where ename=\'" ++ EName ++ "\'"
			" and shop=-1"
			" and merchant=" ++ ?to_s(Merchant),
		    case ?sql_utils:execute(s_read, Sql00) of
			{ok, []} ->
			    ["insert into w_base_setting("
			     "ename, cname, value, type"
			     ", remark, merchant, entry_date) values("
			     "\'" ++ EName ++ "\',"
			     "\'" ++ CName ++ "\',"
			     ++ "\'" ++ ?to_s(Value) ++ "\',"
			     ++ Type  ++ ","
			     ++ "\'\',"
			     ++ ?to_s(Merchant) ++ "," 
			     "\'" ++ Now ++ "\');"|Acc];
			{ok, _} ->
			    Acc
		    end
	    end, [], Values),

    %% print format
    %% {name, isPrint, printWidth}
    Formats = [{"brand",           "0",  "0"},
	       {"style_number",    "0",  "0"},
	       {"type",            "0",  "0"},
	       {"color",           "0",  "0"},
	       {"size_name",       "0",  "0"}, 
	       {"size",            "0",  "0"},
	       {"price",           "0",  "0"},
	       {"discount",        "0",  "0"},
	       {"dprice",          "0",  "0"},
	       {"hand",            "0",  "0"},
	       {"count",           "0",  "0"},
	       {"calc",            "0",  "0"},
	       {"comment",         "0",  "0"}
	      ],


    Sql1 = lists:foldr(
	     fun({Name, Print, Width}, Acc) ->
		     Sql01 = "select id, name, print from w_print_format"
			 " where name=\'" ++ Name ++ "\'"
			 " and shop=-1"
			 " and merchant=" ++ ?to_s(Merchant),
		     case ?sql_utils:execute(s_read, Sql01) of
			 {ok, []} ->
			     ["insert into w_print_format("
			      "name, print, width"
			      ", merchant, entry_date) values("
			      "\'" ++ Name ++ "\',"
			      ++ Print ++ ","
			      ++ Width  ++ ","
			      ++ ?to_s(Merchant) ++ "," 
			      "\'" ++ Now ++ "\');"|Acc];
			 {ok, _} ->
			     Acc
		     end
	     end, [], Formats),

    Reply = ?sql_utils:execute(transaction, Sql0 ++ Sql1, ok),
    {reply, Reply, State};
    

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.



handle_cast({Update, Merchant}, State) ->
    ?DEBUG("update profile of merchant ~p, update ~p", [Merchant, Update]),
    %% get user profile
    MS = [{{'$1', '$2'},
	   [{'==', '$1', ?to_i(Merchant)}],
	   ['$2']
	  }],

    NewProfile = 
	case ets:select(?WUSER_PROFILE, MS) of
	    [] ->
		[];
	    [Profile] -> 
		case Update of
		    update_good ->
			%% Goods = ?w_inventory:purchaser_good(lookup, Merchant), 
			%% Profile#wuser_profile{good=?to_tl(Goods)};
			Profile; 
		    update_setting ->
			{ok, S} = ?w_base:setting(list, Merchant),
			Profile#wuser_profile{setting=?to_tl(S)}; 
		    update_bank ->
			{ok, Cards} = ?w_base:bank_card(list, Merchant),
			Profile#wuser_profile{bank=?to_tl(Cards)};
		    update_shop ->
			{ok, Shops} = ?shop:lookup(Merchant),
			Profile#wuser_profile{shop=Shops};
		    update_employee ->
			{ok, Employees}    = ?employ:employ(list, Merchant),
			Profile#wuser_profile{employee=Employees};
		    update_print ->
			{ok, Prints} = ?w_print:printer(list_conn, Merchant),
			Profile#wuser_profile{print=Prints};
		    update_type ->
			{ok, Types}        = ?attr:type(list, Merchant),
			Profile#wuser_profile{itype=Types};
		    update_brand ->
			{ok, Brands}        = ?attr:brand(list, Merchant),
			Profile#wuser_profile{brand=Brands};
		    update_print_format ->
			{ok, Formats} = ?w_print:format(list, Merchant),
			%% ?DEBUG("formats ~p", [Formats]),
			Profile#wuser_profile{pformat=?to_tl(Formats)};
		    update_firm_format ->
			{ok, Firms} = ?supplier:supplier(w_list, Merchant),
			Profile#wuser_profile{firm=Firms};
		    update_retailer_format ->
			{ok, Retailers} = ?w_retailer:retailer(list, Merchant),
			Profile#wuser_profile{retailer=Retailers}
		end 
	end,

    case NewProfile of
	[] -> {noreply, State};
	NewProfile ->
	    case ets:update_element(
		   ?WUSER_PROFILE, ?to_i(Merchant), {2, NewProfile}) of
		true ->
		    ?DEBUG("success to update profile of merchant ~p", [Merchant]),
		    {noreply, State};
		false ->
		    ?DEBUG("failed to update profile of merchant ~p", [Merchant]),
		    {noreply, State}
	    end
    end;


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
select(MS, RetryFun) ->
    Select = 
	case ets:select(?WUSER_PROFILE, MS) of
	    [] ->
		{ok, R} = RetryFun(),
		R;
	    [[]] ->
		{ok, R} = RetryFun(),
		R;
	    [R] ->
		R
	end,
    %% ?DEBUG("select ~p", [ets:select(?WUSER_PROFILE, MS)]),
    Select.


ms(Merchant, setting) ->
    [{{'$1', #wuser_profile{merchant='$1', setting='$2', _='_'}},
      [{'==', '$1', ?to_i(Merchant)}],
      ['$2']
     }];
ms(Merchant, pformat) ->
    [{{'$1', #wuser_profile{merchant='$1', pformat='$2', _='_'}},
      [{'==', '$1', ?to_i(Merchant)}],
      ['$2']
     }];
ms(Merchant, itype) ->
    [{{'$1', #wuser_profile{merchant='$1', itype='$2', _='_'}},
      [{'==', '$1', ?to_i(Merchant)}],
      ['$2']
     }];
ms(Merchant, retailer) ->
    [{{'$1', #wuser_profile{merchant='$1', retailer='$2', _='_'}},
      [{'==', '$1', ?to_i(Merchant)}],
      ['$2']
     }];
ms(Merchant, firm) ->
    [{{'$1', #wuser_profile{merchant='$1', firm='$2', _='_'}},
      [{'==', '$1', ?to_i(Merchant)}],
      ['$2']
     }];
ms(Merchant, employee) ->
    [{{'$1', #wuser_profile{merchant='$1', employee='$2', _='_'}},
      [{'==', '$1', ?to_i(Merchant)}],
      ['$2']
     }];
ms(Merchant, brand) ->
    [{{'$1', #wuser_profile{merchant='$1', brand='$2', _='_'}},
      [{'==', '$1', ?to_i(Merchant)}],
      ['$2']
     }];
ms(Merchant, size_group) ->
    [{{'$1', #wuser_profile{merchant='$1', size_groups='$2', _='_'}},
      [{'==', '$1', ?to_i(Merchant)}],
      ['$2']
     }];
ms(Merchant, color_type) ->
    [{{'$1', #wuser_profile{merchant='$1', color_type='$2', _='_'}},
      [{'==', '$1', ?to_i(Merchant)}],
      ['$2']
     }];
ms(Merchant, color) ->
    [{{'$1', #wuser_profile{merchant='$1', color='$2', _='_'}},
      [{'==', '$1', ?to_i(Merchant)}],
      ['$2']
     }].


select(user, MS, RetryFun) ->
    Select = 
	case ets:select(?WUSER_SESSION_PROFILE, MS) of
	    [] ->
		{ok, R} = RetryFun(),
		R;
	    [[]] ->
		{ok, R} = RetryFun(),
		R;
	    [R] ->
		R
	end,
    %% ?DEBUG("select ~p", [ets:select(?WUSER_PROFILE, MS)]),
    Select.

ms(Merchant, UserId, user) ->
    [{{{'$1', '$2'}, '$3'},
      [{'==', '$1', Merchant}, {'==', '$2', UserId}],
      ['$3']
     }].

filter(L, Key, MatchValue) ->
    %% ?DEBUG("filter with L ~p, Key ~p, MatchValue ~p", [L, Key, MatchValue]),
    case lists:filter(fun({Pair})->
			 ?v(Key, Pair) =:= MatchValue
		      end, ?to_tl(L)) of
	[] -> [];
	[{Match}] -> Match;
	Match -> Match
    end.
	     

user_nav(Session) ->
    case ?session:get(type, Session) of
	?SUPER ->
	    ?right_auth:navbar(super);
	_ ->
	    ?right_auth:navbar(session, Session)
    end.
