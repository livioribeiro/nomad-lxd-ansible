job "democratic-csi-nfs-controller" {
  datacenters = ["dc1"]

  group "controller" {
    task "plugin" {
      driver = "docker"

      config {
        image = "docker.io/democraticcsi/democratic-csi:latest"

        args = [
          "--csi-version=1.5.0",
          # must match the csi_plugin.id attribute below
          "--csi-name=org.democratic-csi.nfs",
          "--driver-config-file=${NOMAD_TASK_DIR}/driver-config-file.yaml",
          "--log-level=info",
          "--csi-mode=controller",
          "--server-socket=/csi/csi.sock",
        ]
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
        type      = "controller"
        mount_dir = "/csi"
      }

      resources {
        cpu    = 500
        memory = 256
      }
    }
  }
}