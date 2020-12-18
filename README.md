# Hashicorp Nomad cluster with Ansible and LXD

Ansible playbook to create a [Nomad](https://www.nomadproject.io)

The cluster contains 10 nodes:

- 3 [Consul](https://www.consul.io) nodes
- 3 Nomad server nodes
- 3 Nomad client nodes
- 1 [Traefik](https://traefik.io/traefik/) node

[Consul](https://www.consul.io) is used service discovery and to setup the nomad cluster

[Traefik](https://traefik.io/traefik/) is the entrypoint of the cluster

The proxy configuration exposes the services at `{{ service name }}.service.{{ traefik ip }}.nip.io`,
so when you deploy the service [hello.nomad](hello.nomad),
it will be exposed at `hello-world.service.{{ traefik ip }}.nip.io`