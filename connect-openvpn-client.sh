#!/bin/bash
PROFILE=`pwd`/profile.ovpn
openvpn3 config-import --config $PROFILE --name VSaaSVPN --persistent
openvpn3 config-acl --show --lock-down true --grant root --config VSaaSVPN
sudo systemctl enable --now openvpn3-session@VSaaSVPN.service
