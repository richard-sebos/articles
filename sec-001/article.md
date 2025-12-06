# RHEL Crypt Policy

## Intro
- in a recent project I needed a Linux RHEL 9  server to talk to an older Windows server
- One of the advanges of have a home lab is being able to control the version of OS/software you can use
- When you get into small to medium size business it comes hard to for secure changes
- As you get into enterprise level business, you can get into critical business application where the cost and downtime to upgrade thoes system become chancing.
- Most security professional would want to change the Windows server but you can't always to that in the real world.
- Sometime you need to secure the network and users access them.
- Does this mean you lower the security around them?
- What if you want to have a secure Linux system talk to less secure servers?

## RHEl and `update-crypto-policies`
- the `update-crypto-policies` is a command to set the server over all policy level across a number of application for a device
- It does it for all security related programs like the below and more
  - OpenSSL
  - GnuTLS
  - OpenJDK
  - Libssh, OpenSSH
  - Kerberos (GSSAPI)
- It comes with well defind policies like
  - `LEGACY` loosens security so older servers and applications
  - `DEFAULT` balanced security and compatibility
  - `FIPS` strict U.S. government–approved crypto
  - `FUTURE`  higher security than today (“prepare for tomorrow”)
- Having standard policies means you can deploy across multiple enviroments and still get the save security level.
- Our goal was to run the server at a `FIPS` level of security.
- When we tested with the older but still secure server, we needed to drop to 'LEGACY` to get it to work.
- So does this means `FIPS` was now out of scope?

## Custom Policies 
- One of the nice features of `update-crypto-policies` is you can create a custom policy.
- You can take an existing policy like `/usr/share/crypto-policies/policies/FIPS.pol` and save it to `/etc/crypto-policies/policies/CUSTOMER`.
- 
