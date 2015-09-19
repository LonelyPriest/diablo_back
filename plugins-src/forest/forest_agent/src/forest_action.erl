%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright Seasun (C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created :  5 Mar 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(forest_action).

-include("../../../include/knife.hrl").

-include("forest_agent.hrl").

-behaviour(gen_server).

%% API
-export([start_link/1]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-export([sock_send/1]).
-export([refresh_sock/1, connect/2, download/3]).
-export([parse_protocol_path/1, parse/1, do/2]).

-export([execute/2]).

-define(SERVER, ?MODULE).
-define(INTERVAL_SEND, 5000).

-record(state, {sock}).


refresh_sock(Sock) ->
    gen_server:call(?SERVER, {refresh, Sock}).

sock_send(Message) ->
    gen_server:cast(?SERVER, {sock_send, Message}).

start_link(Sock) ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [Sock], []).


init([Sock]) ->
    {ok, #state{sock = Sock}}.


handle_call({refresh, Sock}, _Form, State) ->
    {reply, ok, State#state{sock = Sock}};

handle_call(Request, _From, State) ->
    ?DEBUG("handle_call: receive unkown Request ~p", [Request]),
    Reply = ok,
    {reply, Reply, State}.

handle_cast({sock_send, Message}, #state{sock = Sock} = State) ->
    ?DEBUG("handle_cast: sock send message ~p", [Message]),
    try
	ok = gen_tcp:send(Sock, Message)
    catch
	_:{badmatch, {error, Error}} ->
	    ?DEBUG("handle_cast: sock send message ~p failed, "
		   "reason: ~p", [Message, Error]),
	    ?WARN("agent send message ~p to proxy failed, "
		  "reason: ~p, discard it", [Message, Error]),
	    erlang:send_after(?INTERVAL_SEND, ?SERVER,
			      {'$gen_cast', {sock_send, Message}})
    end,
    {noreply, State};
    
handle_cast({to_proxy, Message}, State) ->
    ?DEBUG("message ~p will be send to proxy", [Message]),
    ok = send(State, Message),
    {noreply, State};
	
handle_cast(Msg, State) ->
    ?DEBUG("handle_cast: receive unkown message ~p", [Msg]),
    {noreply, State}.


handle_info({tcp_closed, Socket}, State) ->
    %% {ok, {PeerHost, Port}} = inet:peername(Socket),
    ?DEBUG("tcp closed on socket ~p" , [Socket]),
    ?WARN("tcp closed on socket ~p" , [Socket]),
    
    forest_connection:reconnect(),
    {noreply, State};

handle_info({tcp, Socket, <<"handshake">> = Message}, State) ->
    {ok, {PeerHost, Port}} = inet:peername(Socket),
    ?DEBUG("congratulations, receve handshake message ~p~nfrom proxy ~p "
	   "on port ~p, Success to connected" , [Message, PeerHost, Port]),
    ?INFO("congratulations, receve handshake message ~p~nfrom proxy ~p "
	  "on port ~p, Success to connected" , [Message, PeerHost, Port]),
    {noreply, State};


handle_info({tcp, Socket, Message}, State) ->
    {ok, {PeerHost, Port}} = inet:peername(Socket),
    DecodeMessage = ejson:decode(Message),
    ?DEBUG("receve message ~p~nfrom proxy ~p on port ~p",
	   [DecodeMessage, PeerHost, Port]),
    
    spawn(?MODULE, do, [DecodeMessage, self()]),
    {noreply, State};

handle_info(Info, State) ->
    ?DEBUG("handle_info: receive unkown info msg ~p", [Info]),
    ?WARN("handle_info: receive unkown info msg ~p", [Info]),
    {noreply, State}.


terminate(_Reason, _State) ->
    ok.


code_change(_OldVsn, State, _Extra) ->
    {ok, State}.


do({[TaskId, _Target,
     {<<"step">>, {[SN, Name, _StqepId,
		    {<<"type">>, <<"1">>} = Type|_] = Step}}]}, Parent) ->
    Source = proplists:get_value(<<"source">>, Step),
    ?DEBUG("Receive download message SN=~p, Name=~p, Source = ~p",
	   [SN, Name, Source]),
        
    %% {Running, Finished, Errored} = knife_utils:step_life_cycle(),
    StepHead = [TaskId, SN, Name, Type],

    case parse_protocol_path(Source) of
	{ftpc, {User, Password, Host, RemotePath}} ->
	    %% Ftp = connect(ftpc, {Host, User, Password}),
	    %% make a temporary dir to download file
	    ?DEBUG("success to parse protocal path: "
		   "Host = ~p, RemotePath ~p", [Host, RemotePath]),
	    
	    {ok, CurrDir} = file:get_cwd(),
	    DownloadDir = CurrDir ++ "/download/",
	    
	    case file:make_dir(DownloadDir) of
		{error, eexist} -> ok;
		ok              -> ok
	    end,

	    ?DEBUG("success to get local download dir ~p", [DownloadDir]),
	    
	    case connect(ftpc, {Host, User, Password}) of
		{ftp_connect_failed, {ECode, EInfo}} ->
		    ?DEBUG("ftp connect to host ~p with user ~p failed, "
			   "ECode ~p, EInfo ~p", [Host, User, ECode, EInfo]),
		    ok = report_status(common_error, Parent,
				       {StepHead, {failed, ECode, EInfo}}),
		    exit({ftp_connect_failed, {ECode, EInfo}});
		Ftp ->
		    ?DEBUG("ftp connect to host ~p with user ~p successfully",
			   [Host, User]),
		    ok = report_status(immedialy, Parent, {StepHead, running}),
		    
		    %% when download a large file, should report interval
		    TRef = report_status({interval, 10000},
					 Parent, {StepHead, running}),
		    
		    try download({ftpc, Ftp}, [RemotePath], DownloadDir) of
			ok ->
			    ?DEBUG("download file ~p from Host ~p to local path ~p "
			       "successfully", [RemotePath, Host, DownloadDir]),
			    %% cancel timer,
			    %% downloaded message must be send after dowloading 
			    timer:cancel(TRef),
			    %% wait for timer to cancel
			    timer:sleep(100),
			    %% now, no dowloading message was send, we can
			    %% send downloaded message
			    ok = report_status(
				   immedialy, Parent, {StepHead, finished});
			{download_failed, {ECode, EInfo}} ->
			    ?DEBUG("download file ~p from host ~p to local ~p failed "
				   "reason: ~p", [RemotePath, Host, DownloadDir, EInfo]),
			    timer:cancel(TRef),
			    timer:sleep(100),
			    ok = report_status(
				   common_error, Parent,
				   {StepHead, {failed, ECode, EInfo}})
		    catch
			{not_enough_space, Path} ->
			    {ECode, EInfo} = ?to_err(not_enough_space, Path),
			    
			    timer:cancel(TRef),
			    timer:sleep(100),
			    
			    ok = report_status(
				   common_error, Parent,
				   {StepHead, {failed, ECode, EInfo}})
		    end,
		    
		    inets:stop(ftpc, Ftp)
	    end;
	{not_surpport, Protocal} ->
	    ?DEBUG("protocal path ~p does not surport noew", [Source]),
	    {ECode, EInfo} = ?to_err(protocal_not_support, Protocal),
	    ok = report_status(common_error, Parent,
			       {StepHead, {failed, ECode, EInfo}}),
	    exit({protocol_not_supported, Source})
    end;

%% some step has filed 'source', such as unzip, 
do({[TaskId, _Target,
     {<<"step">>,
      {[SN, Name, _StepId,
	{<<"type">>, <<"2">>} = Type,
	{<<"source">>, Source},
	{<<"script">>, Script}|OtherProps]}}
    ]}, Parent) ->
    ExecuteUser = proplists:get_value(<<"user">>, OtherProps),
    ?DEBUG("do: task id ~p, step ~p, source ~p, script ~p, execute_user ~p",
	   [TaskId, Name, Source, Script, ExecuteUser]),
    ok = execute_with_interval_report(
	   Parent, [TaskId, SN, Name, Type], Script);

%% some step has not filed "source", such as stop, restart
do({[TaskId, _Target,
     {<<"step">>,
      {[SN, Name, _StepId,
	{<<"type">>, <<"2">>} = Type,
	{<<"script">>, Script}|OtherProps]}}
    ]}, Parent) ->
    ExecuteUser = proplists:get_value(<<"user">>, OtherProps),
    ?DEBUG("do: task id ~p, step ~p, script ~p, execute_user ~p",
	   [TaskId, Name, Script, ExecuteUser]),
    ok = execute_with_interval_report(
	   Parent, [TaskId, SN, Name, Type], Script);

%% nothing, such as dba-check
do({[TaskId, _Target,
     {<<"step">>,
      {[SN, Name, _StepId, {<<"type">>, <<"3">>} = Type|_]}}
    ]}, Parent) ->
    ?DEBUG("do: task id ~p, step ~p", [TaskId, Name]),
    %% {_, Finished, _} = knife_utils:step_life_cycle(),
    ok = report_status(immedialy, Parent, {[TaskId, SN, Name, Type], artificial});


%% nothing, standby
do({[TaskId, _Target,
     {<<"step">>,
      {[SN, Name, _StepId, {<<"type">>, <<"4">>} = Type|_]}}
    ]}, Parent) ->
    ?DEBUG("do: task id ~p, step ~p", [TaskId, Name]),
    %% {_, Finished, _} = knife_utils:step_life_cycle(),
    ok = report_status(immedialy, Parent, {[TaskId, SN, Name, Type], waiting});

do({[TaskId, _Target,
     {<<"step">>, {[SN, {<<"name">> = StepName} = Step,
		    {<<"type">>, _N} = Type|Other]}}]}, Parent) ->
    ?WARN("do: unkown step ~p of task ~p with content ~p found",
	  [StepName, TaskId, Other]),
    
    {ECode, EInfo} = ?to_err(step_not_support, StepName),
    %% {_, _, Errored} = knife_utils:step_life_cycle(),
    ok = report_status(common_error, Parent,
		       {[SN, Step, Type], {failed, ECode, EInfo}});

do(Unkown, _) ->
    ?WARN("do: unkown message ~p receive", [Unkown]).




send(#state{sock = Sock} = _State, Message) when is_tuple(Message) ->
    EncodeMessage = ejson:encode({tuple_to_list(Message)}),
    
    ?DEBUG("encode message = ~p will be send to proxy", [EncodeMessage]),
    sock_send(Sock, EncodeMessage);

send(#state{sock = Sock} = _State, Message) ->
    EncodeMessage = ejson:encode({Message}),
    ?DEBUG("encode message = ~p will be send to proxy", [EncodeMessage]),
    sock_send(Sock, EncodeMessage).

sock_send(Sock, Message) ->
    try
	ok = gen_tcp:send(Sock, Message)
    catch
	_:{badmatch, {error, Err}}  ->
	    ?DEBUG("socket error to send message ~p with reason: ~p, retry again",
		   [Message, Err]),
	    ?WARN("socket error to send message ~p with reason: ~p, retry again",
		  [Message, Err]),
	    %% retry 
	    sock_send(Message)
    end.

connect(ftpc, {Host, User, Password}) ->
    case application:get_application(inets) of
	{ok, inets} -> ok;
	undefined   ->
	    application:start(inets)
    end,

    try
	{ok, Pid} = inets:start(ftpc, [{host, Host}]),
	ok = ftp:user(Pid, ?to_string(User), ?to_string(Password)),	
	Pid
    catch
	_:{badmatch, {error, euser}} ->
	    {ftp_connect_failed, ?to_err(connect_euser, User)};
	_:{badmatch, {error, econn}} ->
	    {ftp_connect_failed, ?to_err(connect_econn, User)};
	_:{badmatch, {error, eclosed}} ->
	    {ftp_connect_failed, ?to_err(connect_eclosed, Host)};
	_:{badmatch, {error, ehost}} ->
	    {ftp_connect_failed, ?to_err(connect_ehost, Host)};
	_:{badmatch, {error, Err}} ->
	    {ftp_connect_failed, ?to_err(connect_unkown_reason, Err)}
    end.

-spec report_status(atom(), pid(), tuple()) -> ok|reference(). 
report_status(common_error, To, {StepHead, {Errored, ECode, EInfo}}) ->
    M =
	StepHead ++
	[
	 {<<"action">>,  ?to_binary(Errored)},
	 {<<"ecode">>,   ?to_binary(ECode)},
	 {<<"einfo">>,   ?to_binary(EInfo)}
	],
    ?DEBUG("report common error with message:~p", [M]),
    To ! {'$gen_cast', {to_proxy, M}},
    ok;

%% report_status(normal_output, To, {TaskId, Action, OutPut}) ->
%%     M = 
%% 	{TaskId, 
%% 	 {<<"action">>,  ?to_binary(Action)},
%% 	 {<<"ecode">>,   ?to_binary(ECode)},
%% 	 {<<"einfo">>,   ?to_binary(EInfo)}
%% 	},
%%     ?DEBUG("report system error with message:~p", [M]),
%%     To ! {'$gen_cast', {to_proxy, M}},
%%     ok;
    
report_status(immedialy, To, {StepHead, StepInfo}) ->
    To ! {'$gen_cast',
	  {to_proxy, StepHead ++ [{<<"action">>, ?to_binary(StepInfo)}]}},
    ok;
%% report_status(immedialy, To, {TaskId, Status}) when is_list(Status)->
%%     To ! {'$gen_cast', {to_proxy, list_to_tuple([TaskId] ++ Status)}},
%%     ok;
report_status({interval, Milliseconds}, To, {StepHead, StepInfo}) ->
    timer:start(),
    {ok, TRef} =
	timer:send_interval(
	  Milliseconds, To,
	  {'$gen_cast',
	   {to_proxy, StepHead ++ [{<<"action">>, ?to_binary(StepInfo)}]}}),
    TRef.

%% =============================================================================
%% @desc: download file from path to local directory
%% @Remote: remote path
%% @File: remote file
%% @Local: local dir to save download file
%% =============================================================================    
download({ftpc, Ftp}, RemotePath, Local) ->
    ?DEBUG("download: Remote ~p, local ~p ", [RemotePath, Local]),

    {ok, CurrentDir} = file:get_cwd(),
    ?DEBUG("download: local current dir ~p", [CurrentDir]),

    %% shoud have enough space to dowanload file
    case get_mount_point_size(linux, Local) >
	file_space({ftpc, Ftp}, RemotePath) of
	true ->
	    ok;
	false ->
	    throw({not_enough_space, Local})
    end,
	
    DownLoadInfo = 
	case ftp_change_dir(Ftp, Local, fun ftp:lcd/2) of
	    ok ->
		case loop_download(Ftp, RemotePath) of
		    ok -> ok;
		    Reason -> Reason
		end;
	    Reason ->
		Reason
	end,
    
    ok = ftp_change_dir(Ftp, CurrentDir, fun ftp:lcd/2),
    inets:stop(ftpc, Ftp),
    DownLoadInfo.

ftp_change_dir(Ftp, Dir, ChangeFun) ->
    ?DEBUG("ftp_change_dir: dir ~p", [Dir]),
    try
	ok = ChangeFun(Ftp, Dir),
	ok
    catch 
	_:{badmatch, {error, epath}} ->
	    ?DEBUG("ftp change dir failed, epath: ~p", [Dir]),
	    {download_failed, ?to_err(download_epath, Dir)};
	_:{badmatch, {error, Err}} ->
	    ?DEBUG("ftp change dir failed, reason: ~p", [Err]),
	    {download_failed,
	     ?to_err(download_unkown_reason,
		     "ftp change dir " ++ Dir ++ "failed:" ++ ?to_string(Err))}
    end.

loop_download(_Ftp, []) ->
    ok;

loop_download(Ftp, [RemotePath|T]) ->
    ?DEBUG("loop_download: remote path = ~p", [RemotePath]),
    RemoteInfo = string:tokens(RemotePath, "/"),
    File = lists:last(RemoteInfo),
    Path = string:join(RemoteInfo -- [File], "/"),
    
    case ftp_change_dir(Ftp, Path, fun ftp:cd/2) of
	ok ->
	    try
		ok = ftp:type(Ftp, binary),
		ok = ftp:recv(Ftp, ?to_string(File)),
		loop_download(Ftp, T)
	    catch
		_:{badmatch, {error, epath}} ->
		    ?DEBUG("failed to download, file path does not exist",
			   [RemotePath]),
		    {download_failed,
		     ?to_err(download_epath,
			    ?to_string(RemotePath))};
		_:{badmatch, {error, Err}} ->
		    ?DEBUG("failed to download file ~p, reason: ~p",
			   [RemotePath, Err]),
		    {download_failed,
		     ?to_err(download_unkown_reason,
			     RemotePath ++ ":" ++ ?to_string(Err))}
	    end;
	Reason ->
	    Reason
    end.
	
	
%% =============================================================================
%% @desc: parse the protocol path
%% @Path: ftp format string "ftp://username:password@ip/server"
%% @return: {ftp, "192.168.0.1", "server"}
%% =============================================================================
parse_protocol_path(Path) when is_binary(Path) =:= false ->
    parse_protocol_path(list_to_binary(Path));

parse_protocol_path(<<"ftp://", T/binary>>) ->
    {User, Passwd, Host, Path} = parse(T),
    {ftpc, {binary_to_list(User), binary_to_list(Passwd),
	    binary_to_list(Host), binary_to_list(Path)}};

parse_protocol_path(Other) ->
    ?FORMAT("~p does not supported now, only ftp can use", [Other]),
    {not_surpport, Other}.

parse(Path) ->
    {User, P1} = parse_user(ftp, Path, <<>>),
    {Pwd, P2}  = parse_pwd(ftp, P1, <<>>),
    {Host, P3}  = parse_host(ftp, P2, <<>>),
    {User, Pwd, Host, P3}.

parse_user(ftp, <<":", T/binary>>, User) ->
    {User, T};
parse_user(ftp, <<H, T/binary>>, User) ->
    parse_user(ftp, T, <<User/binary, H>>).

parse_pwd(ftp, <<"@", T/binary>>, Pwd) ->
    {Pwd, T};
parse_pwd(ftp, <<H, T/binary>>, Pwd) ->
    parse_pwd(ftp, T, <<Pwd/binary, H>>).

parse_host(ftp, <<"/", T/binary>>, Host) ->
    {Host, T};
parse_host(ftp, <<H, T/binary>>, Host) ->
    parse_host(ftp, T, <<Host/binary, H>>).



execute_with_interval_report(Parent, StepHead, Script)->
    %% [Path|Action] = string:tokens(?to_string(Script), " "),
    %% {Running, Finished, Errored} = knife_utils:step_life_cycle(),
    
    TRef = report_status({interval, 10000}, Parent, {StepHead, running}),

    Report = 
	case execute(script, {Script, 0}) of
	    {ok, success} ->
		fun() -> report_status(immedialy, Parent, {StepHead, finished}) end;
	    {error, ECode, EInfo} ->
		fun() -> report_status(common_error, Parent,
				       {StepHead, {failed, ECode, EInfo}}) end
	end,

    %% after unzipped, cancel timer
    timer:cancel(TRef),
    %% wait timer cancel
    timer:sleep(100),

    Report(),
    ok.
    
execute(script, {Script, ExitState}) ->
    %% {_R, Finished, Errored} = knife_utils:step_life_cycle(Action),    
   try knife_utils:execute({script, Script}, ExitState) of
	{ok, SuccInfo}           ->
	    ?DEBUG("Success to execute script ~p with output~n:~p",
		   [Script, SuccInfo]),
	   {ok, success};
	{error, {Status, EInfo}} ->
	   {error, Status, EInfo}
   catch
       error:enoent ->
	   {ECode, EInfo} = ?to_err(exe_script_enoent, Script),
	   {error, ECode, EInfo};
       _:Reason ->
	   {ECode, EInfo} = ?to_err(exe_script_unkown_reason, Reason),
	   {error, ECode, EInfo}
    end.

file_space({ftpc, Ftp}, Path) ->
    file_space({ftpc, Ftp}, Path, 0).

file_space({ftpc, _Ftp}, [], AllSize) ->
    ?DEBUG("All file size ~p", [AllSize]),
    AllSize;
file_space({ftpc, Ftp}, [Path|T], AllSize) ->
    {ok, PathInfo} = ftp:ls(Ftp, Path),
    [_, _, _, _, Size|_] = string:tokens(PathInfo, " "),
    ?DEBUG("The file size ~p of path ~p", [Size, Path]),
    file_space({ftpc, Ftp}, T, ?to_integer(Size) + AllSize).


get_mount_point_size(linux, []) ->
    throw({error, no_mount_point_found});
get_mount_point_size(linux, Path) ->
    case knife_utils:execute(
	   command, "df -kP " ++ Path ++ "|awk '{print $4}'") of
	{ok, Info} ->
	    ?DEBUG("get mount point info ~p", [Info]),
	    [_, Size] = string:tokens(?to_string(Info), "\n"),
	    %% KB to Byte
	    ?to_integer(Size) * 1024;
	{error, _} ->
	    Segments = string:tokens(Path, "/"),
	    NewPath = string:join(Segments -- [lists:last(Segments)], "/"),
	    get_mount_point_size(linux, NewPath)
    end.
    


    
