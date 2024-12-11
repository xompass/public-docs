#!/bin/bash
PROFILE=`pwd`/profile.ovpn

if uname -m | grep -q 'aarch64'; then
    sudo cp $PROFILE /etc/openvpn/client.conf
    sudo systemctl enable openvpn@client
    sudo systemctl start openvpn@client
fi

if uname -m | grep -q 'x86_64'; then
    openvpn3 config-import --config $PROFILE --name VSaaSVPN --persistent
    openvpn3 config-acl --show --lock-down true --grant root --config VSaaSVPN
    sudo systemctl enable --now openvpn3-session@VSaaSVPN.service
fi
