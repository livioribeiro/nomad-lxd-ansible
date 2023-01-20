variable "version" {
  type    = string
  default = "v3.0"
}

variable "proxy_suffix" {
  type    = string
  default = "localhost"
}

job "proxy" {
  datacenters = ["infra"]
  type        = "system"
  namespace   = "system-gateway"

  group "traefik" {
    network {
      port "http" {
        static = 80
      }

      port "traefik" {
        static = 8080
      }
    }

    service {
      name = "traefik"
      port = "traefik"

      check {
        name     = "alive"
        type     = "tcp"
        port     = "http"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "traefik" {
      driver = "docker"

      config {
        image        = "traefik:${var.version}"
        network_mode = "host"

        volumes = [
          "local/traefik.yaml:/etc/traefik/traefik.yaml",
        ]
      }

      template {
        destination     = "local/traefik.yaml"
        left_delimiter  = "[["
        right_delimiter = "]]"
        data            = <<EOF
entryPoints:
  http:
    address: ":80"
    forwardedHeaders:
      insecure: true

accessLog:
  filePath: /var/log/traefik/access.log

api:
  dashboard: true
  insecure: true
  debug: true

metrics:
  prometheus: {}

providers:
  file:
    directory: /etc/traefik/conf/
  consulCatalog:
    exposedByDefault: false
    defaultRule: "Host(`{{ normalize .Name }}.apps.${var.proxy_suffix}`)"
    connectAware: true

EOF
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}