

```bash

password required   pam_debug.so

password    [success=1 default=ignore] pam_succeed_if.so user ingroup rf_guns
password    requisite   pam_pwquality.so retry=3 minlen=12 difok=3  enforce_for_root
password    required    pam_pwhistory.so remember=36 enforce_for_root use_authtok
password    sufficient  pam_unix.so sha512 shadow use_authtok
password sufficient pam_permit.so

password    [success=1 default=ignore] pam_succeed_if.so user ingroup app_users
password    requisite   pam_pwquality.so retry=3 minlen=14 difok=4  enforce_for_root
password    required    pam_pwhistory.so remember=36 enforce_for_root use_authtok
password    sufficient  pam_unix.so sha512 shadow use_authtok
password sufficient pam_permit.so

password    [success=1 default=ignore] pam_succeed_if.so user ingroup app_devs
password    requisite   pam_pwquality.so retry=3 minlen=16 minclass=4 difok=4 enforce_for_root
password    required    pam_pwhistory.so remember=36 enforce_for_root use_authtok
password    sufficient  pam_unix.so sha512 shadow use_authtok
password sufficient pam_permit.so

# --- Default (system admins and everyone else) ---
# strongest policy
password    requisite   pam_pwquality.so retry=3 minlen=20 dcredit=-1 ucredit=-1 lcredit=-1 ocredit=-1 \
                                        difok=5 enforce_for_root
password    required    pam_pwhistory.so remember=64 enforce_for_root use_authtok

# Final apply
password    sufficient  pam_unix.so sha512 shadow {if not "without-nullok":nullok} use_authtok
passwor

```
