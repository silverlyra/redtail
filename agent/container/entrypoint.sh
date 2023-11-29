#!/bin/bash

set -eu -o pipefail

main() {
  if [[ $# -eq 0 ]]; then
    if [[ -t 1 ]]; then
      exec /usr/bin/redis-cli
    else
      start
    fi
  elif [[ -t 1 ]]; then
    exec bash -l "$@"
  else
    exec "$@"
  fi
}

start() {
  (
    echo "bind ${FLY_PRIVATE_IP}"
    echo "bind-source-addr ${FLY_PRIVATE_IP}"
    echo
    echo "maxmemory $(((FLY_VM_MEMORY_MB - 32) * 1024 * 1024))"
  ) >/etc/redis/machine.conf

  mkdir -p /data/log
  env | grep FLY_ | sort >"/data/log/$(date -u +'%Y-%m-%d-%H%M%S')-${FLY_MACHINE_ID:-"$FLY_ALLOC_ID"}"

  # see https://github.com/docker-library/redis/issues/305
  if [[ "$(umask)" == 0022 ]]; then
    umask 0077
  fi

  exec /usr/bin/redis-server /etc/redis/server.conf
}

main "$@"
