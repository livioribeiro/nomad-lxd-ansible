resource "nomad_namespace" "cicd" {
  name = "system-cicd"
}

resource "nomad_external_volume" "woodpecker_data" {
  depends_on = [
    data.nomad_plugin.nfs
  ]

  type         = "csi"
  plugin_id    = "nfs"
  volume_id    = "woodpecker-ci-data"
  name         = "woodpecker-ci-data"
  namespace    = nomad_namespace.cicd.name
  capacity_min = "500MiB"
  capacity_max = "750MiB"

  parameters = {
    uid  = "1000"
    gid  = "1000"
    mode = "770"
  }

  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }
}

data "http" "woodpecker_ci_gitea_app_check" {
  url = "http://root:Password123@gitea.${var.apps_subdomain}.${var.external_domain}/api/v1/user/applications/oauth2"
  request_headers = {
    "Accept": "application/json"
  }
}

locals {
  gitea_woodpecker_apps = [
    for a in jsondecode(data.http.woodpecker_ci_gitea_app_check.response_body)
    : a if a.name == "woodpecker-ci"
  ]
}

locals {
  gitea_woodpecker_app = length(local.gitea_woodpecker_apps) == 0 ? null : element(local.gitea_woodpecker_apps, 0)
}

data "external" "woodpecker_ci_gitea_app" {
  program = [
    "/bin/sh",
    "-c",
    <<EOT
app='${jsonencode(local.gitea_woodpecker_app)}'
result=''
if [ "$app" = 'null' ]
then
  result=$(curl -u 'root:Password123' -H 'Content-Type: application/json' 'http://@gitea.${var.apps_subdomain}.${var.external_domain}/api/v1/user/applications/oauth2')
else
  result="$app"
fi

result=$(echo $result | sed -e 's/"/\\\\"/g')
echo "{\"result\": \"$result\"}"
    EOT
  ]
}

locals {
  woodpecker_gitea_app_result = jsondecode(data.external.woodpecker_ci_gitea_app.result.result)
}

locals {
  gitea_woodpecker_client_id     = local.woodpecker_gitea_app_result.client_id
  gitea_woodpecker_client_secret = local.woodpecker_gitea_app_result.client_secret
}

resource "nomad_job" "woodpecker" {
  depends_on = [nomad_job.docker_registry]

  jobspec = file("${path.module}/jobs/woodpecker-ci.nomad.hcl")
  # detach = false

  hcl2 {
    enabled = true
    vars = {
      namespace               = nomad_namespace.cicd.name
      data_volume_name        = nomad_external_volume.woodpecker_data.name
      woodpecker_host         = "http://woodpecker.${var.apps_subdomain}.${var.external_domain}"
      woodpecker_agent_secret = sha256("woodpecker-ci")
      gitea_url               = "http://gitea.${var.apps_subdomain}.${var.external_domain}"
      gitea_client            = local.gitea_woodpecker_client_id
      gitea_secret            = local.gitea_woodpecker_client_secret
    }
  }
}

resource "consul_config_entry" "woodpecker_agent_intention" {
  kind = "service-intentions"
  name = "woodpecker-server"

  config_json = jsonencode({
    Sources = [
      {
        Name   = "woodpecker-agent"
        Action = "allow"
      }
    ]
  })
}
