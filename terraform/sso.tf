# resource "nomad_namespace" "system_sso" {
#   name = "system-sso"
# }

# resource "nomad_external_volume" "sso_database_data" {
#   depends_on = [
#     data.nomad_plugin.nfs
#   ]

#   type         = "csi"
#   plugin_id    = "nfs"
#   volume_id    = "sso-database-data"
#   name         = "sso-database-data"
#   namespace    = nomad_namespace.system_sso.name
#   capacity_min = "250MiB"
#   capacity_max = "500MiB"

#   capability {
#     access_mode     = "single-node-writer"
#     attachment_mode = "file-system"
#   }
# }

# resource "nomad_job" "sso" {
#   jobspec = file("${path.module}/jobs/keycloak.nomad.hcl")
#   # detach = false

#   hcl2 {
#     enabled = true
#     vars = {
#       namespace   = nomad_namespace.system_sso.name
#       volume_name = nomad_external_volume.sso_database_data.name
#     }
#   }
# }

# resource "consul_config_entry" "sso_intention" {
#   kind = "service-intentions"
#   name = "sso-database"

#   config_json = jsonencode({
#     Sources = [
#       {
#         Name   = "sso"
#         Action = "allow"
#       }
#     ]
#   })
# }