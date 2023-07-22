variable "version" {
  type    = string
  default = "nightly-dind-rootless"
}

variable "namespace" {
  type    = string
  default = "system-cicd"
}

variable "volume_name" {
  type    = string
  default = "actions-gitea"
}

variable "gitea_registration_token" {
  type    = string
  default = ""
}

job "ldap" {
  datacenters = ["apps"]
  type        = "service"
  namespace   = var.namespace

  group "openldap" {
    count = 1

    network {
      mode = "bridge"
    }

    service {
      name = "gitea-actions"

      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "gitea"
              local_bind_port  = "3000"
            }
          }
        }

        sidecar_task {
          resources {
            cpu    = 50
            memory = 32
          }
        }
      }
    }

    volume "data" {
      type            = "csi"
      source          = var.volume_name
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    task "actions" {
      driver = "docker"

      config {
        image = "gitea/act_runner:${var.version}"
      }

      env {
        DOCKER_HOST                     = "tcp://localhost:2376"
        DOCKER_CERT_PATH                = "/certs/client"
        DOCKER_TLS_VERIFY               = "1"
        GITEA_INSTANCE_URL              = "http://${NOMAD_UPSTREAM_ADDR_gitea}"
        GITEA_RUNNER_REGISTRATION_TOKEN = var.gitea_registration_token
      }

      volume_mount {
        volume      = "data"
        destination = "/bitnami/openldap"
      }

      template {
        destination = "local/root.ldif"

        data = <<-EOT
          dn: dc=nomad,dc=local
          objectClass: organization
          objectClass: dcObject
          dc: nomad
          o: nomad

          dn: ou=users,dc=nomad,dc=local
          objectClass: organizationalUnit
          objectClass: top
          ou: users

          dn: ou=groups,dc=nomad,dc=local
          objectClass: organizationalUnit
          objectClass: top
          ou: groups

          # user admin
          dn: cn=admin,ou=users,dc=nomad,dc=local
          objectClass: inetOrgPerson
          objectClass: top
          cn: admin
          sn: admin
          userPassword:: YWRtaW4=

          # admin group membership
          dn: cn=admin,ou=groups,dc=nomad,dc=local
          objectClass: groupOfNames
          cn: admin
          member: cn=admin,ou=users,dc=nomad,dc=local

          # user operator
          dn: cn=operator,ou=users,dc=nomad,dc=local
          objectClass: inetOrgPerson
          objectClass: top
          cn: operator
          sn: operator
          # password=operator
          userPassword:: b3BlcmF0b3I=

          # operator group membership
          dn: cn=operator,ou=groups,dc=nomad,dc=local
          objectClass: groupOfNames
          cn: operator
          member: cn=operator,ou=users,dc=nomad,dc=local
        EOT
      }
    }
  }
}