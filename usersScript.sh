#!/bin/bash

file=$1

while read -r line; do
    user=$(echo "$line" | cut -d: -f1)
    pass=$(echo "$line" | cut -d: -f2)
    uid=$(echo "$line" | cut -d: -f3)
    gid=$(echo "$line" | cut -d: -f4)
    comment=$(echo "$line" | cut -d: -f5)
    home=$(echo "$line" | cut -d: -f6)
    shell=$(echo "$line" | cut -d: -f7)

    # Create group
    if ! getent group "$gid" >/dev/null; then
        sudo groupadd -g "$gid" "$user"
    fi

    # Create user
    sudo useradd -u "$uid" -g "$gid" -c "$comment" -d "$home" -s "$shell" "$user"

    # Create home dir
    sudo mkdir -p "$home"
    sudo chown "$uid:$gid" "$home"

    # password
    if [ "$pass" = "!" ] || [ -z "$pass" ]; then
        sudo passwd -l "$user" >/dev/null
    else
        echo "$user:$pass" | sudo chpasswd --encrypted
    fi
done < "$file"