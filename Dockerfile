# Pelican-compatible wrapper around the official Fluxer single-container image.
# Build Fluxer first (in a clone of github.com/fluxerapp/fluxer):
#   make toolchain native-deps dist && make image      -> tags fluxer:dev
# Then: docker build -t ghcr.io/voiddeficit/fluxer-pelican:latest . && docker push ...
ARG BASE=fluxer:dev
FROM ${BASE}
USER root
# Pelican mounts the server volume at /home/container; keep Fluxer's data there.
RUN rm -rf /var/lib/fluxer && ln -s /home/container/data /var/lib/fluxer \
 && mkdir -p /home/container && chmod 777 /home/container
COPY --chmod=755 entrypoint.sh /entrypoint.sh
ENV USER=container HOME=/home/container
WORKDIR /home/container
STOPSIGNAL SIGTERM
ENTRYPOINT ["/entrypoint.sh"]
