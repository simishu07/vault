Script to check Vailidity of the certificate

#!/bin/bash

# Define Vault server URL and PKI path
VAULT_ADDR="http://10.0.0.124:8200/v1"
PKI_PATH="pki_int"

# Certificate to check
CERT_FILE="certificate.pem"

# Download CRL
echo "Downloading CRL..."
curl -s "${VAULT_ADDR}/${PKI_PATH}/crl" -o crl.pem

# Extract serial number of the certificate
echo "Extracting certificate serial number..."
SERIAL_NUMBER=$(openssl x509 -in ${CERT_FILE} -noout -serial | cut -d= -f 2)

# Check if certificate serial number exists in the CRL
echo "Checking certificate status..."
if openssl crl -in crl.pem -noout -text | grep -q "${SERIAL_NUMBER}"; then
    echo "Certificate ${SERIAL_NUMBER} has been revoked."
else
    echo "Certificate ${SERIAL_NUMBER} is still valid."
fi