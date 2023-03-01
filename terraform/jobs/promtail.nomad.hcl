variable "version" {
  type    = string
  default = "2.7.2"
}

variable "namespace" {
  type    = string
  default = "system-monitoring"
}

job "promtail" {
  datacenters = ["infra", "apps"]
  type        = "system"
  namespace   = var.namespace

  group "promtail" {
    count = 1

    network {
      mode = "bridge"

      port "http" {}
    }
    
    service {
      name = "system-promtail"

      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "loki"
              local_bind_port  = 3100
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
      type      = "host"
      source    = "docker-socket"
      read_only = true
    }

    task "promtail" {
      driver = "docker"

      config {
        image = "grafana/promtail:${var.version}"
        ports = ["http"]
        args = ["-config.file=local/promtail.yaml"]

        // volumes = [
        //   "/var/run/docker.sock:/var/run/docker.sock"
        // ]
      }

      volume_mount {
        volume           = "docker-socket"
        destination      = "/run/docker.sock"
        propagation_mode = "private"
      }

      resources {
        cpu    = 100
        memory = 64
      }

      template {
        destination = "local/promtail.yaml"

        data = <<-EOT
          server:
            http_listen_address: 127.0.0.1
            http_listen_port: {{ env "NOMAD_PORT_http" }}
            grpc_listen_address: 127.0.0.1
            grpc_listen_port: 0

          positions:
            filename: /tmp/positions.yaml

          clients:
            - url: http://{{ env "NOMAD_UPSTREAM_ADDR_loki" }}/loki/api/v1/push

          scrape_configs:
          - job_name: docker-logs
            docker_sd_configs:
              - host: unix:///var/run/docker.sock
                refresh_interval: 5s
            pipeline_stages:
              - docker: {}
            relabel_configs:
              - source_labels: ['__meta_docker_container_log_stream']
                target_label: 'stream'
              - source_labels: ['__meta_docker_container_label_com_hashicorp_nomad_alloc_id']
                target_label: 'nomad_alloc_id'
              - source_labels: ['__meta_docker_container_label_com_hashicorp_nomad_job_name']
                target_label: 'nomad_job_name'
              - source_labels: ['__meta_docker_container_label_com_hashicorp_nomad_job_id']
                target_label: 'nomad_job_id'
              - source_labels: ['__meta_docker_container_label_com_hashicorp_nomad_task_group_name']
                target_label: 'nomad_task_group'
              - source_labels: ['__meta_docker_container_label_com_hashicorp_nomad_task_name']
                target_label: 'nomad_task'
              - source_labels: ['__meta_docker_container_label_com_hashicorp_nomad_namespace']
                target_label: 'nomad_namespace'
              - source_labels: ['__meta_docker_container_label_com_hashicorp_nomad_node_name']
                target_label: 'nomad_node_name'
              - source_labels: ['__meta_docker_container_label_com_hashicorp_nomad_node_id']
                target_label: 'nomad_node_id'
        EOT
      }
    }
  }
}