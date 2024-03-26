#!/bin/bash

echo -n "Starting firewall: "
IPTABLES="/sbin/iptables" # path to iptables
$IPTABLES --flush

# the network interface you want to protect
# NOTE: This may not be eth0 on all nodes -- use ifconfig to
# find the experimental network (10.1.x.x) and adjust this
# variable accordingly. Use the variable by putting a $ in
# front of it like so: $ETH . It can go in any command line
# and will be expanded by the shell.

# For example: iptables -t filter -i $ETH etc... 

ETH="eth1"
SERVER_ADDR="172.30.0.12"
SSH_PORT="22"


# all traffic on the loopback device (127.0.0.1 -- localhost) is OK.
# Don't touch this!
$IPTABLES -A INPUT -i lo -j ACCEPT
$IPTABLES -A OUTPUT -o lo -j ACCEPT


# Allow all inbound and outbound traffic; all protocols, states,
# addresses, interfaces, and ports (it's like no firewall at all!):

#$IPTABLES -t filter -A INPUT -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT
#$IPTABLES -t filter -A OUTPUT -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT


# ANTI-SPOOFING
# Include a rule to block spoofing (traffic appearing to come from the server's IP address [the experiment, not the loopback or control network.])

$IPTABLES -t filter -i $ETH -A INPUT -m state --state NEW -s $SERVER_ADDR -j REJECT
# Rejects all packets coming in that match the server ip address on any port or protocol

# helpful divisions:
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

# Rule One -> Accept: inbound, tcp connection, OpenSSH server (port 22)
$IPTABLES -t filter -i $ETH -A INPUT -m state --state NEW -p tcp --dport 22 -j ACCEPT

# 2. allow new outbound tcp traffic to remote systems running OpenSSH,
# Apache, and SMTP servers (on their standard ports).

# 3. allow new inbound udp traffic to ports 10000-10005, and new outbound
# udp traffic to ports 10006-10010. Inbound and outbound UDP traffic should be limited to being from client (for input) or to client (for output).
# (You can get client's address from DETERLab.)

# 4. allow the server to send and respond to ICMP pings.

# OTHER CONNECTIONS
# -----------------
# *IGNORE* all other traffic


echo "done."

