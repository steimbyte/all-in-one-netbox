# All-in-One NetBox - Lean Memory-Optimized
FROM netboxcommunity/netbox:latest

USER root

# Install PostgreSQL + Redis + Supervisor + sudo
RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql \
    redis-server \
    supervisor \
    sudo \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Create postgres user if not exists
RUN id postgres &>/dev/null || useradd -r -s /bin/bash postgres

# Copy entrypoint script with memory-optimized configs
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=5 \
    CMD curl -f http://localhost:8080/login/ || exit 1

ENTRYPOINT ["/entrypoint.sh"]
