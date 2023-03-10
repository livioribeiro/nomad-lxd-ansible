variable "version" {
  type    = string
  default = "2.6.4"
}

variable "namespace" {
  type    = string
  default = "system-ldap"
}

variable "volume_name" {
  type    = string
  default = "ldap-data"
}

job "ldap" {
  datacenters = ["infra", "apps"]
  type        = "service"
  namespace   = var.namespace

  group "openldap" {
    count = 1

    network {
      mode = "bridge"

      port "ldap" {
        static = 1389
      }
    }

    service {
      name = "openldap"
      port = "ldap"
      tags = ["traefik.enable=true"]
    }

    volume "data" {
      type            = "csi"
      source          = var.volume_name
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    task "openldap" {
      driver = "docker"

      config {
        image = "bitnami/openldap:${var.version}"
        ports = ["ldap"]

        volumes = [
          "local/root.ldif:/ldifs/root.ldif",
        ]
      }

      env {
        LDAP_ROOT = "dc=nomad,dc=local"
        LDAP_ADMIN_USERNAME = "admin"
        LDAP_ADMIN_PASSWORD = "admin"
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