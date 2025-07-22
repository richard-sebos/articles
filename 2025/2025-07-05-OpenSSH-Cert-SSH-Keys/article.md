# Expiring SSH Auth Keys

- With brute force attacked trying to break into server, SSH auth becase of way of stopping these attacks.
- When create a set of SSH Auth keys, you create a private key that is store on the device you are using and a pub key that is store onn a remote device to log into.
- When you SSH into a into the remote server, the two keys are used to validate the log into
- Sounds simple enough, what is the issue?

## Security Issues with SSH Auth
- SSH key are simple to create and it is one for the first thing I learnt about Linux Admin but SSH keys do not expire just  using ssh-keygen.
- If private get gets into the wrong hands, they that uses has access to all the device the public is setup.
- How can we expire SSH keys

## Started by create a set for keys
- the first step is to create a an OpenSSH key to act like a Signing CA
```bash
## -t for OpenSSH Key type
## -f for file name
## -C for commit
ssh-keygen -f ~/.ssh/ca_user -t rsa -b 4096 -C "SSH CA G-110940"

```
- we need to store the certificate on the remote serverr
```bash
sudo mkdir /etc/ssh/trusted-user-ca/ ## used to store cert

## you can either scp the pub cert of or create the file on the server
## I am creating the file and 
## Copy and paste ca_key.pub just create
nano /etc/ssh/trusted-user-ca/ca_key.pub
```
- on the remote server, we need to change the sshd_config file to use the Sign CA public key
```bash 
nano /etc/ssh/sshd_config

## added line
TrustedUserCAKeys /etc/ssh/trusted-user-ca/ca_key.pub
```

```bash
sudo systemctl restart sshd
```

## Create SSH key
- we create a set of SSH auth keys like we normally would
```bash
## -t for OpenSSH Key type
## -f for file name
## -C for comm
ssh-keygen -f ~/.ssh/G-110940 -t rsa -b 4096 -C "SSH Key G-110940"

```

- now we signed the gcloud_user.pub

```bash
## -s Specifices the CA private key to use
## -I Set identity label for cert
## -n user name on cert
## -V time period the cert is valid for 
ssh-keygen -s ~/.ssh/ca_user \
  -I ca-signed-access \
  -n richard \
  -V +1d \
  ~/.ssh/G-110940.pub

Signed user key /Users/sebos/.ssh/G-110940-cert.pub: id "ca-signed-access" serial 0 for richard valid from 2025-07-13T09:43:00 to 2025-07-14T09:44:57
```
- a new file called `~/.ssh/G-110940-cert.pub` will be created, we use that file in the SSH call

```bash
ssh -i ~/.ssh/G-110940 -o CertificateFile=~/.ssh/G-110940-cert.pub richard@34.27.255.12

```

- or update the ssh config file to add 
```bash
Host oracle-server
    HostName 34.27.255.12
    User richard
    IdentityFile ~/.ssh//G-110940
    CertificateFile ~/.ssh/G-110940-cert.pub
```

- from there it was to log in

ssh ca-rhel

## So why do this
- In a word, security.
- The expiration date will expire a key.
- Keys will short shelf life descrase the time a melisious uses can use them if they get out.
- when the key expires, a new key can be generates on the local machine with out changes to the server
- if the local device take lost or stolen, removing the cert from the server stop the SSH auth key log in from working

## Just in Time (JIT) Logins
- if you homelab or company does have a Just in Time (JIT) application to create credital, this could be used to create one
- A thrid system could be used to create the signed creditals that expire in. 8 to 24 hours and scp the to your local device
- You would be able to access the remote server until the creditals expire
- This gives you the access you need while securing the server.


- Over the last year, I looked at different ways to protect the SSH server.  
- Of everything thing I've seems so far, the has been the easies away to increase the SSH connection.
- If you had a Linux server setup to only accept SSH auth key, and you can make those auth active only when needed in let than a minute, why wouldn't you?




```bash
#/bin/bash
export SCRIPT_DIR=~/.ssh/includes.d/ca_keys
export SIGN_DIR=${SCRIPT_DIR}/signing
export SSH_KEY_DIR=${SCRIPT_DIR}/keys


mkdir -p ${SIGN_DIR}
ssh-keygen -f ${SIGN_DIR}/ca_user -t rsa -b 4096 -C "SSH CA G-110940 "


## add  {SIGN_DIR}/ca_user.pub /etc/ssh/trusted-user-ca/
cat ${SIGN_DIR}/ca_user.pub
pause
## add TrustedUserCAKeys /etc/ssh/ca_user.pub - sshd_config
mkdir -p ${SSH_KEY_DIR}
ssh-keygen -f ${SSH_KEY_DIR}/ca_user -t rsa -b 4096 -f ${SSH_KEY_DIR}/G-110940 -C "SSH Key G-110940 "

## Signed the keys 
ssh-keygen -s ${SIGN_DIR}/ca_user \
  -I G-110940 \
  -n richard \
  -V +11d \
  ${SSH_KEY_DIR}/G-110940.pub

cat << 'EOF' >${SCRIPT_DIR}/config
Host oracle-server
    HostName 34.63.32.39
    User richard
    IdentityFile ${SSH_KEY_DIR}/G-110940
    CertificateFile ${SSH_KEY_DIR}/G-110940-cert.pub
EOF
```
