

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
- but we can have both at the same time or can we?

## Stack and  Substack
- A line inside a PAM module is a policy and a group of lines action together is a stack
- So the lines for RF Guns are a stack we can save together in a file called a substack `password-rf_guns`
```bash
# Enforce password quality (all users, including root)
password    requisite    pam_pwquality.so try_first_pass local_users_only retry=3 minlen=12 dcredit=-1 ucredit=-1 lcredit=-1 enforce_for_root

# Prevent password reuse (remember last 64 passwords, enforce for root too)
password    required     pam_pwhistory.so remember=24 enforce_for_root use_authtok

# Standard UNIX authentication with secure hashing
# If you want to allow empty passwords, add "nullok" — otherwise omit it
password    sufficient   pam_unix.so sha512 shadow try_first_pass use_authtok

# Safety catch — deny if nothing else matched
password    required     pam_deny.so
```
- inside of `system-auth` and `password-auth` we can added and the users `rf_guns` group has a different password criteria than the rest
```bash
# If the user is in rf_guns, run the rf_guns substack and default says jump next two lines
password    [success=ok default=2] pam_succeed_if.so user ingroup rf_guns
password    substack    password-rf_guns
password   [success=done default=ignore] pam_succeed_if.so user ingroup rf_guns

# Default branch (everyone else), failure above runs this code next
password   requisite   pam_pwquality.so retry=3 minlen=20 dcredit=-1 ucredit=-1 lcredit=-1 ocredit=-1 difok=5 enforce_for_root
password   required    pam_pwhistory.so remember=64 enforce_for_root use_authtok
password   sufficient  pam_unix.so sha512 shadow {if not "without-nullok":nullok} use_authtok
pa
```
- creating a substack fro users in app_users will create a password criteria from them  but added 
```bash

# If the user is in rf_guns, run the rf_guns substack
# (if requirement is met next line runs; substack file contains pwquality + pam_unix)
password    [success=ok default=2]        pam_succeed_if.so user ingroup rf_guns
password    substack                      password-rf_guns
password    [success=done default=ignore] pam_succeed_if.so user ingroup rf_guns

# If the user is in app_users, run the app_users substack
# (if requirement is met next line runs; substack file contains pwquality + pam_unix)
password    [success=ok default=2]        pam_succeed_if.so user ingroup app_users
password    substack                      password-app_users
password    [success=done default=ignore] pam_succeed_if.so user ingroup app_users

# Default branch (everyone else) — minimal example, put your real default policy here
password   requisite   pam_pwquality.so retry=3 minlen=20 dcredit=-1 ucredit=-1 lcredit=-1 ocredit=-1 difok=5 enforce_for_root
password   required    pam_pwhistory.so remember=64 enforce_for_root use_authtok
password   sufficient  pam_unix.so sha512 shadow {if not "without-nullok":nullok} use_authtok
password   required    pam_deny.so
```

## Is this Really Needed
- this was inspiture but a meeting I was in, good news is we ended up be able to do special character on the RF guns.
- if we had, we would have gone with no special characters and longer password.
- There will be cases where some group of users will needed either less criteria or more criteria and if you do not split the uses the all users have the same criteria.
- If that criteria weakens the password restriction for all users, make all users account easier to hack,
 
