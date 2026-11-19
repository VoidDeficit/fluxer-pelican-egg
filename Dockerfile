# Pelican image for Fluxer with a built-in PostgreSQL server.
# Build Fluxer first (in a clone of github.com/fluxerapp/fluxer):
#   make toolchain native-deps dist && make image      -> tags fluxer:dev
# Then: docker build -t ghcr.io/voiddeficit/fluxer-pelican:latest .
ARG BASE=fluxer:dev
FROM ${BASE} AS fluxer

FROM debian:trixie-slim
RUN apt-get update \
 && apt-get install -y --no-install-recommends postgresql ca-certificates tini \
 && rm -rf /var/lib/apt/lists/* \
 && ln -s /usr/lib/postgresql/*/bin /usr/lib/postgresql/bin
COPY --from=fluxer /opt/fluxer /opt/fluxer
# Pelican runs the container as an arbitrary UID; Postgres needs a passwd entry for it.
RUN chmod 666 /etc/passwd \
 && rm -rf /var/lib/fluxer && ln -s /home/container/data /var/lib/fluxer \
 && mkdir -p /home/container && chmod 777 /home/container
COPY --chmod=755 entrypoint.sh /entrypoint.sh
ENV USER=container HOME=/home/container PATH=/usr/lib/postgresql/bin:$PATH
WORKDIR /home/container
STOPSIGNAL SIGTERM
ENTRYPOINT ["/usr/bin/tini", "--", "/entrypoint.sh"]
