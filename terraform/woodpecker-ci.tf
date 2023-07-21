# resource "nomad_namespace" "cicd" {
#   name = "system-cicd"
# }

# resource "nomad_external_volume" "woodpecker_data" {
#   depends_on = [
#     data.nomad_plugin.nfs
#   ]

#   type         = "csi"
#   plugin_id    = "nfs"
#   volume_id    = "woodpecker-ci-data"
#   name         = "woodpecker-ci-data"
#   namespace    = nomad_namespace.cicd.name
#   capacity_min = "500MiB"
#   capacity_max = "750MiB"

#   parameters = {
#     uid  = "1000"
#     gid  = "1000"
#     mode = "770"
#   }

#   capability {
#     access_mode     = "single-node-writer"
#     attachment_mode = "file-system"
#   }
# }

# resource "gitea_oauth2_app" "woodpecker_ci" {
#   depends_on = [nomad_job.gitea]

#   name = "woodpecker-ci"
#   redirect_uris = ["http://woodpecker.${var.apps_subdomain}.${var.external_domain}/*"]
# }

# resource "nomad_job" "woodpecker" {
#   depends_on = [nomad_job.docker_registry]

#   jobspec = file("${path.module}/jobs/woodpecker-ci.nomad.hcl")
#   # detach = false

#   hcl2 {
#     enabled = true
#     vars = {
#       namespace               = nomad_namespace.cicd.name
#       data_volume_name        = nomad_external_volume.woodpecker_data.name
#       woodpecker_host         = "woodpecker.${var.apps_subdomain}.${var.external_domain}"
#       woodpecker_agent_secret = sha256("woodpecker-ci")
#       gitea_url               = "gitea.${var.apps_subdomain}.${var.external_domain}"
#       gitea_client            = gitea_oauth2_app.woodpecker_ci.client_id
#       gitea_secret            = gitea_oauth2_app.woodpecker_ci.client_secret
#     }
#   }
# }

# resource "consul_config_entry" "woodpecker_agent_intention" {
#   kind = "service-intentions"
#   name = "woodpecker-server"

#   config_json = jsonencode({
#     Sources = [
#       {
#         Name   = "woodpecker-agent"
#         Action = "allow"
#       }
#     ]
#   })
# }
