variable "version" {
  type    = string
  default = "2"
}

variable "namespace" {
  type    = string
  default = "system-registry"
}

variable "volume_name" {
  type    = string
  default = "docker-registry-data"
}

job "docker-registry" {
  datacenters = ["infra", "apps"]
  type        = "service"
  namespace   = var.namespace

  group "registry" {
    count = 1

    update {
      max_parallel = 0
    }

    network {
      mode = "bridge"

      port "docker" {
        static = 5000
      }

      port "docker-debug" {
        to = 5001
      }
    }

    service {
      name = "docker-registry"
      port = "docker"

      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "docker-registry-redis"
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

    service {
      name = "docker-registry-debug"
      port = "docker-debug"
    }

    volume "data" {
      type            = "csi"
      source          = var.volume_name
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    task "registry" {
      driver = "docker"

      config {
        image        = "registry:${var.version}"
        ports        = ["docker"]

        volumes = [
          "local/config.yml:/etc/docker/registry/config.yml",
        ]
      }

      volume_mount {
        volume      = "data"
        destination = "/var/lib/registry"
      }

      resources {
        cpu    = 100
        memory = 128
      }

      template {
        destination = "local/config.yml"
        data = <<-EOT
          version: 0.1
          http:
            addr: 0.0.0.0:5000
            host: http://docker-registry.service.consul:5000
          storage:
            filesystem:
              rootdirectory: /var/lib/registry
              maxthreads: 100
          cache:
            blobdescriptor: redis
            blobdescriptorsize: 10000
          redis:
            addr: {{ env "NOMAD_UPSTREAM_ADDR_docker_registry_redis" }}
          proxy:
            remoteurl: https://registry-1.docker.io
        EOT
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
