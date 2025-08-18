Here’s a new article outline that encompasses everything we've discussed — from modular SSH config to full Ansible integration with centralized variables, templates, and secure deployment:

---

## **Title: End-to-End SSH Hardening with Ansible: Modular Config, Templates, and Centralized Variables**

---

### **1. Introduction**

* SSH is a primary access method and a key attack vector — hardening it is essential.
* Manual SSH config is error-prone and difficult to scale.
* Using Ansible with modular SSH configs, templating, and variable-driven logic ensures:

  * Consistent security policy enforcement.
  * Easier updates and environment-specific customization.
  * Root-only secure deployment.

---

### **2. Modular SSH Configuration Design**

* Break down `/etc/ssh/sshd_config` into logical `.conf` files using `Include`.
* Key config files include:

  * `04-logging.conf` — verbose logging, SyslogFacility.
  * `05-banner.conf` — custom login warnings.
  * `06-session.conf` — session timeouts, keepalives, throttling.
  * `07-authentication.conf` — auth methods, PAM, user limits.
  * `08-access-control.conf` — IP- and group-based restrictions.
  * `10-forwarding.conf` — default deny on tunnels and agents.
  * `11-admin-exceptions.conf` — scoped exceptions for trusted admins.
  * `20-mfa.conf` — public key + PAM 2FA.
  * `30-High-Vol.conf` — support for large-scale login bursts.
  * `40-crypto.conf` — modern crypto suite.
  * `99-hardening.conf` — miscellaneous flags.

---

### **3. Ansible Role Design and Layout**

* Role-based structure for reusability:

  ```
  roles/ssh_hardening/
  ├── files/        → Base config (sshd_config)
  ├── templates/    → Templated config files (.j2)
  ├── vars/         → Centralized variables
  ├── tasks/        → Main logic
  ├── handlers/     → Restart handler
  ```
* Templating used for files requiring customization (e.g., crypto, session, access control).

---

### **4. Centralized Configuration with Variables**

* Define everything in `vars/main.yml`:

  * Allowed address ranges and groups.
  * Session parameters and limits.
  * MFA toggles and banners.
  * Crypto policies (Kex, Ciphers, MACs).
* Benefits:

  * Manage environment differences easily.
  * Enable/disable features conditionally.
  * Prevent hardcoding sensitive or dynamic config.

---

### **5. Secure File Deployment with Root-Only Access**

* Enforce strict file permissions with:

  ```yaml
  mode: '0600'
  owner: root
  group: root
  ```
* Applies to all `.conf` files and the SSH banner.
* Prevents tampering or unauthorized reads of SSH policy.

---

### **6. Banner Deployment**

* Banner managed via variable (`ssh_banner_content`) and deployed to `ssh_banner_file`.
* Used in `05-banner.conf` to warn users and enforce compliance notices.

---

### **7. Sample Templated Configs**

* **07-authentication.conf.j2**: dynamically sets MaxSessions, MaxAuthTries, AllowGroups.
* **08-access-control.conf.j2**: injects Match blocks from allowed IP ranges.
* **30-High-Vol.conf.j2**: defines MaxStartups from vars.
* **40-crypto.conf.j2**: defines modern crypto suite with Kex, Ciphers, MACs.

---

### **8. Config Validation and Safe Restarts**

* Validate `sshd` config before restart:

  ```yaml
  command: sshd -t
  ```
* Use Ansible handlers to restart `sshd` only on changes.
* Keep existing SSH session active during testing to avoid lockout.

---

### **9. Benefits of This Approach**

* Complete SSH hardening is now:

  * Modular.
  * Customizable via vars.
  * Enforced and audited via automation.
* Security improvements:

  * Principle of least privilege.
  * Dynamic policy without manual file edits.
  * Secure defaults and rollback safety.

---

### **10. Conclusion**

* This Ansible-based approach provides a production-grade SSH security baseline.
* Modular config makes management and compliance easier.
* Centralized control and strict permissions protect critical infrastructure access.
* Next steps:

  * Integrate into CI/CD or GIT-driven change pipeline.
  * Add audit/monitoring for access patterns.

---

Would you like this turned into a downloadable Markdown or HTML article draft?
