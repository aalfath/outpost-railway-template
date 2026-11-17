#!/bin/sh
# Redis for Outpost: password required, append-only file plus snapshots on the
# /data volume (in /data/redis), no eviction (Outpost keeps tenants and destinations here).
set -e

if [ "${#REDIS_PASSWORD}" -lt 16 ]; then
  echo "railway-start: REDIS_PASSWORD must be set (16 characters or more)" >&2
  exit 1
fi

# Railway volumes contain lost+found, so the image's entrypoint won't fix
# ownership of /data. Keep Redis's files in a subdirectory it owns.
datadir=/data/redis
mkdir -p "$datadir"
chown -R redis:redis "$datadir"
chmod 0700 "$datadir"

conf=/usr/local/etc/redis/railway.conf
mkdir -p /usr/local/etc/redis
{
  echo "# Written by railway-start.sh on every start. Do not edit."
  echo "port ${REDISPORT:-6379}"
  echo "bind * -::*"
  echo "protected-mode no"
  echo "requirepass ${REDIS_PASSWORD}"
  echo "dir ${datadir}"
  echo "appendonly yes"
  echo "appendfsync everysec"
  echo "save 3600 1 300 100 60 10000"
  echo "maxmemory-policy noeviction"
} > "$conf"
chmod 0640 "$conf"
chown redis:redis "$conf" 2>/dev/null || true

# The image's entrypoint drops to the redis user. It runs from /data, so it
# would only check ownership there; our files live in /data/redis.
cd "$datadir"
exec docker-entrypoint.sh redis-server "$conf"
