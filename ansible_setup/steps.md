# Ansible System setup script
---
- admin richard
```bash
sudo tree -d /opt
tree -d /opt
sudo dnf install  tree
sudo dnf instal  tree
sudo touch /opt/ansible/inventory/prod/hosts.yml
sudo touch /opt/ansible/inventory/dev/hosts.yml
sudo mkdir -p /opt/ansible/inventory/prod/
sudo mkdir -p /opt/ansible/inventory/dev/
mkdir -p /opt/ansible/inventory/dev/
sudo chown -R ansible_admin:ansible_admin /opt/ansible/envs/prod
sudo chmod -R 750 /opt/ansible/envs/prod
sudo chown -R dev_richard:ansible_admin /opt/ansible
sudo chmod -R 770 /opt/ansible

sudo mkdir -p /opt/ansible/envs/{dev,prod}
sudo mkdir -p /opt/ansible/scripts
```
---
- root
```bash
    1  echo /usr/bin/fish | sudo tee -a /etc/shells
    2  which fish
    3  chsh -s /usr/bin/fish ansible_admin
    4  sudo usermod -s /usr/bin/fish ansible_admin
    5  exit
    6  adduser admin_richard
    7  gpasswd --add admin_richard wheel
    8  usermod usermod -s /usr/bin/fish admin_richard
    9   usermod -s /usr/bin/fish admin_richard
   10  su -l admin_richard
   11  passwd admin_richard
   12  su -l admin_richard
   13  history
```
---
- ansible admin
```bash
su -l
help
exit
sudo ls -l /etc/sudoers.d/
ls -l /etc/sudoers.d/
sudo chmod 400 /etc/sudoers.d/ansible
sudo cp sudoers.d/ansible /etc/sudoers.d/.
ls -ltr
clear
emacs sudoers.d/ansible
mkdir sudoers.d
cd setup/
mkdir setup
sudo shutdown -h now
shutdown -h now
sudo dnf -y install ansible-core python3 python3-pip vim git tmux bash-completion policycoreutils policycoreutils-python-utils audit aide  dnf-automatic
sudo dnf -y install ansible-core python3 python3-pip vim git tmux bash-completion policycoreutils policycoreutils-python-utils audit aide fail2ban dnf-automatic
ip a
sudo reboot
sudo dnf update
sudo nmt
```
