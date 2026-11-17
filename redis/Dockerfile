# Redis for Outpost on Railway: the official image, pinned by version and
# digest. Redis 8 includes the query engine, which Outpost uses to list tenants.
FROM redis:8.10.3-alpine@sha256:7958cfbb9d152f87dadfbc89f1b0b15938f0b81ff8982feb327476f4911935c3

COPY railway-start.sh /usr/local/bin/railway-start.sh

EXPOSE 6379

ENTRYPOINT ["/bin/sh", "/usr/local/bin/railway-start.sh"]
