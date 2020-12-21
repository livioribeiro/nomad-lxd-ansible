job "countdash" {
  datacenters = ["dc1"]

  group "api" {
    network {
      mode = "bridge"
      port "http" {}
    }

    service {
      name = "count-api"
      port = "http"

      connect {
        sidecar_service {}
      }
    }

    task "web" {
      driver = "docker"

      config {
        image = "hashicorpnomad/counter-api:v2"
      }

      env {
        PORT = "${NOMAD_PORT_http}"
      }
    }
  }

  group "dashboard" {
    network {
      mode = "bridge"
      port "http" {}
    }

    service {
      name = "count-dashboard"
      port = "http"

      tags = ["traefik.enable=true"]

      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "count-api"
              local_bind_port  = 8080
            }
          }
        }
      }
    }

    task "dashboard" {
      driver = "docker"

      config {
        image = "hashicorpnomad/counter-dashboard:v2"
      }

      env {
        PORT = "${NOMAD_PORT_http}"
        COUNTING_SERVICE_URL = "http://${NOMAD_UPSTREAM_ADDR_count_api}"
      }
    }
  }
}