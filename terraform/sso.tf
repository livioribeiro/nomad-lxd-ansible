resource "nomad_namespace" "system_sso" {
  name = "system-sso"
}

resource "nomad_external_volume" "sso_database_data" {
  depends_on = [
    data.nomad_plugin.nfs
  ]

  type         = "csi"
  plugin_id    = "nfs"
  volume_id    = "sso-database-data"
  name         = "sso-database-data"
  namespace    = nomad_namespace.system_sso.name
  capacity_min = "500MiB"
  capacity_max = "750MiB"

  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }
}

resource "nomad_job" "sso" {
  depends_on = [nomad_job.docker_registry]

  jobspec = file("${path.module}/jobs/keycloak.nomad.hcl")
  # detach = false

  hcl2 {
    enabled = true
    vars = {
      namespace       = nomad_namespace.system_sso.name
      volume_name     = nomad_external_volume.sso_database_data.name
      external_domain = var.external_domain
      apps_subdomain  = var.apps_subdomain
      realm_import    = file("./sso-realm.json")
    }
  }
}

resource "consul_config_entry" "sso_intention" {
  kind = "service-intentions"
  name = "sso-database"

  config_json = jsonencode({
    Sources = [
      {
        Name   = "sso"
        Action = "allow"
      }
    ]
  })
}

resource "nomad_acl_auth_method" "keycloak" {
  name           = "keycloak"
  type           = "OIDC"
  token_locality = "global"
  max_token_ttl  = "10m0s"
  default        = false

  config {
    oidc_discovery_url    = "https://sso.${var.apps_subdomain}.${var.external_domain}/realms/nomad"
    oidc_client_id        = "nomad"
    oidc_client_secret    = "AObFLKhclf5YScp6BLPPMaI6K4muLmv7"
    oidc_scopes           = ["groups"]
    bound_audiences       = ["nomad"]
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

resource "nomad_acl_binding_rule" "admin_keycloak" {
  description = "admin keycloak"
  auth_method = nomad_acl_auth_method.keycloak.name
  selector    = "admin in list.roles"
  bind_type   = "role"
  bind_name   = "admin"
}

resource "nomad_acl_binding_rule" "operator_keycloak" {
  description = "operator keycloak"
  auth_method = nomad_acl_auth_method.keycloak.name
  selector    = "operator in list.roles"
  bind_type   = "role"
  bind_name   = "operator"
}
