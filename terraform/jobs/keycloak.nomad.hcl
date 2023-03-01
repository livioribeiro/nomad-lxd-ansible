variable "version" {
  type    = string
  default = "20.0"
}

variable "postgres_version" {
  type    = string
  default = "15.1-alpine"
}

variable "namespace" {
  type    = string
  default = "system-sso"
}

variable "volume_name" {
  type    = string
  default = "sso-database-data"
}

job "sso" {
  datacenters = ["apps"]
  type        = "service"
  namespace   = var.namespace

  group "sso" {
    count = 1

    network {
      mode = "bridge"

      port "http" {
        to = 8080
      }
    }

    service {
      name = "sso"
      port = "http"
      tags = ["traefik.enable=true"]

      check {
        name     = "Healthiness Check"
        type     = "http"
        port     = "http"
        path     = "/health/live"
        interval = "10s"
        timeout  = "3s"

        check_restart {
          grace = "5s"
        }
      }

      check {
        name      = "Readiness Check"
        type      = "http"
        port      = "http"
        path      = "/health/ready"
        interval  = "10s"
        timeout   = "3s"
        on_update = "ignore_warnings"

        check_restart {
          grace = "5s"
          ignore_warnings = true
        }
      }

      connect {
        sidecar_service {
          tags = ["traefik.enable=false"]

          proxy {
            upstreams {
              destination_name = "sso-database"
              local_bind_port  = 5432
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
    }

    task "keycloak" {
      driver = "docker"

      config {
        image = "quay.io/keycloak/keycloak:${var.version}"
        ports = ["http"]
        args = ["start"]
      }

      env {
        KC_HEALTH_ENABLED        = "true"
        KC_HTTP_ENABLED          = "true"
        KC_PROXY                 = "edge"
        KC_HOSTNAME_STRICT_HTTPS = "false"
        KC_LOG_LEVEL             = "WARN,io.quarkus:INFO,org.infinispan.CONTAINER:INFO"
        KC_HOSTNAME              = "sso.apps.localhost"
        KC_DB                    = "postgres"
        KC_DB_URL_HOST           = "${NOMAD_UPSTREAM_IP_sso_database}"
        KC_DB_URL_PORT           = "${NOMAD_UPSTREAM_PORT_sso_database}"
        KC_DB_URL_DATABASE       = "sso"
        KC_DB_USERNAME           = "sso"
        KC_DB_PASSWORD           = "sso"
        JAVA_OPTS_APPEND         = "-Djgroups.dns.query=sso.service.consul"
        KEYCLOAK_ADMIN           = "admin"
        KEYCLOAK_ADMIN_PASSWORD  = "admin"
      }

      resources {
        cpu    = 500
        memory = 512
      }
    }
  }

  group "database" {
    count = 1

    update {
      max_parallel = 0
    }

    volume "data" {
      type            = "csi"
      source          = var.volume_name
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    network {
      mode = "bridge"
    }

    service {
      port = "5432"

      connect {
        sidecar_service {}

        sidecar_task {
          resources {
            cpu    = 50
            memory = 32
          }
        }
      }
    }

    task "postgres" {
      driver = "docker"

      config {
        image = "postgres:15.1-alpine"
      }

      env {
        POSTGRES_USER = "sso"
        POSTGRES_PASSWORD = "sso"
        PGDATA = "/var/lib/postgresql/data/pgdata"
      }

      volume_mount {
        volume      = "data"
        destination = "/var/lib/postgresql/data/pgdata"
      }

      resources {
        cpu = 100
        memory = 128
      }
    }
  }
}
