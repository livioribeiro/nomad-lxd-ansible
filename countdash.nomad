job "countdash" {
  datacenters = ["dc1"]

  group "api" {
    network {
      mode = "bridge"
      port "http" {}
      port "envoy_metrics" {
        to = 9102
      }
    }

    service {
      name = "count-api"
      port = "http"

      meta {
        envoy_metrics_port = "${NOMAD_HOST_PORT_envoy_metrics}"
      }

      connect {
        sidecar_service {
          proxy {
            config {
              envoy_prometheus_bind_addr = "0.0.0.0:9102"
            }
          }
        }
      }
    }

    task "web" {
      driver = "docker"

      config {
        image = "hashicorpnomad/counter-api:v3"
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
              local_bind_port = 8080
            }
          }
          tags = ["traefik.enable=false"]
        }
      }
    }

    task "dashboard" {
      driver = "docker"

      config {
        image = "hashicorpnomad/counter-dashboard:v3"
      }

      env {
        PORT = "${NOMAD_PORT_http}"
        COUNTING_SERVICE_URL = "http://${NOMAD_UPSTREAM_ADDR_count_api}"
      }
    }
  }
}