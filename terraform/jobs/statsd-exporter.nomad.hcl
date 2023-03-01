variable "version" {
  type    = string
  default = "v0.23.0"
}

variable "namespace" {
  type    = string
  default = "system-monitoring"
}

job "statsd-exporter" {
  datacenters = ["infra", "apps"]
  type        = "system"
  namespace   = var.namespace

  group "statsd-exporter" {
    count = 1

    network {
      port "web" {
        static = 9102
      }

      port "statsd" {
        static = 9125
      }
    }

    service {
      name = "statsd"
      port = "web"
    }

    task "statsd-exporter" {
      driver = "docker"

      config {
        image = "prom/statsd-exporter:${var.version}"
        ports = ["web", "statsd"]
        args  = ["--log.level=debug", ]
      }

      resources {
        cpu    = 200
        memory = 256
      }
    }
  }
}
