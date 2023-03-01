variable "affinity_node" {
  type        = string
  default     = "na"
  description = "Prefer to schedule controller on this node. If no nodes match, placement is still successful."
}

job "plugin-nfs-controller" {
  datacenters = ["dc1"]

  affinity {
    attribute = "${node.unique.name}"
    value     = var.affinity_node
  }

  group "controller" {
    task "plugin" {
      driver = "docker"

      config {
        image = "mcr.microsoft.com/k8s/csi/nfs-csi:latest"

        args = [
          "--v=5",
          "--nodeid=${attr.unique.hostname}",
          "--endpoint=unix:///csi/csi.sock",
          "--drivername=nfs.csi.k8s.io"
        ]
      }

      csi_plugin {
        id        = "nfs"
        type      = "controller"
        mount_dir = "/csi"
      }

      resources {
        memory = 32
        cpu    = 100
      }
    }
  }
}