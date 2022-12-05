variable "nomad_address" {
  type = string
}

terraform {
  required_providers {
    nomad = {
      source = "hashicorp/nomad"
      version = "~> 1.4"
    }
  }
}

provider "nomad" {
  address = "${var.nomad_address}"
}

