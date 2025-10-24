Great — here’s a list of **safe and useful `xl` commands** for inspecting and interacting with the Xen hypervisor from **Dom0 in Qubes OS**, with explanations:

---

### 🔹 **Inspection & Monitoring**

| Command           | Description                                                                 |
| ----------------- | --------------------------------------------------------------------------- |
| `xl info`         | Displays basic info about the Xen hypervisor, version, CPU, memory, etc.    |
| `xl list`         | Lists all running VMs (domains), including their states and resource usage. |
| `xl uptime`       | Shows how long each domain has been running.                                |
| `xl top`          | Real-time resource usage per VM (like `top` for Xen domains).               |
| `xl dmesg`        | View hypervisor log buffer (e.g., boot logs, driver info, errors).          |
| `xl sched-credit` | View scheduling info (useful to understand vCPU weights).                   |

---

### 🔹 **Debugging / Deep Inspection**

| Command                         | Description                                                                |
| ------------------------------- | -------------------------------------------------------------------------- |
| `xenstore-ls`                   | Lists XenStore keys — a low-level inter-domain communication/config store. |
| `xenstore-read /vm/DOMAIN_NAME` | Read specific XenStore entries for a domain.                               |
| `xl debug-keys h`               | Prints help for Xen debug keybindings (useful for diagnostics).            |

---

### 🔹 **Advanced / Use With Caution**

| Command              | Description                                                             |
| -------------------- | ----------------------------------------------------------------------- |
| `xl destroy VMNAME`  | Forcefully terminates a VM. Use only if `qvm-kill` fails.               |
| `xl create`          | Manually create a VM from an XML or config file (rarely used in Qubes). |
| `xl shutdown VMNAME` | Graceful shutdown. Safer to use `qvm-shutdown` in Qubes.                |

---

### ✅ **Best Practices in Dom0**

* Use `xl` only for **read-only inspection** unless you're troubleshooting something deeply.
* For normal VM operations, stick to `qvm-*` tools (they respect Qubes OS security models).
* Never copy/paste unknown commands into Dom0 — verify scripts before running.

---

Would you like a script to log Xen hypervisor stats daily or help interpreting any specific `xl` output?
