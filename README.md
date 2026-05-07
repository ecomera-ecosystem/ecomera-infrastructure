# Ecomera Infrastructure

Shared infrastructure services for the Ecomera ecosystem (Vault, PostgreSQL, Redis).

## Prerequisites

- Docker >= 24.0
- Docker Compose >= 2.20

## Quick Start

```bash
cp .env.example .env
docker compose up -d
```

## Services

| Service    | Port  | Description                          |
|------------|-------|--------------------------------------|
| Vault      | 8200  | Secrets management (KV v2)           |
| PostgreSQL | 5432  | Relational database                  |
| Redis      | 6379  | Cache & session store                |

### Databases

On first start, the PostgreSQL container auto-creates databases defined in `init-databases.sql`:

| Database      | User     | Password     | Used by              |
|---------------|----------|--------------|----------------------|
| `ecomera`     | postgres | postgres     | (default)            |
| `ecomera_auth` | postgres | postgres    | auth-service         |
| `ecomera_product` | postgres | postgres | product-service      |

## Vault Setup

### First Start

On first `docker compose up`, Vault auto-initializes via `vault/init.sh`:
1. Initializes Vault (1 key share, 1 threshold)
2. Unseals Vault
3. Mounts KV v2 secrets engine at `secret/`
4. Seeds secrets for all microservices
5. Persists root token and unseal key to `/vault-creds/vault.env`

**Retrieve the root token:**
```bash
docker logs ecomera-infra-vault 2>&1 | grep "Root Token"
```
Or read from the volume:
```bash
docker exec ecomera-infra-vault cat /vault-creds/vault.env
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

Each service has a `.env.example` file you can copy:
```bash
cp .env.example .env
```
Then paste your `VAULT_TOKEN` into the `.env`.

### Vault UI

Open http://localhost:8200/ui in your browser and authenticate with the root token.

Navigate to `secret/ecomera/` to view seeded secrets for each service.

### Stored Secrets Structure

Vault only stores **secrets**. Connection info (host, port, db name, usernames) lives in each microservice's `.env` file.

```
secret/ecomera/
├── application/          # Shared defaults (eureka.url, zipkin.enabled)
├── shared/               # Shared config (eureka.url)
├── config-server/        # Config server settings (server.port)
├── product-service/
│   ├── db/password
│   ├── redis/password
│   └── jwt/signing-key
├── auth-service/
│   ├── db/password
│   └── jwt/signing-key
└── api-gateway/
    └── zipkin/url
```

### Reset Vault (Reinitialize)

```bash
docker compose down -v
docker compose up -d
```

> **Warning:** `-v` destroys all Vault data and resets the root token. All microservices must be updated with the new token.

## Common Commands

```bash
# Start all infrastructure
docker compose up -d

# View Vault logs
docker logs -f ecomera-infra-vault

# Enter Vault container CLI
docker exec -it ecomera-infra-vault sh

# Read credentials from volume
docker exec ecomera-infra-vault cat /vault-creds/vault.env

# Update a secret manually
docker exec ecomera-infra-vault vault kv put secret/ecomera/product-service db/password=newpassword

# Stop all infrastructure
docker compose down
```
