#!/bin/bash

PTABLES="/sbin/iptables" # Assuming this is for reference, and not used directly in this script
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

if [ "$#" -ne 1 ]; then
	echo "Usage: $0 [1 for server | 0 for client]"
	exit 1
fi

if [ "$1" -eq 1 ]; then
	mode="server"
elif [ "$1" -eq 0 ]; then
	mode="client"
else
	echo "Invalid argument: $1. Use 1 for server mode of 0 for client mode."
	exit 1
fi


# Helper function to test a single port
test_port() {
    local mode=$1
    local protocol=$2
    local port=$3
    if [ "$mode" == "client" ]; then
        if [ "$protocol" == "tcp" ]; then
           if  nc -zvw3 $SERVER_ADDR $port; then
		   echo "Error: TCP port $port should not be accepting connections." >&2
		   return 1
	   fi
        else
            if nc -zvu $SERVER_ADDR $port; then
		    echo "Warning: UDP port $port might be accepting connections." >&2
  	    fi
	fi
    elif [ "$mode" == "server" ]; then
        if [ "$protocol" == "tcp" ]; then
            nc -lvkp $port > /dev/null
        else
            nc -lvkup $port > /dev/null
        fi
    fi
}

# Main logic

if [ "$mode" != "server" ] && [ "$mode" != "client" ]; then
    echo "Usage: $0 [server|client]"
    exit 1
fi

# Define port ranges for testing
EXCLUDE_PORTS=($SSH_PORT $APACHE_PORT $SMTP_PORT $MYSQL_PORT)
EXCLUDE_RANGES_START=($UDP_IN_LOW $UDP_IN_HIGH)
EXCLUDE_RANGES_END=($UDP_OUT_LOW $UDP_OUT_HIGH)

is_excluded() {
	local port=$1
	for exclude in "${EXCLUDE_PORTS[@]}"; do
		if [[ "$PORT" -eq "$exclude" ]]; then
			return 0
		fi
	done

	local range_idx=0
	for start in "${EXCLUDE_RANGES_START[@]}"; do
		local end=${EXCLUDE_RANGES_END[$range_idx]}
		if [[ "$port" -ge "$start" && "$port" -le "$end" ]]; then
			return 0
		fi
		((range_idx++))
	done

	return 1 # Return False
}


for ((port=1; port <= 10011; port++)); do
	if ! is_excluded "$port"; then
		echo "Testing TCP port: $port"
		test_port "$mode" tcp "$port"
		status=$?
		if [[ $status -eq 1 ]]; then
			echo "ERROR! FOUND A TCP PORT INCORRECLTY ACCEPTING INBOUND CONNECTIONS"
			return 1
		fi 

		echo "Testing UDP port: $port"
		test_port $mode udp $port &		
	fi
done

wait
echo "Testing complete."
