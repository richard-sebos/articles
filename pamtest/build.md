

```bash

sudo dnf groupinstall "Development Tools" -y
sudo dnf install pam-devel -y


curl -LO https://downloads.sourceforge.net/project/pamtester/pamtester/0.1.3/pamtester-0.1.3.tar.gz
tar xvf pamtester-0.1.3.tar.gz
cd pamtester-0.1.3
./configure
make
sudo make install
```
