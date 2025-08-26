
### **1. Introduction**

- With SSH being one of the primary attach vectors, it is critical to hardening it
- If your luck, you are working for a company that has a standard sshd_config file that needs to be review from time to time
- In most cases, you either have:
  - different SSH use cases for each server
  - server that just have the default setting
  - a project start with new server and you want to start standard going forward.
- So why is it like this

## The Default Config
- The default config for SSHD is a powerful document with lots of options
- It documents the options for the server, which more applications should do
- It also can make it overwelling for new users
- Depending on the version of Open SSH you have, mine default had 129 and only 3 were not commented out. 
- What to do with all those comments?
 
## Modular SSH Configuration Design**
- As an ex-programmer I was conditioned to break things into modules
- Group like task and structuring it
- I done the same thing with SSH server builds and it gives me
  * Consistent security policy enforcement.
  * Easier updates and environment-specific customization.
  * Role-based structure for reusability:

- Is it the best or right thing to do? 
- No most likely not, but it works for me and I like consistent resutls

- Break down `/etc/ssh/sshd_config` into logical `.conf` files using `Include`.
- Key config files include:

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

- Doesn't this make deployments harder?

## Ansible Role Design and Layout**
- I create an Ansible Role to help with the deploy
- It breaks the above files into
  ```
  roles/build_ssh/
  ├── files/        → Base config (sshd_config)
  ├── templates/    → Templated config files (.j2)
  ├── default/         → Centralized variables
  ├── tasks/        → Main logic
  ├── handlers/     → Restart handler
  ```
- `files` - static conf files that normally do not change that often
- `templates` and defaults are used to dymicly create conf file that change off
  - example used for files requiring customization (e.g., crypto, session, access control).
- `tasks` is where the main Ansible code is
- `handlers` is used to restart the SSH server

- This allows to build and save custom SSH server config and create standard
- It also allows to make customer SSH configuration based in prior standard to speical needs
---

### **10. Conclusion**

* This Ansible-based approach provides a production-grade SSH security baseline.
* Modular config makes management and compliance easier.
* Centralized control and strict permissions protect critical infrastructure access.
* Next steps:

  * Integrate into CI/CD or GIT-driven change pipeline.
  * Add audit/monitoring for access patterns.

