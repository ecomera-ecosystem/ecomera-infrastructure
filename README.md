# Ecomera Infrastructure

Shared infrastructure services for the Ecomera ecosystem (Vault, PostgreSQL, Redis).

## Prerequisites

- Docker >= 24.0
- Docker Compose >= 2.20

## Quick Start

```bash
docker-compose up -d
```

## Services

| Service    | Port  | Description                          |
|------------|-------|--------------------------------------|
| Vault      | 8200  | Secrets management (KV v2)           |
| PostgreSQL | 5432  | Relational database                  |
| Redis      | 6379  | Cache & session store                |

## Vault Setup

### First Start

On first `docker-compose up`, Vault auto-initializes and seeds secrets for all microservices. The root token and unseal key are saved in the `vault-creds` volume.

**Retrieve the root token:**
```bash
docker logs ecomera-vault 2>&1 | grep "Root Token"
```

### Configure Microservices

Copy the `VAULT_TOKEN` into each microservice's `.env` file:

```env
VAULT_HOST=localhost
VAULT_PORT=8200
VAULT_TOKEN=<your-root-token>
```

**Affected services:**
- `ecomera-config-server`
- `ecomera-product-service`
- `ecomera-auth-service`
- `ecomera-api-gateway`

### Vault UI

Open http://localhost:8200/ui in your browser and authenticate with the root token.

### Stored Secrets Structure

```
secret/ecomera/
├── product-service/
│   ├── db/host
│   ├── db/port
│   ├── db/name
│   ├── db/username
│   ├── db/password
│   ├── redis/host
│   ├── redis/port
│   ├── redis/password
│   ├── jwt/signing-key
│   ├── jwt/access-token-ttl
│   └── jwt/refresh-token-ttl
├── auth-service/
│   ├── db/host
│   ├── db/port
│   ├── db/name
│   ├── db/username
│   ├── db/password
│   ├── jwt/signing-key
│   ├── jwt/access-token-ttl
│   └── jwt/refresh-token-ttl
└── api-gateway/
    └── zipkin/url
```

### Reset Vault (Reinitialize)

```bash
docker-compose down
docker volume rm ecomera-infrastructure_vault-data ecomera-infrastructure_vault-creds
docker-compose up -d
```

## Common Commands

```bash
# Start all infrastructure
docker-compose up -d

# View Vault logs
docker logs -f ecomera-vault

# Enter Vault container CLI
docker exec -it ecomera-vault sh

# Update a secret manually
docker exec ecomera-vault vault kv put secret/ecomera/product-service db/password=newpassword

# Stop all infrastructure
docker-compose down
```
