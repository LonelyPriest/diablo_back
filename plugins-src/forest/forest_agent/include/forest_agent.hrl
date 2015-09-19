%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 14 Apr 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------

%% system error, we use spcial code 1111
-define(KNIFE_SYSTEM_ERROR, 1111).

-define(to_err(Err, Key), forest_agent_error:error(Err, Key)).


-record(forest_params_network, {host,
				port,
				family,
				connection_timeout = 3000}
       ).
