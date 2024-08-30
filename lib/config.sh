#!/bin/bash

# Function to create configuration files from templates
create_config_files() {
    if [ ! -f "$CONFIG_FILE" ] || [ ! -f "$CONFIG_CA_FILE" ]; then
        echo "${yellow}Missing configuration files. Creating from the template...${reset}"

        # Prompt user for distinguished name details with default values
        echo "${blue}Please provide the details for your Distinguished Name (DN) options:${reset}"
        read -p "${bold}Country Name (2 letter code) [AE]: ${reset}" COUNTRY
        read -p "${bold}State or Province Name (full name) [Dubai]: ${reset}" STATE
        read -p "${bold}Locality Name (e.g., city) [Dubai]: ${reset}" LOCALITY
        read -p "${bold}Organization Name (e.g., company) [My Company]: ${reset}" ORG_NAME
        read -p "${bold}Organizational Unit Name (e.g., section) [Development]: ${reset}" ORG_UNIT
        read -p "${bold}Email Address [root@localhost]: ${reset}" EMAIL

        # Provide defaults if the user presses enter
        COUNTRY=${COUNTRY:-AE}
        STATE=${STATE:-Dubai}
        LOCALITY=${LOCALITY:-Dubai}
        ORG_NAME=${ORG_NAME:-My Company}
        ORG_UNIT=${ORG_UNIT:-Development}
        EMAIL=${EMAIL:-root@localhost}

        # Use the template to create the config_ssl_ca.cnf file
        sed -e "s/{COUNTRY}/$COUNTRY/g" \
            -e "s/{STATE}/$STATE/g" \
            -e "s/{LOCALITY}/$LOCALITY/g" \
            -e "s/{ORG_NAME}/$ORG_NAME/g" \
            -e "s/{ORG_UNIT}/$ORG_UNIT/g" \
            -e "s/{EMAIL}/$EMAIL/g" \
            "$TEMPLATE_CONFIG_CA_FILE" > "$CONFIG_CA_FILE"

        # Use the template to create the config_ssl.cnf file
        sed -e "s/{COUNTRY}/$COUNTRY/g" \
            -e "s/{STATE}/$STATE/g" \
            -e "s/{LOCALITY}/$LOCALITY/g" \
            -e "s/{ORG_NAME}/$ORG_NAME/g" \
            -e "s/{ORG_UNIT}/$ORG_UNIT/g" \
            -e "s/{EMAIL}/$EMAIL/g" \
            "$TEMPLATE_CONFIG_FILE" > "$CONFIG_FILE"

        echo "${green}Created $CONFIG_FILE and $CONFIG_CA_FILE successfully.${reset}"
    else
        echo "${green}Using existing configuration files.${reset}"
    fi
}
