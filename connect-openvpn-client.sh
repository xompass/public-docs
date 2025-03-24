#!/bin/bash
PROFILE=`pwd`/profile.ovpn

sudo cp $PROFILE /etc/openvpn/client.conf
sudo systemctl enable openvpn@client
sudo systemctl start openvpn@client
