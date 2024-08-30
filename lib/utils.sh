#!/bin/bash

# Define color functions using tput
red=$(tput setaf 1)     # Red
green=$(tput setaf 2)   # Green
yellow=$(tput setaf 3)  # Yellow
blue=$(tput setaf 4)    # Blue
bold=$(tput bold)       # Bold
reset=$(tput sgr0)      # Reset to default

# Function to display usage information
display_usage() {
    echo "${bold}${blue}Usage:${reset} $0 <cert_name> <--add|--remove|--replace> [--force] <domain1> [<domain2> ... <domainN>]"
    echo
    echo "${bold}${yellow}Description:${reset}"
    echo "  LocalDevCertManager is a script-based tool to create and manage SSL/TLS certificates for local development."
    echo "  This tool sets up a root Certificate Authority (CA) and generates domain-specific certificates signed by the CA."
    echo
    echo "${bold}${yellow}Arguments:${reset}"
    echo "  <cert_name>   A friendly name for the certificate. This name will be used to identify the certificate file."
    echo "  --add         Add new domains to an existing certificate (mandatory, choose only one mode)."
    echo "  --remove      Remove specified domains from an existing certificate (mandatory, choose only one mode)."
    echo "  --replace     Replace all existing domains in the certificate with new ones (mandatory, choose only one mode)."
    echo "  --force       Skip all confirmation prompts and force the action."
    echo "  <domain1>     The primary domain for the certificate (e.g., 'example.local')."
    echo "  [domain2]     Additional domains or subdomains for the certificate (optional)."
    echo
    echo "${bold}${yellow}Example:${reset}"
    echo "  $0 MyCert --add example.local www.example.local api.example.local"
    echo
    echo "${bold}${yellow}Notes:${reset}"
    echo "  - You must specify exactly one mode (--add, --remove, or --replace)."
    echo "  - At least one domain must be provided."
    echo "  - The script will prompt for user input to create configuration files if they do not exist."
    echo "  - The root CA key is created with encryption and will require a passphrase for security."
    echo "  - The generated certificates are stored in the 'certs' directory, and the root CA is stored in the 'ca' directory."
    exit 1
}

# Function to display domains in a table format
display_domains() {
    local context="$1"
    shift
    local domains=("$@")

    # Determine the title based on the provided context
    case "$context" in
        existing)
            echo -e "\n${bold}${blue}Existing domains in the certificate:${reset}"
            ;;
        new)
            echo -e "\n${bold}${yellow}Proposed new domains for the certificate:${reset}"
            ;;
        final)
            echo -e "\n${bold}${green}Final list of domains in the certificate:${reset}"
            ;;
        *)
            echo -e "\n${bold}${blue}Domains in the certificate:${reset}"
            ;;
    esac

    # Display the domains in a table format
    if [ ${#domains[@]} -eq 0 ]; then
        echo "${red}No domains found.${reset}"
        return
    fi

    printf "${bold}%-5s %-30s${reset}\n" "No." "Domain"
    local i=1
    for DOMAIN in "${domains[@]}"; do
        printf "${green}%-5s %-30s${reset}\n" "$i" "$DOMAIN"
        ((i++))
    done
}

# Function to confirm an action, shared by all processes
confirm_action() {
    local prompt_message="$1"

    if [ "$FORCE_MODE" != true ]; then
        echo -n "${bold}${yellow}$prompt_message (y/n):${reset} "
        read -r confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo "${red}Action aborted by user.${reset}"
            exit 0
        fi
    fi
}
