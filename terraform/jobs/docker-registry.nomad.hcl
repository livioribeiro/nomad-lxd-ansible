variable "version" {
  type    = string
  default = "2.8.3"
}

variable "namespace" {
  type    = string
  default = "system-registry"
}

variable "volume_name" {
  type    = string
  default = "docker-hub-proxy-data"
}

job "docker-hub-mirror" {
  type      = "service"
  node_pool = "infra"
  namespace = var.namespace

  group "registry" {
    count = 1

    update {
      max_parallel = 0
    }

    network {
      port "docker" {
        static = 5000
      }
    }

    service {
      name = "docker-hub-mirror"
      port = "docker"
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
        image = "registry:${var.version}"
        ports = ["docker"]
        args = ["local/config.yml"]
      }

      volume_mount {
        volume      = "data"
        destination = "/var/lib/registry"
      }

      resources {
        cpu    = 200
        memory = 512
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
            delete:
              enabled: true
            cache:
              blobdescriptor: inmemory
              blobdescriptorsize: 10000
          proxy:
            remoteurl: https://registry-1.docker.io
        EOT
      }
    }
  }
}
