#!/bin/bash

# Configurable Parameters
VMID=9000
VMNAME="sandbox-vm"
ISO_PATH="local:iso/ubuntu-22.04.4-desktop-amd64.iso"
STORAGE="local-lvm"
BRIDGE="vmbr1"  # Or vmbr0 for NAT
CORES=2
RAM=4096  # MB
DISK_SIZE=20G
NET_MODEL="virtio"  # Or e1000 for compatibility

echo "[+] Creating VM $VMID - $VMNAME"

# Step 1: Create VM shell
qm create $VMID \
  --name $VMNAME \
  --memory $RAM \
  --cores $CORES \
  --net0 "$NET_MODEL,bridge=$BRIDGE,firewall=1" \
  --scsihw virtio-scsi-pci \
  --scsi0 $STORAGE:0,format=qcow2,discard=on,ssd=1,size=$DISK_SIZE \
  --boot order=scsi0 \
  --ide2 $ISO_PATH,media=cdrom \
  --ostype l26 \
  --agent 0 \
  --serial0 socket \
  --vga std

# Step 2: Enable Firewall (deny by default)
pvesh set /nodes/$(hostname)/qemu/$VMID/firewall/options --enable 1
qm set $VMID --cipassword disabled

# Step 3: Add initial firewall rules (Web-only egress)
qm set $VMID --hookscript local:snippets/firewall_rules.sh

# Or manually add:
cat <<EOF | qm set $VMID --args "-fw_rule 1"
[OPTIONS]
enable: 1

[RULES]
type: out
action: ACCEPT
proto: tcp
dport: 443,80

type: out
action: DROP
dest: 192.168.0.0/16
EOF

qm snapshot 9000 clean-state --description "Fresh GUI sandbox VM"

# Step 4: Start VM
echo "[+] Starting VM $VMID"
qm start $VMID

echo "[✔] VM created. Proceed with OS installation via console."
