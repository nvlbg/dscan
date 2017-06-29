#!/bin/bash

SSL_DIR=$(erl -noinput -eval 'io:format("~s~n",
   [filename:dirname(code:which(inet_tls_dist))])' -s init stop)

SSL_DIST_OPT="server_certfile   cert.pem     client_certfile   cert.pem    \
              server_keyfile    key.pem      client_keyfile    key.pem     \
              server_cacertfile cacert.pem   client_cacertfile cacert.pem  \
              server_verify     verify_peer  client_verify     verify_peer \
              server_fail_if_no_peer_cert true"

iex --erl "-proto_dist Elixir.Epmdless -start_epmd false -epmd_module Elixir.Epmdless_epmd_client -pa ../../_build/dev/lib/server/ebin $SSL_DIR -ssl_dist_opt $SSL_DIST_OPT \"$@\" -name $1" --no-halt -S mix

