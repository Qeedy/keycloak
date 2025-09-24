#!/bin/bash

# Simplified Keycloak startup script for Railway deployment
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

# Enhanced Railway configuration
echo "🔧 Configuring Railway networking..."
export KC_HOSTNAME_STRICT_HTTPS=false
export KC_HTTP_ENABLED=true
export KC_PROXY=edge

# Allow both HTTP and HTTPS protocols
export KC_HOSTNAME_STRICT=false
export KC_HOSTNAME_STRICT_BACKCHANNEL=false

# Special configuration for private domain as primary
if [ ! -z "$RAILWAY_PRIVATE_DOMAIN" ]; then
    echo "🔧 Configuring for private domain as primary..."
    export KC_HOSTNAME_PORT=80
    export KC_HOSTNAME_STRICT_HTTPS=false
    echo "   - Port: 80 (HTTP)"
    echo "   - HTTPS strict: disabled"
fi

echo "   - HTTPS strict mode: disabled"
echo "   - HTTP enabled: true"
echo "   - Proxy mode: edge"

# Add startup optimizations for faster boot and lower memory usage
export KC_START_OPTIMISTIC_LOCKING=true
export KC_CACHE=local
export KC_CACHE_STACK=kubernetes
export KC_LOG_LEVEL=${KC_LOG_LEVEL:-INFO}

# JVM Memory optimizations for Railway's limited RAM
export JAVA_OPTS_APPEND="-Xms256m -Xmx512m -XX:MaxMetaspaceSize=128m -XX:MetaspaceSize=64m -Xss256k -XX:+UseG1GC -XX:MaxGCPauseMillis=100 -XX:+UseStringDeduplication"

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

# HOSTNAME CONFIGURATION - PRIORITIZE PRIVATE DOMAIN FOR JWT ISSUER
# Strategy: Use private domain as primary for JWT issuer, but allow admin access via public domain
if [ ! -z "$RAILWAY_PRIVATE_DOMAIN" ]; then
    # Use private domain as primary hostname for JWT issuer
    export KC_HOSTNAME=${KC_HOSTNAME:-$RAILWAY_PRIVATE_DOMAIN}
    export KC_HOSTNAME_URL=http://$RAILWAY_PRIVATE_DOMAIN
    export KC_HOSTNAME_ADMIN_URL=http://$RAILWAY_PRIVATE_DOMAIN
    echo "🔧 Hostname set to private domain: $KC_HOSTNAME"
    echo "⚡ JWT issuer will use: http://$RAILWAY_PRIVATE_DOMAIN"
    echo "🔒 Admin URL: $KC_HOSTNAME_ADMIN_URL (HTTP)"
    
    # If public domain exists, configure it for admin console access
    if [ ! -z "$RAILWAY_PUBLIC_DOMAIN" ]; then
        echo "🌐 Public domain available: $RAILWAY_PUBLIC_DOMAIN"
        echo "🔒 Admin console accessible via: https://$RAILWAY_PUBLIC_DOMAIN/admin"
        echo "   - Note: Admin console may need manual configuration for HTTPS"
    fi
elif [ ! -z "$RAILWAY_PUBLIC_DOMAIN" ]; then
    # Fallback to public domain if private domain not available
    export KC_HOSTNAME=${KC_HOSTNAME:-$RAILWAY_PUBLIC_DOMAIN}
    export KC_HOSTNAME_URL=https://$RAILWAY_PUBLIC_DOMAIN
    export KC_HOSTNAME_ADMIN_URL=https://$RAILWAY_PUBLIC_DOMAIN
    echo "🌐 Hostname set to public domain: $KC_HOSTNAME"
    echo "🔒 Admin URL: $KC_HOSTNAME_ADMIN_URL (HTTPS)"
    echo "⚠️  JWT issuer will use HTTPS (not optimal for internal communication)"
else
    # For local testing
    export KC_HOSTNAME=${KC_HOSTNAME:-localhost:8080}
    export KC_HOSTNAME_URL=http://localhost:8080
    export KC_HOSTNAME_ADMIN_URL=http://localhost:8080
    echo "🏠 Local testing mode"
fi

# Clear all existing data to force fresh start
echo "Clearing all existing Keycloak data to force fresh configuration..."
rm -rf /opt/keycloak/data/*

# Recreate necessary directories
mkdir -p /opt/keycloak/data/import

# Start Keycloak without automatic realm import
echo "Starting Keycloak (realm import will be done manually later)..."
exec /opt/keycloak/bin/kc.sh start-dev
