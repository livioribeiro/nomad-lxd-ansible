variable "version" {
  type    = string
  default = "1.20.0-rootless"
}

variable "namespace" {
  type    = string
  default = "system-gitea"
}

variable "gitea_host" {
  type    = string
  default = ""
}

variable "data_volume_name" {
  type    = string
  default = "gitea-data"
}

variable "database_volume_name" {
  type    = string
  default = "gitea-database-data"
}

job "gitea" {
  datacenters = ["apps"]
  type        = "service"
  namespace   = var.namespace

  group "app" {
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
              destination_name = "gitea-database"
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

    volume "data" {
      type            = "csi"
      source          = var.data_volume_name
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    task "redis" {
      driver = "docker"

      lifecycle {
        hook    = "prestart"
        sidecar = true
      }

      config {
        image = "redis:7.0-alpine"
      }

      resources {
        cpu = 100
        memory = 128
      }
    }

    task "gitea" {
      driver = "docker"

      config {
        image = "gitea/gitea:${var.version}"
        ports = ["http"]
        command = "/opt/init.sh"

        volumes = [
          "local/secret_key:/var/lib/gitea/secret_key",
          "local/internal_token:/var/lib/gitea/internal_token",
          "local/init.sh:/opt/init.sh",
        ]
      }

      template {
        data = <<-EOT
          #!/bin/sh
          while ! nc -z localhost 5432
          do
            sleep 1
          done

          gitea migrate

          if [ -z "$(gitea admin user list --admin | grep admin@example.com)" ]
          then
            gitea admin user create --admin --username root --password Password123 --email root@example.com
          fi

          exec /usr/bin/dumb-init -- /usr/local/bin/docker-entrypoint.sh
        EOT

        destination = "local/init.sh"
        perms = "755"
      }

      env {
        GITEA__server__HTTP_PORT          = "${NOMAD_PORT_http}"
        GITEA__server__DOMAIN             = "${var.gitea_host}"
        GITEA__server__ROOT_URL           = "http://${var.gitea_host}/"
        GITEA__security__INSTALL_LOCK     = "true"
        GITEA__security__INTERNAL_TOKEN   = "gitea_internal_token"
        GITEA__security__SECRET_KEY       = "gitea_secret_key"
        GITEA__database__DB_TYPE          = "postgres"
        GITEA__database__HOST             = "localhost:5432"
        GITEA__database__NAME             = "gitea"
        GITEA__database__USER             = "gitea"
        GITEA__database__PASSWD           = "gitea"
        GITEA__cache__ADAPTER             = "redis"
        GITEA__cache__HOST                = "redis://localhost:6379/0"
        GITEA__queue__TYPE                = "redis"
        GITEA__queue__CONN_STR            = "redis://localhost:6379/0"
        GITEA__session__PROVIDER          = "redis"
        GITEA__session__PROVIDER_CONFIG   = "redis://localhost:6379/0"
        GITEA__log__LEVEL                 = "Warn"
        GITEA__actions__ENABLED           = "true"
        GITEA__metrics__ENABLED           = "true"
        GITEA__webhook__ALLOWED_HOST_LIST = "woodpecker.apps.10.99.0.1.nip.io"
      }

      resources {
        cpu    = 100
        memory = 256
      }

      volume_mount {
        volume      = "data"
        destination = "/var/lib/gitea"
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
        image = "postgres:15.2-alpine"
      }

      env {
        POSTGRES_USER = "gitea"
        POSTGRES_PASSWORD = "gitea"
        PGDATA = "/var/lib/postgresql/data/pgdata"
      }

      volume_mount {
        volume      = "data"
        destination = "/var/lib/postgresql/data"
      }

      resources {
        cpu = 100
        memory = 128
      }
    }
  }
}
