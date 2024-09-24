===============================================================
Configure Vault with MySQL Database for Dynamic Secret
===============================================================

===============================================================
Install and configure the MySQL Database
===============================================================
mysql -u root -p

CREATE USER 'vault'@'localhost' IDENTIFIED WITH mysql_native_password BY 'Qwerty@1234';
GRANT ALL PRIVILEGES ON *.* TO 'vault'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;

ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'Qwerty@1234';

===============================================================
CONFIGURE VAULT
===============================================================

mkdir -p /home/opc/vault/data
===============================================================
Create config.hcl in home directory
===============================================================
storage "raft" {
  path    = "/home/opc/vault/data"
  node_id = "node1"
}

listener "tcp" {
  address     = "10.0.0.124:8200"
  tls_disable = "true"
}

api_addr = "http://10.0.0.124:8200"
cluster_addr = "https://10.0.0.124:8201"
ui = true
===============================================================
Prevent mlock error
===============================================================

sudo setcap cap_ipc_lock=+ep $(readlink -f $(which vault))

===============================================================
Configure Vault server with the config.hcl settings
===============================================================

vault server -config=config.hcl

===============================================================
Initialize the Vault
===============================================================
vault operator init

Unseal Key 1: x98RkXGILKkakVJ+MtvKgOamla6Y4BFuvu8j3f6DnMy1
Unseal Key 2: NJRH8ZP4EZOsyATDtgkV4nyRZxkjpj36VVxmpgyRtraG
Unseal Key 3: Pphr56LNTpBGqJIOac/ELD+bipQ3ctiOWYmZABHGcWmx
Unseal Key 4: lgMXYiu67l/ZxnojXR9h4sZxb2Lagoyl5lcPiEJykthw
Unseal Key 5: BpdUL+nlxjPFoyp7ct35G38awl0T/lMpqBNlmDE1e7aE

Initial Root Token: hvs.YrWKnsoVs2Ore5BA6Fj0j4B9

Vault initialized with 5 key shares and a key threshold of 3. Please securely
distribute the key shares printed above. When the Vault is re-sealed,
restarted, or stopped, you must supply at least 3 of these keys to unseal it
before it can start servicing requests.

Vault does not store the generated root key. Without at least 3 keys to
reconstruct the root key, Vault will remain permanently sealed!
===============================================================
Unseal the Vault using any 3 Unseal Keys
===============================================================
vault operator unseal

===============================================================
Login the Vault using Initial Root Token
===============================================================
vault login
Token (will be hidden):
Success! You are now authenticated. The token information displayed below
is already stored in the token helper. You do NOT need to run "vault login"
again. Future Vault requests will automatically use this token.

Key                  Value
---                  -----
token                hvs.YrWKnsoVs2Ore5BA6Fj0j4B9
token_accessor       tf5Bwl9Inx10r9qvRoF6LBNP
token_duration       ∞
token_renewable      false
token_policies       ["root"]
identity_policies    []
policies             ["root"]
===============================================================
Enable Database Backend for the VAULT
===============================================================
vault secrets enable database

vault write demo-mysql/config/my-mysql-database \
    plugin_name=mysql-database-plugin \
    connection_url="{{username}}:{{password}}@tcp(127.0.0.1:3306)/" \
    allowed_roles="mysqlrole" \
    username="vault" \
    password="Qwerty@1234"

vault write database/roles/mysqlrole \
    db_name=my-mysql-database \
    creation_statements="CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';GRANT SELECT ON *.* TO '{{name}}'@'%';" \
    default_ttl="1h" \
    max_ttl="24h"

===============================================================
Create temporary credentials using VAULT commandline
===============================================================
vault read database/creds/mysqlrole

Key                Value
---                -----
lease_id           database/creds/mysqlrole/umxa8gIrLGbNGamTa6PhOdt9
lease_duration     1h
lease_renewable    true
password           F9toWT9-TAbj3HHa8nzu
username           v-root-mysqlrole-hjCrBrLMUCmMYTg

===============================================================
Get list of credentials created in MySQL
===============================================================
vault list sys/leases/lookup/database/creds/mysqlrole

===============================================================
Renew Credentials by 1HR
=============================================================== 
vault lease renew database/creds/mysqlrole/$LEASE_ID

===============================================================
Revoke credential created by VAULT
===============================================================
LEASE_ID=$(vault list -format=json sys/leases/lookup/database/creds/mysqlrole | jq -r ".[0]")
vault lease revoke database/creds/mysqlrole/$LEASE_ID

===============================================================
Revoke ALL credentials created by VAULT
===============================================================
vault lease revoke -prefix database/creds/mysqlrole


===============================================================
Rotate ROOT User credentials
===============================================================

vault write database/config/my-mysql-database \
    plugin_name=mysql-database-plugin \
    connection_url="{{username}}:{{password}}@tcp(127.0.0.1:3306)/" \
    root_rotation_statements="SET PASSWORD = PASSWORD('{{password}}')" \
    allowed_roles="myqlrole" \
    username="root" \
    password="Qwerty@1234"



















===============================================================
List Connections to the Database
===============================================================
curl \
    --header "X-Vault-Token: $VAULT_ROOT_TOKEN" \
    --request LIST \
    http://127.0.0.1:8200/v1/database/config
