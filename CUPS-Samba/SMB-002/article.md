# *Securing Samba at the Global Level: Controlling the Server’s DNA*
- Earily on in my IT caree, I was a planner.
- I like to do a bit of research build plan to implement a install and excutue the install
- The plan rearly worked and there was a bit of rework needed
- Today I use more of a interit aprroach, moving from working safe point to safe point.
- In the first part of this series, Samba as installed and a simple share was created.
- The next section will add 
- In the first part of this series a simple Samba server was setup to verify the base configuration was working.
- Security was minimal and needs to be setup
-

## 🗂️ Outline

### 1. Introduction – “The Root of Trust Lives in [global]”

* Explain that Samba’s global section defines its *trust perimeter*.
* Contrast legacy SMB1 setups vs modern SMB3/SMB signing.
* Brief ProofTrail note: *“The [global] section is your system’s declaration of intent — we’ll be treating it as verifiable policy.”*

### 2. Step 1 – Inspecting Your Baseline

```bash
testparm -sv | grep -E "protocol|min|max|sign|encrypt"
```

* Show output and identify weak defaults.
* Emphasize baseline collection — “before you harden, you measure.”

### 3. Step 2 – Modernizing Protocols

```ini
[global]
   server min protocol = SMB3
   server max protocol = SMB3
```

* Explain why SMB1 is dangerous.
* Verify with `smbstatus` or `smbclient -L localhost -m SMB3`.

### 4. Step 3 – Enforcing Encryption and Signing

```ini
[global]
   smb encrypt = required
   server signing = mandatory
```

* Discuss CPU cost vs data integrity.
* ProofTrail tie-in: “Signatures turn your network traffic into verifiable artifacts.”

### 5. Step 4 – Restricting Guest and Anonymous Access

```ini
[global]
   map to guest = never
   restrict anonymous = 2
```

* Explain privilege boundaries and audit trail implications.

### 6. Step 5 – Defining Access Policies

```ini
[global]
   hosts allow = 192.168.1.0/24
   hosts deny  = ALL
```

* Show how containment can start at the IP layer.
* Mention the concept of “known-good subnets.”

### 7. Step 6 – Verification & Testing

```bash
testparm -s
sudo smbcontrol all reload-config
sudo smbstatus
```

* Verify enforcement and reload configs.

### 8. Step 7 – Logging & Monitoring

* Discuss `/var/log/samba/log.smbd`.
* Show how to grep for connection attempts.
* Link to upcoming ProofTrail log verification.

### 9. Lessons Learned

* Security begins with clear boundaries.
* “If it’s not in `[global]`, it’s an exception you should explain.”

### 🧩 ProofTrail Note

> “The `[global]` section defines your root policy — everything else inherits from it. In ProofTrail terms, this is your first *hash in the chain*.”

---

