variable "version" {
  type    = string
  default = "1.18.4-rootless"
}

variable "postgres_version" {
  type    = string
  default = "15.1-alpine"
}

variable "namespace" {
  type    = string
  default = "system-scm"
}

variable "data_volume_name" {
  type    = string
  default = "gitea-data"
}

variable "database_volume_name" {
  type    = string
  default = "scm-database-data"
}

job "scm" {
  datacenters = ["apps"]
  type        = "service"
  namespace   = var.namespace

  group "gitea" {
    count = 1

    update {
      max_parallel = 0
    }

    network {
      mode = "bridge"

      port "http" {
        to = 3000
      }
    }

    service {
      name = "gitea"
      port = "http"
      tags = ["traefik.enable=true"]

      check {
        type     = "http"
        port     = "http"
        path     = "/api/healthz"
        interval = "10s"
        timeout  = "5s"

        check_restart {
          grace = "200s"
        }
      }

      connect {
        sidecar_service {
          tags = ["traefik.enable=false"]

          proxy {
            upstreams {
              destination_name = "scm-database"
              local_bind_port  = 5432
            }

            upstreams {
              destination_name = "scm-cache"
              local_bind_port  = 6379
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

    volume "data" {
      type            = "csi"
      source          = var.data_volume_name
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    task "gitea" {
      driver = "docker"

      config {
        image = "gitea/gitea:${var.version}"
        ports = ["http"]

        volumes = [
          "local/secret_key:/var/lib/gitea/secret_key",
          "local/internal_token:/var/lib/gitea/internal_token",
        ]
      }

      env {
        GITEA__server__DOMAIN               = "gitea.apps.nomad.localhost"
        GITEA__server__ROOT_URL             = "http://gitea.apps.nomad.localhost/"
        GITEA__security__INSTALL_LOCK       = "true"
        GITEA__security__INTERNAL_TOKEN_URI = "file:/var/lib/gitea/internal_token"
        GITEA__security__SECRET_KEY_URI     = "file:/var/lib/gitea/secret_key"
        GITEA__database__DB_TYPE            = "postgres"
        GITEA__database__HOST               = "${NOMAD_UPSTREAM_ADDR_scm-database}"
        GITEA__database__NAME               = "gitea"
        GITEA__database__USER               = "gitea"
        GITEA__database__PASSWD             = "gitea"
        GITEA__cache__ADAPTER               = "redis"
        GITEA__cache__HOST                  = "redis://${NOMAD_UPSTREAM_ADDR_scm-cache}/0"
        GITEA__queue__TYPE                  = "redis"
        GITEA__queue__CONN_STR              = "redis://${NOMAD_UPSTREAM_ADDR_scm-cache}/0"
        GITEA__session__PROVIDER            = "redis"
        GITEA__log__LEVEL                   = "Warn"
        GITEA__actions__ENABLED             = "true"
        GITEA__metrics__ENABLED             = "true"
      }

      resources {
        cpu    = 100
        memory = 256
      }

      volume_mount {
        volume      = "data"
        destination = "/var/lib/gitea"
      }

      template {
        destination = "local/secret_key"
        data        = uuidv5("dns", "gitea.apps.nomad")
      }

      template {
        destination = "local/internal_token"
        data        = sha512(uuidv4())
      }
    }

    task "gitea-init-secrets" {
      lifecycle {
        hook = "prestart"
        sidecar = false
      }

      driver = "exec"
      config {
        command = "sh"
        args = ["local/init_secrets.sh"]
      }

      volume_mount {
        volume      = "data"
        destination = "/var/lib/gitea"
      }

      template {
        destination = "local/init_secrets.sh"
        data = <<EOT
#!/bin/sh
set -e

if [ ! -f /var/lib/gitea/internal_token]; then
  echo '${sha512(uuidv4())}' > /var/lib/gitea/internal_token
fi

if [ ! -f /var/lib/gitea/secret_key]; then
  echo '${sha512(uuidv4())}' > /var/lib/gitea/secret_key
fi
        EOT
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
      source          = var.database_volume_name
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
        POSTGRES_USER = "gitea"
        POSTGRES_PASSWORD = "gitea"
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

  group "cache" {
    network {
      mode = "bridge"
    }

    service {
      port = "6379"

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

    task "redis" {
      driver = "docker"

      config {
        image = "redis:7.0-alpine"
      }

      resources {
        cpu = 100
        memory = 128
      }
    }
  }
}
