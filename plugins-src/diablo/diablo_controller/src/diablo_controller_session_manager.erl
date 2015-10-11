%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright diablo (C) 2014, buxianhui
%%% @desc: session manager of users
%%% Created : 13 Sep 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_controller_session_manager).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_server).

%% API
-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-export([new/1, get/2, get_user/2,
	 lookup/0, lookup/1, get_session/2, refresh/1,
	 delete/0, delete/1, delete/2]).

-define(SERVER, ?MODULE).

%% second
-define(INTERVAL, 60).
-define(TIMEOUT,  3600 * 2).
%% -define(TIMEOUT,  3600 * 12).

-record(state, {tref}).


%%%===================================================================
%%% API
%%%===================================================================
new(User) ->
    gen_server:call(?SERVER, {new, User}).

lookup() ->
    gen_server:call(?SERVER, lookup_all).
lookup(SessionId) ->
    gen_server:call(?SERVER, {lookup, SessionId}).
refresh(SessionId) ->
    gen_server:call(?SERVER, {refresh, SessionId}).

get_session(by_user, User) ->
    gen_server:call(?SERVER, {get_session_by_user, User}).

get_user(number, Merchant) ->
    gen_server:call(?SERVER, {number_of_user, Merchant}).


delete() ->
    gen_server:call(?SERVER, delete).
delete(SessionId) ->
    gen_server:call(?SERVER, {delete, SessionId}).

delete(longest_unused, Merchant) ->
    gen_server:call(?SERVER, {delete_longest_unused, Merchant}).

start_link() -> 
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

init([]) ->
    ets:new(?SESSION, [set, private, named_table]),

    %% cleanup session that was timeout
    ok = timer:start(),
    %% minisecond, multi 1000
    {ok, TRef} = timer:send_interval(
		   ?INTERVAL * 1000 * 60 , ?SERVER, {'$gen_cast', cleanup_session}),
    
    {ok, #state{tref=TRef}}.

handle_call({new, User}, _From, State) ->    
    ?DEBUG("new session to user ~p", [User]),

    UserId       = ?v(<<"id">>, User),
    UserName     = ?v(<<"name">>, User),
    UserType     = ?v(<<"type">>, User),
    Merchant     = ?v(<<"merchant">>, User),
    MerchantType = ?v(<<"mtype">>, User),

    MS = [{{'_', #session{user_name='$1', _='_'}},
	   [{'==', '$1', ?to_b(UserName)}],
	   ['$_']
	  }],
    case ets:select(?SESSION, MS) of
	[] ->
	    ok;
	[{OldSessionId, _}] ->
	    true = ets:delete(?SESSION, ?to_b(OldSessionId))
    end,

    SessionId = ?to_b(knife_uuid:v5(string, ?to_s(UserId))),
    true = ets:insert(?SESSION,
		      {?to_b(SessionId),
		       #session{
			      id          = ?to_b(SessionId), 
			      user_id     = ?to_i(UserId),
			      user_name   = ?to_b(UserName),
			      user_type   = ?to_i(UserType),
			      merchant    = ?to_i(Merchant),
			      mtype       = ?to_i(MerchantType),
			      login_time  = ?utils:current_time(timestamp)}}),
    {reply, {ok, SessionId}, State};

handle_call({lookup, SessionId}, _From, State) ->
    ?DEBUG("lookup session with session id ~p", [SessionId]),
    MS = [{{'$1', '$2'},
	   [{'==', '$1', ?to_b(SessionId)}],
	   ['$2']
	  }],
    case ets:select(?SESSION, MS) of
	[] ->
	    {reply, {ok, []}, State};
	[Session] ->
	    {reply, {ok, Session}, State}
    end;

    
handle_call({refresh, SessionId}, _From, State) ->
    BinarySessionId =
	case is_binary(SessionId) of
	    true -> SessionId;
	    false-> ?to_b(SessionId)
	end,
	
    MS = [{{'$1', '$2'},
	   [{'==', '$1', BinarySessionId}],
	   ['$2']
	  }],
    case ets:select(?SESSION, MS) of
	[] -> ok;
	[Session] -> 
	    ets:update_element(
	      ?SESSION, ?to_b(BinarySessionId),
	      {2, Session#session{
		    login_time=?utils:current_time(timestamp)}})
    end,
    
    {reply, ok, State};

