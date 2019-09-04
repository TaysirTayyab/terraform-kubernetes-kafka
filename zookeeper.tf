variable "ZOOKEEPER_SERVERS_DEFAULT" {
  default = "zookeeper-1:2888:3888;zookeeper-2:2888:3888;zookeeper-3:2888:3888"
}
resource "kubernetes_service" "zookeeper-client" {
  metadata {
    name      = "kafka-zookeeper-client"
    namespace = "${var.kube_namespace}"
  }
  spec {
    selector {
      app = "kafka-zookeeper"
    }

    port {
      port        = 2181
      target_port = 2181
      name        = "client"
    }
  }
}


resource "kubernetes_service" "zookeeper-headless" {
  metadata {
    name      = "kafka-zookeeper-headless"
    namespace = "${var.kube_namespace}"
  }

  spec {
    selector {
      app = "kafka-zookeeper"
    }

    port {
      port        = 2888
      target_port = 2888
      name        = "followers"
    }

    port {
      port        = 3888
      target_port = 3888
      name        = "election"
    }

    cluster_ip = "None"

  }
}



resource "kubernetes_stateful_set" "zookeeper" {
  metadata {
    name      = "zookeeper"
    namespace = "${var.kube_namespace}"

    labels {
      app       = "kafka-zookeeper"
    }
  }

  spec {
    selector {
      app = "kafka-zookeeper"
    }

    service_name = "kafka-zookeeper-headless"

    # START HERE
    replicas = "1"

    template {
      metadata {
        labels = {
          app = "kafka-zookeeper"
        }
      }
      spec {
        container {
          image = "confluentinc/cp-zookeeper"
          name = "zookeeper"

          port {
            container_port = 2181
            name = "client"
          }

          port {
            container_port = 2888
            name = "server"
          }

          port {
            container_port = 3888
            name = "election"
          }

          env {
            name  = "ZOOKEEPER_CLIENT_PORT"
            value = "2181"
          }

          volume_mount {
            name = "data"
            mount_path = "/zookeeper/data"
          }
        }

        volume {
          name = "data"
          empty_dir = {}
        }
      }
    }
  }
}
