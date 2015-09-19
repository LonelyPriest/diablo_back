%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2014, buxianhui
%%% @doc
%%%    generator the unique sn
%%% @end
%%% Created : 16 Nov 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_controller_inventory_sn).

-include("../../../../include/knife.hrl").

-behaviour(gen_server).

%% API
-export([start_link/0]).

-export([init/2]).
-export([sn/2, dump/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-define(SERVER, ?MODULE). 

-record(state, {}).

-record(unique_ids, {merchant, id}).


%%--------------------------------------------------------------------
%% @desc: generotro a sn with special prefix
%%--------------------------------------------------------------------
sn(ad, Merchant) ->
    Key = ?to_atom("ad-no-" ++ ?to_s(Merchant)),
    gen_server:call(?SERVER, {new, Key});

sn(member, Merchant) ->
    Key = ?to_atom("member-no-" ++ ?to_s(Merchant)),
    gen_server:call(?SERVER, {new, Key});

sn(running_no, Merchant) ->
    Key = ?to_atom("running-no-" ++ ?to_s(Merchant)),
    gen_server:call(?SERVER, {new, Key});

sn(w_inventory_new_sn, Merchant) ->
    Key = ?to_atom("w-inv-new-sn-" ++ ?to_s(Merchant)),
    gen_server:call(?SERVER, {new, Key});

sn(w_inventory_reject_sn, Merchant) ->
    Key = ?to_atom("w-inv-reject-sn" ++ ?to_s(Merchant)),
    gen_server:call(?SERVER, {new, Key});

sn(w_inventory_fix_sn, Merchant) ->
    Key = ?to_atom("w-inv-fix-sn" ++ ?to_s(Merchant)),
    gen_server:call(?SERVER, {new, Key});

sn(w_sale_new_sn, Merchant) ->
    Key = ?to_atom("w-sale-new-sn-" ++ ?to_s(Merchant)),
    gen_server:call(?SERVER, {new, Key});

sn(w_sale_reject_sn, Merchant) ->
    Key = ?to_atom("w-sale-reject-sn-" ++ ?to_s(Merchant)),
    gen_server:call(?SERVER, {new, Key}).


dump() ->
    gen_server:call(?SERVER, dump).

init(merchant, Merchant)->
    gen_server:call(?SERVER, {init, Merchant}).


%%%===================================================================
%%% API
%%%===================================================================


start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).


init([]) ->
    case mnesia:system_info(use_dir) of
        true ->
            ok = mnesia:start(),
            ok;
        false ->
            stopped = mnesia:stop(),
            ok = mnesia:create_schema([node()]),
            ok = mnesia:start(),
            lists:foreach(
              fun({Tab, TabDef}) ->
                      TabDef1 = proplists:delete(match, TabDef),
                      case mnesia:create_table(Tab, TabDef1) of
                          {atomic, ok} -> ok;
                          {aborted, Reason} ->
                              throw({error, {table_creation_failed,
                                             Tab, TabDef1, Reason}})
                      end

              end, table_definitions())
    end,
    {ok, #state{}}.


%% handle_call(new, _From, State) ->
%%     %% <<A:32,B:32,C:32>> = crypto:strong_rand_bytes(12),
%%     %% random:seed({A,B,C}),
%%     %% Length = 10 - erlang:length(Prefix),
%%     %% Random = lists:concat([random:uniform(Length) || _ <-lists:seq(0, 9)]),
%%     Id =  mnesia:dirty_update_counter(unique_ids, record_type, 1),
%%     {reply, Id, State};

%% handle_call(sn_member, _From, State) ->
%%     Id =  mnesia:dirty_update_counter(unique_ids, member_sn, 1),
%%     {reply, Id, State};

handle_call({new, Key}, _From, State) ->
    Id = mnesia:dirty_update_counter(unique_ids, Key, 1),
    {reply, Id, State};

handle_call({init, Merchant}, _From, State) ->
    M = ?to_s(Merchant),
    F = fun() ->
		mnesia:write(#unique_ids{merchant=?to_atom("running-no-" ++ M) , id=0}),
		mnesia:write(#unique_ids{merchant=?to_atom("member-no-" ++ M) , id=0}),
		mnesia:write(#unique_ids{merchant=?to_atom("ad-no-" ++ M) , id=0}),
		
		%% whole sale
		mnesia:write(#unique_ids{merchant=?to_atom("w-inv-new-sn-" ++ M) , id=0}),
		mnesia:write(#unique_ids{merchant=?to_atom("w-inv-reject-sn-" ++ M) , id=0}),
		mnesia:write(#unique_ids{merchant=?to_atom("w-inv-fix-sn-" ++ M) , id=0}), 
		mnesia:write(#unique_ids{merchant=?to_atom("w-sale-new-sn-" ++ M) , id=0}),
		mnesia:write(#unique_ids{merchant=?to_atom("w-sale-reject-sn-" ++ M) , id=0})
	end,
    {atomic, _} = mnesia:transaction(F),
    {reply, ok, State};


handle_call(dump, _From, State) ->
    Reply = mnesia:dump_to_textfile('unique_ids'),
    {reply, Reply, State};

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
table_definitions() ->
    
    [
     {unique_ids,
      [{record_name, unique_ids},
       {attributes, record_info(fields, unique_ids)},
       {disc_copies, [node()]},
       {match, #unique_ids{_ = '_'}}]}
    ].
