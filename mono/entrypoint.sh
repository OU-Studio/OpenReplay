#!/bin/sh
set -e

# Ensure required envs are present (fail fast if missing)
: "${POSTGRES_URL:?Missing POSTGRES_URL}"
: "${REDIS_URL:?Missing REDIS_URL}"
: "${CLICKHOUSE_URL:?Missing CLICKHOUSE_URL}"

# You can export/transform envs for your API/ingest here if they need different names, e.g.:
# export DB_URL="$POSTGRES_URL"
# export REDIS_DSN="$REDIS_URL"
# export CH_URL="$CLICKHOUSE_URL"

# Launch supervisor (which starts nginx, api, ingest)
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
