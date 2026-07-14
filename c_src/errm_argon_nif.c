#include <argon2.h>
#include <erl_nif.h>
#include <stdint.h>
#include <stdio.h>

typedef ErlNifBinary erl_nif_binary_t;
typedef ErlNifEnv erl_nif_env_t;
typedef ERL_NIF_TERM erl_nif_term_t;
typedef ErlNifFunc erl_nif_func_t;
typedef ErlNifResourceType erl_nif_resource_type_t;
typedef ErlNifSInt64 erl_nif_i64_t;
typedef ErlNifUInt64 erl_nif_u64_t;
typedef ErlNifSInt erl_nif_i32_t;
typedef ErlNifUInt erl_nif_u32_t;

typedef char cstr;
typedef int64_t i64;
typedef uint64_t u64;
typedef int32_t i32;
typedef uint32_t u32;
#define null NULL

static erl_nif_term_t make_error(erl_nif_env_t *env, const cstr *message) {
  return enif_make_tuple2(env, enif_make_atom(env, "error"),
                          enif_make_string(env, message, ERL_NIF_LATIN1));
}

static erl_nif_term_t make_ok(erl_nif_env_t *env, erl_nif_term_t term) {
  return enif_make_tuple2(env, enif_make_atom(env, "ok"), term);
}

static erl_nif_term_t hash_nif(erl_nif_env_t *env, i32 argc,
                               const erl_nif_term_t argv[]) {
  if (argc != 5) {
    fprintf(stderr, "errm_argon_nif: hash: arity error, expected 5, got %d\n",
            argc);
    return enif_make_badarg(env);
  }

  erl_nif_binary_t password;
  if (!enif_inspect_binary(env, argv[0], &password)) {
    fprintf(stderr, "errm_argon_nif: hash: could not get password\n");
    return enif_make_badarg(env);
  }

  erl_nif_binary_t salt;
  if (!enif_inspect_binary(env, argv[1], &salt)) {
    fprintf(stderr, "errm_argon_nif: hash: could not get salt\n");
    return enif_make_badarg(env);
  }

  u32 t_cost;
  if (!enif_get_uint(env, argv[2], &t_cost)) {
    fprintf(stderr, "errm_argon_nif: hash: could not get t_cost\n");
    return enif_make_badarg(env);
  }

  u32 m_cost;
  if (!enif_get_uint(env, argv[3], &m_cost)) {
    fprintf(stderr, "errm_argon_nif: hash: could not get m_cost\n");
    return enif_make_badarg(env);
  }

  u32 parallelism;
  if (!enif_get_uint(env, argv[4], &parallelism)) {
    fprintf(stderr, "errm_argon_nif: hash: could not get parallelism\n");
    return enif_make_badarg(env);
  }

  cstr *hash = enif_alloc(sizeof(cstr) * 256);
  if (!hash)
    return make_error(env, "errm_argon_nif: hash: could not allocate hash");

  i32 rc;
  if ((rc = argon2id_hash_encoded(t_cost, m_cost, parallelism, password.data,
                                  password.size, salt.data, salt.size, 64, hash,
                                  sizeof(cstr) * 256)) != ARGON2_OK) {
    enif_free(hash);
    cstr message[256];
    snprintf(message, sizeof(message),
             "errm_argon_nif: hash: argon2id_hash_encoded failed: %d\n", rc);
    return make_error(env, message);
  }

  erl_nif_term_t term_string = enif_make_string(env, hash, ERL_NIF_LATIN1);
  enif_free(hash);
  return term_string;
}

static ERL_NIF_TERM verify_nif(ErlNifEnv *env, int argc,
                               const ERL_NIF_TERM argv[]) {
  if (argc != 2) {
    fprintf(stderr, "errm_argon_nif: verify: arity error, expected 2, got %d\n",
            argc);
    return enif_make_badarg(env);
  }

  erl_nif_binary_t password, encoded;
  if (!enif_inspect_binary(env, argv[0], &password)) {
    fprintf(stderr, "errm_argon_nif: verify: could not get password\n");
    return enif_make_badarg(env);
  }

  if (!enif_inspect_binary(env, argv[1], &encoded)) {
    fprintf(stderr, "errm_argon_nif: verify: could not get encoded hash\n");
    return enif_make_badarg(env);
  }

  cstr *encoded_str = enif_alloc(encoded.size + 1);
  if (!encoded_str)
    return make_error(env, "memory allocation failed");

  memcpy(encoded_str, encoded.data, encoded.size);
  encoded_str[encoded.size] = '\0';

  int rc = argon2id_verify(encoded_str, password.data, password.size);
  enif_free(encoded_str);
  return rc == ARGON2_OK ? make_ok(env, enif_make_atom(env, "true"))
                         : make_ok(env, enif_make_atom(env, "false"));
}

erl_nif_func_t nif_funcs[] = {
    {"hash", 5, hash_nif, ERL_NIF_DIRTY_JOB_CPU_BOUND},
    {"verify", 2, verify_nif, ERL_NIF_DIRTY_JOB_CPU_BOUND},
};

ERL_NIF_INIT(errm_argon_nif, nif_funcs, NULL, NULL, NULL, NULL)
