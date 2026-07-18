-module(errm_argon_nif).
-export([hash/5, verify/2]).
-on_load(init/0).

-spec init() -> ok.
init() ->
  Path = errm_argon_nif_loader:path(errm_argon, "errm_argon_nif"),
  case erlang:load_nif(Path, 0) of
    ok -> ok;
    {error, Reason} -> erlang:error({nif_load_failed, Path, Reason})
  end.


-spec hash(Password :: binary(), Salt :: binary(), Iterations :: non_neg_integer(), Memory :: non_neg_integer(), Threads :: non_neg_integer()) -> {ok, Hash :: binary()} | {error, Reason :: term()}.
hash(_Password, _Salt, _Iterations, _Memory, _Threads) -> erlang:nif_error(not_loaded).

-spec verify(Password :: binary(), Hash :: binary()) -> {ok, Bool :: boolean()} | {error, Reason :: term()}.
verify(_Password, _Hash) -> erlang:nif_error(not_loaded).
