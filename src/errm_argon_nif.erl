-module(errm_argon_nif).
-export([hash/5, verify/2]).
-on_load(init/0).

-spec init() -> ok.
init() ->
  BaseName = "errm_argon_nif",
  Candidates = [
    case escript:script_name() of
      Script0 when is_list(Script0) ->
        Dir0 = filename:dirname(Script0),
        filename:join([Dir0, "..", "lib", "errm_argon", "priv", BaseName]);
      _ -> false
    end,
    case escript:script_name() of
      Script1 when is_list(Script1) ->
        Dir1 = filename:dirname(Script1),
        filename:join([Dir1, "..", "priv", BaseName]);
      _ -> false
    end,
    case escript:script_name() of
      Script2 when is_list(Script2) ->
        Dir2 = filename:dirname(Script2),
        filename:join(Dir2, BaseName);
      _ -> false
    end,
    case code:priv_dir(errm_sqlite) of
      Priv when is_list(Priv) -> filename:join(Priv, BaseName);
      _ -> false
    end,
    case code:lib_dir(errm_sqlite) of
      {ok, LibDir} -> filename:join([LibDir, "priv", BaseName]);
      _ -> false
    end,
    filename:join("priv", BaseName),
    filename:join(".", BaseName),
    os:getenv("ERRM_ARGON_NIF_PATH")
  ],
  Paths = lists:filtermap(fun
    (false) -> false;
    (undefined) -> false;
    (P) when is_list(P) -> {true, P}
  end, Candidates),
  try_load_nif(Paths).

try_load_nif([]) ->
  erlang:error({nif_load_failed, no_candidate_paths});
try_load_nif([Path | Rest]) ->
  io:format("Trying NIF path: ~s~n", [Path]),
  case erlang:load_nif(Path, 0) of
    ok ->
      io:format("NIF loaded successfully from ~s~n", [Path]),
      ok;
    {error, Reason} ->
      io:format("Failed to load NIF from ~s: ~p~n", [Path, Reason]),
      try_load_nif(Rest)
  end.

-spec hash(Password :: binary(), Salt :: binary(), Iterations :: non_neg_integer(), Memory :: non_neg_integer(), Threads :: non_neg_integer()) -> {ok, Hash :: binary()} | {error, Reason :: term()}.
hash(_Password, _Salt, _Iterations, _Memory, _Threads) -> erlang:nif_error(not_loaded).

-spec verify(Password :: binary(), Hash :: binary()) -> {ok, Bool :: boolean()} | {error, Reason :: term()}.
verify(_Password, _Hash) -> erlang:nif_error(not_loaded).
