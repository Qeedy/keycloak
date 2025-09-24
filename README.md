# Keycloak Service for Railway Deployment

This directory contains the Keycloak service configuration for deployment on Railway.

## 📁 Structure

```
keycloak_service/
├── Dockerfile              # Docker configuration for Keycloak
├── entrypoint.sh           # Custom startup script
├── projectlos-realm.json   # Realm configuration
├── railway.json            # Railway deployment configuration
└── README.md              # This file
```

## 🚀 Deployment to Railway

### 1. Create New Service in Railway

1. **Login to Railway Dashboard**
2. **Click "New Service"**
3. **Select "GitHub Repo"**
4. **Choose your repository**
5. **Set Root Directory to:** `keycloak_service`
6. **Service Name:** `keycloak`

### 2. Environment Variables

Configure the following environment variables in Railway:

```bash
# Admin Credentials
KEYCLOAK_ADMIN=admin
KEYCLOAK_ADMIN_PASSWORD=admin

# Database Configuration (Railway will provide these)
KC_DB=postgres
KC_DB_URL=${{Postgres.DATABASE_URL}}?currentSchema=keycloak
KC_DB_USERNAME=${{Postgres.PGUSER}}
KC_DB_PASSWORD=${{Postgres.PGPASSWORD}}

# Keycloak Configuration
KC_HTTP_ENABLED=true
KC_PROXY=edge
KC_HOSTNAME_STRICT=false
KC_HOSTNAME_STRICT_HTTPS=false
KC_HOSTNAME_STRICT_BACKCHANNEL=false
KC_LOG_LEVEL=INFO

# Railway Specific
KC_HOSTNAME=${{RAILWAY_PUBLIC_DOMAIN}}
```

### 3. Database Setup

Make sure you have a PostgreSQL database service in your Railway project:

1. **Add PostgreSQL Database** if not already present
2. **Keycloak will automatically create the `keycloak` schema**
3. **Realm will be imported automatically on first startup**

### 4. Service Dependencies

The Keycloak service should be deployed **after** the PostgreSQL database is ready.

## 🔧 Configuration Details

### Dockerfile Features

- Based on official Keycloak 26.0.0 image
- Includes realm configuration import
- Custom entrypoint script for Railway compatibility
- Health checks configured
- Proper file permissions

### Entrypoint Script Features

- Automatic DATABASE_URL parsing for Railway
- Environment variable defaults
- Database connection waiting
- Realm import handling
- Railway domain configuration

### Realm Configuration

The `projectlos-realm.json` includes:

- **Realm:** `projectlos`
- **Client:** `projectlos-client` with secret `projectlos-secret-123`
- **Roles:** ADMIN, MAKER, CHECKER, APPROVER
- **Test Users:** admin, maker, checker, approver (and test variants)

## 🔗 Service URLs

After deployment, your Keycloak service will be available at:

- **Admin Console:** `https://your-keycloak.railway.app/admin`
- **Realm Endpoint:** `https://your-keycloak.railway.app/realms/projectlos`
- **OpenID Configuration:** `https://your-keycloak.railway.app/realms/projectlos/.well-known/openid_configuration`

## 🧪 Testing

After deployment, test the service:

```bash
# Health check
curl https://your-keycloak.railway.app/health/ready

# Realm access
curl https://your-keycloak.railway.app/realms/projectlos

# Admin login (using browser)
https://your-keycloak.railway.app/admin
# Username: admin
# Password: admin
```

## 🔐 Security Notes

1. **Change default admin password** in production
2. **Update client secrets** for production deployment
3. **Configure proper redirect URIs** for your application domains
4. **Enable HTTPS** in production (Railway provides this automatically)

## 🚨 Troubleshooting

### Common Issues

1. **Database Connection Failed**
   - Check if PostgreSQL service is running
   - Verify DATABASE_URL environment variable
   - Check database schema permissions

2. **Realm Import Failed**
   - Check if projectlos-realm.json file exists
   - Verify file permissions
   - Check Keycloak logs for import errors

3. **Service Won't Start**
   - Check environment variables
   - Verify Railway domain configuration
   - Check health check endpoint

### Logs

View logs in Railway dashboard or use Railway CLI:

```bash
railway logs keycloak
```

## 📞 Support

For issues related to this Keycloak deployment, check:

1. Railway service logs
2. Keycloak admin console
3. Database connection status
4. Environment variable configuration
