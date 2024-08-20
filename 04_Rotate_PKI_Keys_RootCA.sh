echo "#######################################" && \
echo "Creating Root CA V2 using CERTSTRAP......." && \
echo "#######################################"

certstrap --depot-path root \
    init \
    --organization "Example" \
    --common-name "Example Labs Root CA v2" \
    --expires "10 years" \
    --curve P-256 \
    --path-length 2 \
    --passphrase "secret"

echo "#######################################" && \
echo "Root CA using CERTSTRAP COMPLETED" && \
echo "#######################################"

read -p "Press enter to continue"

echo "#######################################" && \
echo "Generate a new issuer for the Intermediate CA V2.1" && \
echo "#######################################"
vault write -format=json \
    pki_int/intermediate/generate/internal \
    organization="Example" \
    common_name="Example Labs Intermediae CA v2.1" \
    key_type=ec \
    key_bits=256 \
    | jq -r '.data.csr' > pki_int_v2.1.csr

read -p "Press enter to continue"

echo "***************************************" && \
echo "Sign and generate a certificate using the CSR with Root CA V2" && \
echo "***************************************"
certstrap --depot-path root \
    sign \
    --CA "Example Labs Root CA v2" \
    --passphrase "secret" \
    --intermediate \
    --csr pki_int_v2.1.csr \
    --expires "5 years" \
    --path-length 1 \
    --cert pki_int_v2.1.crt \
    "Example Labs Intermediate CA v2.1"

openssl x509 -in pki_int_v1.1.crt -text -noout

read -p "Press enter to continue"

echo "***************************************" && \
echo "Store the resulting certificate into the Intermediate CA V2" && \
echo "using the pki_int/intermediate/set-signed endpoint" && \
echo "***************************************"
vault write -format=json \
    pki_int/intermediate/set-signed \
    certificate=@pki_int_v2.1.crt \
    > pki_int_v2.1.set-signed.json && cat pki_int_v2.1.set-signed.json

cat pki_int_v2.1.set-signed.json \
    | jq -r '.data.imported_issuers[0]' \
    > pki_int_v2.1.issuer_ref
vault write -format=json \
    pki_int/issuer/`cat pki_int_v2.1.issuer_ref` \
    issuer_name=v2.1 \
    > pki_int_v2.1.rename.json && cat pki_int_v2.1.rename.json

read -p "Press enter to continue"

echo "#######################################" && \
echo "Intermediate CA using VAULT COMPLETED, CHECK CERTIFICATES IN VAULT UI" && \
echo "#######################################"
ls -ltr
read -p "Press enter to continue"

echo "#######################################" && \
echo "Creating Issuing CA V2 using VAULT..." && \
echo "#######################################"

echo "***************************************" && \
echo "Generate private key and CSR for Issuing CA V2.1.1" && \
echo "using the pki_int/intermediate/generate/internal endpoint" && \
echo "***************************************"
vault write -format=json \
    pki_iss/intermediate/generate/internal \
    organization="Example" \
    common_name="Example Labs Issuing CA v2.1.1" \
    key_type=ec \
    key_bits=256 \
    | jq -r '.data.csr' > pki_iss_v2.1.1.csr

read -p "Press enter to continue"

echo "***************************************" && \
echo "Sign and generate a certificate using the CSR with the Intermediate CA V2.1" && \
echo "***************************************"
vault write -format=json \
    pki_int/issuer/v2.1/sign-intermediate \
    organization="Example" \
    csr=@pki_iss_v2.1.1.csr \
    ttl=8760h \
    format=pem \
    > pki_iss_v2.1.1.crt.json && cat pki_iss_v2.1.1.crt.json
cat pki_iss_v2.1.1.crt.json \
  | jq -r '.data.certificate' \
  > pki_iss_v2.1.1.crt && openssl x509 -in pki_iss_v2.1.1.crt -text -noout

echo "*******************************************************************************" && \
echo "BOTH Intermediate & Issuing CA SHOULD BE VISIBLE NOW IN THE CERTIFICATES" && \
echo "*******************************************************************************"
read -p "Press enter to continue"

echo "***************************************" && \
echo "Store intermediate and issuing certificates into the Issuing CA 2.1.1" && \
echo "using the pki_int/intermediate/set-signed endpoint" && \
echo "***************************************"
cat pki_iss_v2.1.1.crt pki_int_v2.1.crt > pki_iss_v2.1.1.chain.crt
vault write -format=json \
    pki_iss/intermediate/set-signed \
    certificate=@pki_iss_v2.1.1.chain.crt \
    > pki_iss_v2.1.1.set-signed.json
cat pki_iss_v2.1.1.set-signed.json

cat pki_iss_v2.1.1.set-signed.json \
    | jq -r '.data.imported_issuers[0]' \
    > pki_iss_v2.1.1.issuer_ref
vault write -format=json \
    pki_iss/issuer/`cat pki_iss_v2.1.1.issuer_ref` \
    issuer_name=v2.1.1 \
    > pki_iss_v2.1.1.rename.json
cat pki_iss_v2.1.1.rename.json


read -p "Press enter to continue"

echo "#######################################" && \
echo "Issuing CA using VAULT COMPLETED, CHECK CERTIFICATES IN VAULT UI" && \
echo "#######################################"
ls -ltr
read -p "Press enter to continue"

echo "***************************************" && \
echo "Rotate the Intermediate CA by setting the default issuer to v2.1" && \
echo "***************************************"
vault write -format=json \
    pki_int/root/replace \
    default=v2.1 \
    > pki_int_v2.1.replace.json
cat pki_int_v2.1.replace.json

read -p "Press enter to continue"

echo "***************************************" && \
echo "Rotate the Issuing CA by setting the default issuer to v2.1.1" && \
echo "***************************************"

vault write -format=json \
    pki_iss/root/replace \
    default=v2.1.1 \
    > pki_iss_v2.1.1.replace.json && cat pki_iss_v2.1.1.replace.json

echo "***************************************" && \
echo "Check CONSUL Terminal v2.1 and v2.1.1 certificates should be GENERATED" && \
echo "***************************************"
read -p "Press enter to continue"



echo "#######################################" && \
echo "Rotation of CERTIFICATE in Root CA in VAULT COMPLETED" && \
echo "#######################################"