- One of the nice things about a layered security approach,  being able to contect the piece of the the layers to create a strong security system without a lot of extra work
- I would like to take a few different topic I've done recently and bring them together to create a JIT credential system for Linux
- There will be additional code, but the code was simple enough to create.

## JIT Credential
- Just-in-Time (JIT) credential, creates access credential as need and for some short time period.
- Just long enough to do a setup of work or for some short fix time
- In this article, we will look at create this for a Bastion box to access the VM on a Proxmox VE server
- With the including of restricted users, MFA and logging while access us needed, this will be combined to create a security policy

## Sets Needed, 
- I created a new VM on my Proxmox VE to use as a jumpbox(bastion box)
    - To start it was just a Oracle Linux 9 server with a mininaul instatllion done
- Add firewall rules to all laptop access to that host
    - I have a OpnSense firewall and my Proxmox PE server and they VMs created are on a seperate VLAN (VMNet)
    - I gave my laptop  on VLAN HomeNet access to the just the jumpbox
- created restricted user
    - On the bastion server, I created two users
        - richard
        - admin_richard
    - richard is the restricted user and has SSH access to the server
    - admin_richard has sudo access but cannot log via SSH     
- add ca key to SSH
    - I created a set of OpenSSH key to be used as CA cert
- The public key for the OpenSSH key was moved to the bastion box
- the SSH server was then changed to use the OpenSSH CA

## JIT App
- I create a small Python app to administrate the SSH credentials.
- First you need to create a MFA token to use with the app
- It uses the Autheniticator app on my phone to verify access
- run `   ` to generate a new TOTIP token
- It will provide a secret code string to add to the app

- The app registers a user and secret code to create a login
- It generates a password for that user
- to get a to bastion box you need to run `  ` and login with MFA token and password
- it will then ask why access is needed and once provided, it will generate SSH keys to log in
- the app will then provide an SSH connection command you can use to connect to server
- For my testing, I had it set access set for 15 minute afterwards the SSH key will not longer work
- Note: this access time is only for logging into the server. Once logged in, you have access after that timeout until you logout

## Access Report
- An access report can be generated to see who has requested access and why
- The report only notes access to the bastion server and not the servers behind it
- SIEM like tools (Security Information and Event Management) like Wazun, ELK Stack or Graylog can be uses to verify what was access

## So why do this
- Prior to setting this up, my home laptop was a critical failure point
- It had all my SSH keys store and if lose, I would have to rebuild access to all my servers
- Worst, it could be used to attack all my other servers since the SSH auth keys were installed it it
- Now, the bastion host will be my jump server and not my desktop
- To get to the bastion box, you need access to the CA Cert and SSH Auth key
- The app gives me access but I need a password and MFA to generate SSH keys
- With the short life of the SSH keys, even if the private key gets out, you can not access a server with it for very long.

## Is Overkill or Useful
- In a small homelab, a lot of security is overkill but it doens't take long before small labs grow
- The same procedure and Python scripts can be used in a small business to increase the security
- In a larger company, deicated third part apps would work.
- The important think is to have the security options
- Plus, I've found most overkill security opions seem less overkill when a breach is stopped
- No one security layer can stop an attacker, but if there are enough layers, it can slow them down or get them to go after easier targets.
