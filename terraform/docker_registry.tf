resource "nomad_namespace" "system_registry" {
  name = "system-registry"
}

resource "nomad_csi_volume" "docker_hub_proxy_data" {
  depends_on = [
    data.nomad_plugin.nfs
  ]

  plugin_id    = "nfs"
  volume_id    = "docker-hub-proxy-data"
  name         = "docker-hub-proxy-data"
  namespace    = nomad_namespace.system_registry.name
  capacity_min = "12GiB"
  capacity_max = "16GiB"

  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }
}

resource "nomad_job" "docker_registry" {
  jobspec = file("${path.module}/jobs/docker-registry.nomad.hcl")
  detach  = false

  hcl2 {
    vars = {
      namespace   = nomad_namespace.system_registry.name
      volume_name = nomad_csi_volume.docker_hub_proxy_data.name
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