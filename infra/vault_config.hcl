# PREDATOR 2026 — vault_config.hcl
# SCRUM-19 | Phase 0 | Spec §16.3
# HashiCorp Vault on-prem configuration for dynamic secrets
# Deployed on Zone B management network only

# ---------------------------------------------------------------------------
# Storage backend — file-based for single-node on-prem Vault
# ---------------------------------------------------------------------------
storage "file" {
  path = "/opt/vault/data"
}

# ---------------------------------------------------------------------------
# Listener — management NIC only (Zone B, non-routable from Zone A)
# ---------------------------------------------------------------------------
listener "tcp" {
  address         = "192.168.1.10:8200"
  tls_cert_file   = "/etc/vault/tls/vault.crt"
  tls_key_file    = "/etc/vault/tls/vault.key"
  tls_min_version = "tls13"
}

# ---------------------------------------------------------------------------
# Security settings
# ---------------------------------------------------------------------------
ui                 = false    # Disable web UI in production
disable_mlock      = false    # mlock prevents memory from paging to disk

# ---------------------------------------------------------------------------
# Audit logging — every access to Vault is logged
# ---------------------------------------------------------------------------
audit {
  type = "file"
  options = {
    file_path = "/var/log/vault/audit.log"
    mode      = "0600"
  }
}

# ---------------------------------------------------------------------------
# Dynamic secrets — ClickHouse credentials (§16.1)
# ---------------------------------------------------------------------------
# Enable: vault secrets enable database
# Configure in vault_bootstrap.sh:
#   vault write database/config/predator-clickhouse \
#     plugin_name=postgresql-database-plugin \
#     allowed_roles="predator-clickhouse" \
#     connection_url="clickhouse://{{username}}:{{password}}@192.168.1.20:9000/predator" \
#     username="vault_admin" password="..."
#
# Rotation TTL = 1 hour (§16.3):
#   vault write database/roles/predator-clickhouse \
#     db_name=predator-clickhouse \
#     creation_statements="CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}'" \
#     default_ttl="1h" max_ttl="2h"

# ---------------------------------------------------------------------------
# Policy — predator process reads only its own credentials
# ---------------------------------------------------------------------------
# vault policy write predator-process - <<EOF
# path "database/creds/predator-clickhouse" { capabilities = ["read"] }
# path "database/creds/predator-kafka"      { capabilities = ["read"] }
# path "secret/data/predator/*"             { capabilities = ["read"] }
# EOF

# ---------------------------------------------------------------------------
# AppRole auth for the predator trading process
# ---------------------------------------------------------------------------
# vault auth enable approle
# vault write auth/approle/role/predator \
#   role_name=predator \
#   secret_id_ttl=0 \
#   token_num_uses=0 \
#   token_ttl=1h \
#   token_max_ttl=2h \
#   policies=predator-process
# RoleID stored at /etc/predator/vault_role_id (non-secret, process reads)
# SecretID injected on process startup by the systemd unit via Vault Agent

# ---------------------------------------------------------------------------
# No secrets in environment variables or source code (§16.1)
# ---------------------------------------------------------------------------
