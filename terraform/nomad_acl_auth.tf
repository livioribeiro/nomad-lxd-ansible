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

resource "nomad_acl_auth_method" "vault" {
  name           = "vault"
  type           = "OIDC"
  token_locality = "global"
  max_token_ttl  = "10m0s"
  default        = true

  config {
    oidc_discovery_url    = "https://vault.${var.external_domain}/v1/identity/oidc/provider/nomad"
    oidc_client_id        = data.vault_identity_oidc_client_creds.nomad.client_id
    oidc_client_secret    = data.vault_identity_oidc_client_creds.nomad.client_secret
    oidc_scopes           = [vault_identity_oidc_scope.groups.name]
    bound_audiences       = [data.vault_identity_oidc_client_creds.nomad.client_id]
    allowed_redirect_uris = [
      "http://localhost:4649/oidc/callback",
      "http://nomad.${var.external_domain}/ui/settings/tokens",
      "https://nomad.${var.external_domain}/ui/settings/tokens",
    ]
    list_claim_mappings = {
      "groups" : "roles"
    }
  }
}

resource "nomad_acl_binding_rule" "admin" {
  description = "admin"
  auth_method = nomad_acl_auth_method.vault.name
  selector    = "admin in list.roles"
  bind_type   = "role"
  bind_name   = "admin"
}

resource "nomad_acl_binding_rule" "operator" {
  description = "operator"
  auth_method = nomad_acl_auth_method.vault.name
  selector    = "operator in list.roles"
  bind_type   = "role"
  bind_name   = "operator"
}
