%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2014, buxianhui
%%% @doc
%%%  File utilies
%%% @end
%%% Created : 27 Feb 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(knife_file).

-include("knife.hrl").
-include_lib("kernel/include/file.hrl").

-export([is_file/1, is_dir/1, file_size/1, ensure_dir/1, wildcard/2, list_dir/1]).
-export([read_term_file/1, write_term_file/2, write_file/2, write_file/3]).
-export([append_file/2, ensure_parent_dirs_exist/1]).
-export([rename/2, delete/1, recursive_delete/1, recursive_copy/2]).
-export([lock_file/1]).

is_file(File) ->
    case read_file_info(File) of
        {ok, #file_info{type=regular}}   -> true;
        {ok, #file_info{type=directory}} -> true;
        _                                -> false
    end.

is_dir(Dir) -> is_dir_internal(read_file_info(Dir)).

is_dir_no_handle(Dir) -> is_dir_internal(prim_file:read_file_info(Dir)).

is_dir_internal({ok, #file_info{type=directory}}) -> true;
is_dir_internal(_)                                -> false.

file_size(File) ->
    case read_file_info(File) of
        {ok, #file_info{size=Size}} -> Size;
        _                           -> 0
    end.

ensure_dir(File) -> with_fhc_handle(fun () -> ensure_dir_internal(File) end).

ensure_dir_internal("/")  ->
    ok;
ensure_dir_internal(File) ->
    Dir = filename:dirname(File),
    case is_dir_no_handle(Dir) of
        true  -> ok;
        false -> ensure_dir_internal(Dir),
                 prim_file:make_dir(Dir)
    end.

wildcard(Pattern, Dir) ->
    {ok, Files} = list_dir(Dir),
    {ok, RE} = re:compile(Pattern, [anchored]),
    [File || File <- Files, match =:= re:run(File, RE, [{capture, none}])].

list_dir(Dir) -> with_fhc_handle(fun () -> prim_file:list_dir(Dir) end).

read_file_info(File) ->
    with_fhc_handle(fun () -> prim_file:read_file_info(File) end).

with_fhc_handle(Fun) ->
    with_fhc_handle(1, Fun).

with_fhc_handle(_N, Fun) ->
    %% ok = file_handle_cache:obtain(N),
    try Fun()
    after ok
    %% after ok = file_handle_cache:release(N)
    end.

read_term_file(File) ->
    try
        {ok, Data} = with_fhc_handle(fun () -> prim_file:read_file(File) end),
        {ok, Tokens, _} = erl_scan:string(binary_to_list(Data)),
        TokenGroups = group_tokens(Tokens),
        {ok, [begin
                  {ok, Term} = erl_parse:parse_term(Tokens1),
                  Term
              end || Tokens1 <- TokenGroups]}
    catch
        error:{badmatch, Error} -> Error
    end.

group_tokens(Ts) -> [lists:reverse(G) || G <- group_tokens([], Ts)].

group_tokens([], [])                    -> [];
group_tokens(Cur, [])                   -> [Cur];
group_tokens(Cur, [T = {dot, _} | Ts])  -> [[T | Cur] | group_tokens([], Ts)];
group_tokens(Cur, [T | Ts])             -> group_tokens([T | Cur], Ts).

write_term_file(File, Terms) ->
    write_file(File, list_to_binary([io_lib:format("~w.~n", [Term]) ||
                                        Term <- Terms])).

write_file(Path, Data) -> write_file(Path, Data, []).

%% write_file/3 and make_binary/1 are both based on corresponding
%% functions in the kernel/file.erl module of the Erlang R14B02
%% release, which is licensed under the EPL. That implementation of
%% write_file/3 does not do an fsync prior to closing the file, hence
%% the existence of this version. APIs are otherwise identical.
write_file(Path, Data, Modes) ->
    Modes1 = [binary, write | (Modes -- [binary, write])],
    case make_binary(Data) of
        Bin when is_binary(Bin) ->
            with_fhc_handle(
              fun () -> case prim_file:open(Path, Modes1) of
                            {ok, Hdl}      -> try prim_file:write(Hdl, Bin) of
                                                  ok -> prim_file:sync(Hdl);
                                                  {error, _} = E -> E
                                              after
                                                  prim_file:close(Hdl)
                                              end;
                            {error, _} = E -> E
                        end
              end);
        {error, _} = E -> E
    end.

make_binary(Bin) when is_binary(Bin) ->
    Bin;
make_binary(List) ->
    try
        iolist_to_binary(List)
    catch error:Reason ->
            {error, Reason}
    end.

append_file(File, Suffix) ->
    case read_file_info(File) of
        {ok, FInfo}     ->
	    ?FORMAT("file ~p, suffix ~p, FInfo ~p", [File, Suffix, FInfo]),
	    append_file(File, FInfo#file_info.size, Suffix);
        {error, enoent} ->
	    ?FORMAT("failed to append file, file not exist", []),
	    append_file(File, 0, Suffix);
        Error           ->
	    ?FORMAT("failed to append file with error ~p", [Error]),
	    Error
    end.

append_file(File, 0, Suffix) ->
    with_fhc_handle(fun () ->
                            case prim_file:open([File, Suffix], [append]) of
                                {ok, Fd} ->
				    ?FORMAT("ok, open file ~p", [File]),
				    prim_file:close(Fd);
                                Error    ->
				    ?FORMAT("error to open file with error ~p", [Error]),
				    Error
                            end
                    end);

append_file(_, _, "") ->
    ok;

append_file(File, _, Suffix) ->
    case with_fhc_handle(2, fun () ->
                                file:copy(File, {[File, Suffix], [append]})
                            end) of
        {ok, _BytesCopied} -> ok;
        Error              -> Error
    end.

ensure_parent_dirs_exist(Filename) ->
    case ensure_dir(Filename) of
        ok              -> ok;
        {error, Reason} ->
            throw({error, {cannot_create_parent_dirs, Filename, Reason}})
    end.

rename(Old, New) -> with_fhc_handle(fun () -> prim_file:rename(Old, New) end).

delete(File) -> with_fhc_handle(fun () -> prim_file:delete(File) end).

recursive_delete(Files) ->
    with_fhc_handle(
      fun () -> lists:foldl(fun (Path,  ok) -> recursive_delete1(Path);
                                (_Path, {error, _Err} = Error) -> Error
                            end, ok, Files)
      end).

recursive_delete1(Path) ->
    case is_dir_no_handle(Path) and not(is_symlink_no_handle(Path)) of
        false -> case prim_file:delete(Path) of
                     ok              -> ok;
                     {error, enoent} -> ok; %% Path doesn't exist anyway
                     {error, Err}    -> {error, {Path, Err}}
                 end;
        true  -> case prim_file:list_dir(Path) of
                     {ok, FileNames} ->
                         case lists:foldl(
                                fun (FileName, ok) ->
                                        recursive_delete1(
                                          filename:join(Path, FileName));
                                    (_FileName, Error) ->
                                        Error
                                end, ok, FileNames) of
                             ok ->
                                 case prim_file:del_dir(Path) of
                                     ok           -> ok;
                                     {error, Err} -> {error, {Path, Err}}
                                 end;
                             {error, _Err} = Error ->
                                 Error
                         end;
                     {error, Err} ->
                         {error, {Path, Err}}
                 end
    end.

is_symlink_no_handle(File) ->
    case prim_file:read_link(File) of
        {ok, _} -> true;
        _       -> false
    end.

recursive_copy(Src, Dest) ->
    %% Note that this uses the 'file' module and, hence, shouldn't be
    %% run on many processes at once.
    case is_dir(Src) of
        false -> case file:copy(Src, Dest) of
                     {ok, _Bytes}    -> ok;
                     {error, enoent} -> ok; %% Path doesn't exist anyway
                     {error, Err}    -> {error, {Src, Dest, Err}}
                 end;
        true  -> case file:list_dir(Src) of
                     {ok, FileNames} ->
                         case file:make_dir(Dest) of
                             ok ->
                                 lists:foldl(
                                   fun (FileName, ok) ->
                                           recursive_copy(
                                             filename:join(Src, FileName),
                                             filename:join(Dest, FileName));
                                       (_FileName, Error) ->
                                           Error
                                   end, ok, FileNames);
                             {error, Err} ->
                                 {error, {Src, Dest, Err}}
                         end;
                     {error, Err} ->
                         {error, {Src, Dest, Err}}
                 end
    end.

%% When we stop supporting Erlang prior to R14, this should be
%% replaced with file:open [write, exclusive]
lock_file(Path) ->
    case is_file(Path) of
        true  -> {error, eexist};
        false -> with_fhc_handle(
                   fun () -> {ok, Lock} = prim_file:open(Path, [write]),
                             ok = prim_file:close(Lock)
                   end)
    end.
