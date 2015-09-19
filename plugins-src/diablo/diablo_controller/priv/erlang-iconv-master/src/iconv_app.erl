-module(iconv_app).

-behavior(application).

-export([start/2, stop/1]).

start(normal, _) ->
	iconv_sup:start_link().

stop(_) ->
	ok.
