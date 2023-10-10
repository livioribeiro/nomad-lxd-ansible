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
  default = "../.tmp/ssh/id_rsa.pub"
}

variable "ubuntu_version" {
  type    = string
  default = "jammy"
}

source "lxd" "consul" {
  image           = "images:ubuntu/${var.ubuntu_version}/cloud"
  container_name  = "packer-consul"
  output_image    = "consul"

  publish_properties = {
    alias       = "consul"
    description = "Consul image"
  }
}

build {
  name = "consul"
  sources = ["source.lxd.consul"]

  provisioner "file" {
    source      = var.ssh_key_file
    destination = "/tmp/ssh_id_rsa.pub"
  }

  provisioner "shell" {
    env = {
      DEBIAN_FRONTEND = "noninteractive"
      GPG_HASHICORP = "https://apt.releases.hashicorp.com/gpg"
    }

    script = "provision-consul.sh"
  }
}

source "lxd" "vault" {
  image           = "local:consul"
  container_name  = "packer-vault"
  output_image    = "vault"

  publish_properties = {
    alias       = "vault"
    description = "Vault image"
  }
}

build {
  name = "vault"
  sources = ["source.lxd.vault"]

  provisioner "shell" {
    env = {
      DEBIAN_FRONTEND = "noninteractive"
    }

    inline = ["apt-get install -q -y vault"]
  }
}

source "lxd" "nomad_server" {
  image           = "local:consul"
  container_name  = "packer-nomad-server"
  output_image    = "nomad-server"

  publish_properties = {
    alias       = "nomad-server"
    description = "Nomad server image"
  }
}

build {
  name = "nomad_server"
  sources = ["source.lxd.nomad_server"]

  provisioner "shell" {
    env = {
      DEBIAN_FRONTEND = "noninteractive"
    }

    inline = ["apt-get install -q -y nomad"]
  }
}

source "lxd" "nomad_client" {
  image           = "local:nomad-server"
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
    source      = "daemon.json"
    destination = "/tmp/daemon.json"
  }

  provisioner "file" {
    source      = "docker-dns.conf"
    destination = "/tmp/docker-dns.conf"
  }

  provisioner "shell" {
    env = {
      GPG_DOCKER      = "https://download.docker.com/linux/ubuntu/gpg"
      GPG_GETENVOY    = "https://deb.dl.getenvoy.io/public/gpg.8115BA8E629CC074.key"
      CNI_PLUGINS_URL = "https://github.com/containernetworking/plugins/releases/download/v1.3.0/cni-plugins-linux-amd64-v1.2.0.tgz"
    }

    script = "provision-nomad-client.sh"
  }
}
