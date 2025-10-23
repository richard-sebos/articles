#!/bin/bash
# Return a newline-separated list of running VMs in Qubes
get_vm_list() {
  qvm-ls --running --raw-data --fields name 2>/dev/null | awk 'NR>1 {print $1}' ||
  qvm-ls --running 2>/dev/null | awk 'NR>1 {print $1}'
}

