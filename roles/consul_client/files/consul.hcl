data_dir = "/var/consul"

server = false
advertise_addr = "{{ GetInterfaceIP \"eth0\" }}"
client_addr = "127.0.0.1 {{ GetInterfaceIP \"eth0\" }}"

retry_join = [ "consul1" ]

ports {
    grpc = 8502
}

connect {
    enabled = true
}
