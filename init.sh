#!/bin/bash
# Init Script für All-in-One NetBox

# PostgreSQL starten
/usr/lib/postgresql/18/bin/postgres -D /var/lib/postgresql/18/main &
POSTGRES_PID=$!
sleep 3

# DB User und Database erstellen
su postgres -c "/usr/lib/postgresql/18/bin/psql -c \"CREATE USER netbox WITH PASSWORD 'netbox' CREATEDB;\""
su postgres -c "/usr/lib/postgresql/18/bin/psql -c \"CREATE DATABASE netbox OWNER netbox;\""

# Postgres beenden
kill $POSTGRES_PID 2>/dev/null || true
wait $POSTGRES_PID 2>/dev/null || true

# Redis Passwort setzen
echo "netbox" > /data/redis/.redis_password

echo "✅ Init done"
