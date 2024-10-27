#!/bin/bash
# Define the CSV file and README file
CSV_FILE="users.csv"
README_FILE="README.md"

# clears the CSV file
clear_csv() {
    > $CSV_FILE
    echo "All users have been deleted."
}

# Deletes a specific user from the CSV file
delete_user() {
    read -p "Enter the user or account name to delete: " username_to_delete
    temp_file=$(mktemp)
    user_deleted=false
    while IFS=, read -r username password; do
        if [[ $username != "$username_to_delete" ]]; then
            echo "$username,$password" >> $temp_file
        else
            user_deleted=true
        fi
    done < $CSV_FILE
    mv $temp_file $CSV_FILE
    if $user_deleted; then
        echo "User or account name $username_to_delete has been successfully deleted."
    else
        echo "User or account name $username_to_delete not found."
    fi
}

# Displays users/accounts with the password
display_users() {
    if [[ -s $CSV_FILE ]]; then
        while IFS=, read -r username password; do
            echo "User or Account Name: $username, Password: $password"
        done < $CSV_FILE
    else
        echo "No users found."
    fi
}

# README file
read_readme() {
    if [[ -f $README_FILE ]]; then
        cat $README_FILE
    else
        echo "README file not found."
    fi
}

# Generates a password
generate_password() {
    local length=$1
    local use_alpha=$2
    local use_numeric=$3
    local use_special=$4
    local characters=""
    [[ $use_alpha == "y" ]] && characters+=$(echo {a..z} {A..Z} | tr -d ' ')
    [[ $use_numeric == "y" ]] && characters+=$(echo {0..9} | tr -d ' ')
    [[ $use_special == "y" ]] && characters+='!@#$%^&*()_+'
    if [[ -z $characters ]]; then
        echo "Error: At least one character type must be selected."
        exit 1
    fi
    password=$(tr -dc "$characters" < /dev/urandom | head -c $length)
    echo $password
}

# Checks if a user exists
user_exists() {
    local username=$1
    while IFS=, read -r existing_username password; do
        if [[ $existing_username == "$username" ]]; then
            return 0
        fi
    done < $CSV_FILE
    return 1
}

# Check for -h or --help option before the main loop
if [[ $1 == "-h" || $1 == "--help" ]]; then
    read_readme
    exit 0
fi

# Main loop
while true; do
    echo "Options:"
    echo "1. Add a user/account"
    echo "2. Display users/account"
    echo "3. Delete all users/account"
    echo "4. Delete a specific user/account"
    echo "-h or --help to view README, -q to quit"
    read -p "Select an option (1-4) or -q to quit, -h or --help: " choice

    # Check if the user entered something
    if [[ -z "$choice" ]]; then
        echo "No option selected. Please enter a valid option."
        continue
    fi

    case $choice in
        1)
            while true; do
                read -p "Enter a user or account name: " username
                if [[ -z "$username" ]]; then
                    echo "User or account name cannot be empty. Please enter a valid name."
                elif user_exists "$username"; then
                    echo "User or account name $username already exists. Please choose a different name."
                else
                    break
                fi
            done
            read -p "Enter the password length (default is 12): " length
            length=${length:-12}

            while true; do
                # Validate "y" or "n" response for each character type
                while true; do
                    read -p "Include alphabetic characters? (y/n): " use_alpha
                    if [[ $use_alpha == "y" || $use_alpha == "n" ]]; then
                        break
                    else
                        echo "Invalid input. Please enter 'y' or 'n'."
                    fi
                done
                while true; do
                    read -p "Include numeric characters? (y/n): " use_numeric
                    if [[ $use_numeric == "y" || $use_numeric == "n" ]]; then
                        break
                    else
                        echo "Invalid input. Please enter 'y' or 'n'."
                    fi
                done
                while true; do
                    read -p "Include special characters? (y/n): " use_special
                    if [[ $use_special == "y" || $use_special == "n" ]]; then
                        break
                    else
                        echo "Invalid input. Please enter 'y' or 'n'."
                    fi
                done
                if [[ $use_alpha == "n" && $use_numeric == "n" && $use_special == "n" ]]; then
                    echo "Error: At least one character type must be selected."
                else
                    break
                fi
            done
            

            # Confirm user creation
            echo
            echo "You are about to create the following user or account:"
            echo "Name: $username"
            echo "Password length: $length"
            echo "Include alphabetic characters: $use_alpha"
            echo "Include numeric characters: $use_numeric"
            echo "Include special characters: $use_special"
            echo
            read -p "Do you want to proceed? (y/n): " confirm
            if [[ $confirm != "y" ]]; then
                echo "User creation canceled."
                continue
            fi
            
            # Generate and store password
            password=$(generate_password $length $use_alpha $use_numeric $use_special)
            echo "$username,$password" >> $CSV_FILE
            echo "User or account name $username has been successfully created with password $password"
            ;;
        2)
            echo
            display_users
            echo
            ;;
        3)
            clear_csv
            ;;
        4)
            delete_user
            ;;
        -h|--help)
            read_readme
            ;;
        -q)
            echo "Exiting the script."
            exit 0
            ;;
        *)
            echo "Invalid choice. Please try again."
            ;;
    esac
done

