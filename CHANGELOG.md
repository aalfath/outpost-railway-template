# Changelog

## 2026-11-17: Outpost 1.9.0 (first release)

- Outpost 1.9.0 from `hookdeck/outpost:v1.9.0@sha256:f14e70ef7704ca2e93ef30449b90a071ea3b7284e291932e13649ca09186e4b4`, all three services in one process, migrations applied on start, health check `/healthz`.
- Redis 8.10.3 from `redis:8.10.3-alpine@sha256:7958cfbb9d152f87dadfbc89f1b0b15938f0b81ff8982feb327476f4911935c3`, with a password, append-only file and snapshots on a volume (in `/data/redis`, because the Railway volume root holds `lost+found`), no eviction.
- RabbitMQ 4.4.0 from `rabbitmq:4.4.0-alpine@sha256:7b77c3d3a996c7fcca1ca8bf53ce1557ff43c13b8ca2c132df6031781b209ef2`, data on a volume with a fixed node name.
- Railway's Postgres for the event log.
- Defaults: worker restarts after a broker or Redis outage, private webhook addresses blocked, delivery concurrency 100.
