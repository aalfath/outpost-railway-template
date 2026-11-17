#!/bin/sh
# Start script for Outpost on Railway: Railway defaults, wait for the
# dependencies, apply migrations, then run all three services in one process.
set -e
bb=/usr/local/bin/busybox

# Listen on Railway's PORT.
export API_PORT="${PORT:-${API_PORT:-3333}}"

# Defaults for a single-node deployment. Every one can be overridden with a
# service variable of the same name.
export GIN_MODE="${GIN_MODE:-release}"
export LOG_LEVEL="${LOG_LEVEL:-info}"
export DELIVERY_MAX_CONCURRENCY="${DELIVERY_MAX_CONCURRENCY:-100}"
export LOG_MAX_CONCURRENCY="${LOG_MAX_CONCURRENCY:-10}"
# Reconnect queue workers after a broker or Redis restart instead of failing
# /healthz until someone restarts Outpost.
export SUPERVISOR_RESTART_WORKERS="${SUPERVISOR_RESTART_WORKERS-deliverymq,logmq,retrymq}"
# Tenants choose where webhooks go: keep them off Railway's private network
# (Redis, Postgres, RabbitMQ) unless you turn this off.
export DESTINATIONS_BLOCK_PRIVATE_ADDRESSES="${DESTINATIONS_BLOCK_PRIVATE_ADDRESSES:-true}"

for v in API_KEY API_JWT_SECRET AES_ENCRYPTION_SECRET REDIS_HOST POSTGRES_URL RABBITMQ_SERVER_URL; do
  eval "val=\${$v:-}"
  if [ -z "$val" ]; then
    echo "railway-start: $v must be set" >&2
    exit 1
  fi
done

# host:port from a URL such as amqp://user:pass@host:5672/vhost
hostport() {
  hp="${1#*://}"; hp="${hp##*@}"; hp="${hp%%/*}"; hp="${hp%%\?*}"
  echo "$hp"
}

wait_tcp() { # name host port
  i=0
  until $bb nc -z -w 3 "$2" "$3" 2>/dev/null; do
    i=$((i + 1))
    if [ "$i" -ge 60 ]; then
      echo "railway-start: $1 ($2:$3) still not reachable, starting anyway" >&2
      return 0
    fi
    [ "$i" = 1 ] && echo "railway-start: waiting for $1 ($2:$3)" >&2
    $bb sleep 2
  done
}

hp=$(hostport "$POSTGRES_URL"); wait_tcp Postgres "${hp%:*}" "${hp##*:}"
hp=$(hostport "$RABBITMQ_SERVER_URL"); wait_tcp RabbitMQ "${hp%:*}" "${hp##*:}"
wait_tcp Redis "$REDIS_HOST" "${REDIS_PORT:-6379}"

# Apply pending SQL and Redis migrations (a no-op when there are none).
i=0
until /usr/local/bin/outpost migrate apply --yes; do
  i=$((i + 1))
  if [ "$i" -ge 10 ]; then
    echo "railway-start: migrations failed 10 times, giving up" >&2
    exit 1
  fi
  echo "railway-start: migrations failed, retrying in 5 s" >&2
  $bb sleep 5
done

exec /usr/local/bin/outpost serve
