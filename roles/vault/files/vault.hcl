ui = true
disable_mlock = true

listener "tcp" {
  address = "{{ GetInterfaceIP \"eth0\" }}:8200"
  tls_disable = 1
}

storage "file" {
  path = "/var/vault"
}
