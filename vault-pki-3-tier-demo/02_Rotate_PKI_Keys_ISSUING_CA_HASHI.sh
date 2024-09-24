echo "#######################################" && \
echo "Rotate Issuing CA in VAULT........." && \
echo "#######################################"

echo "#######################################" && \
echo "Generate a new issuer for Issuing CA" && \
echo "#######################################"


echo "***************************************" && \
echo "Generate PRIVATE KEY and CSR for v1.1.2 ISSUER" && \
echo "***************************************"
vault write -format=json \
    demo-pki_iss/intermediate/generate/internal \
    organization="Hashicorp" \
    common_name="Hashicorp SE Issuing CA v1.1.2" \
    key_type=ec \
    key_bits=256 \
    > pki_iss_v1.1.2.csr.json && cat pki_iss_v1.1.2.csr.json

cat pki_iss_v1.1.2.csr.json | jq -r '.data.csr' \
    > pki_iss_v1.1.2.csr && openssl req -text -noout -verify -in pki_iss_v1.1.2.csr


echo "***************************************" && \
echo "Verify SUBJECT, it should mention Issuing CA v1.1.2" && \
echo "***************************************"

echo "***************************************" && \
echo "Sign and Generate a certificate using the CSR with Intermediate CA" && \
echo "***************************************"
vault write -format=json \
    demo-pki_int/root/sign-intermediate \
    organization="Hashicorp" \
    csr=@pki_iss_v1.1.2.csr \
    ttl=8760h \
    format=pem \
    > pki_iss_v1.1.2.crt.json && cat pki_iss_v1.1.2.crt.json

cat pki_iss_v1.1.2.crt.json | jq -r '.data.certificate' \
    > pki_iss_v1.1.2.crt && openssl x509 -in pki_iss_v1.1.2.crt -text -noout
echo "***************************************" && \
echo "Verify ISSUER and SUBJECT, it should mention Int CA v1.1 and Issuing CA v1.1.2" && \
echo "***************************************"
read -p "Press enter to continue"

echo "***************************************" && \
echo "Store intermediate certificate and new issuing certificate into the Issuing CA" && \
echo "***************************************"
cat pki_iss_v1.1.2.crt pki_int_v1.1.crt > pki_iss_v1.1.2.chain.crt
vault write -format=json \
    demo-pki_iss/intermediate/set-signed \
    certificate=@pki_iss_v1.1.2.chain.crt \
    > pki_iss_v1.1.2.set-signed.json && cat pki_iss_v1.1.2.set-signed.json

echo "***************************************" && \
echo "Rename the new issuer to v1.1.2" && \
echo "***************************************"
cat pki_iss_v1.1.2.set-signed.json \
    | jq -r '.data.imported_issuers[0]' \
    > pki_iss_v1.1.2.issuer_id
vault write -format=json \
    demo-pki_iss/issuer/`cat pki_iss_v1.1.2.issuer_id` \
    issuer_name=v1.1.2 \
    > pki_iss_v1.1.2.rename.json && cat pki_iss_v1.1.2.rename.json
    
echo "***************************************" && \
echo "Check, ISSUER ID SHOULD BE RENAMED TO v1.1.2" && \
echo "***************************************"
read -p "Press enter to continue"

echo "***************************************" && \
echo "Rotate the Issuing CA by setting the default issuer to v1.1.2" && \
echo "***************************************"

vault write -format=json \
    demo-pki_iss/root/replace \
    default=v1.1.2 \
    > pki_iss_v1.1.2.replace.json && cat pki_iss_v1.1.2.replace.json
vault list -detailed demo-pki_iss/issuers | grep -v "n/a"
read -p "Press enter to continue"

echo "#######################################" && \
echo "Rotation of CERTIFICATE in Issuing CA in VAULT COMPLETED" && \
echo "#######################################"