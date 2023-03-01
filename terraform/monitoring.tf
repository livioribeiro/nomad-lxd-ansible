# Prometheus Consul ACL
resource "consul_acl_policy" "prometheus" {
  name  = "prometheus"
  rules = <<-EOT
    agent_prefix "" {
      policy = "read"
    }

    node_prefix "" {
      policy = "read"
    }

    service_prefix "" {
      policy = "read"
    }

    service_prefix "prometheus" {
      policy = "write"
    }
  EOT
}
resource "consul_acl_role" "prometheus" {
  name        = "prometheus"
  description = "prometheus role"

  policies = [
    "${consul_acl_policy.prometheus.id}"
  ]
}

resource "consul_acl_token" "prometheus" {
  description = "prometheus acl token"
  roles       = [consul_acl_role.prometheus.name]
  local       = true
}

data "consul_acl_token_secret_id" "prometheus" {
  accessor_id = consul_acl_token.prometheus.id
}

resource "nomad_namespace" "system_monitoring" {
  name = "system-monitoring"
}

resource "nomad_job" "prometheus" {
  jobspec = file("${path.module}/jobs/prometheus.nomad.hcl")
  # detach = false

  hcl2 {
    enabled = true
    vars = {
      namespace        = nomad_namespace.system_monitoring.name
      consul_acl_token = data.consul_acl_token_secret_id.prometheus.secret_id
    }
  }
}

resource "nomad_job" "statsd_exporter" {
  jobspec = file("${path.module}/jobs/statsd-exporter.nomad.hcl")
  # detach = false

  hcl2 {
    enabled = true
    vars = {
      namespace = nomad_namespace.system_monitoring.name
    }
  }
}

resource "nomad_job" "loki" {
  jobspec = file("${path.module}/jobs/loki.nomad.hcl")
  # detach = false

  hcl2 {
    enabled = true
    vars = {
      namespace = nomad_namespace.system_monitoring.name
    }
  }
}

resource "nomad_job" "promtail" {
  jobspec = file("${path.module}/jobs/promtail.nomad.hcl")
  # detach = false

  hcl2 {
    enabled = true
    vars = {
      namespace = nomad_namespace.system_monitoring.name
    }
  }
}

resource "consul_config_entry" "promtail_loki_intention" {
  kind = "service-intentions"
  name = "loki"

  config_json = jsonencode({
    Sources = [
      {
        Name   = "system-promtail"
        Action = "allow"
      }
    ]
  })
}

# Grafana
resource "nomad_job" "grafana" {
  jobspec = file("${path.module}/jobs/grafana.nomad.hcl")
  # detach = false

  hcl2 {
    enabled = true
    vars = {
      namespace = nomad_namespace.system_monitoring.name
    }
  }
}

resource "consul_config_entry" "grafana_prometheus_intention" {
  kind = "service-intentions"
  name = "prometheus"

  config_json = jsonencode({
    Sources = [
      {
        Name   = "grafana"
        Action = "allow"
      }
    ]
  })
}

resource "consul_config_entry" "grafana_loki_intention" {
  kind = "service-intentions"
  name = "loki"

  config_json = jsonencode({
    Sources = [
      {
        Name   = "grafana"
        Action = "allow"
      }
    ]
  })
}