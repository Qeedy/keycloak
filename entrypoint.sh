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

# Add startup optimizations for faster boot
export KC_START_OPTIMISTIC_LOCKING=true
export KC_CACHE=local
export KC_CACHE_STACK=kubernetes
export KC_LOG_LEVEL=${KC_LOG_LEVEL:-INFO}

# Parse DATABASE_URL for Railway
if [ ! -z "$DATABASE_URL" ]; then
    # Extract components from DATABASE_URL
    DB_URL_PARSED=$(echo $DATABASE_URL | sed 's/postgres:\/\/\([^:]*\):\([^@]*\)@\([^:]*\):\([^\/]*\)\/\(.*\)/\1 \2 \3 \4 \5/')
    read -r DB_USER DB_PASS DB_HOST DB_PORT DB_NAME <<< "$DB_URL_PARSED"
    
    # Set Keycloak database environment variables
    export KC_DB=postgres
    export KC_DB_USERNAME=${KC_DB_USERNAME:-$DB_USER}
    export KC_DB_PASSWORD=${KC_DB_PASSWORD:-$DB_PASS}
    export KC_DB_URL_HOST=${KC_DB_URL_HOST:-$DB_HOST}
    export KC_DB_URL_PORT=${KC_DB_URL_PORT:-$DB_PORT}
    export KC_DB_URL_DATABASE=${KC_DB_URL_DATABASE:-$DB_NAME}
    export KC_DB_SCHEMA=keycloak
    
    echo "Database configuration:"
    echo "  Host: $DB_HOST"
    echo "  Port: $DB_PORT"
    echo "  Database: $DB_NAME"
    echo "  Username: $DB_USER"
    echo "  Schema: keycloak"
    
    # Add database connection timeout and retry settings
    export KC_DB_POOL_INITIAL_SIZE=5
    export KC_DB_POOL_MIN_SIZE=5
    export KC_DB_POOL_MAX_SIZE=20
    
    # Test database connection
    echo "Testing database connection..."
    sleep 2
else
    echo "No DATABASE_URL found, using default H2 database"
fi

# Set hostname for Railway
if [ ! -z "$RAILWAY_PUBLIC_DOMAIN" ]; then
    export KC_HOSTNAME=${KC_HOSTNAME:-$RAILWAY_PUBLIC_DOMAIN}
    echo "Hostname set to: $KC_HOSTNAME"
fi

# Check if we need to rebuild database configuration
if [ -f "/opt/keycloak/data/h2/keycloakdb.mv.db" ]; then
    echo "Found existing H2 database, removing to force PostgreSQL configuration..."
    rm -rf /opt/keycloak/data/h2
fi

# Import realm if file exists
REALM_FILE="/opt/keycloak/data/import/projectlos-realm.json"
if [ -f "$REALM_FILE" ]; then
    echo "Realm file found: $REALM_FILE"
    echo "Starting Keycloak with realm import..."
    exec /opt/keycloak/bin/kc.sh start-dev --import-realm --optimized
else
    echo "No realm file found. Starting Keycloak without import..."
    exec /opt/keycloak/bin/kc.sh start-dev --optimized
fi
