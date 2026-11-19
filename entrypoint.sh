#!/bin/sh
set -e
cd /home/container
mkdir -p data

# Pelican's UID usually has no passwd entry; Postgres refuses to run without one.
if ! getent passwd "$(id -u)" >/dev/null; then
  echo "container:x:$(id -u):$(id -g)::/home/container:/bin/sh" >> /etc/passwd
fi

# Built-in PostgreSQL, used unless FLUXER_POSTGRES_URL points elsewhere.
if [ -z "$FLUXER_POSTGRES_URL" ]; then
  PGDATA=/home/container/postgres
  PGPORT=${PGPORT:-5432}
  if [ ! -s "$PGDATA/PG_VERSION" ]; then
    echo "[fluxer-egg] Initialising built-in PostgreSQL in $PGDATA"
    PGPASS=$(head -c 24 /dev/urandom | od -An -tx1 | tr -d ' \n')
    printf '%s' "$PGPASS" > /home/container/.pgpass_fluxer && chmod 600 /home/container/.pgpass_fluxer
    printf '%s\n' "$PGPASS" > /tmp/pwfile
    initdb -D "$PGDATA" -U fluxer --pwfile=/tmp/pwfile -A scram-sha-256 -E UTF8 >/dev/null
    rm -f /tmp/pwfile
  fi
  PGPASS=$(cat /home/container/.pgpass_fluxer)
  pg_ctl -D "$PGDATA" -l /home/container/postgres.log -w \
    -o "-c listen_addresses=127.0.0.1 -p $PGPORT -k /tmp" start
  PGPASSWORD=$PGPASS psql -h 127.0.0.1 -p "$PGPORT" -U fluxer -d postgres -tAc \
    "SELECT 1 FROM pg_database WHERE datname='fluxer'" | grep -q 1 \
    || PGPASSWORD=$PGPASS createdb -h 127.0.0.1 -p "$PGPORT" -U fluxer fluxer
  export FLUXER_POSTGRES_URL="postgres://fluxer:${PGPASS}@127.0.0.1:${PGPORT}/fluxer"
  trap 'kill -TERM "$CHILD" 2>/dev/null; wait "$CHILD"; pg_ctl -D "$PGDATA" -m fast stop' TERM INT
  STOP_PG=1
fi

# Expand Pelican's {{VAR}} placeholders in the startup command.
MODIFIED_STARTUP=$(echo "$STARTUP" | sed -e 's/{{/${/g' -e 's/}}/}/g')
echo ":/home/container$ ${MODIFIED_STARTUP}"
if [ -n "$STOP_PG" ]; then
  eval "${MODIFIED_STARTUP}" &
  CHILD=$!
  wait "$CHILD"; CODE=$?
  pg_ctl -D "$PGDATA" -m fast stop || true
  exit $CODE
else
  eval exec ${MODIFIED_STARTUP}
fi
