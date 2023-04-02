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
