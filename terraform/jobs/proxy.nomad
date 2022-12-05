variable "version" {
  type = string
  default = "v2.8.3"
}

variable "proxy_suffix" {
  type = string
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
          "local/nomad.yaml:/etc/traefik/conf/nomad.yaml",
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

      template {
        destination = "local/nomad.yaml"
        data        = <<EOF
http:
  serversTransports:
    httpsInsecure:
      insecureSkipVerify: true

  middlewares:
    forwarded-https:
      headers:
        customRequestHeaders:
          X-Forwarded-Proto: https

  routers:

    waypoint-ui:
      service: waypoint-ui
      middlewares:
        - forwarded-https
      rule: "Host(`waypoint-ui.apps.${var.proxy_suffix}`)"

  services:

    waypoint-ui:
      loadBalancer:
        serversTransport: httpsInsecure
        servers:
          - url: https://waypoint-ui.service.consul:9702

EOF
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}