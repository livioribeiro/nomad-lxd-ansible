packer {
  required_plugins {
    lxd = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/lxd"
    }
  }
}

variable "ssh_key_file" {
  type    = string
  default = "../../.tmp/ssh/id_rsa.pub"
}

variable "ubuntu_version" {
  type    = string
  default = "jammy"
}

source "lxd" "nomad_client" {
  image           = "images:ubuntu/${var.ubuntu_version}/cloud"
  container_name  = "packer-nomad-client"
  output_image    = "nomad-client"
  publish_properties = {
    alias       = "nomad-client"
    description = "Nomad client image"
  }
  launch_config = {
    "security.nesting" = true
    "security.privileged" = true
  }
}

build {
  name = "nomad_client"
  sources = ["source.lxd.nomad_client"]

  provisioner "file" {
    source      = var.ssh_key_file
    destination = "/tmp/ssh_id_rsa.pub"
  }

  provisioner "file" {
    source      = "../../roles/consul_dns/files/consul.conf"
    destination = "/tmp/consul-dns.conf"
  }

  provisioner "file" {
    sources = [
      "docker-dns.conf",
      "daemon.json",
    ]
    destination = "/tmp/"
  }

  provisioner "shell" {
    script = "provision.sh"
  }

  provisioner "shell" {
    inline = ["mkdir /etc/certs.d"]
  }

  provisioner "file" {
    source      = "../../.tmp/certs/ca/cert.pem"
    destination = "/etc/certs.d/ca.pem"
  }

  provisioner "file" {
    sources = [
      "../../.tmp/certs/nomad_client/cert.pem",
      "../../.tmp/certs/nomad_client/key.pem",
    ]
    destination = "/etc/certs.d/"
  }
}