===============================================================
List roles
===============================================================
curl \
    --header "X-Vault-Token: $VAULT_ROOT_TOKEN" \
    --request LIST \
    http://127.0.0.1:8200/v1/database/roles

===============================================================
Create credentials
===============================================================
curl \
    --header "X-Vault-Token: $VAULT_ROOT_TOKEN" \
    http://127.0.0.1:8200/v1/database/creds/mysqlrole



Run this command to renew credentials, replacing <lease_id> with the right lease_id:
vault write sys/leases/renew lease_id="<lease_id>" increment="120"

Run this command to revoke credentials, replacing <lease_id> with the right lease_id:
vault write sys/leases/revoke lease_id="<lease_id>"

You can also determine the remaining lifetime of the credentials:
vault write sys/leases/lookup lease_id="<lease_id>"



=================================================================================================================================================================================
VAULT-2
=================================================================================================================================================================================

===============================================================
Create Root CA
===============================================================
vault secrets enable pki
vault secrets tune -max-lease-ttl=87600h pki
vault write -field=certificate pki/root/generate/internal \
     common_name="example.com" \
     issuer_name="root-2023" \
     ttl=87600h > root_2023_ca.crt
vault list pki/issuers/
vault read pki/issuer/$(vault list -format=json pki/issuers/ | jq -r '.[]') \
 | tail -n 6

vault write pki/roles/2023-servers allow_any_name=true
vault write pki/config/urls \
     issuing_certificates="$VAULT_ADDR/v1/pki/ca" \
     crl_distribution_points="$VAULT_ADDR/v1/pki/crl"

===============================================================
Generate Intermediate CA
===============================================================
vault secrets enable -path=pki_int pki
vault secrets tune -max-lease-ttl=43800h pki_int
vault write -format=json pki_int/intermediate/generate/internal \
     common_name="example.com Intermediate Authority" \
     issuer_name="example-dot-com-intermediate" \
     | jq -r '.data.csr' > pki_intermediate.csr
vault write -format=json pki/root/sign-intermediate \
     issuer_ref="root-2023" \
     csr=@pki_intermediate.csr \
     format=pem_bundle ttl="43800h" \
     | jq -r '.data.certificate' > intermediate.cert.pem
vault write pki_int/intermediate/set-signed certificate=@intermediate.cert.pem

===============================================================
Create a Role
===============================================================
vault write pki_int/roles/example-dot-com \
     issuer_ref="$(vault read -field=default pki_int/config/issuers)" \
     allowed_domains="example.com" \
     allow_subdomains=true \
     max_ttl="720h"

===============================================================
Request for Certificates
===============================================================
vault write pki_int/issue/example-dot-com common_name="test.example.com" ttl="24h"


===============================================================
Configure certificate for NGINX
===============================================================

certificate.crt = certificate+issue_ca
private_key= private key


server {
    listen       443 ssl;
    server_name  vaultdemosim.com;
    ssl_certificate /home/opc/certificate.crt;
    ssl_certificate_key /home/opc/private_key.key;
    ssl on;
    ssl_session_timeout 5m;
    ssl_certificate /home/opc/certificate.crt;
    ssl_certificate_key /home/opc/private_key.key;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers HIGH:!aNULL:!MD5;

    root   /usr/share/nginx/html;
    index index.php index.html index.htm;

    location / {
        try_files $uri $uri/ =404;
    }
    error_page 404 /404.html;
    error_page 500 502 503 504 /50x.html;

    location = /50x.html {
        root /usr/share/nginx/html;
    }

    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_pass unix:/var/run/php-fpm/php-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}

sudo nginx -t => Check if NGINX configuration file is correct
sudo systemctl restart nginx => restart the NGINX service


===============================================================
Revoke the Certificate
===============================================================

vault write pki_int/revoke serial_number=<serial_number>

Example=> vault write pki_int/revoke serial_number=08:17:61:95:bb:fc:a4:5a:43:a8:8f:94:12:8a:fe:10:4a:56:a3:4c

===============================================================
Remove expired certificates
===============================================================
vault write pki_int/tidy tidy_cert_store=true tidy_revoked_certs=true


===============================================================
Remove expired certificates
===============================================================

List certificates
 curl \
    --header "X-Vault-Token: hvs.YrWKnsoVs2Ore5BA6Fj0j4B9" \
    --request LIST \
    http://10.0.0.124:8200/v1/pki_iss/certs

Read Certificate
curl \
    http://10.0.0.124:8200/v1/pki_iss/cert/13:da:b8:2a:ea:6a:ec:c9:47:6f:22:6a:6c:14:60:0b:22:3c:1a:91

List Revoked Certificates
curl \
    --header "X-Vault-Token: hvs.YrWKnsoVs2Ore5BA6Fj0j4B9" \
    --request LIST \
    http://10.0.0.124:8200/v1/pki_iss/certs/revoked   

 curl \
    --header "X-Vault-Token: hvs.YrWKnsoVs2Ore5BA6Fj0j4B9" \
    --request LIST \
    http://127.0.0.1:8200/v1/pki_iss/certs/revoked
   