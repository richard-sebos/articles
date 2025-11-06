Excellent question — that line goes inside your **`~/.ssh/config`** file (the SSH client configuration file), but it must be placed **after any global directives** and **before or after other `Host` blocks**, depending on what you’re trying to match.

Let’s go through it carefully so you can see the correct structure and placement.

---

## 🗂️ File: `~/.ssh/config`

If it doesn’t exist yet, create it:

```bash
touch ~/.ssh/config
chmod 600 ~/.ssh/config
```

---

## ✅ Example Layout

Here’s a **clean, secure example** tailored for your Claude Qube setup:

```bash
# ===============================
#  SSH Configuration for GitHub
# ===============================

# Default SSH behavior
Host *
    ForwardAgent no
    ForwardX11 no
    IdentitiesOnly yes
    ServerAliveInterval 60
    ServerAliveCountMax 2

# Restrict usage of a specific SSH key to a single repo
Match host github.com exec "grep -q 'git@github.com:YourOrgOrUser/YourRepo.git' '%C'"
    IdentityFile ~/.ssh/id_claude_qube
    IdentitiesOnly yes
    ForwardAgent no
```

---

## 🧩 Explanation

### 🔹 `Match` block

This is a **conditional section** in your SSH client config.
It applies settings only when the given conditions match.

* `host github.com` → Only applies when connecting to GitHub
* `exec "grep -q 'git@github.com:YourOrgOrUser/YourRepo.git' '%C'"` →
  Runs a command that must return **0 (true)** for the block to apply.
  The `%C` variable expands to a hash derived from the connection parameters, which can include the hostname, username, and key fingerprint.

*(You can also use `exec` to check `$SSH_ORIGINAL_COMMAND` or other context, but `%C` works safely for repo URL matching.)*

### 🔹 `IdentityFile`

Specifies which private key to use for that repo.

### 🔹 `IdentitiesOnly yes`

Ensures SSH won’t try other keys from your agent — only the one you’ve specified.

---

## 🧠 Simpler Alternative (if you want per-repo control without `Match exec`)

If the `exec` syntax feels too brittle, you can use **Deploy Keys** in GitHub (recommended for simplicity and security):

```bash
Host github.com-yourrepo
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_claude_qube
    IdentitiesOnly yes
```

Then clone your repo using the alias:

```bash
git clone git@github.com-yourrepo:YourOrgOrUser/YourRepo.git
```

This approach is easier to manage and avoids the need for `Match exec` logic.

---

## 🔐 Security Notes

* Ensure `chmod 600 ~/.ssh/config` and `chmod 600 ~/.ssh/id_claude_qube`.
* Don’t use `ForwardAgent yes` — keep it isolated.
* Keep your YubiKey key separate and hardware-enforced if possible.

---

Would you like me to show you both **(a)** the simple deploy key version and **(b)** the advanced “`Match exec` restricted” version together in one combined, production-safe config for your Qube?
That way you can pick which style fits best.
