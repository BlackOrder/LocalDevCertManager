#!/bin/bash

# Function to create Root CA if it does not exist
create_root_ca() {
    # Check if the CA_KEY_PASS environment variable is set.
    if [ -z "$CA_KEY_PASS" ]; then
        echo "${red}Error: CA_KEY_PASS is not set. Please export it before running the script.${reset}"
        exit 1
    fi

    if [ ! -f ca/ca.key ]; then
        confirm_action "${yellow}Do you want to create a new Root CA?${reset}"
        echo "${yellow}Creating encrypted Root CA key...${reset}"
        # Use -passout to provide the passphrase from the environment variable
        openssl genrsa -aes256 -passout env:CA_KEY_PASS -out ca/ca.key 2048
        echo "${yellow}Creating Root CA certificate...${reset}"
        # Use -passin to provide the passphrase when reading the key
        openssl req -new -x509 -key ca/ca.key -passin env:CA_KEY_PASS -out ca/ca.crt -days 10000 -config config_ssl_ca.cnf
    else
        # Validate that the exported CA_KEY_PASS is valid for the existing CA key.
        if ! openssl rsa -in ca/ca.key -passin env:CA_KEY_PASS -check -noout >/dev/null 2>&1; then
            echo "${red}Error: The exported CA_KEY_PASS is invalid for the existing CA key. Please check your passphrase.${reset}"
            exit 1
        else
            echo "${green}Existing Root CA key found and passphrase is valid. Using existing CA.${reset}"
        fi
    fi

    # Ensure CA files directory exists
    mkdir -p ca_files

    # Initialize CA-related files
    touch ca_files/index.txt
    if [ ! -f ca_files/ca.srl ]; then
        echo "${yellow}Initializing serial number for CA...${reset}"
        echo "01" > ca_files/ca.srl  # Initialize serial number with a non-zero value
    fi
}

