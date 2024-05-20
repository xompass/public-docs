#!/bin/bash
echo "Enter .ovpn profile full path, e.g /home/myusername/vpn-profile.ovpn:"
read PROFILE
openvpn3 config-import --config $PROFILE --name VSaaSVPN --persistent
openvpn3 config-acl --show --lock-down true --grant root --config VSaaSVPN
sudo systemctl enable --now openvpn3-session@VSaaSVPN.service
