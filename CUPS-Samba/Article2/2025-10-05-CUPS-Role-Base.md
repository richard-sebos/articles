

- In [last article](https://richard-sebos.github.io/sebostechnology/posts/CUPS/) I introduced what CUPS and how, even in this digital age, print is still used to drive business process
-  In this one, we start looking at CUPS users setup and how Role-Based Access Control (RBAC) can be used to increase the security of CUPS.
- RBAC, in its simple terms is restricting what a users por group of users can do bases on what they need to do or or required level of access withing the device, system or application.
- Why is this needed?

## RBAC and CUPS
- A good what to look at what RBAC can do is by example.
- Let break the CUPS task into three roles
    - End user: could be casher manager or leader of a team in warehouse that eith manually or automatic through application prints doucments out
        - They are normally near the printer
        - Want to verify the job was sent to the printer if printing takes to long
        - Reprint if jobs misprints or is missing
    - Help Desk: Entry point for printer issues that end users cannot resolve
        - This could including moving jobs to a different printer
        - Cancal All job pending on a printer
        - can do most things users can
    - Admin: Second level support to back the help desk
        - Centralized resource that maintinace and configures one or more CUPS for and enterprise
        - add and remove printers
        - logs through logs to see what printers have stop working
        - can do thing that both help desk and user can do

- each of these users would have different access under RBAC with end users with the lease access and admins with the most.
- RBAC doesn't decide who is more or less important since with out end uses, help desk and admins are not needed, without admins there are not systems for help desk and end users to use and help desk is needed because i've known a few admin that should never ever talk to end users.

## CUPS users
- CUPS allows users to be either Basic, Digest or Kerberos depending on your version of CUPS.
- Digest, depending on your version could be depecated and Kerberos needs a Active Directory type user authentication so I will be using Basic for these examples
- Under Basic, CUPS uses the default Linux user authnicator to validate users
- The Linux users will be assigned to groups and those group will be used by CUPS to allow access to different features
    - cups_viewer will be the end users
    - cups_help_desk will be the help desk users
    - cups_admin will be the admins
If we wanted to assigne the end users role to a user all we need to do is
```bash
sudo usermod -aG cups_view <user id>
```
SO, how does CUPS enforce the roles?

## Locations and Policies
- The CUPS configureation files uses a Apache-style configuration syntax
- There are Location and Policy tag when we can assign block of directives to users and groups

### Locations
- when I first saw location, my first thought was where access can come from but, it is the location relative to the root branch of the website
 - `<Location />` is the home page of the CUPS server page - `<Locaton /admin>` is access to the Administration page
 - To allow cups_admin to Administration page
```bash
<Location /admin>
  AuthType Basic             ## use Linux base auth
  Require group cups_admin   ## RBAC access for admin by groups
  Allow localhost            ## What IPs I came frim
  Allow 192.168.20.0/24
  Allow 192.168.35.0/24
  Order deny,allow           ## This tells the CUPS daemon to process Deny rules first, then apply Allow rules.
  Encryption Required
</Location>
```

- There is a nice catch all with `Require valid-user` so any Linux user can see the CUPS home page where there is no functional, just menu to other pages
```bash
<Location />
  Order allow,deny
  Allow localhost
  Allow 192.168.20.0/24
  Allow 192.168.35.0/24
  AuthType Basic
  Require valid-user
  Encryption Required
</Location>
```


