
sudo useradd richard
sudo useradd admin_richard
sudo groupadd rf_scanners
sudo useradd -g rf_scanners rf_richard
sudo su -l richard
    ->======================
    mkdir -p .ssh
    vim .ssh/authorized_keys.  ## Put the auth key in here
    chmod 600 .ssh/authorized_keys
    chmod 700 .ssh
    ->======================
sudo su -l rf_richard
    ->======================
    mkdir -p .ssh
    vim .ssh/authorized_keys.  ## Put the auth key in here
    chmod 600 .ssh/authorized_keys
    chmod 700 .ssh
    ->======================
sudo mkdir -p  /home/jail/home/rf_richard/data
sudo mkdir -p  /home/jail/app
sudo mkdir -p  /home/jail/bin
sudo mkdir -p  /home/jail/lib64
sudo chown root:root /home/jail/home/rf_richard
sudo chown rf_richard:rf_scanners /home/jail/home/rf_richard/data
ldd /bin/bash
sudo cp /lib64/ld-linux-x86-64.so.2 /home/jail/lib64/.
sudo cp /lib64/libc.so.6  /home/jail/lib64/.
sudo cp /lib64/libdl.so.2 /home/jail/lib64/.
sudo cp /lib64/libtinfo.so.6 /home/jail/lib64/.
sudo vim  /home/jail/app/launch_scanner.sh 
sudo chmod +x /home/jail/app/launch_scanner.sh
->======================
    #!/bin/bash

echo "==========================================="
echo " Welcome to the RF Scanner Chroot Test App"
echo "==========================================="

echo ""
echo "You are currently in: $(pwd)"
echo "Listing contents of your home directory:"
echo ""

ls -la /home/rf_richard/data

echo ""
echo "Test complete. Disconnecting now..."
sleep 3
exit 0
->======================
sudo vim /etc/ssh/sshd_config
->======================
    ## added to the end
    Match User rf_richard
    ChrootDirectory /home/jail
    ForceCommand /app/launch_scanner.sh
    PermitTTY no
    AllowTcpForwarding no
    X11Forwarding no
->====================== 
sudo systemctl restart sshd
ldd /usr/bin/ls
sudo /lib64/libselinux.so.1 /home/jail/lib64/.
sudo cp /lib64/libselinux.so.1 /home/jail/lib64/.
sudo cp /lib64/libcap.so.2 /home/jail/lib64/.
sudo cp /lib64/libc.so.6 /home/jail/lib64/.
sudo cp /lib64/libpcre2-8.so.0 /home/jail/lib64/.
sudo cp /lib64/libdl.so.2 /home/jail/lib64/.
sudo cp /lib64/ld-linux-x86-64.so.2 /home/jail/lib64/.
sudo cp /lib64/libpthread.so.0 /home/jail/lib64/.
sudo mkdir -p /home/jail/usr/bin
sudo cp /usr/bin/ls /home/jail/usr/bin/.
which sleep 
ldd /usr/bin/sleep 
sudo cp /usr/bin/sleep /home/jail/usr/bin/.
