# Hashicorp Nomad cluster with Consul, Traefik, Ansible and LXD

Ansible playbook to create a [Nomad](https://www.nomadproject.io) cluster
with [Consul](https://www.consul.io), [Vault](https://vaultproject.io),
[Traefik](https://traefik.io/traefik/) using [LXD](https://linuxcontainers.org/#LXD)
and https://nip.io/

The cluster contains the following nodes:

- 3 Consul nodes
- 3 Vault nodes
- 3 Nomad server nodes
- 5 Nomad client nodes (3 "apps" node, 2 "infra" node)
- 1 NFS server node
- 1 Load balancer node

Consul is used to bootstrap the Nomad cluster, for service discovery and for the
service mesh.

The Nomad client infra nodes are the entrypoints of the cluster. They will run Traefik
and use Consul service catalog to expose the applications.

Load balancer node will map ports 80 and 443 into the host, which will also have the ip
`10.99.0.1`, that is part of the cluster.

The proxy configuration exposes the services at `{{ service name }}.apps.10.99.0.1.nip.io`,
so when you deploy the service [hello.nomad](hello.nomad), it will be exposed at
`hello-world.apps.10.99.0.1.nip.io`

Consul, Vault and Nomad ui can be accessed in `https://consul.10.99.0.1.nip.io`,
`https://vault.10.99.0.1.nip.io` and `https://nomad.10.99.0.1.nip.io`, respectivelly.

Root tokens can be found in the `.tmp` directory.

## NFS and CSI Plugin

For storage with the NFS node, a CSI plugin will be configured using the [RocketDuck CSI plugin](https://gitlab.com/rocketduck/csi-plugin-nfs).


The are also examples of [other CSI plugins](csi_plugins).

## Examples

There are 3 example jobs:

- [hello.nomad](examples/hello.nomad), a simples hello world
- [countdash.nomad](examples/countdash.nomad), shows the usage of consul connect
- [nfs](examples/nfs/), show how to setup volumes using the nfs csi plugin

