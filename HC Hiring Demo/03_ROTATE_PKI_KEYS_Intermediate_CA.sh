echo "#######################################" && \
echo "Rotate Intermediate CA in VAULT........." && \
echo "#######################################"
vault list -detailed pki_int/issuers

echo "***************************************" && \
echo "Generate PRIVATE KEY and CSR for v1.2 ISSUER" && \
echo "***************************************"
vault write -format=json \
    pki_int/intermediate/generate/internal \
    organization="Example" \
    common_name="Example Labs Intermediae CA v1.2" \
    key_type=ec \
    key_bits=256 \
    | jq -r '.data.csr' > pki_int_v1.2.csr

echo "***************************************" && \
echo "Sign and Generate a certificate using the CSR with Root CA" && \
echo "***************************************"
certstrap --depot-path root sign \
    --CA "Example Labs Root CA v1" \
    --passphrase "secret" \
    --intermediate \
    --csr pki_int_v1.2.csr \
    --expires "5 years" \
    --path-length 1 \
    --cert pki_int_v1.2.crt \
    "Example Labs Intermediate CA v1.2"

openssl x509 -in pki_int_v1.2.crt -text -noout

echo "***************************************" && \
echo "Store signed certificate into the Intermediate CA" && \
echo "***************************************"
cat pki_iss_v1.1.2.crt pki_int_v1.1.crt > pki_iss_v1.1.2.chain.crt
vault write -format=json \
    pki_int/intermediate/set-signed \
    certificate=@pki_int_v1.2.crt \
    > pki_int_v1.2.set-signed.json && cat pki_int_v1.2.set-signed.json
read -p "Press enter to continue"

echo "***************************************" && \
echo "Rename the new Intermediate Issuer to v1.2" && \
echo "***************************************"
cat pki_int_v1.2.set-signed.json \
    | jq -r '.data.imported_issuers[0]' \
    > pki_int_v1.2.issuer_ref
vault write -format=json \
    pki_int/issuer/`cat pki_int_v1.2.issuer_ref` \
    issuer_name=v1.2 \
    > pki_int_v1.2.rename.json
    
echo "***************************************" && \
echo "Generate a new issuer for the Issuing CA v1.2.1" && \
echo "***************************************"
vault write -format=json \
    pki_iss/intermediate/generate/internal \
    organization="Example" \
    common_name="Example Labs Issuing CA v1.2.1" \
    key_type=ec \
    key_bits=256 \
    | jq -r '.data.csr' > pki_iss_v1.2.1.csr

vault write -format=json \
    pki_int/issuer/v1.2/sign-intermediate \
    organization="Example" \
    csr=@pki_iss_v1.2.1.csr \
    ttl=8760h \
    format=pem \
    > pki_iss_v1.2.1.crt.json && cat pki_iss_v1.2.1.crt.json

cat pki_iss_v1.2.1.crt.json \
    | jq -r '.data.certificate' \
    > pki_iss_v1.2.1.crt && openssl x509 -in pki_iss_v1.2.1.crt -text -noout

cat pki_iss_v1.2.1.crt pki_int_v1.2.crt > pki_iss_v1.2.1.chain.crt
vault write -format=json \
    pki_iss/intermediate/set-signed \
    certificate=@pki_iss_v1.2.1.chain.crt \
    > pki_iss_v1.2.1.set-signed.json
cat pki_iss_v1.2.1.set-signed.json

cat pki_iss_v1.2.1.set-signed.json \
    | jq -r '.data.imported_issuers[0]' \
    > pki_iss_v1.2.1.issuer_ref
vault write -format=json \
    pki_iss/issuer/`cat pki_iss_v1.2.1.issuer_ref` \
    issuer_name=v1.2.1 \
    > pki_iss_v1.2.1.rename.json && cat pki_iss_v1.2.1.rename.json
echo "***************************************" && \
echo "Check CONSUL Terminal v1.2 and v1.2.1 should be GENERATED" && \
echo "***************************************"

read -p "Press enter to continue"
echo "***************************************" && \
echo "Rotate the Intermediate CA by setting the default issuer to v1.2" && \
echo "***************************************"

vault write -format=json \
    pki_int/root/replace \
    default=v1.2 \
    > pki_int_v1.2.replace.json && cat pki_int_v1.2.replace.json

vault list -detailed pki_iss/issuers | grep -v "n/a"
read -p "Press enter to continue"

echo "***************************************" && \
echo "Rotate the Issuing CA by setting the default issuer to v1.2.1" && \
echo "***************************************"

vault write -format=json \
    pki_iss/root/replace \
    default=v1.2.1 \
    > pki_iss_v1.2.1.replace.json && cat pki_iss_v1.2.1.replace.json

vault list -detailed pki_iss/issuers | grep -v "n/a"

echo "#######################################" && \
echo "Rotation of CERTIFICATE in Intermediate CA in VAULT COMPLETED" && \
echo "#######################################"