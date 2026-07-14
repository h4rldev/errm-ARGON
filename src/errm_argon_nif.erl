-module(errm_argon_nif).
-export([hash/5, verify/2]).
-on_load(init/0).

init() ->
 NifPath = case code:priv_dir(errm_argon) of
    PrivDir when is_list(PrivDir) ->
      filename:join([PrivDir, "errm_argon_nif"]);
    {error, bad_name} ->
      logger:error("Could not find priv_dir"),
      case code:lib_dir(errm_argon) of
        {ok, LibDir} ->
          filename:join([LibDir, "priv", "errm_argon_nif"]);
        _ ->
          logger:error("Could not find lib_dir"),
          "./priv/errm_argon_nif"
      end;
    _ ->
      logger:error("Could not find priv_dir, and it wasnt bad_name"),
      "./priv/errm_argon_nif"
    end,

    NifPathStr = case NifPath of
      Path when is_list(Path) -> Path
    end,
    case erlang:load_nif(NifPathStr, 0) of
      ok -> ok;
      {error, Reason} -> erlang:error({nif_load_failed, Reason})
    end.

-spec hash(Password :: binary(), Salt :: binary(), Iterations :: non_neg_integer(), Memory :: non_neg_integer(), Threads :: non_neg_integer()) -> {ok, Hash :: binary()} | {error, Reason :: term()}.
hash(_Password, _Salt, _Iterations, _Memory, _Threads) -> erlang:nif_error(not_loaded).

-spec verify(Password :: binary(), Hash :: binary()) -> {ok, Bool :: boolean()} | {error, Reason :: term()}.
verify(_Password, _Hash) -> erlang:nif_error(not_loaded).
