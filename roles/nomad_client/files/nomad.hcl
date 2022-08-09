data_dir  = "/var/nomad"

client {
  enabled = true
  network_interface = "eth0"
}

telemetry {
  prometheus_metrics = true
  disable_hostname = true
  publish_allocation_metrics = true
  publish_node_metrics = true
}