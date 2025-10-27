# *Securing Samba at the Global Level: Controlling the Server’s DNA*


When I first got into IT, I was all about planning. I’d spend hours researching, mapping everything out, and building the “perfect” install plan before touching anything. But, like most people find out sooner or later, things rarely go exactly as planned. There was always some hiccup that meant going back and tweaking things. These days, I take a more practical approach—working step by step, making sure things are stable before moving forward. It’s less about perfection upfront and more about building confidence as I go.

In the first part of this series, we got Samba up and running with a basic file share. That laid the groundwork. In this next part, we’re going to focus on security—specifically by tightening up the `[global]` section of the config. We’ll cover things like authentication settings, protocol restrictions, and general best practices to help lock things down and keep your Samba setup more secure.



## 1. Introduction – “The Root of Trust Lives in [global]”
- Samba config file `smb.conf` is broken into two blocks:
   - global - the section that specifies global directives for all shares
   - share - it configures the share specific directives that override the defaults and global directives
   - why have both?
   - `global` allow you to set as baseline policy of minimal standard that can be set for one Samba server or adpoted as a standard across different Samba servers
   - `share`  allow you to tighen or losen security as needed for indiviual shares

## Starting Baseline
- we started with a very basic 
```ini
[global]
   ## Sets the NetBIOS workgroup name for the Samba server.
   workgroup = WORKGROUP

   ## Enables per-user authentication 
   security = user

   ## This tells Samba to map failed login attempts (invalid users) to the guest account.
   map to guest = Bad User
```
- there is not alot of security here and leaves gaps open that need to be closed.

## SMB Protocol and Encryption
- The SMB protocol is the protocol the SMB client uses to talk to the Samba server
- Older version of Windows may need a older version of SMB protocal but global we will start with
```ini
   server min protocol = SMB3
   server max protocol = SMB3_11
```

| Version         | Status       | Recommended?          | Why/Why Not                                                       |
| --------------- | ------------ | --------------------- | ----------------------------------------------------------------- |
| **SMB1**        | **Obsolete** | ❌ **Never**           | No encryption, vulnerable to **WannaCry**, no signing enforcement |
| **SMB2.0/2.1**  | **Legacy**   | 🔶 **Only if needed** | Better than SMB1, but lacks encryption                            |
| **SMB3.0/3.02** | **Modern**   | ✅ **Yes**             | Adds AES encryption + signing                                     |
| **SMB3.1.1**    | **Current**  | ✅ **Preferred**       | Adds pre-auth integrity, supports **TLS**, and better encryption  |

- if needed, shares change override to lower if there is a special need
- Let start addeding encryption
```ini
   smb encrypt = required
   server signing = mandatory
   client signing = mandatory
```
| Setting                       | Purpose                            | Enforced?                     |
| ----------------------------- | ---------------------------------- | ----------------------------- |
| `smb encrypt = required`      | Requires AES encryption (SMB3+)    | ✅ Yes                         |
| `server signing = mandatory`  | Requires integrity protection      | ✅ Yes                         |
| `client signing = mandatory`  | Samba must sign its client traffic | ✅ Yes (if used as client)     |
| TLS Encryption (SMB over TLS) | Full session encryption (TLS)      | ❌ No (needs `smbtls` + certs) |

## User Restrictions
- The simple config file was using `security = user` and since we don't have an Active Directory or Kerberos setup, we will stay with it.
- To seperate the OS log in with the Samba login, we will use `passdb backend = tdbsam` we will also make sure the user can not log into a terminal

```ini
   security = user
   passdb backend = tdbsam
   map to guest = never
   restrict anonymous = 2
```



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

