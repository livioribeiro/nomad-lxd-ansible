# Hashicorp Nomad cluster with Consul, Traefik, Ansible and LXD

Ansible playbook to create a [Nomad](https://www.nomadproject.io) cluster
with [Consul](https://www.consul.io) and [Traefik](https://traefik.io/traefik/)
using [LXD](https://linuxcontainers.org/#LXD)

The cluster contains 10 nodes:

- 3 Consul nodes
- 3 Nomad server nodes
- 3 Nomad client nodes
- 1 Traefik node

Consul is used to bootstrap the Nomad cluster, for service discovery
and for the service mesh

Traefik is the entrypoint of the cluster.
It will use Consul service catalog to expose the services.

The proxy configuration exposes the services at `{{ service name }}.service.{{ traefik ip }}.nip.io`,
so when you deploy the service [hello.nomad](hello.nomad),
it will be exposed at `hello-world.service.{{ traefik ip }}.nip.io`

There are 2 example jobs:

- [hello.nomad](hello.nomad), a simples hello world
- [countdash.nomad](countdash.nomad), shows the usage of consul connect