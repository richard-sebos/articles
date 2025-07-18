
- With modern device, there could be hundreds to thoughts of programs added to make a Linux dsitro.
- Each one of these programs adds an entry point for a meleisious attack to try to attack your syste,
- What if you could contain an application without adding additional applicatitions

## chroot
- Linux has a powerful feature chroot that allows you to isolated filesystem and treating it as the root for the system
- It allows you to create a limit enviroment with a subset of the existing file system, thereby reducing the attack risk
- If the application or library is outside this isolated filesystem the user and application they run do not have access to it
- It sound very restrictive?

## Why Use chroot and SSH
- In a word because of the restrictivness.
- In the example below, you see after setup the enviroment and logging in through SSH, commands like `ls` and `sleep` where not there.
- They needed to be added as well as the librarys needed to run those commands.
- SSH into a chroot enviroment can create a very restrictive session for users to login to.
- So what not use it more often

## Risks with chroot
- chroot works will with applications that are either self contained or use few other application or library.
- It also needs to have a copy of the other applications and libraries is it own sub-filesystem
- these need to be copy and not sybolic links
- When the real location is updates through patching, the copies are not


## How it works
- Recently, I worked on a project were remote uses needed limited access to a Linux system through SSH
- I wanted a test system to see if chroot would work well with this system
- So I setup an enviroment by

### Creating the Isolated Filesystem
- Create the chroot root location at `/home/jail` and a new users app_richard.
- `/home/jail` is directories and not a user

```bash
/home
├── jail
│   ├── app
│   ├── home
│   │   └── app_richard
├── app_richard 
```
- root needs to own everything under `/home/jail` at this point

### Setup Limited Application
- when the user logis in through SSH, an launch_app.sh will be launched
- it is stored at ` /home/jail/app/launch_app.sh` and has
```bash
#!/bin/bash

echo "==========================================="
echo " Welcome to the Chroot Test App"
echo "==========================================="

echo ""
echo "You are currently in: $(pwd)"
echo "Listing contents of your home directory:"
echo ""

ls -la /home/rf_richard

echo ""
echo "Test complete. Disconnecting now..."
sleep 3
exit 0

```
- For this shell script to run, the isolated needs access to `bash`, `ls` and `sleep` and there libraries
- `echo` and `exit` come as part of  `bash`
- `ldd` command can be used to file the libraries needed for those commands
```bash
 ldd /usr/bin/bash
        linux-vdso.so.1 (0x00007ffc181ee000)
        libtinfo.so.6 => /lib64/libtinfo.so.6 (0x00007f0b8bac3000)
        libdl.so.2 => /lib64/libdl.so.2 (0x00007f0b8b8bf000)
        libc.so.6 => /lib64/libc.so.6 (0x00007f0b8b4e8000)
        /lib64/ld-linux-x86-64.so.2 (0x00007f0b8c00e000)

```
- Once the commands are copied to similar structure, the chroot looks like
```bash

/home
├── jail
│   ├── app
│   │   └── launch_app.sh
│   ├── bin
│   │   └── bash
│   ├── home
│   │   └── app_richard
│   ├── lib64
│   │   ├── ld-linux-x86-64.so.2
│   │   ├── libcap.so.2
│   │   ├── libc.so.6
│   │   ├── libdl.so.2
│   │   ├── libpcre2-8.so.0
│   │   ├── libpthread.so.0
│   │   ├── libselinux.so.1
│   │   └── libtinfo.so.6
│   └── usr
│       └── bin
│           ├── ls
│           └── sleep
├── app_richard 
```
- Since there was more that one user, I created a `app_users` group to assign to those users

### SSH changes
- the changes to SSH where simple and I just added this block to the end of the sshd_cofig file
```bash
    ## added to the end
    Match Group app_users
    ChrootDirectory /home/jail
    ForceCommand /app/launch_app.sh
    PermitTTY no
    AllowTcpForwarding no
    X11Forwarding no
```
- and restarted the SSH server
``` bash
sudo systemctl restart sshd
```
- when login into the system you get
```bash
===========================================
 Welcome to the RF Scanner Chroot Test App
===========================================

You are currently in: /home/rf_richard
Listing contents of your home directory:

total 0
drwxr-xr-x. 2 1003 1004  6 Jul 18 01:25 .
drwxr-xr-x. 3    0    0 18 Jul 18 01:25 ..

Test complete. Disconnecting now...
```

- If you are going to use chroot, make sure to create a process to rebuild the enviroments when updates are done.
