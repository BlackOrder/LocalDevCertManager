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
    echo "${bold}${blue}Usage:${reset} $0 <cert_name> --type [client|member|localdev] <--add|--remove|--replace> [--force] [--validity <days>] <domain1> [<domain2> ... <domainN>]"
    echo
    echo "${bold}${yellow}Description:${reset}"
    echo "  LocalDevCertManager is a script-based tool to create and manage SSL/TLS certificates."
    echo "  It sets up a root Certificate Authority (CA) and generates domain-specific certificates"
    echo "  signed by the CA. Certificates can be used for MongoDB cluster members, clients, or"
    echo "  local development, and you can optionally override the validity period."
    echo
    echo "${bold}${yellow}Arguments:${reset}"
    echo "  <cert_name>       A friendly name for the certificate. This name identifies the certificate file."
    echo "  --type            The certificate type. Must be one of:"
    echo "                      client     (for MongoDB client authentication)"
    echo "                      member     (for MongoDB cluster member authentication)"
    echo "                      localdev   (for local development)"
    echo "  --add             Add new domains to an existing certificate (choose exactly one mode)."
    echo "  --remove          Remove specified domains from an existing certificate (choose exactly one mode)."
    echo "  --replace         Replace all existing domains in the certificate with new ones (choose exactly one mode)."
    echo "  --force           Skip all confirmation prompts and force the action."
    echo "  --validity <days> Override the certificate validity period (in days). Default is 365 days."
    echo "  <domain1>         The primary domain for the certificate (e.g., 'example.local')."
    echo "  [domain2]         Additional domains or subdomains for the certificate (optional)."
    echo
    echo "${bold}${yellow}Environment:${reset}"
    echo "  CA_KEY_PASS       The passphrase for the CA key. This must be exported in your shell."
    echo "                    Example: export CA_KEY_PASS='YourSecurePassphrase'"
    echo
    echo "${bold}${yellow}Example:${reset}"
    echo "  $0 MyCert --type client --add --validity 5000 example.local www.example.local"
    echo
    echo "${bold}${yellow}Notes:${reset}"
    echo "  - You must specify exactly one mode: --add, --remove, or --replace."
    echo "  - At least one domain must be provided."
    echo "  - The script will prompt for user input to create configuration files if they do not exist."
    echo "  - The root CA key is created with encryption and will require a passphrase provided via CA_KEY_PASS."
    echo "  - Generated certificates are stored in the 'certs' directory, and the CA is stored in the 'ca' directory."
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
# Usage: confirm_action "Prompt message" [default]
# Where [default] is "Y" or "N" (defaults to "Y")
confirm_action() {
    local prompt_message="$1"
    local default_value="${2:-Y}"  # Default to Y if no default is provided

    if [ "$FORCE_MODE" != true ]; then
        if [[ "$default_value" =~ ^[Yy]$ ]]; then
            echo -n "${bold}${yellow}$prompt_message (Y/n):${reset} "
        else
            echo -n "${bold}${yellow}$prompt_message (y/N):${reset} "
        fi

        read -r confirm

        # If no input is provided, use the default value
        if [ -z "$confirm" ]; then
            confirm="$default_value"
        fi

        # If the final response is not a yes, abort the action.
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo "${red}Action aborted by user.${reset}"
            exit 0
        fi
    fi
}
