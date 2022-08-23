job "nfs-example" {
  datacenters = ["apps"]
  type        = "service"

  group "example" {
    count = 3

    volume "example" {
      type            = "csi"
      source          = "nfs-example"
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "multi-node-multi-writer"
    }

    task "example" {
      driver = "docker"

      config {
        image = "busybox"

        args = [
          "sleep",
          "infinity",
        ]
      }

      volume_mount {
        volume      = "example"
        destination = "/mnt"
      }

      resources {
        cpu    = 50
        memory = 30
      }
    }
  }
}
