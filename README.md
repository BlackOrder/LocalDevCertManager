# LocalDevCertManager

**LocalDevCertManager** is a script-based tool for generating and managing SSL/TLS certificates for local development environments. This tool creates a root Certificate Authority (CA) and generates domain-specific certificates signed by this CA, ensuring secure communication for development purposes.

## Features

- **Root CA Generation**: Creates a root CA with an encrypted private key to securely sign certificates.
- **Certificate Management**: Generates and manages SSL/TLS certificates for multiple domains or subdomains.
- **Automated Renewal**: Automatically renews certificates when they are expired or missing necessary domains.
- **Easy Configuration**: Uses template configuration files to simplify the certificate creation process.

## Prerequisites

- **OpenSSL**: Ensure OpenSSL is installed on your machine.

## Installation

1. **Clone the repository**:

    ``` bash
    git clone https://github.com/yourusername/LocalDevCertManager.git
    cd LocalDevCertManager
    ```

2. **Make the script executable**:

    ``` bash
    chmod +x generate_certificates.sh
    ```

## Usage

To create or manage certificates, run the ` generate_certificates.sh ` script with the following parameters:

``` bash
./generate_certificates.sh <cert_name> <domain1> [<domain2> ... <domainN>]
```

### Example

``` bash
./generate_certificates.sh "MyCert" example.local www.example.local api.example.local
```

This command creates a new certificate named ` MyCert ` for the domains ` example.local `, ` www.example.local `, and ` api.example.local `.

### Notes

- If the configuration files (` config_ssl.cnf ` or ` config_ssl_ca.cnf `) do not exist, the script will generate them based on the template files and prompt the user for required details.
- The generated certificates are stored in the ` certs ` directory, and the root CA is stored in the ` ca ` directory.


## Trusting the CA Certificate

To make your generated certificates trusted by your browser and operating system, you need to trust the root CA certificate.

### Windows

Open the Run dialog by pressing ` Win + R `, type ` certmgr.msc `, and press Enter.
In the Certificates - Current User window, navigate to Trusted Root Certification Authorities # Certificates.
Right-click inside the window and select All Tasks # Import....
Follow the prompts to import the ` ca.crt ` file from the ` ca ` directory of this repository.
Restart your browser to apply the changes.
### Linux

Copy the CA certificate (` ca/ca.crt `) to the trusted certificates directory (e.g., ` /usr/local/share/ca-certificates/ `).

``` bash sudo cp ca/ca.crt /usr/local/share/ca-certificates/localdevca.crt ```

Update the CA store:

``` bash sudo update-ca-certificates ```

Restart your browser to apply the changes.

## Files

- **.gitignore**: Lists files and directories to be ignored by Git, such as generated certificates and configuration files.
- **config_ca.cnf**: Configuration file for the root Certificate Authority.
- **config_ssl_ca_template.cnf**: Template for creating the CA configuration file.
- **config_ssl_template.cnf**: Template for creating the SSL certificate configuration file.
- **generate_certificates.sh**: Main script to generate and manage certificates.

## Contributing

Feel free to open issues, submit pull requests, or suggest features to improve this tool.

## License

This project is licensed under the MIT License - see the ` LICENSE ` file for details.
