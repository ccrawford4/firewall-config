#!/bin/bash

echo -n "Starting firewall: "

IPTABLES="/sbin/iptables" # path to iptables
$IPTABLES --flush

ETH="eth1"
SERVER_ADDR="10.0.1.1"
CLIENT_ADDR="10.0.1.2"
SSH_PORT="22"
APACHE_PORT="80"
MYSQL_PORT="3306"
UDP_IN_LOW="10000"
UDP_IN_HIGH="10005"
UDP_OUT_LOW="10006"
UDP_OUT_HIGH="10010"
SMTP_PORT="587"


# all traffic on the loopback device (127.0.0.1 -- localhost) is OK.
$IPTABLES -A INPUT -i lo -j ACCEPT
$IPTABLES -A OUTPUT -o lo -j ACCEPT


# ANTI-SPOOFING
# Rejects all packets coming in that match the server ip address on any port or protocol
$IPTABLES -t filter -i $ETH -A INPUT -m state --state NEW -s $SERVER_ADDR -j REJECT

# EXISTING CONNECTIONS
# --------------------
# Rules here specifically allow inbound traffic and outbound traffic for ALL previously
# accepted connections.
$IPTABLES -t filter -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
$IPTABLES -t filter -A OUTPUT -m state --state RELATED,ESTABLISHED -j ACCEPT


# NEW CONNECTIONS
# ---------------
# Rules here allow NEW traffic:
# 1. allow inbound traffic to the OpenSSH, Apache2, and MySQL servers. (MySQL traffic only allowed from client.)

$IPTABLES -t filter -i $ETH -A INPUT -m state --state NEW -p tcp --dport $SSH_PORT -j ACCEPT
$IPTABLES -t filter -i $ETH -A INPUT -m state --state NEW -p tcp --dport $APACHE_PORT -j ACCEPT
$IPTABLES -t filter -i $ETH -A INPUT -m state --state NEW -p tcp -s $CLIENT_ADDR --dport $MYSQL_PORT -j ACCEPT


# 2. allow new outbound tcp traffic to remote systems running OpenSSH,
# Apache, and SMTP servers (on their standard ports).

$IPTABLES -t filter -o $ETH -A OUTPUT -m state --state NEW -p tcp --dport $SSH_PORT -j ACCEPT
$IPTABLES -t filter -o $ETH -A OUTPUT -m state --state NEW -p tcp --dport $APACHE_PORT -j ACCEPT
$IPTABLES -t filter -o $ETH -A OUTPUT -m state --state NEW -p tcp --dport $SMTP_PORT -j ACCEPT

# 3. allow new inbound udp traffic to ports 10000-10005, and new outbound
# udp traffic to ports 10006-10010. Inbound and outbound UDP traffic should be limited to being from client (for input) or to client (for output).

$IPTABLES -t filter -i $ETH -A INPUT -m state --state NEW -p udp -s $CLIENT_ADDR --dport $UDP_IN_LOW:$UDP_IN_HIGH -j ACCEPT
$IPTABLES -t filter -o $ETH -A OUTPUT -m state --state NEW -p udp -s $CLIENT_ADDR --dport $UDP_OUT_LOW:$UDP_OUT_HIGH -j ACCEPT

# 4. allow the server to send and respond to ICMP pings.
$IPTABLES -t filter -i $ETH -A INPUT -m state --state NEW -p icmp --icmp-type echo-request -j ACCEPT
$IPTABLES -t filter -o $ETH -A OUTPUT -m state --state NEW -p icmp --icmp-type echo-reply -j ACCEPT
$IPTABLES -t filter -o $ETH -A OUTPUT -m state --state NEW -p icmp --icmp-type echo-request -j ACCEPT

# OTHER CONNECTIONS
# -----------------
# *IGNORE* all other traffic
$IPTABLES -t filter -i $ETH -A INPUT -m state --state NEW -j DROP
$IPTABLES -t filter -o $ETH -A FORWARD -m state --state NEW -j DROP
$IPTABLES -t filter -o $ETH -A OUTPUT -m state --state NEW -j DROP


echo "done."

