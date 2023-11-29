FROM rust:latest as build

RUN apt-get update && apt-get install -y libclang-dev

WORKDIR /usr/local/src

COPY . .

RUN --mount=type=cache,target=/usr/local/cargo,from=rust:latest,source=/usr/local/cargo \
  --mount=type=cache,target=target \
  cargo build --release --package redtail-agent && \
  mv ./target/release/libredtail_agent.so /usr/local/lib


FROM debian:bookworm-slim AS install

COPY --chmod=0444 agent/container/redis.gpg /usr/share/keyrings/redis.gpg
COPY --chmod=0644 agent/container/redis.apt.list /etc/apt/sources.list.d/redis.list
COPY --chmod=0755 agent/container/install.sh /usr/local/bin/install-redis

RUN ["/usr/local/bin/install-redis"]


FROM debian:bookworm-slim

RUN --mount=type=cache,target=/var/lib/apt/lists \
  apt-get update && \
  apt-get install -y libatomic1 libjemalloc2 liblzf1 openssl 

RUN useradd -r -m -s /bin/bash -d /data -N -g daemon redis

COPY --from=install /usr/bin/redis-benchmark /usr/bin/redis-benchmark
COPY --from=install /usr/bin/redis-check-aof /usr/bin/redis-check-aof
COPY --from=install /usr/bin/redis-check-rdb /usr/bin/redis-check-rdb
COPY --from=install /usr/bin/redis-cli /usr/bin/redis-cli
COPY --from=install /usr/bin/redis-server /usr/bin/redis-server
COPY --chmod=0755 agent/container/entrypoint.sh /usr/sbin/redtail-entrypoint

COPY --from=install /usr/share/bash-completion/completions/redis-cli /usr/share/bash-completion/completions/redis-cli
COPY --from=install /usr/share/doc/redis/copyright /usr/share/doc/redis/copyright
COPY --chmod=0444 agent/container/redis.gpg /usr/share/keyrings/redis.gpg
COPY --chmod=0644 agent/container/redis.apt.list /etc/apt/sources.list.d/redis.list

COPY --from=build /usr/local/lib/libredtail_agent.so /usr/lib/redtail.so

RUN ["install", "-d", "/etc/redis"]
COPY agent/redis.conf /etc/redis/server.conf
# FIXME(lyra): redis user should not be allowed to overwrite its own configuration file
COPY --chown=redis:daemon agent/machine.conf /etc/redis/machine.conf
COPY agent/container/profile.sh /etc/profile.d/redis

USER redis:daemon
WORKDIR /data
ENTRYPOINT ["/usr/sbin/redtail-entrypoint"]
