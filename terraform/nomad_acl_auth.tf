data "vault_identity_oidc_client_creds" "nomad" {
  name = vault_identity_oidc_client.nomad.name
}

resource "nomad_acl_policy" "admin" {
  name        = "admin"
  description = "Nomad Admin"
  rules_hcl = <<-EOT
    namespace "*" {
      policy = "write"
    }

    node {
      policy = "write"
    }

    agent {
      policy = "write"
    }

    operator {
      policy = "write"
    }

    quota {
      policy = "write"
    }

    host_volume "*" {
      policy = "write"
    }

    plugin {
      policy = "read"
    }
  EOT
}

resource "nomad_acl_policy" "operator" {
  name        = "operator"
  description = "Nomad Operator"
  rules_hcl = <<-EOT
    namespace "system-*" {
      policy = "read"
    }

    namespace "*" {
      policy = "write"
    }

    node {
      policy = "read"
    }

    agent {
      policy = "read"
    }

    operator {
      policy = "read"
    }

    quota {
      policy = "read"
    }

    plugin {
      policy = "read"
    }
  EOT
}

resource "nomad_acl_role" "admin" {
  name        = "admin"
  description = "Nomad Admin"

  policy {
    name = nomad_acl_policy.admin.name
  }
}

resource "nomad_acl_role" "operator" {
  name        = "operator"
  description = "Nomad Operator"

  policy {
    name = nomad_acl_policy.operator.name
  }
}

resource "null_resource" "nomad_acl_auth_method" {
  depends_on = [
    data.vault_identity_oidc_client_creds.nomad
  ]

  provisioner "local-exec" {
    environment = {
      NOMAD_ADDR = var.nomad_address
      NOMAD_TOKEN = var.nomad_secret_id
      NOMAD_CACERT = "../.tmp/certs/ca/cert.pem"
      NOMAD_CLIENT_CERT = "../.tmp/certs/client/cert.pem"
      NOMAD_CLIENT_KEY = "../.tmp/certs/client/key.pem"
      AUTH_METHOD_CONFIG = <<EOT
{
  "OIDCDiscoveryURL": "https://vault.10.99.0.1.nip.io/v1/identity/oidc/provider/nomad",
  "OIDCClientID": "${data.vault_identity_oidc_client_creds.nomad.client_id}",
  "OIDCClientSecret": "${data.vault_identity_oidc_client_creds.nomad.client_secret}",
  "BoundAudiences": ["${data.vault_identity_oidc_client_creds.nomad.client_id}"],
  "OIDCScopes": ["groups"],
  "AllowedRedirectURIs": [
    "http://localhost:4649/oidc/callback",
    "http://nomad.10.99.0.1.nip.io/ui/settings/tokens",
    "https://nomad.10.99.0.1.nip.io/ui/settings/tokens"
  ],
  "ListClaimMappings": {
    "groups": "roles"
  }
}
EOT
    }

    command = <<-EOT
      echo $AUTH_METHOD_CONFIG | \
      nomad acl auth-method create \
        -default=true \
        -name=vault \
        -token-locality=global \
        -max-token-ttl="10m" \
        -type=OIDC \
        -config -
      EOT
  }

  provisioner "local-exec" {
    environment = {
      NOMAD_ADDR = var.nomad_address
      NOMAD_TOKEN = var.nomad_secret_id
      NOMAD_CACERT = "../.tmp/certs/ca/cert.pem"
      NOMAD_CLIENT_CERT = "../.tmp/certs/client/cert.pem"
      NOMAD_CLIENT_KEY = "../.tmp/certs/client/key.pem"
    }

    command = "nomad acl binding-rule create -auth-method=vault -bind-type=role -bind-name='admin' -selector='admin in list.roles' || true"
  }

  provisioner "local-exec" {
    environment = {
      NOMAD_ADDR = var.nomad_address
      NOMAD_TOKEN = var.nomad_secret_id
      NOMAD_CACERT = "../.tmp/certs/ca/cert.pem"
      NOMAD_CLIENT_CERT = "../.tmp/certs/client/cert.pem"
      NOMAD_CLIENT_KEY = "../.tmp/certs/client/key.pem"
    }

    command = "nomad acl binding-rule create -auth-method=vault -bind-type=role -bind-name='operator' -selector='operator in list.roles' || true"
  }
}