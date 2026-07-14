-module(errm_argon_tests).
-include_lib("eunit/include/eunit.hrl").

hash_test() ->
    Password = "secret123",
    {ok, Hash} = errm_argon:hash(Password),
    ?assert(is_binary(Hash)),
    ?assertMatch("$argon2id$" ++ _, binary_to_list(Hash)),
    ?assert(errm_argon:verify(Password, Hash)).

hash_interactive_test() ->
    Password = "secret456",
    {ok, Hash} = errm_argon:hash(Password, interactive),
    ?assertMatch("$argon2id$" ++ _, binary_to_list(Hash)),
    ?assert(errm_argon:verify(Password, Hash)).

hash_moderate_test() ->
    Password = "secret789",
    {ok, Hash} = errm_argon:hash(Password, moderate),
    ?assertMatch("$argon2id$" ++ _, binary_to_list(Hash)),
    ?assert(errm_argon:verify(Password, Hash)).

hash_sensitive_test() ->
    Password = "secret101",
    {ok, Hash} = errm_argon:hash(Password, sensitive),
    ?assertMatch("$argon2id$" ++ _, binary_to_list(Hash)),
    ?assert(errm_argon:verify(Password, Hash)).

hash_custom_params_test() ->
    Password = "custom_pass",
    {ok, Hash} = errm_argon:hash(Password, 3, 64 bsl 10, 1),
    ?assertMatch("$argon2id$v=19$m=65536,t=3,p=1" ++ _, binary_to_list(Hash)),
    ?assert(errm_argon:verify(Password, Hash)).

verify_correct_test() ->
    Password = "correct",
    {ok, Hash} = errm_argon:hash(Password),
    ?assert(errm_argon:verify(Password, Hash)).

verify_wrong_test() ->
    Password = "correct",
    Wrong = "wrong",
    {ok, Hash} = errm_argon:hash(Password),
    ?assertNot(errm_argon:verify(Wrong, Hash)).

verify_invalid_hash_test() ->
    Password = "password",
    InvalidHash = <<"invalid_hash">>,
    ?assertNot(errm_argon:verify(Password, InvalidHash)).

empty_password_test() ->
    Password = "",
    {ok, Hash} = errm_argon:hash(Password),
    ?assert(errm_argon:verify(Password, Hash)).

invalid_params_test() ->
    Password = "test",
    Result = errm_argon:hash(Password, 0, 64 bsl 10, 1),
    ?assertMatch({error, _}, Result).

low_memory_test() ->
    Password = "test",
    Result = errm_argon:hash(Password, 3, 1, 1),
    ?assertMatch({error, _}, Result).

binary_password_test() ->
    Password = <<"binary_pass">>,
    {ok, Hash} = errm_argon:hash(binary_to_list(Password)),
    ?assert(errm_argon:verify(binary_to_list(Password), Hash)).

verify_binary_test() ->
    Password = <<"binary_pass2">>,
    {ok, Hash} = errm_argon:hash(binary_to_list(Password)),
    ?assert(errm_argon:verify(binary_to_list(Password), Hash)).
