resource "nomad_namespace" "system_autoscaling" {
  name = "system-autoscaling"
}

resource "nomad_acl_policy" "nomad_autoscaler" {
  name      = "nomad-autoscaler"

  rules_hcl = <<-EOT
    node {
      policy = "read"
    }
  
    namespace "*" {
      policy = "write"
    }
  EOT
}

resource "nomad_acl_token" "nomad_autoscaler" {
  name     = "nomad-autoscaler"
  type     = "client"
  policies = [nomad_acl_policy.nomad_autoscaler.name]
}

resource "nomad_job" "autoscaler" {
  jobspec = file("${path.module}/jobs/autoscaler.nomad.hcl")
  # detach = false

  hcl2 {
    vars = {
      namespace   = nomad_namespace.system_autoscaling.name
      nomad_token = nomad_acl_token.nomad_autoscaler.secret_id
    }
  }
}

resource "consul_config_entry" "nomad_autoscaler_intention" {
  kind = "service-intentions"
  name = "prometheus"

  config_json = jsonencode({
    Sources = [
      {
        Name   = "autoscaler"
        Action = "allow"
      }
    ]
  })
}
