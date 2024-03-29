variable "version" {
  type    = string
  default = "9.5.12"
}

variable "namespace" {
  type    = string
  default = "system-monitoring"
}

job "grafana" {
  type      = "service"
  namespace = var.namespace

  group "grafana" {
    count = 1

    network {
      mode = "bridge"

      port "http" {
        to = 3000
      }
    }
    
    service {
      name = "grafana"
      port = "http"
      tags = ["traefik.enable=true"]

      connect {
        sidecar_service {
          tags = ["traefik.enable=false"]

          proxy {
            upstreams {
              destination_name = "loki"
              local_bind_port  = 3100
            }

            upstreams {
              destination_name = "prometheus"
              local_bind_port  = 9090
            }
          }
        }
        sidecar_task {
          resources {
            cpu    = 50
            memory = 32
          }
        }
      }

      check {
        name     = "Healthiness Check"
        type     = "http"
        port     = "http"
        path      = "/robots.txt"
        interval = "10s"
        timeout  = "5s"

        check_restart {
          grace = "10s"
          limit = 5
        }
      }

      check {
        name      = "Readiness Check"
        type      = "http"
        port      = "http"
        path      = "/robots.txt"
        interval  = "10s"
        timeout   = "5s"
        on_update = "ignore_warnings"

        check_restart {
          grace = "5s"
          ignore_warnings = true
        }
      }
    }

    task "grafana" {
      driver = "docker"

      config {
        image = "grafana/grafana-oss:${var.version}"
        ports = ["http"]

        mount {
          type = "bind"
          source = "local/datasource-loki.yaml"
          target = "/usr/share/grafana/conf/provisioning/datasources/loki.yaml"
          readonly = true
        }
      }

      resources {
        cpu    = 200
        memory = 256
      }

      template {
        destination = "local/datasource-loki.yaml"
        data = <<-EOT
          apiVersion: 1
          datasources:
          - name: Loki
            type: loki
            url: http://loki.service.consul:3100
        EOT
      }
    }
  }
}