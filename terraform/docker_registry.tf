resource "nomad_namespace" "system_registry" {
  name = "system-registry"
}

resource "nomad_external_volume" "docker_registry_data" {
  depends_on = [
    data.nomad_plugin.nfs
  ]

  type         = "csi"
  plugin_id    = "nfs"
  volume_id    = "docker-registry-data"
  name         = "docker-registry-data"
  namespace    = nomad_namespace.system_registry.name
  capacity_min = "2GiB"
  capacity_max = "3GiB"

  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }
}

resource "nomad_job" "docker-registry" {
  jobspec = file("${path.module}/jobs/docker-registry.nomad.hcl")
  detach = false

  hcl2 {
    enabled = true
    vars = {
      namespace   = nomad_namespace.system_registry.name
      volume_name = nomad_external_volume.docker_registry_data.name
    }
  }
}

resource "consul_config_entry" "docker_registry_intention" {
  kind = "service-intentions"
  name = "docker-registry-cache"

  config_json = jsonencode({
    Sources = [
      {
        Name   = "docker-registry"
        Action = "allow"
      }
    ]
  })
}