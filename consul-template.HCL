cat <<EOF > consul-template.hcl
vault {
  address     = "http://127.0.0.1:8200"
  token       = "hvs.GHDM2UxUZUtKBhlPlxViME0e"
  renew_token = false
}
template {
  contents = <<EOH
{{- with secret "pki_iss/issue/example" "common_name=test.example.com" "ttl=30s" -}}
{{ .Data.private_key }}
{{- end }}
EOH
  destination = "cert.key"
  exec {
    command = [ "cat", "cert.key" ]
  }
}
template {
  contents = <<EOH
{{- with secret "pki_iss/issue/example" "common_name=test.example.com" "ttl=30s" -}}
{{ .Data.certificate }}
{{- end }}
EOH
  destination = "cert.crt"
  exec {
    command = [
      "openssl", "x509", "-in", "cert.crt",
      "-issuer", "-subject", "-startdate", "-enddate",
      "-noout"
    ]
  }
}
template {
  contents = <<EOH
{{- with secret "pki_iss/issue/example" "common_name=test.example.com" "ttl=30s" -}}
{{- range .Data.ca_chain -}}
{{ . }}
{{ end -}}
{{- end -}}
EOH
  destination = "cert.ca"
  exec {
    command = [ "cat", "cert.ca" ]
  }
}
EOF
