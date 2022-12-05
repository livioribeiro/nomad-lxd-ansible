variable "version" {
  type = string
  default = "0.4.0"
}

job "storage-node" {
  datacenters = ["apps", "infra"]
  type        = "system"
  namespace   = "system-storage"

  group "node" {
    task "node" {
      driver = "docker"

      config {
        image = "registry.gitlab.com/rocketduck/csi-plugin-nfs:${var.version}"

        args = [
          "--type=node",
          "--node-id=${attr.unique.hostname}",
          "--nfs-server=nfs-server:/srv/nomad",
          "--mount-options=defaults", # Adjust accordingly
        ]

        network_mode = "host" # required so the mount works even after stopping the container

        privileged = true
      }

      csi_plugin {
        id        = "nfs" # Whatever you like, but node & controller config needs to match
        type      = "node"
        mount_dir = "/csi"
      }

      resources {
        cpu    = 300
        memory = 100
      }

    }
  }
}