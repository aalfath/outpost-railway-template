# Outpost for Railway: the official image, pinned by version and digest.
# busybox adds `sleep` and `nc` for the start script (the upstream image is
# distroless and only ships busybox's shell).
FROM busybox:1.38.0-musl@sha256:80e38f9a1b39188b8bdb28879178edb322a4402b081a9aedda1924609decd6f6 AS busybox

FROM hookdeck/outpost:v1.9.0@sha256:f14e70ef7704ca2e93ef30449b90a071ea3b7284e291932e13649ca09186e4b4

COPY --from=busybox /bin/busybox /usr/local/bin/busybox
COPY railway-start.sh /usr/local/bin/railway-start.sh

# 3333 = HTTP API, tenant portal and /healthz (Railway sets PORT)
EXPOSE 3333

ENTRYPOINT ["/bin/sh", "/usr/local/bin/railway-start.sh"]
