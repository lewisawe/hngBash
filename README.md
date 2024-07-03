# Script Details

A bash script to automate user creation, group assignment, and password generation for new developers.

## The create_users.sh script performs the following actions:

- Checks if the script is being run as root and if the input file exists.
- Creates the log and password files, setting the permissions on the password file so that only the file owner can read it.
- Defines a function called create_user, which takes two arguments: the username and a comma-separated list of groups. The function creates a personal group with the same name as the username, creates the user with the personal group and specified groups, sets a random password for the user, and logs the actions to both the log and password files.
- Reads the input file line by line, skipping empty lines and removing whitespace. For each line, the script checks if the user already exists and skips the line if so. If the user does not exist, the script calls the create_user function to create the user and log the actions.
