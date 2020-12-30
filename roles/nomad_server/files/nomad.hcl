data_dir  = "/var/nomad"

server {
  enabled          = true
  bootstrap_expect = 3
  raft_protocol    = 3
}
