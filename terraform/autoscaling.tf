resource "nomad_namespace" "system_autoscaling" {
  name = "system-autoscaling"
}

resource "nomad_acl_policy" "nomad_autoscaler" {
  name = "nomad-autoscaler"
  rules_hcl = <<-EOT
    namespace "*" {
      policy = "write"
    }
  EOT
}

resource "nomad_acl_token" "nomad_autoscaler" {
  name = "nomad-autoscaler"
  type = "client"
  policies = [nomad_acl_policy.nomad_autoscaler.name]
}

resource "nomad_job" "autoscaler" {
  jobspec = file("${path.module}/jobs/autoscaler.nomad.hcl")
  # detach = false

  hcl2 {
    enabled = true
    vars = {
      namespace   = nomad_namespace.system_autoscaling.name
      ca_cert     = var.ca_cert
      client_cert = var.nomad_autoscaler_cert
      client_key  = var.nomad_autoscaler_key
      nomad_token = nomad_acl_token.nomad_autoscaler.secret_id
    }
  }
}