variable "version" {
  type = string
  default = "0.6.1"
}

job "storage-controller" {
  datacenters = ["infra"]
  type        = "service"
  namespace   = "system-storage"

  group "controller" {
    task "controller" {
      driver = "docker"

      config {
        image = "registry.gitlab.com/rocketduck/csi-plugin-nfs:${var.version}"

        args = [
          "--type=controller",
          "--node-id=${attr.unique.hostname}",
          "--nfs-server=nfs-server:/srv/nomad",
          "--mount-options=defaults", # Adjust accordingly
        ]

        network_mode = "host" # required so the mount works even after stopping the container

        privileged = true
      }

      csi_plugin {
        id        = "nfs" # Whatever you like, but node & controller config needs to match
        type      = "controller"
        mount_dir = "/csi"
      }

      resources {
        cpu    = 400
        memory = 120
      }

    }
  }
}
