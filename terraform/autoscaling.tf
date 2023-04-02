# resource "nomad_namespace" "system_autoscaling" {
#   name = "system-autoscaling"
# }

# resource "nomad_acl_policy" "nomad_autoscaler" {
#   name      = "nomad-autoscaler"
#   rules_hcl = <<-EOT
#     namespace "*" {
#       policy = "write"
#     }
#   EOT
# }

# resource "nomad_acl_token" "nomad_autoscaler" {
#   name     = "nomad-autoscaler"
#   type     = "client"
#   policies = [nomad_acl_policy.nomad_autoscaler.name]
# }

# resource "nomad_job" "autoscaler" {
#   jobspec = file("${path.module}/jobs/autoscaler.nomad.hcl")
#   # detach = false

#   hcl2 {
#     enabled = true
#     vars = {
#       namespace   = nomad_namespace.system_autoscaling.name
#     }
#   }
# }

# resource "consul_config_entry" "nomad_autoscaler_intention" {
#   kind = "service-intentions"
#   name = "prometheus"

#   config_json = jsonencode({
#     Sources = [
#       {
#         Name   = "autoscaler"
#         Action = "allow"
#       }
#     ]
#   })
# }

# resource "consul_config_entry" "nomad_autoscaler_promtail_intention" {
#   kind = "service-intentions"
#   name = "loki"

#   config_json = jsonencode({
#     Sources = [
#       {
#         Name   = "autoscaler-promtail"
#         Action = "allow"
#       }
#     ]
#   })
# }
