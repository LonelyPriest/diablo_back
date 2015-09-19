%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright SeasunGame(C) 2014, buxianhui
%%% @doc
%%%  Error description of controller
%%% @end
%%% Created : 27 Mar 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(controller_error).

-include("../../../include/knife.hrl").
-include("controller.hrl").

-compile(export_all).

error(job_not_exist, JobId) ->
    {9001, ?to_binary("job [" ++ ?to_string(JobId) ++ "] does not exist")};

error(unkown_step, {JobId, Step}) ->
    {9002, ?to_binary("step " ++ ?to_string(Step)
		      ++ " of job [" ++ ?to_string(JobId) ++ "] does not surpport")};
error(empty_step, JobId) ->
    {9003, ?to_binary("steps of job [" ++ ?to_string(JobId) ++ "] can not be empty")};


error(task_not_exist, TaskId) ->
    {9004, ?to_binary("task [" ++ ?to_string(TaskId) ++ "] does not exist")}.



step_state_to_code(downloading) ->
    1001;
step_state_to_code(unzipping) ->
    1002;
step_state_to_code(stopping) ->
    1003;
step_state_to_code(restarting) ->
    1004;
step_state_to_code(downloaded) ->
    2001;
step_state_to_code(unzipped) ->
    2002;
step_state_to_code(stopped) ->
    2003;
step_state_to_code(restarted) ->
    2004;
step_state_to_code(err_download) ->
    3001;
step_state_to_code(err_unzip) ->
    3002;
step_state_to_code(err_stop) ->
    3003;
step_state_to_code(err_restart) ->
    3004;
step_state_to_code(timeout) ->
    9999;
step_state_to_code(command) ->
    1111;
step_state_to_code(processing) ->
    8888;
step_state_to_code(Code) ->
    Code.
