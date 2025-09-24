# Stage 1: Builder
FROM registry.access.redhat.com/ubi9 AS builder
RUN dnf install --installroot /mnt/rootfs curl --releasever 9 --setopt install_weak_deps=false --nodocs -y && \
    dnf --installroot /mnt/rootfs clean all

# Stage 2: Final
FROM quay.io/keycloak/keycloak:26.0.0
COPY --from=builder /mnt/rootfs /

# Set working directory
WORKDIR /opt/keycloak

# Create necessary directories
USER root
RUN mkdir -p /opt/keycloak/data/import

# Copy realm configuration
COPY projectlos-realm.json /opt/keycloak/data/import/projectlos-realm.json

# Copy startup script
COPY entrypoint.sh /opt/keycloak/bin/entrypoint.sh

# Make scripts executable
RUN chmod +x /opt/keycloak/bin/entrypoint.sh

# Set ownership (Keycloak 26.0.0 uses UID 1000)
RUN chown -R 1000:1000 /opt/keycloak/data /opt/keycloak/bin/entrypoint.sh

# Switch back to keycloak user (UID 1000)
USER 1000

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
  CMD curl -f http://localhost:8080/health/ready || exit 1

# Use custom entrypoint
ENTRYPOINT ["/opt/keycloak/bin/entrypoint.sh"]
