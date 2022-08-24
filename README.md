# Hashicorp Nomad cluster with Consul, Traefik, Ansible and LXD

Ansible playbook to create a [Nomad](https://www.nomadproject.io) cluster
with [Consul](https://www.consul.io), [Vault](https://vaultproject.io),
[Traefik](https://traefik.io/traefik/) and [Prometheus](https://prometheus.io)
using [LXD](https://linuxcontainers.org/#LXD)

The cluster contains the following nodes:

- 3 Consul nodes
- 3 Nomad server nodes
- 4 Nomad client nodes (3 "apps" node, 1 "infra" node)
- 1 NFS server node

Consul is used to bootstrap the Nomad cluster, for service discovery and for the
service mesh.

The client infra nodes are the entrypoint of the cluster. They will run Traefik
and use Consul service catalog to expose the applications. The ports 80 and 8080
will be mapped into the host for convenience.

The proxy configuration exposes the services at `{{ service name }}.apps.localhost`,
so when you deploy the service [hello.nomad](hello.nomad),
it will be exposed at `hello-world.apps.localhost`

## NFS and CSI Plugin

For storage with the NFS node, a CSI plugin will be configured using the [RocketDuck CSI plugin](https://gitlab.com/rocketduck/csi-plugin-nfs).


The are also examples of [other CSI plugins](csi_plugins).

## Examples

There are 3 example jobs:

- [hello.nomad](examples/hello.nomad), a simples hello world
- [countdash.nomad](examples/countdash.nomad), shows the usage of consul connect
- [nfs](examples/nfs/), show how to setup volumes using the nfs csi plugin

