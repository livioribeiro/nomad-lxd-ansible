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
    "security.nesting"    = true
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
    source      = "daemon.json"
    destination = "/tmp/daemon.json"
  }

  provisioner "file" {
    source      = "docker-dns.conf"
    destination = "/tmp/docker-dns.conf"
  }

  provisioner "shell" {
    env = {
      GPG_HASHICORP   = "https://apt.releases.hashicorp.com/gpg"
      GPG_DOCKER      = "https://download.docker.com/linux/ubuntu/gpg"
      GPG_GETENVOY    = "https://deb.dl.getenvoy.io/public/gpg.8115BA8E629CC074.key"
      CNI_PLUGINS_URL = "https://github.com/containernetworking/plugins/releases/download/v1.3.0/cni-plugins-linux-amd64-v1.2.0.tgz"
    }

    script = "provision.sh"
  }
}
