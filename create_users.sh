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

# Define log file and secure password file paths

LOGFILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.csv"


# Create log and password files

mkdir -p /var/secure
touch "$LOGFILE" "$PASSWORD_FILE"
chmod 600 "$PASSWORD_FILE"

generate_random_password()
{
    local length=${1:-10} # Default length is 10 if no argument is provided
    tr -dc 'A-Za-z0-9!?%+=' < /dev/urandom | head -c "$length"
}

log_message()
{
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOGFILE"
}

# Function to create a user

create_user()
{
    local username=$1
    local groups=$2

    # Create the user's personal group if it doesn't exist
    if ! getent group "$username" > /dev/null; then
        groupadd "$username"
        log_message "Created personal group $username"
    fi

    # Create user if it doesn't exist, or modify existing user's primary group
    
	if getent passwd "$username" > /dev/null; then
        usermod -g "$username" "$username"
        log_message "User $username already exists, modified primary group to $username"
    else
        useradd -m -g "$username" "$username"
        log_message "Created user $username"
    fi

    # Add user to specified groups
    
	IFS=',' read -r -a groups_array <<< "$groups"
    for group in "${groups_array[@]}"; do
        group=$(echo "$group" | xargs)  # Trim whitespace
        if ! getent group "$group" > /dev/null; then
            groupadd "$group"
            log_message "Created group $group"
        fi
        usermod -aG "$group" "$username"
        log_message "Added user $username to group $group"
    done

    # Set up home directory permissions
    
	chmod 700 "/home/$username"
    chown "$username:$username" "/home/$username"
    log_message "Set up home directory for user $username"

    # Generate a random password if the user didn't exist previously
    
	if [ -z "$3" ]; then
        password=$(generate_random_password 12)
        echo "$username:$password" | chpasswd
        echo "$username,$password" >> "$PASSWORD_FILE"
        log_message "Set password for user $username"
    fi
}

# Read the input file and create users

while IFS=';' read -r username groups; do
    # Ignore empty lines and comments
    [[ -z "$username" || "$username" =~ ^# ]] && continue
    if getent passwd "$username" > /dev/null; then
        create_user "$username" "$groups" "exists"
    else
        create_user "$username" "$groups"
    fi
done < "$1"

echo "User creation process completed succesfuly. Check $LOG_FILE."