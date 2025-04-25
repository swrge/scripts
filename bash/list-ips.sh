#!/bin/bash

# Functions to convert between IP address and 32-bit integer
ip_to_int() {
    local ip=$1
    local a b c d
    IFS=. read -r a b c d <<< "$ip"
    echo $(( (a << 24) + (b << 16) + (c << 8) + d ))
}

int_to_ip() {
    local int=$1
    local a=$(( (int >> 24) & 255 ))
    local b=$(( (int >> 16) & 255 ))
    local c=$(( (int >> 8) & 255 ))
    local d=$(( int & 255 ))
    echo "$a.$b.$c.$d"
}

# Check if correct number of arguments is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 w.x.y.z/mask"
    exit 1
fi

# Parse input in the format w.x.y.z/mask
input=$1
if [[ ! "$input" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)/([0-9]+)$ ]]; then
    echo "Usage: $0 w.x.y.z/mask"
    exit 1
fi

# Extract IP and mask from input
ip_part=${input%/*}
mask=${input#*/}

# Split IP into octets
IFS=. read -r w x y z <<< "$ip_part"

# Validate inputs
for octet in $w $x $y $z; do
    if [ "$octet" -lt 0 ] || [ "$octet" -gt 255 ]; then
        echo "Invalid octet: $octet"
        exit 1
    fi
done

if [ "$mask" -lt 16 ] || [ "$mask" -gt 32 ]; then
    echo "Invalid mask: $mask"
    exit 1
fi

# Construct IP address
ip="$w.$x.$y.$z"
ip_int=$(ip_to_int "$ip")

# Compute mask as a 32-bit integer (first 'mask' bits set to 1)
mask_int=$(( (1 << 32) - (1 << (32 - mask)) ))

# Compute network address
network_int=$(( ip_int & mask_int ))
start_ip=$(int_to_ip $network_int)

# Compute number of addresses
num=$(( 1 << (32 - mask) ))

# Compute end IP (broadcast address)
end_int=$(( network_int + num - 1 ))
end_ip=$(int_to_ip $end_int)

# Output summary
echo "$num addresses"
echo "IP address range: $start_ip - $end_ip"

# Extract starting octets
IFS=. read -r w x y z <<< "$start_ip"

# List all IP addresses
for ((i=1; i<=num; i++)); do
    echo "$w.$x.$y.$z"
    (( z++ ))
    if (( z > 255 )); then
        z=0
        (( y++ ))
        if (( y > 255 )); then
            y=0
            (( x++ ))
            if (( x > 255 )); then
                x=0
                (( w++ ))
                if (( w > 255 )); then
                    echo "Error: octet overflow"
                    exit 1
                fi
            fi
        fi
    fi
done
