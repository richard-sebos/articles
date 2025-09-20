

- in last article we looked at setting account  for different type of users for [account locks and expirations](https://richard-sebos.github.io/sebostechnology/posts/Users-Tiers/)
    - RF Guns
    - Application Users
    - Application Developers
    - System Adminstrators

- Now we are going to look at setting password criteria for these type users

## Why have different Password Strictions
- If one thing diveds user and IT professional like is password restrictions.
- Not all users have the same access and some user have critical access that a bad actions can uses to attacked the system
- Mantitor Access Control (MAC) or SELinux can help restrict what a users can access, password are still the front door to allow access to systems.
- Even as this article is been written different best partices are in place depending on your infrusture
    - If you have great log monitoring, then password restrictions as less important (what is the standard for this?)
- For now, we will use at least 12 character and a mix of lower, upper, numerics and special characters

## Stand Password setup
- Most major Linux system us PAM (Pluggable Authentication Modules) to handle password standard
- it uses `/etc/security/pwquality.conf` to set password restrictions with options like
```bash
minlen = 12 — Minimum total password length is 12 characters.
dcredit = -1 — Requires at least one digit.
ucredit = -1 — Requires at least one uppercase letter.
ocredit = -1 — Requires at least one special character (non-alphanumeric).
lcredit = -1 — Requires at least one lowercase letter.
```
- this allow restiction to be placed on all users
- the `pam_pwquality.so` in the `/etc/pam.d/system-auth` and `/etc/pam.d/system-auth`  is used to enforce password restictins
`password    requisite     pam_pwquality.so try_first_pass local_users_only retry=3 authtok_type=`
- But what if we wanted RF Guns to have different restrictions, example exclude special character

## Inline restrictions
- PAM allows for restictions to be specified in the `system-auth` and ` password-auth` files
- for `RF Guns` we  want
```bash
## this has 12 chars with lower, upper, and numerics but no special charactor
password    requisite     pam_pwquality.so try_first_pass local_users_only retry=3 minlen=12 dcredit=-1 ucredit=-1 lcredit=-1
```
- for `App Users` we want
```bash
## this has 12 chars with lower, upper, and numerics but no special charactor
password    requisite     pam_pwquality.so try_first_pass local_users_only retry=3 minlen=14 dcredit=-1 ocredit = -1 ucredit=-1 lcredit=-1
```
