resource "nomad_namespace" "system-registry" {
  name = "system-registry"
}

resource "nomad_namespace" "system-gateway" {
  name = "system-gateway"
}

resource "nomad_namespace" "system-storage" {
  name = "system-storage"
}

resource "nomad_namespace" "system-monitoring" {
  name = "system-monitoring"
}

resource "nomad_namespace" "system-autoscaling" {
  name = "system-autoscaling"
}

resource "nomad_job" "proxy" {
  jobspec = file("jobs/proxy.nomad")
  detach = false

  depends_on = [
    nomad_namespace.system-gateway
  ]

  hcl2 {
    enabled = true
  }
}

resource "nomad_job" "prometheus" {
  jobspec = file("jobs/prometheus.nomad")
  detach = false

  depends_on = [
    nomad_namespace.system-monitoring
  ]

  hcl2 {
    enabled = true
  }
}

resource "nomad_job" "autoscaler" {
  jobspec = file("jobs/autoscaler.nomad")
  detach = false

  depends_on = [
    nomad_namespace.system-autoscaling
  ]

  hcl2 {
    enabled = true
  }
}

resource "nomad_job" "docker-registry" {
  jobspec = file("jobs/docker-registry.nomad")
  detach = false

  depends_on = [
    nomad_namespace.system-registry
  ]

  hcl2 {
    enabled = true
  }
}

resource "nomad_job" "rocketduck-nfs-controller" {
  jobspec = file("jobs/rocketduck-nfs/controller.nomad")
  detach = false

  depends_on = [
    nomad_namespace.system-storage
  ]

  hcl2 {
    enabled = true
  }
}

resource "nomad_job" "rocketduck-nfs-node" {
  jobspec = file("jobs/rocketduck-nfs/node.nomad")
  detach = false

  depends_on = [
    nomad_namespace.system-storage
  ]

  hcl2 {
    enabled = true
  }
}