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
