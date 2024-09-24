vault {
  address     = "https://vault-cluster-simrssin-public-vault-5f4506b3.2439576d.z1.hashicorp.cloud:8200"
  token       = ""
  renew_token = false
}
template {
  contents = <<EOH
{{- with secret "demo-pki_iss/issue/hashicorp" "common_name=vault.hashicorp.com" "ttl=60s" -}}
{{ .Data.private_key }}
{{- end }}
EOH
  destination = "private_key.key"
  exec {
    command = [ "cat", "private_key.key" ]
  }
}
template {
  contents = <<EOH
{{- with secret "demo-pki_iss/issue/hashicorp" "common_name=vault.hashicorp.com" "ttl=60s" -}}
{{ .Data.certificate }}
{{- end }}
EOH
  destination = "certificate.crt"
  exec {
    command = [
      "openssl", "x509", "-in", "certificate.crt",
      "-issuer", "-subject", "-startdate", "-enddate",
      "-noout"
    ]
  }
}
template {
  contents = <<EOH
{{- with secret "demo-pki_iss/issue/hashicorp" "common_name=vault.hashicorp.com" "ttl=60s" -}}
{{- range .Data.ca_chain -}}
{{ . }}
{{ end -}}
{{- end -}}
EOH
  destination = "issue_ca.ca"
  exec {
    command = [ "cat", "issue_ca.ca" ]
  }
}
