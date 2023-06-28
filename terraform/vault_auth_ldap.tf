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

resource "vault_identity_group" "admin_ldap" {
  name     = "admin-ldap"
  type     = "external"
  policies = [vault_policy.nomad_admin.name]
}

resource "vault_identity_group" "operator_ldap" {
  name     = "operator-ldap"
  type     = "external"
  policies = [vault_policy.nomad_operator.name]
}

resource "vault_identity_group_alias" "admin_ldap" {
  name           = "admin"
  mount_accessor = vault_ldap_auth_backend.ldap.accessor
  canonical_id   = vault_identity_group.admin_ldap.id
}

resource "vault_identity_group_alias" "operator_ldap" {
  name           = "operator"
  mount_accessor = vault_ldap_auth_backend.ldap.accessor
  canonical_id   = vault_identity_group.operator_ldap.id
}

resource "nomad_acl_binding_rule" "admin_ldap" {
  description = "admin ldap"
  auth_method = nomad_acl_auth_method.vault.name
  selector    = "\"admin-ldap\" in list.roles"
  bind_type   = "role"
  bind_name   = "admin"
}

resource "nomad_acl_binding_rule" "operator_ldap" {
  description = "operator ldap"
  auth_method = nomad_acl_auth_method.vault.name
  selector    = "\"operator-ldap\" in list.roles"
  bind_type   = "role"
  bind_name   = "operator"
}
