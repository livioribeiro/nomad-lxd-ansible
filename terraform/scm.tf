resource "nomad_namespace" "system_scm" {
  name = "system-scm"
}

resource "nomad_external_volume" "gitea_data" {
  depends_on = [
    data.nomad_plugin.nfs
  ]

  type         = "csi"
  plugin_id    = "nfs"
  volume_id    = "gitea-data"
  name         = "gitea-data"
  namespace    = nomad_namespace.system_scm.name
  capacity_min = "250MiB"
  capacity_max = "500MiB"

  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }

  parameters = {
    uid  = "1000"
    gid  = "1000"
    mode = "770"
  }
}

resource "nomad_external_volume" "scm_database_data" {
  depends_on = [
    data.nomad_plugin.nfs,
  ]

  type         = "csi"
  plugin_id    = "nfs"
  volume_id    = "scm-database-data"
  name         = "scm-database-data"
  namespace    = nomad_namespace.system_scm.name
  capacity_min = "250MiB"
  capacity_max = "500MiB"

  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }
}

resource "nomad_job" "scm" {
  jobspec = file("${path.module}/jobs/gitea.nomad.hcl")
  # detach = false

  hcl2 {
    enabled = true
    vars = {
      namespace            = nomad_namespace.system_scm.name
      data_volume_name     = nomad_external_volume.gitea_data.name
      database_volume_name = nomad_external_volume.scm_database_data.name
    }
  }
}

resource "consul_config_entry" "scm_database_intention" {
  kind = "service-intentions"
  name = "scm-database"

  config_json = jsonencode({
    Sources = [
      {
        Name   = "gitea"
        Action = "allow"
      }
    ]
  })
}

resource "consul_config_entry" "scm_cache_intention" {
  kind = "service-intentions"
  name = "scm-cache"

  config_json = jsonencode({
    Sources = [
      {
        Name   = "gitea"
        Action = "allow"
      }
    ]
  })
}