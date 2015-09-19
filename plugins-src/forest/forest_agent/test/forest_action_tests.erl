-module(forest_action_tests).

-include_lib("eunit/include/eunit.hrl").

connect_test_() ->
    Ftp1 = forest_action:connect(ftpc, {"10.20.96.160", "buxianhui", "wli"}),

    FailedInfo = forest_action:connect(ftpc, {"10.20.96.161", "buxianhui", "wli"}),

    [?_assertEqual(true, is_pid(Ftp1)),
     ?_assertMatch({ftp_connect_failed, {9104, _}}, FailedInfo)].


download_test_() ->
    Url = <<"ftp://buxianhui:wli@10.20.96.160"
	    "/download_test/erl_runtime-centos6.5-x86-64.tar.gz">>,
    {ftpc, {User, Passwd, Host, RemotePath}} = forest_action:parse_protocol_path(Url),
    Ftp = forest_action:connect(ftpc, {Host, User, Passwd}),
    try
	forest_action:download(
	  {ftpc, Ftp},
	  [RemotePath],
	  "/home/buxianhui/kingsoft_deploy/knife/plugins-src/forest_agent/download") of
	D ->
	    ?_assertEqual(ok, D)
    catch
	{not_enough_space, _} = Error ->
	    ?_assertMatch({not_enough_space, _}, Error)
    end.

execute_test_()->
    R = forest_action:execute(script, {"/home/buxianhui/download_test/jx_online_3.sh stop", 0}),
    ?_assertMatch({ok, _}, R).
    
    
   
    
