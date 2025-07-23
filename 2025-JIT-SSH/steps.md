- One of the nice things about a layered security approach,  being able to contect the piece of the the layers to create a strong security system without a lot of extra work
- I would like to take a few different topic I've done recently and bring them together to create a JIT credential system for Linux
- There will be additional code, but the code was simple enough to create.

## JIT Credential
- Just-in-Time (JIT) credential, created access credential as need and for some short time period.
- Just long enough to do a setup of work or for some short fix time
- In this article, we will look a create this for a Bastion box to access the VM on a Proxmox VE server
- With the including of restricted users, MFA and logging why access us needed, <something>

- created bastion host on PVE
- Add firewall rules to all laptop access to that host
- created OpenSSH CA Keys
- created restricted user
    - no password created
- add ca key to SSH
- created code to make 
    - MFA
    - Register user on ticketing
    - Create logging to checkout ssh key
