variable "version" {
  type    = string
  default = "next"
}

variable "namespace" {
  type    = string
  default = "system-cicd"
}

variable "woodpecker_host" {
  type    = string
  default = ""
}

variable "woodpecker_agent_secret" {
  type    = string
  default = ""
}

variable "gitea_url" {
  type    = string
  default = ""
}

variable "gitea_client" {
  type    = string
  default = ""
}

variable "gitea_secret" {
  type    = string
  default = ""
}

variable "data_volume_name" {
  type    = string
  default = "woodpecker-ci-data"
}

job "woodpecker-ci" {
  datacenters = ["apps", "infra"]
  type        = "service"
  namespace   = var.namespace

  group "server" {
    count = 1

    update {
      max_parallel = 0
    }

    network {
      mode = "bridge"

      port "http" {
        to = 8000
      }

      port "server" {
        to = 9000
      }
    }

    service {
      name = "woodpecker"
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
    }

    service {
      name = "woodpecker-server"
      port = "9000"
      
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

    volume "data" {
      type            = "csi"
      source          = var.data_volume_name
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    task "server" {
      driver = "docker"

      config {
        image = "woodpeckerci/woodpecker-server:${var.version}"
        ports = ["http"]
      }

      env {
        WOODPECKER_OPEN         = true
        WOODPECKER_HOST         = var.woodpecker_host
        WOODPECKER_GITEA        = true
        WOODPECKER_GITEA_URL    = var.gitea_url
        WOODPECKER_GITEA_CLIENT = var.gitea_client
        WOODPECKER_GITEA_SECRET = var.gitea_secret
        WOODPECKER_AGENT_SECRET = var.woodpecker_agent_secret
      }

      resources {
        cpu    = 100
        memory = 256
      }

      volume_mount {
        volume      = "data"
        destination = "/var/lib/woodpecker/"
      }
    }
  }

  group "agent" {
    count = 3

    update {
      max_parallel = 0
    }

    network {
      mode = "bridge"
    }

    service {
      name = "woodpecker-agent"
      
      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "woodpecker-server"
              local_bind_port  = 9000
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

    volume "docker-socket" {
      type            = "host"
      source          = "docker-socket"
      read_only       = true
    }

    task "server" {
      driver = "docker"

      config {
        image = "woodpeckerci/woodpecker-agent:${var.version}"
      }

      env {
        WOODPECKER_SERVER       = "localhost:9000"
        WOODPECKER_AGENT_SECRET = var.woodpecker_agent_secret
      }

      resources {
        cpu    = 100
        memory = 256
      }

      volume_mount {
        volume      = "docker-socket"
        destination = "/var/run/docker.sock"
      }
    }
  }
}
