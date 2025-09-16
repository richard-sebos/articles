
- this works for first stack but not the second one

```bash
# --- rf_guns branch ---
password    [success=6 default=ignore] pam_succeed_if.so !user ingroup rf_guns use_uid
password    requisite pam_pwquality.so retry=3 minlen=15
password    required    pam_pwhistory.so remember=36 enforce_for_root use_authtok
password    sufficient  pam_unix.so sha512 shadow use_authtok
password    required    pam_deny.so
password sufficient pam_succeed_if.so 1=1

# --- app_users branch ---
password    [success=6 default=ignore] pam_succeed_if.so !user ingroup app_users use_uid
password    requisite pam_pwquality.so retry=3 minlen=14
password    required    pam_pwhistory.so remember=36 enforce_for_root use_authtok
password    sufficient  pam_unix.so sha512 shadow use_authtok
password    required    pam_deny.so
password sufficient pam_succeed_if.so 1=1

password    required    pam_deny.so
```
