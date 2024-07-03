#!/bin/bash

# Check if script is run as root 
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

if [ $# -eq 0 ]; then
    echo "Please provide an input file"
    echo "Usage: $0 <input-file.txt or input-file.csv>"
    exit 1
fi

INPUT_FILE=$1
LOG_FILE="/var/log/user_management.log"
PASSWORD_DIR="/var/secure"
PASSWORD_FILE="$PASSWORD_DIR/user_passwords.csv"

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Input file does not exist"
    exit 1
fi

# Create log file 
touch $LOG_FILE

# Create secure directory 
mkdir -p $PASSWORD_DIR

# Create password file 
touch $PASSWORD_FILE
chmod 600 $PASSWORD_FILE

# Function to log actions
log_action() {
    echo "$(date): $1" >> $LOG_FILE
}

if [[ "$INPUT_FILE" == *.csv ]]; then
    delimiter=","
else
    delimiter=";"
fi

while IFS="$delimiter" read -r username groups
do
    username=$(echo $username | xargs)
    groups=$(echo $groups | xargs)
    [ -z "$username" ] && continue
    if id "$username" &>/dev/null; then
        log_action "User $username already exists"
        continue
    fi

    groupadd $username
    log_action "Created group $username"

    useradd -m -g $username $username
    log_action "Created user $username with $username"

    password=$(openssl rand -base64 12) 
    echo "$username:$password" | chpasswd
    echo "$username,$password" >> $PASSWORD_FILE
    log_action "Set password for user $username"

    IFS=',' read -ra group_array <<< "$groups"
    for group in "${group_array[@]}"; do
        group=$(echo $group | xargs)
        if ! getent group $group > /dev/null 2>&1; then
            groupadd $group
            log_action "Created group $group"
        fi
        usermod -a -G $group $username
        log_action "Added user $username to group $group"
    done

    log_action "Completed setup for user $username"
done < "$INPUT_FILE"

echo "User creation process completed succesfuly. Check $LOG_FILE."