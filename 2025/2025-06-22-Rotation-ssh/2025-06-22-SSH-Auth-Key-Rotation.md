# SSH Authentication Key Rotation: Why and How to Expire SSH Keys
## Introduction

When setting up a new Linux server, it's common practice to configure SSH authentication using public keys. Often, these keys are reused indefinitely—sometimes for weeks, months, or even years. While SSH keys provide a robust layer of security, they can also introduce risk if not managed properly. Unlike passwords, SSH keys are not usually rotated or set to expire, leading to a false sense of long-term security.
## Table of Contents

1. [Introduction](#introduction)
2. [How SSH Keys Work](#how-ssh-keys-work)
3. [Do SSH Keys Expire?](#do-ssh-keys-expire)
4. [Using `AuthorizedKeysCommand` to Enforce Key Expiration](#using-authorizedkeyscommand-to-enforce-key-expiration)
5. [How the Expiry Script Works](#how-the-expiry-script-works)
6. [Are These Keys Truly Expired?](#are-these-keys-truly-expired)
7. [Conclusion](#conclusion)


Although a private SSH key that remains secret does offer strong protection, best security practices dictate that all credentials, including SSH keys, should be rotated periodically. This guide explores methods for enforcing SSH key expiration and how to implement key rotation strategies for improved security hygiene.

---

## How SSH Keys Work

SSH key-based authentication relies on a key pair generated on the client system. The private key remains securely stored on the client machine, while the corresponding public key is placed on the server in the user's `~/.ssh/authorized_keys` file.

When a client attempts to log in, the SSH server checks if the provided private key matches any of the public keys stored in the `authorized_keys` file. If a match is found and all configurations are valid, the login proceeds without requiring a password.

---

## Do SSH Keys Expire?

Out of the box, OpenSSH does not support key expiration. This means that once a key is added to the `authorized_keys` file, it remains valid indefinitely—unless manually removed. While this simplifies administration, it introduces long-term risk if keys are not rotated regularly.

A more advanced approach involves SSH Certificate Authorities (CAs), which can issue keys with built-in expiration dates. However, implementing a CA setup adds complexity and may not be necessary for smaller environments. In this article, we'll explore a lighter alternative using `AuthorizedKeysCommand`.

---

## Using `AuthorizedKeysCommand` to Enforce Key Expiration

The OpenSSH server configuration (`sshd_config`) includes directives for managing how authorized keys are retrieved. By default, SSH checks the user's `.ssh/authorized_keys` file. However, you can override this behavior:

```bash
# Disable default authorized_keys lookup
AuthorizedKeysFile none

# Use custom script to retrieve keys dynamically
AuthorizedKeysCommand /usr/local/bin/ssh-key-expiry-check
```

This setup disables static file lookups and instead invokes a script that determines which keys are valid based on expiration dates defined in a structured data file.

---

## How the Expiry Script Works

The expiration script uses a JSON file located at `/etc/ssh/user_keys.json`. This file lists each system user, their associated public keys, and an expiration date for each key.

Example JSON structure:

```json
{
  "richard": [
    {
      "key": "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICn4EzI2g9gqlWCw6V1jvysZiO5tKLn/zbUalRWJRL3o sebos@dockOnWall.sebostechnology.local",
      "expires": "2025-08-01"
    }
  ]
}
```

The script, invoked by the SSH daemon, filters keys for the given user and returns only those that have not yet expired:

```bash
USER="$1"
KEYS_FILE="/etc/ssh/user_keys.json"

jq -r --arg user "$USER" '
  .[$user][] |
  select((.expires | strptime("%Y-%m-%d") | mktime) >= now) |
  .key
' "$KEYS_FILE"
```

If a key matches the client's private key and has not expired, SSH grants access. If all keys are expired, access is denied:

```bash
ssh rockey
Received disconnect from UNKNOWN port 65535:2: Too many authentication failures
Disconnected from UNKNOWN port 65535
```

---

## Are These Keys Truly Expired?

This solution offers **soft expiration**, not enforced cryptographically. Keys are still technically valid and could be reused if re-added or if the configuration is reverted. However, this method offers a lightweight, controllable approach for environments that don’t require full CA integration.

It's especially useful when:

* You need to add expiration policies to existing keys.
* You're managing a small number of servers or users.
* You want a reversible and low-risk method to improve SSH key lifecycle management.

> **Note:** Before deploying this change, ensure you have an alternative login method (e.g., console or secondary key) to avoid locking yourself out.

---

## Conclusion

Rotating SSH authentication keys is a critical part of maintaining secure access to Linux servers. While OpenSSH doesn’t natively support key expiration, using `AuthorizedKeysCommand` with a custom script allows administrators to implement soft key expiry. For higher security environments, consider transitioning to SSH certificate-based authentication, which includes built-in expiration and stronger validation mechanisms.

Implementing even basic key rotation mechanisms helps enforce better operational security and minimizes long-term exposure due to stale or forgotten SSH keys.

