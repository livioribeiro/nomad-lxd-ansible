job "gitea" {
  datacenters = ["dc1"]

  group "gitea" {
    count = 1

    ephemeral_disk {
      # try to deploy this service on the same node every time
      sticky  = true
      # try to migrate the ephemeral disk if possible 
      migrate = true
      # set the ephemeral disk size to 2GB 
      size    = "2048"
    }

    task "server" {
      driver = "docker"

      config {
        image = "gitea/gitea:1.6"

        port_map = {
          http = 3000
        }

        # with docker driver, it is possible to mount volumes insinde the container from the ephemeral disk
        volumes = [
          "local/gitea-data:/data"
        ]
      }

      resources {
        network {
          port "http" {}
        }
      }

      service {
        name = "gitea"
        port = "http"
        tags = ["traefik.enable=true"]
      }
    }
  }
}
