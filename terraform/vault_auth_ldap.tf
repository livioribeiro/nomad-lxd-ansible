resource "vault_ldap_auth_backend" "ldap" {
  depends_on = [
    nomad_job.ldap
  ]

  path     = "ldap"
  url      = "ldap://openldap.service.consul:1389"
  binddn   = "cn=admin,dc=nomad,dc=local"
  bindpass = "admin"
  userdn   = "ou=users,dc=nomad,dc=local"
  groupdn  = "ou=groups,dc=nomad,dc=local"
}

resource "vault_identity_group" "admin" {
  name = "admin"
  type = "external"
}

resource "vault_identity_group" "operator" {
  name = "operator"
  type = "external"
}

resource "vault_identity_group_alias" "admin" {
  name           = "admin"
  mount_accessor = vault_ldap_auth_backend.ldap.accessor
  canonical_id   = vault_identity_group.admin.id
}

resource "vault_identity_group_alias" "operator" {
  name           = "operator"
  mount_accessor = vault_ldap_auth_backend.ldap.accessor
  canonical_id   = vault_identity_group.operator.id
}

resource "vault_identity_oidc_assignment" "nomad" {
  name       = "nomad"
  group_ids  = [
    vault_identity_group.admin.id,
    vault_identity_group.operator.id,
  ]
}

resource "vault_identity_oidc_key" "nomad" {
  depends_on = [
    vault_ldap_auth_backend.ldap
  ]

  name               = "nomad"
  allowed_client_ids = ["*"]
  verification_ttl   = 7200
  rotation_period    = 3600
  algorithm          = "RS256"
}

resource "vault_identity_oidc_client" "nomad" {
  name          = "nomad"
  redirect_uris = [
    "http://localhost:4649/oidc/callback",
    "http://nomad.${var.external_domain}/ui/settings/tokens",
    "https://nomad.${var.external_domain}/ui/settings/tokens",
  ]
  assignments = [
    vault_identity_oidc_assignment.nomad.name
  ]
  id_token_ttl     = 1800
  access_token_ttl = 3600
}

resource "vault_identity_oidc_scope" "groups" {
  name        = "groups"
  template    = "{\"groups\":{{identity.entity.groups.names}}}"
  description = "Vault OIDC Groups Scope"
}

resource "vault_identity_oidc_provider" "nomad" {
  name = "nomad"
  issuer_host = "vault.${var.external_domain}"
  allowed_client_ids = [
    vault_identity_oidc_client.nomad.client_id
  ]
  scopes_supported = [
    vault_identity_oidc_scope.groups.name
  ]
}
