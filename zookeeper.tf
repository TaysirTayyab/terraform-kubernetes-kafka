data "template_file" "zookeeper_host_names" {
  count    = "${var.zookeeper-replicas}"
  template = "zookeeper-${count.index}.${kubernetes_service.zookeeper.metadata.0.name}.${var.kube_namespace}.svc.cluster.local"
}

resource "kubernetes_service" "zookeeper" {
  metadata {
    name      = "kafka-zookeeper-headless"
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
          image = "confluentinc/cp-zookeeper"
          name = "zookeeper"
          command = [
            "bash",
            "-c",
            <<EOF
ZOOKEEPER_SERVER_ID=$(($${HOSTNAME##*-}+1)) \
/etc/confluent/docker/run
EOF
            ,
          ]

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

          env {
            name  = "ZOOKEEPER_SERVERS"
            value = "${join(";", formatlist("%s:2888:3888", data.template_file.zookeeper_host_names.*.rendered))}"
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
