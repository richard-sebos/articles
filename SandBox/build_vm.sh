#!/bin/bash
# create_sandbox_vm.sh - Fully automated hardened sandbox VM in Proxmox

# -----------------------------
# CONFIGURATION
# -----------------------------
VMID=9001
VMNAME="sandbox-auto"
RAM=4096
CPUS=2
DISK_SIZE="20G"
ISO_PATH="local:iso/ubuntu-22.04.4-live-server-amd64.iso"
STORAGE="local-lvm"
BRIDGE="vmbr1"
HTTP_PORT=8080
HTTP_DIR="/var/lib/autoinstall"

# -----------------------------
# Prepare autoinstall config
# -----------------------------
echo "[+] Setting up autoinstall files in $HTTP_DIR"
mkdir -p $HTTP_DIR

# user-data with hardened setup
cat > $HTTP_DIR/user-data <<EOF
#cloud-config
autoinstall:
  version: 1
  identity:
    hostname: sandbox
    username: sandbox
    password: \"\$6\$rounds=4096\$3HgnPMBhW3r...ReplaceThis...\"  # Use mkpasswd
  locale: en_US
  keyboard: us
  packages:
    - xfce4
    - firefox
    - clamav
    - yara
    - wireshark
    - net-tools
    - auditd
    - fail2ban
    - apparmor
  ssh:
    install-server: false
  late-commands:
    - curtin in-target -- systemctl disable ssh
    - curtin in-target -- ufw enable
    - curtin in-target -- ufw default deny incoming
    - curtin in-target -- ufw allow out to any port 80,443 proto tcp
    - curtin in-target -- systemctl enable auditd
EOF

# minimal meta-data file
cat > $HTTP_DIR/meta-data <<EOF
instance-id: sandbox-001
EOF

# Start HTTP server to serve autoinstall files
if ! pgrep -f "python3 -m http.server $HTTP_PORT" > /dev/null; then
  echo "[+] Starting HTTP server on port $HTTP_PORT"
  cd $HTTP_DIR && nohup python3 -m http.server $HTTP_PORT &
fi

# -----------------------------
# Create VM in Proxmox
# -----------------------------
echo "[+] Creating VM $VMID"
qm create $VMID \
  --name $VMNAME \
  --memory $RAM \
  --cores $CPUS \
  --net0 virtio,bridge=$BRIDGE,firewall=1 \
  --scsihw virtio-scsi-pci \
  --scsi0 $STORAGE:0,format=qcow2,size=$DISK_SIZE \
  --ide2 $ISO_PATH,media=cdrom \
  --boot order=scsi0 \
  --serial0 socket \
  --vga serial0

# -----------------------------
# Output instructions
# -----------------------------
echo "[✔] VM $VMID created."
echo "[!] Now start the VM and edit the GRUB boot params:"
echo "    autoinstall ds=nocloud-net;s=http://<Proxmox-IP>:$HTTP_PORT/"
echo "Then press Ctrl+X to boot and begin autoinstall."
echo ""
echo "Tip: Run \"qm start $VMID && qm terminal $VMID\" to access the VM console."

qm snapshot 9000 clean-state --description "Fresh GUI sandbox VM"

# Step 4: Start VM
echo "[+] Starting VM $VMID"
qm start $VMID

echo "[✔] VM created. Proceed with OS installation via console."
