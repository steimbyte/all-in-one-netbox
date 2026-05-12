#!/bin/bash
# Generate secure secrets for all-in-one-netbox

echo "🔐 Generating secure secrets..."

# Generate SECRET_KEY
SECRET_KEY=$(openssl rand -hex 50)
echo "SECRET_KEY=$SECRET_KEY"

# Generate DB_PASSWORD
DB_PASSWORD=$(openssl rand -hex 24)
echo "DB_PASSWORD=$DB_PASSWORD"

# Generate REDIS_PASSWORD (same for both instances)
REDIS_PASSWORD=$(openssl rand -hex 24)
echo "REDIS_PASSWORD=$REDIS_PASSWORD"

# Generate SUPERUSER_PASSWORD if not set
SUPERUSER_PASSWORD="Admin$(openssl rand -hex 8)!"
echo "SUPERUSER_PASSWORD=Admin[generated]"

echo ""
echo "✅ Run 'cp .env.example .env' and fill in the values above"
