#!/bin/bash

# Function to check if a certificate already exists and manage domain modification
check_existing_certificate() {
    if [ -f "$CERT_PATH" ]; then
        echo "${green}Certificate $CERT_NAME already exists.${reset}"

        # Extract existing domains from the certificate
        EXISTING_DOMAINS=$(openssl x509 -in "$CERT_PATH" -noout -text | grep -oP '(?<=DNS:)[^,]*')
        EXISTING_DOMAINS_ARRAY=($EXISTING_DOMAINS)

        # Initialize a temporary array to store the modified domain list
        TEMP_DOMAINS=("${EXISTING_DOMAINS_ARRAY[@]}")

        # Perform add, remove, or replace operations
        if [ "$ADD_MODE" = true ]; then
            echo "${yellow}Adding new domains to the certificate...${reset}"
            for DOMAIN in "${DOMAINS[@]}"; do
                if [[ ! " ${TEMP_DOMAINS[@]} " =~ " ${DOMAIN} " ]]; then
                    TEMP_DOMAINS+=("$DOMAIN")
                fi
            done

        elif [ "$REMOVE_MODE" = true ]; then
            echo "${yellow}Removing specified domains from the certificate...${reset}"
            for REMOVE_DOMAIN in "${DOMAINS[@]}"; do
                for i in "${!TEMP_DOMAINS[@]}"; do
                    if [[ "${TEMP_DOMAINS[i]}" == "$REMOVE_DOMAIN" ]]; then
                        unset 'TEMP_DOMAINS[i]'
                    fi
                done
            done
            TEMP_DOMAINS=("${TEMP_DOMAINS[@]}")  # Clean up empty entries

        elif [ "$REPLACE_MODE" = true ]; then
            echo "${yellow}Replacing existing domains with the new domains provided...${reset}"
            TEMP_DOMAINS=("${DOMAINS[@]}")
        fi

        # Remove duplicates and sort arrays for comparison
        IFS=$'\n' TEMP_DOMAINS=($(sort -u <<<"${TEMP_DOMAINS[*]}"))
        IFS=$'\n' EXISTING_DOMAINS_ARRAY=($(sort -u <<<"${EXISTING_DOMAINS_ARRAY[*]}"))
        unset IFS

        # Handle empty domain list scenario
        if [ ${#TEMP_DOMAINS[@]} -eq 0 ]; then
            echo "${red}No domains remain after modification.${reset}"
            confirm_action "Do you want to remove the certificate for $CERT_NAME?"
            echo "${yellow}Removing certificate...${reset}"
            rm -f "$CERT_PATH" "$KEY_PATH"
            echo "${green}Certificate removed.${reset}"
            exit 0
        fi

        # Compare sorted domain lists
        if [ "${#TEMP_DOMAINS[@]}" -eq "${#EXISTING_DOMAINS_ARRAY[@]}" ] && [[ "${TEMP_DOMAINS[*]}" == "${EXISTING_DOMAINS_ARRAY[*]}" ]]; then
            echo "${green}The resulting domains match the existing certificate. No changes required.${reset}"
            display_domains "existing" "${EXISTING_DOMAINS_ARRAY[@]}"
            exit 0
        else
            echo "${yellow}The resulting domains differ from the existing certificate. Proposed changes:${reset}"
            display_domains "existing" "${EXISTING_DOMAINS_ARRAY[@]}"
            display_domains "new" "${TEMP_DOMAINS[@]}"
            confirm_action "Do you want to proceed with the changes?"
            DOMAINS=("${TEMP_DOMAINS[@]}")
        fi
    else
        echo "${yellow}Certificate $CERT_NAME does not exist. Creating a new one...${reset}"
        if [ "$REMOVE_MODE" = true ]; then
            echo "${red}Error: Attempted to remove domains from a non-existent certificate.${reset}"
            exit 1
        fi

        display_domains "new" "${DOMAINS[@]}"
        confirm_action "Do you want to create a new certificate for $CERT_NAME with the provided domains?"
        DOMAINS=("${DOMAINS[@]}")
    fi
}

# Function to rename the old certificate and key
rename_old_certificate() {
    OLD_CERT_DIR="certs/old/$CERT_NAME"
    mkdir -p "$OLD_CERT_DIR"
    mv "$CERT_PATH" "$OLD_CERT_DIR/${CERT_NAME}_${TIMESTAMP}.crt"
    mv "$KEY_PATH" "$OLD_CERT_DIR/${CERT_NAME}_${TIMESTAMP}.key"
    echo "${green}Old certificate moved to $OLD_CERT_DIR/${CERT_NAME}_${TIMESTAMP}.crt${reset}"
}

# Function to generate a new temporary certificate
generate_temp_certificate() {
    SAN="[ alternate_names ]\n"
    i=1
    for DOMAIN in "${DOMAINS[@]}"; do
        SAN+="DNS.$i = $DOMAIN\n"
        ((i++))
    done

    cp config_ssl.cnf config_ssl_multi.cnf
    sed -i "s/{DOMAIN}/$UNIQUE_CN/g" config_ssl_multi.cnf
    sed -i "s/{alternate_names}/$SAN/g" config_ssl_multi.cnf

    echo "${yellow}Generating temporary key and CSR for the provided domains...${reset}"
    openssl genrsa -out "$TEMP_KEY_PATH" 2048
    openssl req -new -sha256 -key "$TEMP_KEY_PATH" -config config_ssl_multi.cnf -out "certs/$TEMP_CERT_NAME.csr"

    # Ensure Serial and Index Files Exist
    [ ! -f ca_files/ca.srl ] && echo 00 > ca_files/ca.srl
    [ ! -f ca_files/index.txt ] && touch ca_files/index.txt

    echo "${yellow}Signing the temporary certificate for all provided domains...${reset}"
    openssl ca -config config_ca.cnf -out "$TEMP_CERT_PATH" -in "certs/$TEMP_CERT_NAME.csr" -keyfile ca/ca.key

    rm config_ssl_multi.cnf
    rm "certs/$TEMP_CERT_NAME.csr"
}
