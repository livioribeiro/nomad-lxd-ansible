# Hashicorp Nomad cluster with Consul, Traefik, Ansible and LXD

Ansible playbook to create a [Nomad](https://www.nomadproject.io) cluster
with [Consul](https://www.consul.io), [Vault](https://vaultproject.io),
[Traefik](https://traefik.io/traefik/) and [Prometheus](https://prometheus.io)
using [LXD](https://linuxcontainers.org/#LXD)

The cluster contains the following nodes:

- 3 Consul nodes
- 3 Nomad server nodes
- 3 Nomad client nodes
- 1 Traefik node

Consul is used to bootstrap the Nomad cluster, for service discovery
and for the service mesh

Traefik is the entrypoint of the cluster.
It will use Consul service catalog to expose the services.

The proxy configuration exposes the services at `{{ service name }}.service.localhost`,
so when you deploy the service [hello.nomad](hello.nomad),
it will be exposed at `hello-world.service.localhost`

## CSI Plugins

There are 2 CSI plugins available: Nfs, powered by [RocketDuck csi plugin](https://gitlab.com/rocketduck/csi-plugin-nfs),
and [PortWorx](https://docs.portworx.com/install-portworx/install-with-other/nomad/installation/install-as-a-nomad-job).

The PortWorx plugin probably will not work under LXD

## Examples

There are 3 example jobs:

- [hello.nomad](examples/hello.nomad), a simples hello world
- [countdash.nomad](examples/countdash.nomad), shows the usage of consul connect
- [nfs](examples/nfs/), show how to setup volumes using the nfs csi plugin

