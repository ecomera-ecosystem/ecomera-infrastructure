export VAULT_ADDR=http://127.0.0.1:8200

echo '[vault] Waiting for Vault to start...'
until vault status 2>&1 | grep -q 'Sealed'; do sleep 2; done
echo '[vault] Vault server is running'

echo '[vault] Checking initialization status...'
if vault status 2>&1 | grep -q 'Initialized.*true'; then
  echo '[vault] Vault already initialized, unsealing...'
  if [ -f /vault-creds/vault.env ]; then
    . /vault-creds/vault.env
    vault operator unseal $VAULT_UNSEAL_KEY
    echo '[vault] Vault unsealed successfully'
    export VAULT_TOKEN=$VAULT_TOKEN
  else
    echo '[vault] ERROR: Credentials missing'
    echo '[vault] Run: docker compose down -v'
    exit 1
  fi
else
  echo '[vault] Vault not initialized, initializing...'
  INIT_OUTPUT=$(vault operator init -key-shares=1 -key-threshold=1)
  UNSEAL_KEY=$(echo "$INIT_OUTPUT" | grep 'Unseal Key 1:' | sed 's/.*Unseal Key 1: *//' | tr -d '[:space:]')
  ROOT_TOKEN=$(echo "$INIT_OUTPUT" | grep 'Root Token:' | sed 's/.*Root Token: *//' | tr -d '[:space:]')
  vault operator unseal $UNSEAL_KEY
  export VAULT_TOKEN=$ROOT_TOKEN
  echo "VAULT_ADDR=http://vault:8200" > /vault-creds/vault.env
  echo "VAULT_TOKEN=$ROOT_TOKEN" >> /vault-creds/vault.env
  echo "VAULT_UNSEAL_KEY=$UNSEAL_KEY" >> /vault-creds/vault.env
  echo "[vault] Root Token: $ROOT_TOKEN"
fi

echo '[vault] Ensuring KV v2 secrets engine is mounted...'
if ! vault secrets list 2>/dev/null | grep -q '^secret/'; then
  vault secrets enable -path=secret kv-v2
  echo '[vault] KV v2 engine enabled at secret/'
else
  echo '[vault] Secret engine already mounted'
fi

echo '[vault] Seeding secrets for application (shared defaults)...'
vault kv put secret/ecomera/application eureka.url=http://ecomera-eureka-server:8761/eureka/ zipkin.enabled=true
echo '[vault] Seeding secrets for shared config...'
vault kv put secret/ecomera/shared eureka.url=http://ecomera-eureka-server:8761/eureka/
echo '[vault] Seeding secrets for config-server...'
vault kv put secret/ecomera/config-server server.port=8888
echo '[vault] Seeding secrets for product-service...'
vault kv put secret/ecomera/product-service db/password=postgres redis/password= jwt/signing-key=SuperSecretJWTKeyThatShouldBeRotatedRegularly1234567890
echo '[vault] Seeding secrets for auth-service...'
vault kv put secret/ecomera/auth-service db/password=postgres jwt/signing-key=SuperSecretJWTKeyThatShouldBeRotatedRegularly1234567890
echo '[vault] Seeding secrets for cart-service...'
vault kv put secret/ecomera/cart-service db/password=postgres redis/password=
echo '[vault] Seeding secrets for order-service...'
vault kv put secret/ecomera/order-service db/password=postgres redis/password=
echo '[vault] Seeding secrets for payment-service...'
vault kv put secret/ecomera/payment-service db/password=postgres redis/password= stripe/secret-key=sk_test_placeholder stripe/webhook-secret=whsec_placeholder
echo '[vault] Seeding secrets for api-gateway...'
vault kv put secret/ecomera/api-gateway zipkin/url=http://zipkin:9411/api/v2/spans
echo '[vault] Seeding complete!'

echo ''
echo '========================================'
echo '  Vault is ready!'
echo '  Root Token:     '$VAULT_TOKEN
echo '  UI:             http://localhost:8200/ui'
echo '========================================'

tail -f /dev/null
