terraform {
  required_providers {
    consul = {
      source  = "hashicorp/consul"
      version = "~>2.17"
    }

    nomad = {
      source  = "hashicorp/nomad"
      version = "~>1.4"
    }

    vault = {
      source = "hashicorp/vault"
      version = "3.13.0"
    }
  }
}

provider "consul" {
  address  = var.consul_address
  scheme   = var.consul_scheme
  token    = var.consul_token
  ca_pem   = var.ca_cert
  cert_pem = var.client_cert
  key_pem  = var.client_key
}

provider "nomad" {
  address   = var.nomad_address
  secret_id = var.nomad_secret_id
  ca_pem    = var.ca_cert
  cert_pem  = var.client_cert
  key_pem   = var.client_key
}

provider "vault" {
  address      = var.vault_address
  token        = var.vault_token
  ca_cert_file = "../.tmp/certs/ca/cert.pem"
}