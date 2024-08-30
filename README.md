# LocalDevCertManager

LocalDevCertManager is a script-based tool to create and manage SSL/TLS certificates for local development. This tool sets up a root Certificate Authority (CA) and generates domain-specific certificates signed by the CA.

## Features

Create a root Certificate Authority (CA) for local development.
Generate domain-specific certificates signed by the root CA.
Add, remove, or replace domains in existing certificates.
User-friendly prompts with colorful output for better readability.
Configuration files created automatically from templates if they do not exist.
Secure encrypted private keys for the root CA.
## Prerequisites

OpenSSL: Ensure you have OpenSSL installed on your system.
macOS: `brew install openssl`
Ubuntu/Debian: `sudo apt-get install openssl`
Arch Linux: `sudo pacman -S openssl`
## Installation

Clone the Repository:
```bash
git clone https://github.com/blackorder/LocalDevCertManager.git
cd LocalDevCertManager
```

Make Scripts Executable:
```bash
chmod +x generate_certificates.sh
chmod +x lib/*.sh
```

## Usage

```bash Usage: ./generate_certificates.sh <cert_name> <domain1> [<domain2> ... <domainN>] <--add|--remove|--replace> [--force] ```

## Arguments

`cert_name`: A friendly name for the certificate. This name will be used to identify the certificate file.
`domain1`: The primary domain for the certificate (e.g., 'example.local').
`domain2`: Additional domains or subdomains for the certificate (optional).
`--add`: Add new domains to an existing certificate (mandatory, choose only one mode).
`--remove`: Remove specified domains from an existing certificate (mandatory, choose only one mode).
`--replace`: Replace all existing domains in the certificate with new ones (mandatory, choose only one mode).
`--force`: Skip all confirmation prompts and force the action.
## Example

```bash ./generate_certificates.sh MyCert example.local www.example.local api.example.local --add ```

This example adds 'example.local', 'www.example.local', and 'api.example.local' to the 'MyCert' certificate, preserving existing domains.

## Notes

You must specify exactly one mode (`--add`, `--remove`, or `--replace`).
At least one domain must be provided.
The script will prompt for user input to create configuration files if they do not exist.
The root CA key is created with encryption and will require a passphrase for security.
The generated certificates are stored in the 'certs' directory, and the root CA is stored in the 'ca' directory.
## Example Commands

To add domains to an existing certificate:
```bash ./generate_certificates.sh MyCert newdomain.local --add ```

To remove domains from an existing certificate:
```bash ./generate_certificates.sh MyCert olddomain.local --remove ```

To replace all domains in an existing certificate:
```bash ./generate_certificates.sh MyCert newdomain1.local newdomain2.local --replace ```

To force actions without confirmation prompts:
```bash ./generate_certificates.sh MyCert newdomain.local --add --force ```

## Steps to Trust the CA

Windows
Locate the root CA certificate file, typically stored in the ca directory (e.g., ca.crt).
Open the "Run" dialog (`Windows key + R`), type mmc, and press Enter.
In the "Console", go to File ``` Add/Remove Snap-in```.
Select Certificates and click Add, choose Computer Account, then click Next, Finish, and OK.
Navigate to Trusted Root Certification Authorities ``` Certificates```.
Right-click in the window and select All Tasks ``` Import```.
Follow the wizard to import the ca.crt file.
Linux
Locate the root CA certificate file, typically stored in the ca directory (e.g., ca.crt).
Copy the certificate to the trusted root CA directory:
```bash sudo cp ca/ca.crt /usr/local/share/ca-certificates/ ```

Update the certificate store:
```bash sudo update-ca-certificates ```

## License

This project is licensed under the MIT License. See the LICENSE file for more details.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.

## Author

Developed by [blackorder](https://www.github.com/blackorder) with :heart: and :coffee:.
