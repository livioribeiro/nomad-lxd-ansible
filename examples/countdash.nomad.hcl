job "countdash" {
  group "api" {
    network {
      mode = "bridge"

      port "envoy_metrics" {
        to = 9102
      }
    }

    scaling {
      enabled = true
      min     = 1
      max     = 20

      policy {
        cooldown = "20s"

        check "cpu" {
          source = "prometheus"
          query  = "nomad_client_allocs_cpu_total_percent{exported_job='countdash', task_group='api', task='api'}"

          strategy "threshold" {
            upper_bound = 0.1
            delta = 1
          }
        }
      }
    }

    service {
      name = "count-api"
      port = "9001"

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

        sidecar_task {
          resources {
            cpu    = 25
            memory = 30
          }
        }
      }
    }

    task "api" {
      driver = "docker"

      config {
        image = "hashicorpnomad/counter-api:v3"
      }

      env {
        PORT = "9001"
      }

      resources {
        cpu    = 50
        memory = 10
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
          tags = ["traefik.enable=false"]

          proxy {
            upstreams {
              destination_name = "count-api"
              local_bind_port = 8080
            }
          }
        }
        sidecar_task {
          resources {
            cpu    = 50
            memory = 30
          }
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

      resources {
        cpu    = 50
        memory = 30
      }
    }
  }
}