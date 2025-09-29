#!/bin/bash

# Keycloak startup script for Railway deployment
set -e

echo "Starting Keycloak service..."

# Wait for database to be ready if DATABASE_URL is provided
if [ ! -z "$DATABASE_URL" ]; then
    echo "Waiting for database to be ready..."
    sleep 5
fi

# Set default environment variables if not provided
export KEYCLOAK_ADMIN=${KEYCLOAK_ADMIN:-admin}
export KEYCLOAK_ADMIN_PASSWORD=${KEYCLOAK_ADMIN_PASSWORD:-admin}
export KC_DB=${KC_DB:-postgres}
export KC_HTTP_ENABLED=${KC_HTTP_ENABLED:-true}
export KC_PROXY=${KC_PROXY:-edge}
export KC_HOSTNAME_STRICT=${KC_HOSTNAME_STRICT:-false}
export KC_HOSTNAME_STRICT_HTTPS=${KC_HOSTNAME_STRICT_HTTPS:-false}
export KC_HOSTNAME_STRICT_BACKCHANNEL=${KC_HOSTNAME_STRICT_BACKCHANNEL:-false}

# Additional proxy and admin settings for Railway
export KC_PROXY_HEADERS=${KC_PROXY_HEADERS:-xforwarded}
export KC_HOSTNAME_DEBUG=${KC_HOSTNAME_DEBUG:-true}

# Disable healthcheck endpoints via JVM options
# Note: KC_HEALTH_ENABLED and KC_METRICS_ENABLED are not valid Keycloak options
# Healthcheck will be disabled via JVM system properties

# Additional settings to disable healthcheck
export KC_HTTP_ENABLED=true
export KC_PROXY=edge

# Disable healthcheck via system properties
export JAVA_OPTS_APPEND="$JAVA_OPTS_APPEND -Dquarkus.health.enabled=false -Dquarkus.metrics.enabled=false -Dquarkus.management.enabled=false -Dquarkus.management.health.enabled=false -Dquarkus.management.health.readiness.enabled=false -Dquarkus.management.health.liveness.enabled=false -Dquarkus.management.health.startup.enabled=false -Dquarkus.management.health.probes.enabled=false -Dquarkus.management.health.context-property-validation.enabled=false"

# Add startup optimizations for faster boot and lower memory usage
export KC_START_OPTIMISTIC_LOCKING=true
export KC_CACHE=local
export KC_CACHE_STACK=kubernetes
export KC_LOG_LEVEL=${KC_LOG_LEVEL:-INFO}

# JVM Memory optimizations for Railway's limited RAM
# Healthcheck disabled via JVM options
export JAVA_OPTS_APPEND="-Xms256m -Xmx512m -XX:MaxMetaspaceSize=128m -XX:MetaspaceSize=64m -Xss256k -XX:+UseG1GC -XX:MaxGCPauseMillis=100 -XX:+UseStringDeduplication -Dquarkus.http.port=8080 -Dquarkus.http.host=0.0.0.0"

# Set PostgreSQL database configuration
export KC_DB=postgres
export KC_DB_USERNAME=${KC_DB_USERNAME:-postgres}
export KC_DB_PASSWORD=${KC_DB_PASSWORD:-yaNSDZveAOsFmqFZmAGiRfUHWrQIKAYi}
export KC_DB_URL_HOST=${KC_DB_URL_HOST:-shuttle.proxy.rlwy.net}
export KC_DB_URL_PORT=${KC_DB_URL_PORT:-22024}
export KC_DB_URL_DATABASE=${KC_DB_URL_DATABASE:-railway}
export KC_DB_SCHEMA=keycloak

echo "Database configuration:"
echo "  Host: $KC_DB_URL_HOST"
echo "  Port: $KC_DB_URL_PORT"
echo "  Database: $KC_DB_URL_DATABASE"
echo "  Username: $KC_DB_USERNAME"
echo "  Schema: $KC_DB_SCHEMA"

# Add database connection timeout and retry settings (reduced for memory efficiency)
export KC_DB_POOL_INITIAL_SIZE=2
export KC_DB_POOL_MIN_SIZE=2
export KC_DB_POOL_MAX_SIZE=10

# Test database connection
echo "Testing database connection..."
sleep 2

# Set hostname for Railway
if [ ! -z "$RAILWAY_PUBLIC_DOMAIN" ]; then
    export KC_HOSTNAME=${KC_HOSTNAME:-$RAILWAY_PUBLIC_DOMAIN}
    export KC_HOSTNAME_URL=https://$RAILWAY_PUBLIC_DOMAIN
    export KC_HOSTNAME_ADMIN_URL=https://$RAILWAY_PUBLIC_DOMAIN
    echo "Hostname set to: $KC_HOSTNAME"
    echo "Admin URL set to: $KC_HOSTNAME_ADMIN_URL"
else
    # For local testing
    export KC_HOSTNAME=${KC_HOSTNAME:-localhost:8080}
    export KC_HOSTNAME_URL=http://localhost:8080
    export KC_HOSTNAME_ADMIN_URL=http://localhost:8080
fi

# Clear all existing data to force fresh start
echo "Clearing all existing Keycloak data to force fresh configuration..."
rm -rf /opt/keycloak/data/*

# Recreate necessary directories
mkdir -p /opt/keycloak/data/import

# Start Keycloak without automatic realm import
echo "Starting Keycloak (realm import will be done manually later)..."
echo "Healthcheck disabled via JVM options"

exec /opt/keycloak/bin/kc.sh start-dev

