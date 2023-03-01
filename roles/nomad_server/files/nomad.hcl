data_dir   = "/var/nomad"
datacenter = "infra"

server {
  enabled          = true
  bootstrap_expect = 3
  raft_protocol    = 3
}

acl {
  enabled = true
}

telemetry {
  prometheus_metrics         = true
  disable_hostname           = true
  publish_allocation_metrics = true
  publish_node_metrics       = true
}
