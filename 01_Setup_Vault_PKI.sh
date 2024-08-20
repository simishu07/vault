

if ! command -v vault &> /dev/null
then
    echo "VAULT not installed"
    exit 1
fi
if ! command -v certstrap &> /dev/null
then
    echo "CERTSTRAP not installed"
    exit 1
fi


echo "#######################################" && \
echo "Creating Root CA using CERTSTRAP......." && \
echo "#######################################"

certstrap --depot-path root init \
    --organization "Example" \
    --common-name "Example Labs Root CA v1" \
    --expires "10 years" \
    --curve P-256 \
    --path-length 2 \
    --passphrase "secret"

echo "#######################################" && \
echo "Root CA using CERTSTRAP COMPLETED" && \
echo "#######################################"

read -p "Press enter to continue"

echo "#######################################" && \
echo "Creating Intermediate CA using VAULT..." && \
echo "#######################################"

read -p "Press enter to continue"

echo "***************************************" && \
echo "Enable and tune PKI secrets engine....." && \
echo "***************************************"
vault secrets enable -path=pki_int pki
vault secrets tune -max-lease-ttl=43800h pki_int

read -p "Press enter to continue"

echo "***************************************" && \
echo "Configure CA and CRL URLs.............." && \
echo "***************************************"

vault write pki_int/config/urls \
    issuing_certificates="http://127.0.0.1:8200/v1/pki_int/ca" \
    crl_distribution_points="http://127.0.0.1:8200/v1/pki_int/crl"

read -p "Press enter to continue"

echo "***************************************" && \
echo "Generate private key and CSR for Intermediate CA" && \
echo "using the pki_int/intermediate/generate/internal endpoint" && \
echo "***************************************"
vault write -format=json \
    pki_int/intermediate/generate/internal \
    organization="Example" \
    common_name="Example Labs Intermediate CA v1.1" \
    key_type=ec \
    key_bits=256 \
    > pki_int_v1.1.csr.json

cat pki_int_v1.1.csr.json
cat pki_int_v1.1.csr.json | jq -r '.data.csr' > pki_int_v1.1.csr
openssl req -text -noout -verify -in pki_int_v1.1.csr

read -p "Press enter to continue"

echo "***************************************" && \
echo "Sign and generate a certificate using the CSR with Root CA" && \
echo "***************************************"
certstrap --depot-path root sign \
    --CA "Example Labs Root CA v1" \
    --passphrase "secret" \
    --intermediate \
    --csr pki_int_v1.1.csr \
    --expires "5 years" \
    --path-length 1 \
    --cert pki_int_v1.1.crt \
    "Example Labs Intermediate CA v1.1"
openssl x509 -in pki_int_v1.1.crt -text -noout

read -p "Press enter to continue"

echo "***************************************" && \
echo "Store the resulting certificate into the Intermediate CA" && \
echo "using the pki_int/intermediate/set-signed endpoint" && \
echo "***************************************"
vault write -format=json \
    pki_int/intermediate/set-signed \
    certificate=@pki_int_v1.1.crt \
    > pki_int_v1.1.set-signed.json

cat pki_int_v1.1.set-signed.json

read -p "Press enter to continue"

echo "#######################################" && \
echo "Intermediate CA using VAULT COMPLETED, CHECK CERTIFICATES IN VAULT UI" && \
echo "#######################################"
ls -ltr
read -p "Press enter to continue"

echo "#######################################" && \
echo "Creating Issuing CA using VAULT..." && \
echo "#######################################"


echo "***************************************" && \
echo "Enable and tune PKI secrets engine....." && \
echo "***************************************"
vault secrets enable -path=pki_iss pki
vault secrets tune -max-lease-ttl=8760h pki_iss

read -p "Press enter to continue"


echo "***************************************" && \
echo "Configure CA and CRL URLs.............." && \
echo "***************************************"

vault write pki_iss/config/urls \
    issuing_certificates="http://127.0.0.1:8200/v1/pki_iss/ca" \
    crl_distribution_points="http://127.0.0.1:8200/v1/pki_iss/crl"

read -p "Press enter to continue"

echo "***************************************" && \
echo "Generate private key and CSR for Issuing CA" && \
echo "using the pki_int/intermediate/generate/internal endpoint" && \
echo "***************************************"
vault write -format=json \
    pki_iss/intermediate/generate/internal \
    organization="Example" \
    common_name="Example Labs Issuing CA v1.1.1" \
    key_type=ec \
    key_bits=256 \
    > pki_iss_v1.1.1.csr.json

