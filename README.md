# Outpost on Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/outpost-2?utm_medium=integration&utm_source=button&utm_campaign=outpost)

A one-click [Railway](https://railway.com) template for [Outpost](https://github.com/hookdeck/outpost) by Hookdeck, the open-source (Apache-2.0) service for outbound webhooks and event destinations: you publish an event once, and Outpost delivers it to each of your customers' webhooks or queues with retries, signatures and delivery logs.

**Version:** Outpost 1.9.0, from the official image `hookdeck/outpost:v1.9.0`, pinned by digest in [`outpost/Dockerfile`](outpost/Dockerfile).

## What the template deploys

| Service | Source | What it does | Data |
|---|---|---|---|
| **Outpost** | this repo, [`outpost/`](outpost/) | API, delivery and log services in one process, on the public domain. Health check `/healthz` | none (stateless) |
| **Redis** | this repo, [`redis/`](redis/) (`redis:8.10.3-alpine`, pinned) | Tenants, destinations and their encrypted credentials, retry schedule. Redis 8's query engine turns on Outpost's "list tenants" API | volume `/data`, append-only file plus snapshots, no eviction |
| **RabbitMQ** | this repo, [`rabbitmq/`](rabbitmq/) (`rabbitmq:4.4.0-alpine`, pinned) | Outpost's internal delivery and log queues | volume `/var/lib/rabbitmq`, fixed node name |
| **Postgres** | Railway's Postgres | Event and delivery-attempt log | Railway volume |

Everything except Postgres builds from this repository, so you get Railway's "update available" notice when the pins here are bumped.

The Outpost start script waits for Postgres, RabbitMQ and Redis, runs `outpost migrate apply --yes` (a no-op when nothing is pending), then starts `outpost serve` on Railway's `PORT`.

## Variables

All values are generated or referenced. The template asks you for nothing.

| Service | Variable | Default | What it is |
|---|---|---|---|
| Outpost | `API_KEY` | random, 48 characters | Admin API key: `Authorization: Bearer <API_KEY>` |
| Outpost | `API_JWT_SECRET` | random, 64 characters | Signs tenant JWTs and portal links |
| Outpost | `AES_ENCRYPTION_SECRET` | random, 32 characters | Encrypts destination credentials in Redis. Keep it: changing it makes stored credentials unreadable |
| Outpost | `PORT` | `3333` | HTTP port (API, portal, health check) |
| Outpost | `POSTGRES_URL`, `REDIS_*`, `RABBITMQ_SERVER_URL` | references | Connections over Railway's private network |
| Redis | `REDIS_PASSWORD` | random, 32 characters | Redis password |
| RabbitMQ | `RABBITMQ_DEFAULT_USER` / `RABBITMQ_DEFAULT_PASS` | `outpost` / random, 32 characters | Broker login, set on first start |

Defaults set by the start script, each overridable with a service variable of the same name:

- `DELIVERY_MAX_CONCURRENCY=100`, `LOG_MAX_CONCURRENCY=10` (upstream's defaults are 1).
- `SUPERVISOR_RESTART_WORKERS=deliverymq,logmq,retrymq`: queue workers restart after a broker or Redis outage instead of being reported failed on the first error.
- `DESTINATIONS_BLOCK_PRIVATE_ADDRESSES=true`: webhook destinations can't point at private addresses, so a tenant can't reach Redis, Postgres or RabbitMQ through Railway's private network ([upstream advice](https://hookdeck.com/docs/outpost/self-hosting/deployment#outbound-network-access)). If one of your own receivers runs inside the Railway project, list its addresses in `DESTINATIONS_PRIVATE_ADDRESS_ALLOWLIST`, or set the block to `false` if only your team creates destinations.

Optional settings you may want later (none are needed to start): `TOPICS` (comma-separated list of allowed topics; empty allows any topic), `PORTAL_REFERER_URL` and the other `PORTAL_*` branding settings, `DISABLE_TELEMETRY=true`, `OTEL_*`. See the [configuration reference](https://hookdeck.com/docs/outpost/self-hosting/configuration).

## After deploy

```sh
OUTPOST_URL=https://YOUR-DOMAIN.up.railway.app   # the Outpost service's public domain
API_KEY=...                                        # the Outpost service's API_KEY variable

curl $OUTPOST_URL/healthz
curl -X PUT "$OUTPOST_URL/api/v1/tenants/acme" -H "Authorization: Bearer $API_KEY"
curl "$OUTPOST_URL/api/v1/tenants/acme/destinations" -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"type":"webhook","topics":["*"],"config":{"url":"https://example.com/webhooks"}}'
curl "$OUTPOST_URL/api/v1/publish" -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"tenant_id":"acme","topic":"user.created","eligible_for_retry":true,"data":{"user_id":"u1"}}'
curl "$OUTPOST_URL/api/v1/tenants/acme/portal" -H "Authorization: Bearer $API_KEY"   # tenant portal link
```

More in the [Outpost docs](https://hookdeck.com/docs/outpost) and the [API reference](https://hookdeck.com/docs/outpost/api).

## How updates reach you

Outpost, Redis and RabbitMQ build from this repository's `main` branch. When a new version is tested here, the pin in the `Dockerfile` is bumped, the change is described in [`CHANGELOG.md`](CHANGELOG.md), and Railway shows an "update available" notice on your deployment. You decide when to apply it. Read the changelog first. Outpost migrations run on every start, and upstream's [upgrade notes](https://hookdeck.com/docs/outpost/self-hosting/guides/migration) list anything that needs a manual step.

## Files

- `outpost/Dockerfile`, `outpost/railway-start.sh`: the pinned Outpost image, busybox's `nc` and `sleep` for the dependency wait, migrations and start.
- `redis/Dockerfile`, `redis/railway-start.sh`: pinned Redis 8 with a password, persistence and no eviction.
- `rabbitmq/Dockerfile`, `rabbitmq/railway-start.sh`: pinned RabbitMQ 4.4 with a fixed node name, no remote `guest` login and a memory alarm sized to the container.

Not affiliated with Hookdeck. Outpost is licensed under Apache-2.0.
