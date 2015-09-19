%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright Seasun(C) 2014, buxianhui
%%% @doc
%%%  Agent information which connect to the forest proxy
%%% @end
%%% Created :  4 Mar 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(forest_node).

-behaviour(gen_server).

%% API
-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-export([insert/2, lookup/1, delete/1]).

-define(SERVER, ?MODULE).
-define(FOREST_NODE, forest_node).

-record(state, {}).


insert(AgentIp, Sock)->
    gen_server:call(?SERVER, {insert, {AgentIp, Sock}}).

delete(AgentIp) ->
    gen_server:call(?SERVER, {delete, AgentIp}).

lookup(all) ->
    gen_server:call(?SERVER, {lookup_all});

lookup(AgentIp) when erlang:is_list(AgentIp) ->
    %% Ip with string to inet ip with tuple
    {ok, InetIp} = inet:ip(AgentIp),
    gen_server:call(?SERVER, {lookup, {InetIp}}).

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

init([]) ->
    %% TableId = ets:new(?FOREST_NODE, [bag, private, named_table]),
    ets:new(?FOREST_NODE, [set, private, named_table]),
    {ok, #state{}}.

handle_call({insert, {AgentIp, Sock}}, _From, State)->
    true = ets:insert(?FOREST_NODE, {AgentIp, Sock}),
    {reply, ok, State};

handle_call({delete, AgentIp}, _From, State) ->
    true = ets:delete(?FOREST_NODE, AgentIp),
    {reply, ok, State};

handle_call({lookup, {AgentIp}}, _From, State)->
    Socks = ets:lookup(?FOREST_NODE, AgentIp),
    {reply, {ok, Socks}, State};

handle_call({lookup_all}, _From, State)->
    Socks = ets:tab2list(?FOREST_NODE),
    {reply, {ok, Socks}, State};
    
handle_call(_Request, _From, State) ->
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

%%%===================================================================
%%% Internal functions
%%%===================================================================
