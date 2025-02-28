#!/bin/bash

# Source the library files
source lib/config.sh
source lib/ca.sh
source lib/cert.sh
source lib/utils.sh

# Check if at least two parameters are provided
if [ $# -lt 2 ]; then
    display_usage
fi

# Initialize variables
CERT_NAME=$1
shift

CERT_TYPE=""
VALIDITY_DAYS=0
ADD_MODE=false
REMOVE_MODE=false
REPLACE_MODE=false
FORCE_MODE=false
DOMAINS=()

# Parse arguments
while [[ "$1" != "" ]]; do
    case $1 in
        --add) ADD_MODE=true ;;
        --remove) REMOVE_MODE=true ;;
        --replace) REPLACE_MODE=true ;;
        --force) FORCE_MODE=true ;;
        --type)
            shift
            CERT_TYPE="$1"
            ;;
        --validity)
            shift
            VALIDITY_DAYS="$1"
            ;;
        *) DOMAINS+=("$1") ;;
    esac
    shift
done

# Validate that certificate type is specified and valid
if [[ "$CERT_TYPE" != "client" && "$CERT_TYPE" != "member" && "$CERT_TYPE" != "localdev" ]]; then
    echo "${red}Error: You must specify a valid certificate type with --type [client|member|localdev].${reset}"
    exit 1
fi

# Validate mode and domain count
mode_count=0
[[ "$ADD_MODE" == true ]] && ((mode_count++))
[[ "$REMOVE_MODE" == true ]] && ((mode_count++))
[[ "$REPLACE_MODE" == true ]] && ((mode_count++))

if [ "$mode_count" -ne 1 ]; then
    echo "${red}Error: Exactly one of --add, --remove, or --replace must be specified.${reset}"
    exit 1
fi
if [ ${#DOMAINS[@]} -eq 0 ]; then
    echo "${red}Error: At least one domain must be provided.${reset}"
    exit 1
fi

# Generate unique CN and temporary certificate name
TIMESTAMP=$(date '+%Y%m%d%H%M%S')

# Set the CN as the first domain in the DOMAINS array
UNIQUE_CN="${DOMAINS[0]}"

# Build the alternate names block only if more than one domain is supplied
SAN="[ alternate_names ]\n"
i=0
# Skip the first domain since it's used as the CN
for DOMAIN in "${DOMAINS[@]}"; do
    SAN+="DNS.$i = $DOMAIN\n"
    ((i++))
done

TEMP_CERT_NAME="temp_cert_${CERT_NAME//[^a-zA-Z0-9]/-}-$TIMESTAMP"

# Ensure necessary directories exist
mkdir -p ca certs/old ca_files

# Config file paths
TEMPLATE_CONFIG_CA_FILE="config_ssl_ca_template.cnf"
CONFIG_CA_FILE="config_ssl_ca.cnf"

# Choose the template based on certificate type
if [ "$CERT_TYPE" = "member" ]; then
    TEMPLATE_CONFIG_FILE="config_ssl_member_template.cnf"
    CONFIG_FILE="config_ssl_member.cnf"
elif [ "$CERT_TYPE" = "client" ]; then
    TEMPLATE_CONFIG_FILE="config_ssl_client_template.cnf"
    CONFIG_FILE="config_ssl_client.cnf"
elif [ "$CERT_TYPE" = "localdev" ]; then
    TEMPLATE_CONFIG_FILE="config_ssl_localdev_template.cnf"
    CONFIG_FILE="config_ssl_localdev.cnf"
fi

# Create configuration files if needed
create_config_files

# Create Root CA if needed
create_root_ca

# Paths for certificate files
CERT_PATH="certs/$CERT_NAME.crt"
KEY_PATH="certs/$CERT_NAME.key"
TEMP_CERT_PATH="certs/$TEMP_CERT_NAME.crt"
TEMP_KEY_PATH="certs/$TEMP_CERT_NAME.key"

# Check if certificate exists before proceeding
if [ "$REMOVE_MODE" == true ] && [ ! -f "$CERT_PATH" ]; then
    echo "${red}Error: Certificate $CERT_NAME does not exist, cannot remove domains from a non-existent certificate.${reset}"
    exit 1
fi

# Check existing certificate and handle domain modification
check_existing_certificate

# Generate a new temporary certificate
generate_temp_certificate

# Validate the temporary certificate
if openssl x509 -noout -in "$TEMP_CERT_PATH"; then
    echo "${green}Temporary certificate created successfully.${reset}"

    # Rename old certificate if needed
    [ -f "$CERT_PATH" ] && rename_old_certificate

    # Rename temporary certificate to final name
    mv "$TEMP_CERT_PATH" "$CERT_PATH"
    mv "$TEMP_KEY_PATH" "$KEY_PATH"
    echo "${green}Temporary certificate renamed to $CERT_NAME successfully.${reset}"

    # Create a combined PEM file (key + cert) for applications that require a single file.
    cat "$KEY_PATH" "$CERT_PATH" > "certs/${CERT_NAME}.pem"
    echo "${green}Combined PEM file created as certs/${CERT_NAME}.pem.${reset}"
else
    echo "${red}Error: Temporary certificate creation failed or invalid. Aborting.${reset}"
    rm -f "$TEMP_CERT_PATH" "$TEMP_KEY_PATH"
    exit 1
fi

# Display the final list of domains in the certificate
display_domains "final" "${DOMAINS[@]}"
