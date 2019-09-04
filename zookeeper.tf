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

    replicas = "${var.zookeeper-replicas}"

    template {
      metadata {
        labels = {
          app = "kafka-zookeeper"
        }
      }
      spec {
        container {
          image = "k8s.gcr.io/kubernetes-zookeeper:1.0-3.4.10"
          name = "zookeeper"
          command = ["sh", "-c", "start-zookeeper --servers=${var.zookeeper-replicas} --data_dir=/zookeeper/data"]

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

