

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
- CUPS allows users to be either Default, Digest or Kerberos depending on your version of CUPS.
- Digest, depending on your version could be depecated and Kerberos needs a Active Directory type user authentication so I will be using Default for these examples
- Under default, CUPS uses the default Linux user authnicator to validate users
- The Linux users will be assigned to groups and those group will be used by CUPS to allow access to different features
    - cups_viewer will be the end users
    - cups_help_desk will be the help desk users
    - cups_admin will be the admins
If we wanted to assigne the end users role to a user all we need to do is
```bash
sudo usermod -aG cups_view <user id>
```
SO, how does CUPS enforce the roles?





