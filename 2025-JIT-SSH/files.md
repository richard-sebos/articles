jit_ssh/
├── ca/
│   ├── ca_user_key        # Private SSH CA
│   └── ca_user_key.pub    # Public SSH CA
├── db/
│   └── users.yaml         # username, password hash, TOTP secret
│   └── tickets.sqlite     # logging access requests
├── keys/
│   └── temp_keys/         # Store ephemeral user keys
├── main.py
├── mfa.py
├── ssh_ca.py
├── ticketing.py
└── user_auth.py
