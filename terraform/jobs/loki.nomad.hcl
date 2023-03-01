variable "version" {
  type    = string
  default = "2.7.2"
}

variable "namespace" {
  type    = string
  default = "system-monitoring"
}

job "loki" {
  datacenters = ["infra", "apps"]
  type        = "service"
  namespace   = var.namespace

  group "loki" {
    count = 1

    network {
      mode = "bridge"

      port "http" {
        to = 3100
      }
    }
    
    service {
      name = "loki"
      port = "3100"

      connect {
        sidecar_service {}

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
        path     = "/ready"
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
        path      = "/ready"
        interval  = "10s"
        timeout   = "5s"
        on_update = "ignore_warnings"

        check_restart {
          grace = "5s"
          ignore_warnings = true
        }
      }
    }

    task "loki" {
      driver = "docker"

      config {
        image = "grafana/loki:${var.version}"
        args = ["-config.file=local/loki.yaml"]
        ports = ["http"]

        logging {
          type = "json-file"
        }
      }

      resources {
        cpu    = 200
        memory = 256
      }

      template {
        destination   = "local/loki.yaml"
        change_mode   = "signal"
        change_signal = "SIGHUP"

        data = <<-EOT
          auth_enabled: false

          server:
            http_listen_port: {{ env "NOMAD_PORT_http" }}

          common:
            path_prefix: /tmp/loki
            storage:
              filesystem:
                chunks_directory: /tmp/loki/chunks
                rules_directory: /tmp/loki/rules
            replication_factor: 1
            ring:
              instance_addr: 127.0.0.1
              kvstore:
                store: inmemory

          ingester:
            lifecycler:
              address: 127.0.0.1
              ring:
                kvstore:
                  store: inmemory
                replication_factor: 1
              final_sleep: 0s
            chunk_idle_period: 5m
            chunk_retain_period: 30s
            wal:
              dir: /loki/wal

          query_range:
            results_cache:
              cache:
                embedded_cache:
                  enabled: true
                  max_size_mb: 100

          schema_config:
            configs:
              - from: 2020-10-24
                store: boltdb-shipper
                object_store: filesystem
                schema: v11
                index:
                  prefix: index_
                  period: 24h

          storage_config:
            boltdb:
              directory: /loki/index
            filesystem:
              directory: /loki/chunks
        EOT
      }
    }
  }
}