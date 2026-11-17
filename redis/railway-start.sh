#!/bin/sh
# Redis for Outpost: password required, append-only file plus snapshots on the
# /data volume, no eviction (Outpost keeps tenants and destinations here).
set -e

if [ "${#REDIS_PASSWORD}" -lt 16 ]; then
  echo "railway-start: REDIS_PASSWORD must be set (16 characters or more)" >&2
  exit 1
fi

conf=/usr/local/etc/redis/railway.conf
mkdir -p /usr/local/etc/redis
{
  echo "# Written by railway-start.sh on every start. Do not edit."
  echo "port ${REDISPORT:-6379}"
  echo "bind * -::*"
  echo "protected-mode no"
  echo "requirepass ${REDIS_PASSWORD}"
  echo "dir /data"
  echo "appendonly yes"
  echo "appendfsync everysec"
  echo "save 3600 1 300 100 60 10000"
  echo "maxmemory-policy noeviction"
} > "$conf"
chmod 0640 "$conf"
chown redis:redis "$conf" 2>/dev/null || true

# The image's entrypoint fixes /data ownership and drops to the redis user.
exec docker-entrypoint.sh redis-server "$conf"
