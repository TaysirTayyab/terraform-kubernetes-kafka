data "template_file" "kafka_host_names" {
  count    = "${var.kafka-replicas}"
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
  depends_on = ["kubernetes_stateful_set.zookeeper"]

  metadata {
    name      = "kafka"  #???
    namespace = "${var.kube_namespace}"

    labels {
      app       = "kafka"
    }
  }

  spec {
    replicas = "${var.kafka-replicas}"
    selector {
      match_labels {
        app = "kafka"
      }
    }

    service_name = "kafka"
    replicas = "${var.kafka-replicas}"

    template {
      metadata {
        labels = {
          app = "kafka"
        }
      }
      spec {
        affinity {
          pod_anti_affinity {
            preferred_during_scheduling_ignored_during_execution {
              weight = 100
              pod_affinity_term {
                topology_key = "kubernetes.io/hostname"
                label_selector {
                  match_expressions {
                    key = "app"
                    operator = "In"
                    values = ["kafka"]
                  }
                }
              }
            }
          }
        }
        container {
          image = "confluentinc/cp-kafka:${var.kafka_container_image_version}"
          name = "server"

          port {
            container_port = 9092
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
            name = "KAFKA_ZOOKEEPER_CONNECT"
            # value = "zookeeper:2181"
            value = "${join(",", data.template_file.zookeeper_host_names.*.rendered)}"
          }
          env {
            name = "KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR"
            value = "${var.kafka-replicas}"
          }

          volume_mount {
            name = "kafka-data"
            mount_path = "/opt/kafka/data"
          }
        }
      }
    }
    volume_claim_template {
      metadata {
        name = "kafka-data"
      }
      spec {
        access_modes = ["ReadWriteOnce"]
        storage_class_name = "standard"   # want a different type??
        resources {
          requests {
            storage = "1Gi"
          }
        }
      }
    }
  }
}
