variable "nfs_server_host" {
  type = string
}

variable "external_domain" {
  type = string
}

variable "apps_subdomain" {
  type = string
}

variable "ca_cert" {
  type = string
}

variable "consul_address" {
  type = string
}

variable "consul_scheme" {
  type = string
}

variable "consul_token" {
  type = string
}

variable "nomad_address" {
  type = string
}

variable "nomad_secret_id" {
  type = string
}

variable "vault_address" {
  type = string
}

variable "vault_token" {
  type = string
}

variable "client_cert" {
  type = string
}

variable "client_key" {
  type = string
}

# variable "nomad_autoscaler_cert" {
#   type = string
# }

# variable "nomad_autoscaler_key" {
#   type = string
# }
