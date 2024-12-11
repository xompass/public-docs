#!/bin/bash
sudo apt update

if uname -m | grep -q 'aarch64'; then
  sudo apt install -y openvpn
fi

if uname -m | grep -q 'x86_64'; then
  sudo mkdir -p /etc/apt/keyrings && curl -fsSL https://packages.openvpn.net/packages-repo.gpg | sudo tee /etc/apt/keyrings/openvpn.asc
  DISTRO=$(lsb_release -c | awk '{print $2}')
  echo "deb [signed-by=/etc/apt/keyrings/openvpn.asc] https://packages.openvpn.net/openvpn3/debian $DISTRO main" | sudo tee /etc/apt/sources.list.d/openvpn-packages.list
  sudo apt install -y openvpn3
fi

