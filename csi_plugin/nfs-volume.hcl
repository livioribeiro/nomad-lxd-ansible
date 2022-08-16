id        = "nfs-share1"
name      = "nfs-share1"
type      = "csi"
plugin_id = "nfs"

capability {
    access_mode = "single-node-writer"
    attachment_mode = "file-system"
}

parameters {
    server = "nfs-server"
    share = "/srv/nomad"
}