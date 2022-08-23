data_dir = "/var/nomad"

server {
  enabled          = true
  bootstrap_expect = 3
  raft_protocol    = 3
}

telemetry {
  prometheus_metrics         = true
  disable_hostname           = true
  publish_allocation_metrics = true
  publish_node_metrics       = true
}
