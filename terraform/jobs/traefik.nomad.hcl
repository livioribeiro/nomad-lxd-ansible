variable "version" {
  type    = string
  default = "v2.9"
}

variable "proxy_suffix" {
  type    = string
  default = ""
}

variable "namespace" {
  type    = string
  default = "system-gateway"
}

variable "consul_acl_token" {
  type    = string
  default = ""
}

job "proxy" {
  datacenters = ["infra"]
  type        = "system"
  namespace   = var.namespace

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
  consulCatalog:
    exposedByDefault: false
    defaultRule: "Host(`{{ normalize .Name }}.${var.proxy_suffix}`)"
    connectAware: false
    endpoint:
      token: "${var.consul_acl_token}"

EOF
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}