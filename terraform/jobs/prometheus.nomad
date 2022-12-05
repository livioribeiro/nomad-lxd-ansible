variable "version" {
  type = string
  default = "v2.38.0"
}

job "prometheus" {
  datacenters = ["infra"]
  type        = "service"
  namespace   = "system-monitoring"

  group "monitoring" {
    count = 1

    network {
      port "prometheus" {
        static = 9090
      }
    }

    restart {
      attempts = 2
      interval = "30m"
      delay    = "15s"
      mode     = "fail"
    }

    ephemeral_disk {
      size = 300
    }

    task "prometheus" {
      driver = "docker"

      config {
        image = "prom/prometheus:${var.version}"

        volumes = [
          "local/prometheus.yml:/etc/prometheus/prometheus.yml",
        ]

        ports = ["prometheus"]
      }

      service {
        name = "prometheus"
        tags = ["traefik.enable=true"]
        port = "prometheus"

        check {
          name     = "prometheus port alive"
          type     = "http"
          path     = "/-/healthy"
          interval = "10s"
          timeout  = "2s"
        }
      }

      template {
        change_mode = "noop"
        destination = "local/prometheus.yml"

        data = <<EOF
# Source:
# https://learn.hashicorp.com/tutorials/nomad/prometheus-metrics
# https://www.mattmoriarity.com/2021-02-21-scraping-prometheus-metrics-with-nomad-and-consul-connect/
---

global:
  scrape_interval:     5s
  evaluation_interval: 5s

scrape_configs:

  - job_name: nomad_metrics

    consul_sd_configs:
    - server: '{{ env "NOMAD_IP_prometheus" }}:8500'
      services: [nomad-client, nomad]

    relabel_configs:
    - source_labels: ['__meta_consul_tags']
      regex: '(.*)http(.*)'
      action: keep

    scrape_interval: 5s
    metrics_path: /v1/metrics
    params:
      format: [prometheus]

  - job_name: proxy_metrics

    consul_sd_configs:
      - server: '{{ env "NOMAD_IP_prometheus" }}:8500'
        services: [proxy]

  - job_name: nomad_autoscaler

    consul_sd_configs:
    - server: '{{ env "NOMAD_IP_prometheus" }}:8500'
      services: [autoscaler]

    scrape_interval: 5s
    metrics_path: /v1/metrics
    params:
      format: [prometheus]

  - job_name: consul_metrics

    consul_sd_configs:
    - server: '{{ env "NOMAD_IP_prometheus" }}:8500'
      services: [consul]

    scrape_interval: 5s
    metrics_path: /v1/agent/metrics
    params:
      format: [prometheus]

  - job_name: consul_connect_envoy_metrics
    
    consul_sd_configs:
      - server: '{{ env "NOMAD_IP_prometheus" }}:8500'

    relabel_configs:
    - source_labels: [__meta_consul_service]
      action: drop
      regex: (.+)-sidecar-proxy
    - source_labels: [__meta_consul_service_metadata_envoy_metrics_port]
      action: keep
      regex: (.+)
    - source_labels: [__address__, __meta_consul_service_metadata_envoy_metrics_port]
      regex: ([^:]+)(?::\d+)?;(\d+)
      replacement: $${1}:$${2}
      target_label: __address__
EOF
      }
    }
  }
}