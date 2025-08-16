- start by doing updates
sudo dnf install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo dnf install -y vault

vault --version

sudo dnf install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo dnf install -y vault

vault --version

sudo nano /etc/vault.d/vault.hcl

disable_mlock = true

listener "tcp" {
  address     = "127.0.0.1:8200"
  tls_disable = 1
}

storage "file" {
  path = "/opt/vault/data"
}

ui = false


sudo tee /etc/systemd/system/vault.service > /dev/null <<'EOF'
[Unit]
Description=HashiCorp Vault - local jump box
After=network-online.target
Wants=network-online.target

[Service]
User=vault
Group=vault
ExecStart=/usr/bin/vault server -config=/etc/vault.d/vault.hcl
ExecReload=/bin/kill --signal HUP $MAINPID
Restart=on-failure
LimitNOFILE=65536
ProtectSystem=full
ProtectHome=read-only
PrivateTmp=yes
NoNewPrivileges=yes

[Install]
WantedBy=multi-user.target
EOF


sudo systemctl daemon-reload
sudo systemctl enable --now vault

echo 'export VAULT_ADDR="http://127.0.0.1:8200"' >> ~/.bashrc
source ~/.bashrc
unset VAULT_TOKEN
rm -f ~/.vault-token
export VAULT_ADDR='http://127.0.0.1:8200'

vault operator init

need to do three times with different keys
vault operator unseal

vault login

vault secrets enable -path=ssh-client-signer ssh
vault write ssh-client-signer/config/ca generate_signing_key=true

vault write ssh-client-signer/roles/server-admins \
    key_type=ca \
    allow_user_certificates=true \
    allowed_users="admin_richard" \
    default_user="admin_richard" \
    ttl="10m"

ssh-keygen -t ed25519 -f ~/.ssh/tempkey -q -N ""

vault write -field=signed_key ssh-client-signer/sign/server-admins \
    public_key=@$HOME/.ssh/tempkey.pub > ~/.ssh/tempkey-cert.pub

ssh -i ~/.ssh/tempkey -o CertificateFile=~/.ssh/tempkey-cert.pub admin_richard@192.168.35.23

rm -f ~/.ssh/tempkey ~/.ssh/tempkey-cert.pub






vault secrets enable -path=secret kv-v2
vault kv put secret/localhost/login admin_richard="s3cr3t!"

secret/<team>/<environment>/<system>/<credential_type>

vault kv put  secret/homelab/dev/jumpbox-cloud/login admin_richard="ThisisaTest"

# read the current value
path "secret/data/homelab/dev/jumpbox-cloud/login" {
  capabilities = ["read"]
}
# read metadata (versions, checks)
path "secret/metadata/homelab/dev/jumpbox-cloud/login" {
  capabilities = ["read"]
}

jumpbox-login-read.hcl
# read the current value
path "secret/data/homelab/dev/jumpbox-cloud/login" {
  capabilities = ["read"]
}
# read metadata (versions, checks)
path "secret/metadata/homelab/dev/jumpbox-cloud/login" {
  capabilities = ["read"]
}

jumpbox-login-admin.hcl
# CRUD on the secret data
path "secret/data/homelab/dev/jumpbox-cloud/login" {
  capabilities = ["create","read","update","delete"]
}

# metadata ops (needed for versioning/lifecycle)
path "secret/metadata/homelab/dev/jumpbox-cloud/login" {
  capabilities = ["read","update","delete"]
}

# KV v2 versioned ops (soft-delete, destroy, undelete)
path "secret/delete/homelab/dev/jumpbox-cloud/login"   { capabilities = ["update"] }
path "secret/destroy/homelab/dev/jumpbox-cloud/login"  { capabilities = ["update"] }
path "secret/undelete/homelab/dev/jumpbox-cloud/login" { capabilities = ["update"] }

vault policy write jumpbox-login-read  jumpbox-login-read.hcl
vault policy write jumpbox-login-admin jumpbox-login-admin.hcl

vault auth enable userpass

# create users with scoped policies
vault write auth/userpass/users/richard \
  password="REDACTED1" \
  policies="jumpbox-login-read" \
  token_ttl="1h" token_max_ttl="4h"

vault write auth/userpass/users/admin_richard \
  password="REDACTED2" \
  policies="jumpbox-login-admin" \
  token_ttl="1h" token_max_ttl="8h"

  # richard should read OK, write FAIL
vault login -method=userpass username=richard
vault kv get secret/homelab/dev/jumpbox-cloud/login
vault kv put secret/homelab/dev/jumpbox-cloud/login admin_richard="nope"   # expect permission denied

# admin_richard should read/write OK
vault login -method=userpass username=admin_richard
vault kv put secret/homelab/dev/jumpbox-cloud/login admin_richard="newVal"
vault kv get secret/homelab/dev/jumpbox-cloud/login

# verify effective caps (KV v2 uses "data/*" paths)
vault token capabilities secret/data/homelab/dev/jumpbox-cloud/login

vault audit enable file file_path=/var/log/vault_audit.log
