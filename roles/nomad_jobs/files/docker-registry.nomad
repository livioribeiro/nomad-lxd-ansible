job "docker-registry" {
  datacenters = ["infra"]

  group "registry" {
    count = 1

    network {
      port "docker" {
        static = 5000
      }
    }

    service {
      name = "docker-registry"
      port = "docker"
      tags = ["traefik.enable=true"]
    }

    task "registry" {
      driver = "docker"

      config {
        image = "registry:2"
        ports = ["docker"]
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}
