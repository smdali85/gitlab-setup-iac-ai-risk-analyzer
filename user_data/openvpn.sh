#!/bin/bash
set -e

echo "========== OpenVPN Setup Started =========="

# ------------------------------
# System update
# ------------------------------
yum update -y
yum install -y curl wget unzip iptables-services

# ------------------------------
# Install OpenVPN using angristan script
# ------------------------------
cd /home/ec2-user

curl -O https://raw.githubusercontent.com/angristan/openvpn-install/master/openvpn-install.sh
chmod +x openvpn-install.sh

# Auto install OpenVPN
AUTO_INSTALL=y \
APPROVE_IP=y \
ENDPOINT=$(curl -s http://checkip.amazonaws.com) \
./openvpn-install.sh

# ------------------------------
# Enable IP Forwarding
# ------------------------------
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p

# ------------------------------
# Configure NAT for VPN Clients
# ------------------------------
PRIMARY_IFACE=$(ip route | grep default | awk '{print $5}')

iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o $PRIMARY_IFACE -j MASQUERADE
iptables-save > /etc/sysconfig/iptables

systemctl enable iptables
systemctl restart iptables

# ------------------------------
# Push routes to access private subnets (GitLab subnet)
# ------------------------------
OVPN_SERVER_CONF="/etc/openvpn/server/server.conf"

echo 'push "route 10.50.6.0 255.255.254.0"' >> $OVPN_SERVER_CONF
echo 'push "route 10.50.8.0 255.255.254.0"' >> $OVPN_SERVER_CONF
echo 'push "route 10.50.10.0 255.255.254.0"' >> $OVPN_SERVER_CONF

# Restart OpenVPN service
systemctl restart openvpn-server@server

# ------------------------------
# Enable OpenVPN at boot
# ------------------------------
systemctl enable openvpn-server@server

echo "========== OpenVPN Setup Completed =========="

# ------------------------------
# Copy client config to ec2-user home
# ------------------------------
CLIENT_FILE=$(ls /root/*.ovpn | head -n 1)
cp $CLIENT_FILE /home/ec2-user/
chown ec2-user:ec2-user /home/ec2-user/*.ovpn

echo "Client VPN profile copied to /home/ec2-user/"
