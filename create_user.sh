#!/bin/bash


INPUT_FILE=$1
LOG_FILE="/var/log/user_management.log"
PASSWORD_DIR="/var/secure"
PASSWORD_FILE="$PASSWORD_DIR/user_passwords.csv"


touch $LOG_FILE

mkdir -p $PASSWORD_DIR

touch $PASSWORD_FILE
chmod 600 $PASSWORD_FILE

