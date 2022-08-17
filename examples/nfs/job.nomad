job "example" {
  datacenters = ["dc1"]
  type        = "service"

  group "example" {

    volume "example" {
      type            = "csi"
      source          = "example"
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
        cpu    = 100
        memory = 50
      }
    }
  }
}
