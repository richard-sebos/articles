#!/bin/bash
sudo apt install -y \
  debootstrap qemu-user-static binfmt-support \
  gcc-aarch64-linux-gnu g++-aarch64-linux-gnu \
  curl git tar sudo parted dosfstools u-boot-tools

sudo apt install -y debian-archive-keyring

sudo apt install --reinstall tar

sudo apt update
sudo apt install -y mmdebstrap