# To list SSH secrets paths
path "demo-ssh/*" {
  capabilities = [ "list" ]
}
# To use the configured SSH secrets engine otp_key_role role
path "demo-ssh/creds/otp_key_role" {
  capabilities = ["create", "read", "update"]
}
