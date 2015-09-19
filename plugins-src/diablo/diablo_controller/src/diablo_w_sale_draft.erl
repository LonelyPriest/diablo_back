%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2015, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 20 Mar 2015 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_w_sale_draft).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_server).

%% API
-export([start_link/0]).
-export([new/4, lookup/1, lookup/2, lookup/3, lookup/4]).
-export([get/3, delete/2, delete/3]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-define(SERVER, ?MODULE).

-record(state, {}).

new(wsale_draft, Merchant, Attrs, Invs) ->
    gen_server:call(?SERVER, {new_wsale_draft, Merchant, Attrs, Invs}).

lookup(wsale_draft) ->
    gen_server:call(?SERVER, lookup_wsale_draft).

lookup(wsale_draft, Merchant) ->
    gen_server:call(?SERVER, {lookup_wsale_draft, Merchant}).

lookup(wsale_draft, Merchant, Shop) ->
    gen_server:call(?SERVER, {lookup_wsale_draft, Merchant, Shop}).

lookup(wsale_draft, Merchant, Shop, Employee) ->
    gen_server:call(?SERVER, {lookup_wsale_draft, Merchant, Shop, Employee}).

delete(wsale_draft, Merchant) ->
    gen_server:cast(?SERVER, {delete_wsale_draft, Merchant}).

delete(wsale_draft, Merchant, Attrs) ->
    gen_server:cast(?SERVER, {delete_wsale_draft, Merchant, Attrs}).

get(wsale_draft, Merchant, SN) ->
    gen_server:call(?SERVER, {get_wsale_draft, Merchant, SN}).

%%%===================================================================
%%% API
%%%=================================================================== 
start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).


%%%===================================================================
%%% gen_server callbacks
%%%=================================================================== 
init([]) ->
    %% ets:new(?WSALE_DRAFT, [set, private, named_table]),
    
    case ets:file2tab("wsale_draft") of
	{ok, ?WSALE_DRAFT} ->
		{ok, #state{}};
	{error, _Error}->
	    ?INFO("no draft, create new ..."),
	    ets:new(?WSALE_DRAFT, [set, private, named_table]),
	    {ok, #state{}}
    end.


handle_call({new_wsale_draft, Merchant, Attrs, Invs}, _From, State) ->
    ?DEBUG("wsale_draft with merchant ~p~nattrs~p~nInvs~p",
	   [Merchant, Attrs, Invs]),
    Retailer   = ?v(<<"retailer">>, Attrs),
    Shop       = ?v(<<"shop">>, Attrs),
    Employee   = ?v(<<"employee">>, Attrs),
    %% Total      = ?v(<<"total">>, Props, 0),
    %% DateTime   = ?v(<<"datetime">>, Props, ?utils:current_time(localtime)),

    SN = lists:concat([Merchant, "-", Retailer, "-", Shop, "-", ?to_s(Employee)]),
    true = ets:insert(?WSALE_DRAFT,
		      {?to_b(SN), #wsale_draft{
			      merchant=?to_i(Merchant),
			      shop=?to_i(Shop),
			      employee=?to_b(Employee),
			      attrs=Attrs,
			      invs=Invs}}),
    
    ets:tab2file(?WSALE_DRAFT, "wsale_draft"),

    {reply, {ok, SN}, State};

handle_call(lookup_wsale_draft, _From, State) ->
    ?DEBUG("lookup_wsale_draft", []),
    MS = [{'_', [], ['$_']}],
    case ets:select(?WSALE_DRAFT, MS) of
	[] ->
	    {reply, {ok, []}, State};
	Drafts ->
	    {reply, {ok, Drafts}, State}
    end;

handle_call({lookup_wsale_draft, Merchant}, _From, State) ->
    ?DEBUG("lookup_wsale_draft with merchant ~p", [Merchant]),
    MS = [{{'$1', #wsale_draft{
	      merchant='$2', attrs='$3', _='_'}},
	   [{'==', '$2', ?to_i(Merchant)}],
	   [{{[{{<<"sn">>, '$1'}}|'$3']}}]
	  }],
    case ets:select(?WSALE_DRAFT, MS) of
	[] ->
	    {reply, {ok, []}, State};
	Drafts ->
	    {reply, {ok, Drafts}, State}
    end;

