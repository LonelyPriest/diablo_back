-module(iconv_sup).

-author("ery.lee@gmail.com").

-behavior(supervisor).

-export([start_link/0, init/1]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
    {ok, {{one_for_one, 10, 100},
      [{iconv, {iconv, start_link, []},
        permanent, 5000, worker, [iconv]}]}}.
