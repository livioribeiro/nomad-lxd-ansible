variable "version" {
  type = string
  default = "2.11.2"
}

variable "cpu" {
  type = number
  default = 1024
}

variable "memory" {
  type = number
  default = 1024
}

job "portworx" {
  datacenters = ["dc1"]
  type        = "service"
  namespace   = "system-storage"

  group "portworx" {
    count = 3

    constraint {
      operator  = "distinct_hosts"
      value     = "true"
    }

    # restart policy for failed portworx tasks
    restart {
      attempts = 3
      delay    = "30s"
      interval = "5m"
      mode     = "fail"
    }

    # how to handle upgrades of portworx instances
    update {
      max_parallel     = 1
      health_check     = "checks"
      min_healthy_time = "10s"
      healthy_deadline = "5m"
      auto_revert      = true
      canary           = 0
      stagger          = "30s"
    }

    network {
      port "portworx" {
        static = "9015"
      }
    }

    task "px-node" {
      driver = "docker"
      kill_timeout = "120s"   # allow portworx 2 min to gracefully shut down
      kill_signal = "SIGTERM" # use SIGTERM to shut down the nodes

      # setup environment variables for px-nodes
      env {
        AUTO_NODE_RECOVERY_TIMEOUT_IN_SECS = "1500"
        PX_TEMPLATE_VERSION                = "V4"
        CSI_ENDPOINT                       = "unix://var/lib/csi/csi.sock"
      }

      # CSI Driver config
      csi_plugin {
        id             = "portworx"
        type           = "monolith"
        mount_dir      = "/var/lib/csi"
        health_timeout = "30m"
      } 

      # container config
      config {
        image        = "portworx/oci-monitor:${var.version}"
        network_mode = "host"
        ipc_mode = "host"
        privileged = true
        
        # configure your parameters below
        # do not remove the last parameter (needed for health check)
        args = [
            "-c", "px-cluster-nomadv1",
            "-a",
            "-b",
            "-k", "consul://127.0.0.1:8500",
            "--endpoint", "0.0.0.0:9015"
        ]

        volumes = [
            "/var/cores:/var/cores",
            "/var/run/docker.sock:/var/run/docker.sock",
            "/run/containerd:/run/containerd",
            "/etc/pwx:/etc/pwx",
            "/opt/pwx:/opt/pwx",
            "/proc:/host_proc",
            "/etc/systemd/system:/etc/systemd/system",
            "/var/run/log:/var/run/log",
            "/var/log:/var/log",
            "/var/run/dbus:/var/run/dbus"
        ]

      }

      # resource config
      resources {
        cpu    = var.cpu
        memory = var.memory
      }

    }
  }
}