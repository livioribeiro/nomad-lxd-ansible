job "hello-world" {
  datacenters = ["dc1"]

  group "example" {
    count = 3
    task "server" {
      # we will run a docker container
      driver = "docker"

      # resouces required by the task
      resources {
        network {
          # require a random port named "http"
          port "http" {}
        }
      }

      config {
        # docker image to run
        image = "hashicorp/http-echo"
        args = [
          "-listen", ":8080",
          "-text", "hello world",
        ]

        # map the random port to port 8080 on the task
        port_map = {
          http = 8080
        }
      }

      # exposed service
      service {
        # service name, compose the url like 'hello-world.service.myorg.com'
        name = "hello-world"
        # service will bind to this port
        port = "http"
        # tell traefik to expose this service
        tags = ["traefik.enable=true"]
      }
    }
  }
}
