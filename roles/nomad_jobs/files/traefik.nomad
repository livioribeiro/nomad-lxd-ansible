job "traefik" {
  datacenters = ["dc1"]
  type        = "system"

  group "traefik" {

    network {
      port "http" {
        static = 80
      }

      port "api" {
        static = 8080
      }
    }

    service {
        name = "traefik"
        port = "api"

        check {
            name     = "alive"
            type     = "tcp"
            port     = "http"
            interval = "10s"
            timeout  = "2s"
        }

        tags = ["traefik.enable=true"]
    }

    task "traefik" {
      driver = "docker"

      config {
        image        = "traefik:v2.8.3"
        network_mode = "host"

        volumes = [
          "local/traefik.toml:/etc/traefik/traefik.toml",
        ]
      }

      template {
        data = <<EOF
[entryPoints]
    [entryPoints.http]
    address = ":80"
    [entryPoints.traefik]
    address = ":8080"

[api]
    dashboard = true
    insecure  = true

# Enable Consul Catalog configuration backend.
[providers.consulCatalog]
    prefix           = "internal"
    exposedByDefault = true
    constraints = "Tag(`internal`)"
    defaultRule = "Host(`{{ normalize .Name }}.internal`)"

    [providers.consulCatalog.endpoint]
    address = "127.0.0.1:8500"
    scheme  = "http"
EOF

        destination = "local/traefik.toml"
        left_delimiter = "[["
        right_delimiter = "]]"
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}