cat pki_iss_v1.1.1.csr.json

cat pki_iss_v1.1.1.csr.json | jq -r '.data.csr' \
    > pki_iss_v1.1.1.csr
openssl req -text -noout -verify -in pki_iss_v1.1.1.csr

read -p "Press enter to continue"

echo "***************************************" && \
echo "Sign and generate a certificate using the CSR with the Intermediate CA" && \
echo "***************************************"
vault write -format=json \
    pki_int/root/sign-intermediate \
    organization="Example" \
    csr=@pki_iss_v1.1.1.csr \
    ttl=8760h \
    format=pem \
    > pki_iss_v1.1.1.crt.json
cat pki_iss_v1.1.1.crt.json
cat pki_iss_v1.1.1.crt.json | jq -r '.data.certificate' \
    > pki_iss_v1.1.1.crt
openssl x509 -in pki_iss_v1.1.1.crt -text -noout   

echo "*******************************************************************************" && \
echo "BOTH Intermediate & Issuing CA SHOULD BE VISIBLE NOW IN THE CERTIFICATES" && \
echo "*******************************************************************************"
read -p "Press enter to continue"

echo "***************************************" && \
echo "Store intermediate and issuing certificates into the Issuing CA" && \
echo "using the pki_int/intermediate/set-signed endpoint" && \
echo "***************************************"
cat pki_iss_v1.1.1.crt pki_int_v1.1.crt > pki_iss_v1.1.1.chain.crt
vault write -format=json \
    pki_iss/intermediate/set-signed \
    certificate=@pki_iss_v1.1.1.chain.crt \
    > pki_iss_v1.1.1.set-signed.json

cat pki_iss_v1.1.1.set-signed.json
read -p "Press enter to continue"


echo "#######################################" && \
echo "Issuing CA using VAULT COMPLETED, CHECK CERTIFICATES IN VAULT UI" && \
echo "#######################################"
ls -ltr
read -p "Press enter to continue"

echo "#######################################" && \
echo "Create ROLE using VAULT" && \
echo "#######################################"

echo "***************************************" && \
echo "Create an issuing role" && \
echo "***************************************"
vault write pki_iss/roles/example \
    organization="Example" \
    allowed_domains="example.com" \
    allow_subdomains=true \
    allow_wildcard_certificates=false \
    key_type=ec \
    key_bits=256 \
    generate_lease=true \
    max_ttl=2160h

read -p "Press enter to continue"

echo "***************************************" && \
echo "Issue a leaf certificate" && \
echo "***************************************"
vault write -format=json \
    pki_iss/issue/example \
    common_name="sample.example.com" \
    > pki_iss_v1.1.1.sample.crt.json

cat pki_iss_v1.1.1.sample.crt.json
cat pki_iss_v1.1.1.sample.crt.json | jq -r .data.certificate \
    | openssl x509 -text -noout
read -p "Press enter to continue"


echo "***************************************" && \
echo "Watch for Issuer, Subject Field and DNS" && \
echo "***************************************"
read -p "Press enter to continue"

vault list -detailed pki_int/issuers

echo "***************************************" && \
echo "Rename the default issuer of Intermediate CA to v1.1 using the pki_int/issuer/default endpoint" && \
echo "***************************************"
vault write -format=json \
    pki_int/issuer/default \
    issuer_name=v1.1 \
    > pki_int_v1.1.rename.json && cat pki_int_v1.1.rename.json


read -p "Press enter to continue"

echo "***************************************" && \
echo "Rename the default issuer of Issuing CA to v1.1.1 using the pki_int/issuer/default endpoint" && \
echo "***************************************"
vault write -format=json \
    pki_iss/issuer/default \
    issuer_name=v1.1.1 \
    > pki_iss_v1.1.1.rename.json && cat pki_iss_v1.1.1.rename.json


echo "#######################################" && \
echo "ROLE AND LEAF CREATION COMPLETED" && \
echo "#######################################"
ls -ltr
read -p "Press enter to continue"

echo "#######################################" && \
echo "THREE TIER PKI CA SHOULD BE COMPLETED NOW" && \
echo "#######################################"
