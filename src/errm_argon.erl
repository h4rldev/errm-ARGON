-module(errm_argon).
-export([hash/1, hash/2, hash/4, verify/2]).

-type hash_profile() :: interactive | moderate | sensitive.
-export_type([hash_profile/0]).

-spec hash(Password :: string()) -> {ok, binary()} | {error, term()}.
hash(Password) ->
  hash(Password, interactive).

-spec hash(Password :: string(), Profile :: hash_profile()) -> {ok, binary()} | {error, term()}.
hash(Password, Profile) ->
  Schedulers = erlang:system_info(schedulers_online),
  Parallelism0 = case Profile of
    interactive -> min(max(1, Schedulers div 4), 4);
    moderate    -> min(max(1, Schedulers div 3), 6);
    sensitive   -> min(max(1, Schedulers div 2), 8);
    _           -> min(max(1, Schedulers div 4), 4)
  end,

  Parallelism = case Parallelism0 of
    P when is_integer(P) -> P;
    _ -> 1
  end,

  {TCost, MCostKiB} = case Profile of
    interactive -> {3, 64 bsl 10};
    moderate    -> {5, 256 bsl 10};
    sensitive   -> {10, 1024 bsl 10};
    _           -> {3, 64 bsl 10}
  end,

  Salt = crypto:strong_rand_bytes(16),
  case errm_argon_nif:hash(list_to_binary(Password), Salt, TCost, MCostKiB, Parallelism) of
    Encoded when is_list(Encoded) -> {ok, list_to_binary(Encoded)};
    {error, Reason} -> {error, Reason};
    Other -> {error, {unexpected, Other}}
  end.

-spec hash(Password :: string(), TCost :: non_neg_integer(),
           MCostKiB :: non_neg_integer(), Parallelism :: non_neg_integer()) -> {ok, binary()} | {error, term()}.
hash(Password, TCost, MCostKiB, Parallelism) ->
  Salt = crypto:strong_rand_bytes(16),
  case errm_argon_nif:hash(list_to_binary(Password), Salt, TCost, MCostKiB, Parallelism) of
    Encoded when is_list(Encoded) -> {ok, list_to_binary(Encoded)};
    {error, Reason} -> {error, Reason};
    Other -> {error, {unexpected, Other}}
  end.

-spec verify(Password :: string(), Hash :: binary()) -> boolean().
verify(Password, Hash) ->
  case errm_argon_nif:verify(list_to_binary(Password), Hash) of
    {ok, true} -> true;
    {ok, false} -> false;
    {error, Reason} ->
      logger:error("Verification failed: ~p", [Reason]),
      false
  end.