handle_call({lookup_wsale_draft, Merchant, Shop}, _From, State) ->
    ?DEBUG("lookup_wsale_draft with merchant ~p, shop ~p", [Merchant, Shop]),
    MS = [{{'$1', #wsale_draft{
	      merchant='$2', shop='$3', attrs='$4', _='_'}},
	   [{'==', '$2', ?to_i(Merchant)}, {'==', '$3', ?to_i(Shop)}],
	   [{{[{{<<"sn">>, '$1'}}|'$4']}}]
	  }],
    case ets:select(?WSALE_DRAFT, MS) of
	[] ->
	    {reply, {ok, []}, State};
	Drafts ->
	    {reply, {ok, Drafts}, State}
    end;

handle_call({lookup_wsale_draft, Merchant, Shop, Employee}, _From, State) ->
    ?DEBUG("lookup_wsale_draft with merchant ~p, shop ~p, employee ~p",
	   [Merchant, Shop, Employee]),
    MS = [{{'$1', #wsale_draft{
    	      merchant='$2', shop='$3', employee='$4', attrs='$5', _='_'}},
    	   [{'==', '$2', ?to_i(Merchant)},
    	    {'==', '$3', ?to_i(Shop)},
    	    {'==', '$4', ?to_b(Employee)}],
	   [{{[{{<<"sn">>, '$1'}}|'$5']}}]
    	  }],
    
    case ets:select(?WSALE_DRAFT, MS) of
	[] ->
	    {reply, {ok, []}, State};
	Drafts ->
	    {reply, {ok, Drafts}, State}
    end;

handle_call({get_wsale_draft, Merchant, SN}, _From, State) ->
    ?DEBUG("get_wsale_draft with merchant ~p, SN ~p", [Merchant, SN]),
    MS = [{{'$1', #wsale_draft{
	      merchant='$2', shop='$3', _='_', attrs='$4', invs='$5'}},
	   [{'==', '$1', ?to_b(SN)},
	    {'==', '$2', ?to_i(Merchant)}],
	   [{{'$3', '$5'}}]
	  }],
    case ets:select(?WSALE_DRAFT, MS) of
	[] ->
	    {reply, {ok, []}, State};
	[Draft] ->
	    {reply, {ok, Draft}, State}
    end;
    
handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

handle_cast({delete_wsale_draft, Merchant}, State) ->
    ?DEBUG("delete_wsale_draft with merchant ~p", [Merchant]),
    MS = [{{'$1', #wsale_draft{merchant='$2',  _='_'}},
	   [{'==', '$2', ?to_i(Merchant)}],
	   [true]
	  }],

    _N = ets:select_delete(?WSALE_DRAFT, MS), 
    {noreply, State};

handle_cast({delete_wsale_draft, Merchant, Attrs}, State) -> 
    ?DEBUG("delete_wsale_draft with merchant ~p, Attrs ~p", [Merchant, Attrs]),
    Retailer   = ?v(<<"retailer">>, Attrs),
    Shop       = ?v(<<"shop">>, Attrs),
    Employee   = ?v(<<"employee">>, Attrs),

    SN = lists:concat([Merchant, "-", Retailer, "-", Shop, "-", ?to_s(Employee)]),
    MS = [{{'$1', '_'},
	   [{'==', '$1', ?to_b(SN)}],
	   [true]
	  }],

    _N = ets:select_delete(?WSALE_DRAFT, MS),
    ets:tab2file(?WSALE_DRAFT, "wsale_draft"),
    {noreply, State};

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
