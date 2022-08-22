job "democratic-csi-nfs-node" {
  datacenters = ["dc1"]

  # you can run node plugins as service jobs as well, but this ensures
  # that all nodes in the DC have a copy.
  type = "system"

  group "nodes" {
    task "plugin" {
      driver = "docker"

      env {
        CSI_NODE_ID = "${attr.unique.hostname}"
      }

      config {
        image = "docker.io/democraticcsi/democratic-csi:latest"

        args = [
          "--csi-version=1.5.0",
          # must match the csi_plugin.id attribute below
          "--csi-name=org.democratic-csi.nfs",
          "--driver-config-file=${NOMAD_TASK_DIR}/driver-config-file.yaml",
          "--log-level=info",
          "--csi-mode=node",
          "--server-socket=/csi/csi.sock",
        ]

        # node plugins must run as privileged jobs because they
        # mount disks to the host
        privileged = true
        ipc_mode = "host"
        network_mode = "host"
      }

      template {
        destination = "${NOMAD_TASK_DIR}/driver-config-file.yaml"

        data = <<EOF
driver: nfs-client
instance_id: {{ env "node.unique.id" }}
nfs:
  shareHost: nfs-server
  shareBasePath: /srv/nomad
  # shareHost:shareBasePath should be mounted at this location in the controller container
  controllerBasePath: "/storage"
  dirPermissionsMode: "0777"
  dirPermissionsUser: root
  dirPermissionsGroup: root
EOF
      }

      csi_plugin {
        # must match --csi-name arg
        id        = "org.democratic-csi.nfs"
        type      = "node"
        mount_dir = "/csi"
      }

      resources {
        cpu    = 500
        memory = 256
      }
    }
  }
}