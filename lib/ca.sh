#!/bin/bash

# Function to create Root CA if it does not exist
create_root_ca() {
    if [ ! -f ca/ca.key ]; then
        confirm_action "${yellow}Do you want to create a new Root CA?${reset}"
        echo "${yellow}Creating encrypted Root CA key...${reset}"
        openssl genrsa -aes256 -out ca/ca.key 2048  # Encrypted private key with a passphrase
        echo "${yellow}Creating Root CA certificate...${reset}"
        openssl req -new -x509 -key ca/ca.key -out ca/ca.crt -days 3650 -config config_ssl_ca.cnf
    else
        echo "${green}Root CA already exists, using existing CA.${reset}"
    fi

    # Ensure CA files directory exists
    mkdir -p ca_files

    # Initialize CA-related files
    touch ca_files/index.txt
    if [ ! -f ca_files/ca.srl ]; then
        echo "${yellow}Initializing serial number for CA...${reset}"
        echo 00 > ca_files/ca.srl  # Initialize serial number
    fi
}
