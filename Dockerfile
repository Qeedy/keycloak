FROM quay.io/keycloak/keycloak:26.0.0

# Set working directory
WORKDIR /opt/keycloak

# Install curl for health checks
USER root
RUN microdnf install -y curl && microdnf clean all

# Create necessary directories
RUN mkdir -p /opt/keycloak/data/import

# Copy realm configuration
COPY projectlos-realm.json /opt/keycloak/data/import/projectlos-realm.json

# Copy startup script
COPY entrypoint.sh /opt/keycloak/bin/entrypoint.sh

# Make scripts executable
RUN chmod +x /opt/keycloak/bin/entrypoint.sh

# Set ownership
RUN chown -R keycloak:keycloak /opt/keycloak/data /opt/keycloak/bin/entrypoint.sh

# Switch back to keycloak user
USER keycloak

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
  CMD curl -f http://localhost:8080/health/ready || exit 1

# Use custom entrypoint
ENTRYPOINT ["/opt/keycloak/bin/entrypoint.sh"]
