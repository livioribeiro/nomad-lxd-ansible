# Traefik Consul ACL
resource "consul_acl_policy" "traefik" {
  name  = "traefik"
  rules = <<-EOT
    node_prefix "" {
      policy = "read"
    }

    service_prefix "" {
      policy = "read"
    }

    service_prefix "traefik" {
      policy = "write"
    }
  EOT
}
resource "consul_acl_role" "traefik" {
  name        = "traefik"
  description = "Traefik role"

  policies = [
    "${consul_acl_policy.traefik.id}"
  ]
}

resource "consul_acl_token" "traefik" {
  description = "Traefik acl token"
  roles       = [consul_acl_role.traefik.name]
  local       = true
}

data "consul_acl_token_secret_id" "traefik" {
  accessor_id = consul_acl_token.traefik.id
}

resource "nomad_namespace" "system_gateway" {
  name = "system-gateway"
}

resource "nomad_job" "proxy" {
  jobspec = file("${path.module}/jobs/proxy.nomad.hcl")
  # detach = false

  hcl2 {
    enabled = true
    vars = {
      namespace        = nomad_namespace.system_gateway.name
      proxy_suffix     = "${var.apps_subdomain}.${var.external_domain}"
      consul_acl_token = data.consul_acl_token_secret_id.traefik.secret_id
    }
  }
}