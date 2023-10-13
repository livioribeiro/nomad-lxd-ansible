terraform {
  backend "consul" {
    path = "terraform/nomad-cluster"
  }

  required_providers {
    consul = {
      source  = "hashicorp/consul"
      version = "~>2.18"
    }

    nomad = {
      source  = "hashicorp/nomad"
      version = "~>2.0"
    }

    vault = {
      source  = "hashicorp/vault"
      version = "~>3.20"
    }
  }
}

provider "consul" {
  address   = var.consul_address
  scheme    = var.consul_scheme
  token     = var.consul_token
  ca_file   = "../.tmp/certs/ca/cert.pem"
  cert_file = "../.tmp/certs/client/cert.pem"
  key_file  = "../.tmp/certs/client/key.pem"
}

provider "nomad" {
  address    = var.nomad_address
  secret_id  = var.nomad_secret_id
  ca_file    = "../.tmp/certs/ca/cert.pem"
  cert_file  = "../.tmp/certs/client/cert.pem"
  key_file   = "../.tmp/certs/client/key.pem"
}

provider "vault" {
  address      = var.vault_address
  token        = var.vault_token
  ca_cert_file = "../.tmp/certs/ca/cert.pem"
}
