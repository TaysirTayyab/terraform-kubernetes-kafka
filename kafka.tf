data "template_file" "kafka_host_names" {
  count    = "${var.kafka_replicas}"
  template = "kafka-${count.index}.${kubernetes_service.kafka.metadata.0.name}.${var.kube_namespace}.svc.cluster.local"
}

resource "kubernetes_service" "kafka" {
  metadata {
    name      = "kafka"
    namespace = "${var.kube_namespace}"
  }

  spec {
    selector {
      app = "kafka"
    }

    port {
      port        = 9092
      target_port = 9092
      name        = "client"
    }

    cluster_ip = "None"
  }
}

resource "kubernetes_stateful_set" "kafka" {
  metadata {
    name      = "kafka"
    namespace = "${var.kube_namespace}"

    labels {
      app = "kafka"
    }
  }

  spec {
    selector {
      app = "kafka"
    }

    service_name = "kafka"
    replicas     = "${var.kafka_replicas}"

    template {
      metadata {
        labels {
          app = "kafka"
        }
      }

      spec {
        container {
          name  = "kafka"
          image = "confluentinc/cp-kafka:${var.kafka_container_image_version}"

          resources {
            limits {
              cpu    = "100m"
              memory = "250Mi"
            }
          }

          env {
            name = "POD_NAME"

            value_from {
              field_ref {
                field_path = "metadata.name"
              }
            }
          }

          env {
            name  = "KAFKA_ADVERTISED_LISTENERS"
            value = "PLAINTEXT://$(POD_NAME).${kubernetes_service.kafka.metadata.0.name}.${var.kube_namespace}.svc.cluster.local:9092"
          }

          env {
            name  = "KAFKA_ZOOKEEPER_CONNECT"
            value = "${join(",", data.template_file.zookeeper_host_names.*.rendered)}"
          }

          env {
            name  = "CONFLUENT_SUPPORT_METRICS_ENABLE"
            value = "0"
          }

          port {
            container_port = 9092
            name           = "client"
          }
        }
      }
    }
  }
}
