#!/bin/bash
sudo apt update
sudo apt install -y nano curl mosquitto
sudo systemctl enable mosquitto

sudo apt-get install ca-certificates curl gnupg lsb-release

sudo mkdir -p /etc/apt/keyrings

# All together in one line
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# All together in one line
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian bullseye stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin

sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
sudo update-alternatives --set iptables /usr/sbin/iptables-legacy

sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER

echo "Relog to refresh permissions..."
