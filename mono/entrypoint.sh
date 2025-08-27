#!/bin/sh
set -e

# Fail fast if critical envs are missing (optional)
# : "${POSTGRES_URL:?Missing POSTGRES_URL}"
# : "${REDIS_URL:?Missing REDIS_URL}"
# : "${CLICKHOUSE_URL:?Missing CLICKHOUSE_URL}"

exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
