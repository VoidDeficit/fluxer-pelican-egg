# Pelican image for Fluxer with a built-in PostgreSQL server.
# Build Fluxer first (in a clone of github.com/fluxerapp/fluxer):
#   make toolchain native-deps dist && make image      -> tags fluxer:dev
# Then: docker build -t ghcr.io/voiddeficit/fluxer-pelican:latest .
ARG BASE=fluxer:dev
FROM ${BASE} AS fluxer

FROM debian:trixie-slim
RUN apt-get update \
 && apt-get install -y --no-install-recommends postgresql ca-certificates tini \
    libatomic1 libaom3 libdav1d7 libde265-0 libglib2.0-0t64 liblcms2-2 libvips42t64 \
    libwebp7 libwebpdemux2 libwebpmux3 libyuv0 libjemalloc2 \
 && rm -rf /var/lib/apt/lists/* \
 && ln -s /usr/lib/postgresql/*/bin /usr/lib/postgresql/bin
COPY --from=fluxer /opt/fluxer /opt/fluxer
# Wings runs containers with a read-only root filesystem as UID 999 (GID 987) by default.
# Postgres needs a passwd entry, and Fluxer's writable paths must point into the
# server volume (/home/container) or the /tmp tmpfs.
RUN echo "container:x:999:987::/home/container:/bin/sh" >> /etc/passwd \
 && chmod 666 /etc/passwd \
 && rm -rf /var/lib/fluxer /etc/fluxer /run/fluxer \
 && ln -s /home/container/data /var/lib/fluxer \
 && ln -s /home/container/etc /etc/fluxer \
 && ln -s /tmp/fluxer-run /run/fluxer \
 && mkdir -p /home/container && chmod 777 /home/container
COPY --chmod=755 entrypoint.sh /entrypoint.sh
ENV USER=container HOME=/home/container PATH=/usr/lib/postgresql/bin:$PATH
WORKDIR /home/container
STOPSIGNAL SIGTERM
ENTRYPOINT ["/usr/bin/tini", "--", "/entrypoint.sh"]
