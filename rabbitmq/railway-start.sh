#!/bin/sh
# Writes the Railway settings for RabbitMQ, then hands over to the official
# image's entrypoint (which fixes volume ownership and drops root).
set -e

if [ -z "${RABBITMQ_DEFAULT_USER:-}" ] || [ "${#RABBITMQ_DEFAULT_PASS}" -lt 12 ]; then
  echo "railway-start: RABBITMQ_DEFAULT_USER and RABBITMQ_DEFAULT_PASS (12+ characters) must be set" >&2
  exit 1
fi

conf=/etc/rabbitmq/conf.d/90-railway.conf
{
  echo "# Written by railway-start.sh on every start. Do not edit."
  echo "# The guest user may only log in from inside the container."
  echo "loopback_users.guest = true"
  echo "listeners.tcp.default = 5672"
} > "$conf"

# Size the memory alarm to the container's memory limit, not the host's RAM.
limit=""
if [ -r /sys/fs/cgroup/memory.max ]; then
  limit=$(cat /sys/fs/cgroup/memory.max)
elif [ -r /sys/fs/cgroup/memory/memory.limit_in_bytes ]; then
  limit=$(cat /sys/fs/cgroup/memory/memory.limit_in_bytes)
fi
host_kb=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
case "$limit" in
  ''|*[!0-9]*) ;;
  *)
    if [ "$limit" -lt $((host_kb * 1024)) ]; then
      echo "total_memory_available_override_value = ${limit}" >> "$conf"
      echo "railway-start: container memory limit ${limit} bytes" >&2
    fi
    ;;
esac

if [ "${1:-}" = "rabbitmq-server" ] || [ "$#" -eq 0 ]; then
  exec docker-entrypoint.sh rabbitmq-server
fi
exec docker-entrypoint.sh "$@"
