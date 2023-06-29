resource "nomad_namespace" "system_ldap" {
  name = "system-ldap"
}

resource "nomad_external_volume" "ldap_data" {
  depends_on = [
    data.nomad_plugin.nfs
  ]

  type         = "csi"
  plugin_id    = "nfs"
  volume_id    = "ldap-data"
  name         = "ldap-data"
  namespace    = nomad_namespace.system_ldap.name
  capacity_min = "250MiB"
  capacity_max = "500MiB"

  parameters = {
    uid  = "1001"
    gid  = "1001"
    mode = "770"
  }

  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }
}

resource "nomad_job" "ldap" {
  depends_on = [nomad_job.docker_registry]

  jobspec = file("${path.module}/jobs/openldap.nomad.hcl")
  detach  = false

  hcl2 {
    enabled = true
    vars = {
      namespace   = nomad_namespace.system_ldap.name
      volume_name = nomad_external_volume.ldap_data.name
    }
  }
}

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

