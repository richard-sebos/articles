## Started by create a set uof keys

```bash

ssh-keygen -t ed25519 -f ~/.ssh/ca_user -C "User Signing CA"

```bash
-rw-------  1 sebos  staff  411 Jul  5 06:58 /Users/sebos/.ssh/ca_user
-rw-r--r--  1 sebos  staff   97 Jul  5 06:58 /Users/sebos/.ssh/ca_user.pub
```

- I did not add password but it would be a good thing

- Created a pair of keys for remote login

```bash
ssh-keygen -t ed25519 -f ~/.ssh/gcloud_user -C "gcloud access"
```

```bash
-rw-------  1 sebos  staff  399 Jul  5 06:59 /Users/sebos/.ssh/gcloud_user
-rw-r--r--  1 sebos  staff   95 Jul  5 06:59 /Users/sebos/.ssh/gcloud_user.pub
```

```bash
ssh-keygen -s ~/.ssh/ca_user \
  -I gcloud-access \
  -n richard \
  -V +1d \
  ~/.ssh/gcloud_user.pub


Signed user key /Users/sebos/.ssh/gcloud_user-cert.pub: id "gcloud-access" serial 0 for richard valid from 2025-07-05T07:05:00 to 2025-07-06T07:06:33
```

```bash
[info@instance-20250701-111537 ~]$ sudo mkdir -p /etc/ssh/trusted-user-ca
[info@instance-20250701-111537 ~]$ sudo vim /etc/ssh/trusted-user-ca/ca_user.pub
## I copied and paste the /Users/sebos/.ssh/ca_user.pub
[info@instance-20250701-111537 ~]$ sudo vim /etc/ssh/sshd_config
[info@instance-20250701-111537 ~]$ sudo systemctl restart sshd
```

- update the ssh config file to add 
```bash
Host ca-rhel
    HostName 34.134.227.140
    User richard
    IdentityFile ~/.ssh/gcloud_user
    CertificateFile ~/.ssh/gcloud_user-cert.pub
```

- from there it was to log in

ssh ca-rhel