handle_call({get_session_by_user, User}, _From, State) ->
    ?DEBUG("get_session_by_user with user ~p", [User]),
    MS = [{{'_', #session{user_name='$1', _='_'}},
	   [{'==', '$1', ?to_b(User)}],
	   ['$_']
	  }],
    case ets:select(?SESSION, MS) of
	[] ->
	    {reply, {ok, []}, State};
	[Session] ->
	    ?DEBUG("get session ~p of user ~p", [Session, User]),
	    {reply, {ok, Session}, State};
	_ ->
	    {reply, {error, more_session}, State}
    end;

handle_call({number_of_user, Merchant}, _From, State) ->
    ?DEBUG("number_of_user with merchant ~p", [Merchant]),
    MS = [{{'$1', #session{merchant='$2', _='_'}},
	   [{'==', '$2', Merchant}],
	   ['$1']}
	 ],
    Ids = ets:select(?SESSION, MS),
    {reply, {ok, length(Ids)}, State};

handle_call(lookup_all, _From, State)->
    Sessions = ets:tab2list(?SESSION),
    {reply, {ok, Sessions}, State};

handle_call({delete, SessionId}, _From, State) ->
    ?DEBUG("delete with parameters: SessionId ~p", [SessionId]),
    true = ets:delete(?SESSION, ?to_b(SessionId)),
    {reply, ok, State};

handle_call(delete, _From, State) ->
    ?DEBUG("delete all sessions", []),
    true = ets:delete_all_objects(?SESSION),
    {reply, ok, State};

handle_call({delete_longest_unused, Merchant}, _From, State) ->
    MS = [{{'$1', #session{merchant='$2', _='_'}},
	   [{'==', '$2', Merchant}],
	   ['$_']}
	 ], 
    case ets:select(?SESSION, MS) of
	[] -> {reply, ok, State};
	Users ->
	    %% ?DEBUG("logined users ~p", [Users]),
	    %% merchant can not be fired
	    FilterUsers = 
		lists:filter(
		  fun({_, #session{user_type=UType}=_Session}) ->
			  case UType =:= ?MERCHANT of
			      true -> false;
			      false -> true
			  end
		  end, Users),

	    ?DEBUG("filter logined users ~p", [FilterUsers]),
	    case user(longest_unused, FilterUsers) of
		[] -> {reply, {error, no_users}, State};
		{SessionId, _Session} ->
		    ?DEBUG("delete session ~p that longest unused", [SessionId]),
		    true = ets:delete(?SESSION, SessionId),
		    {reply, ok, State}
	    end
    end;

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

handle_cast(cleanup_session, State) ->
    ?DEBUG("cleanup_session after 1 hour", []),
    %% CleanSessions = 
    ets:foldl(
      fun({Id, Session}, Acc)->
	      %% ?DEBUG("session id ~p, session ~p", [Id, Session]),
	      case ?utils:current_time(timestamp)
		  - Session#session.login_time >= ?TIMEOUT of
		  true ->
		      %% not acitivte, delete
		      ?INFO("session ~p does not activited, delete it", [Session]),
		      true = ets:delete(?SESSION, Id),
		      [Id|Acc];
		  false -> Acc
	      end
      end, [], ?SESSION),

    %% ?DEBUG("clean sessions ~p", [CleanSessions]),
    {noreply, State};

handle_cast(_Msg, State) ->
    {noreply, State}.


handle_info(_Info, State) ->
    ?DEBUG("receive unkown message ~p", [_Info]), 
    {noreply, State}.


terminate(_Reason, _State) ->
    ok.


code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
user(longest_unused, []) ->
    [];
user(longest_unused, [H|T]) ->
    user(longest_unused, H, T).

user(longest_unused, {_, LSesion} = User, []) ->
    case LSesion#session.user_type =:= ?MERCHANT of
	true  -> [];
	false -> User
    end;

user(longest_unused, {_, LSesion} = User, [{_, HSession} = H|T]) -> 
    case LSesion#session.user_type =:= ?MERCHANT of
	true ->
	    user(longest_unused, H, T);
	false ->
	    case  HSession#session.login_time < LSesion#session.login_time of
		true ->
		    user(longest_unused, H, T);
		false ->
		    user(longest_unused, User, T)
	    end
    end.

get(id, Session)->
    Session#session.user_id;
get(name, Session) ->
    Session#session.user_name;
get(type, Session) ->
    Session#session.user_type;
get(merchant, Session) ->
    Session#session.merchant;
get(mtype, Session) ->
    Session#session.mtype;
get(time, Session) ->
    Session#session.login_time.

