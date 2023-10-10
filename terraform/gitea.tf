resource "nomad_namespace" "gitea" {
  name = "system-gitea"
}

resource "nomad_csi_volume" "gitea_data" {
  depends_on = [
    data.nomad_plugin.nfs
  ]

  plugin_id    = "nfs"
  volume_id    = "gitea-data"
  name         = "gitea-data"
  namespace    = nomad_namespace.gitea.name
  capacity_min = "250MiB"
  capacity_max = "500MiB"

  parameters = {
    uid  = "1000"
    gid  = "1000"
    mode = "770"
  }

  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }
}

resource "nomad_csi_volume" "gitea_database_data" {
  depends_on = [
    data.nomad_plugin.nfs,
  ]

  plugin_id    = "nfs"
  volume_id    = "gitea-database-data"
  name         = "gitea-database-data"
  namespace    = nomad_namespace.gitea.name
  capacity_min = "250MiB"
  capacity_max = "500MiB"

  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }

  parameters = {
    uid  = "70"
    gid  = "70"
    mode = "700"
  }
}

resource "nomad_job" "gitea" {
  depends_on = [nomad_job.docker_registry]

  jobspec = file("${path.module}/jobs/gitea.nomad.hcl")
  # detach = false

  hcl2 {
    vars = {
      namespace            = nomad_namespace.gitea.name
      data_volume_name     = nomad_csi_volume.gitea_data.name
      database_volume_name = nomad_csi_volume.gitea_database_data.name
      gitea_host           = "gitea.${var.apps_subdomain}.${var.external_domain}"
    }
  }
}

resource "consul_config_entry" "gitea_database_intention" {
  kind = "service-intentions"
  name = "gitea-database"

  config_json = jsonencode({
    Sources = [
      {
        Name   = "gitea"
        Action = "allow"
      }
    ]
  })
}
