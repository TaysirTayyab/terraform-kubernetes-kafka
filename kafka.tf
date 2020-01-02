resource "kubernetes_config_map" "kafka_jmx_exporter_config" {
  metadata {
    name      = "kafka-jmx-exporter-config"
    namespace = "${var.kube_namespace}"
  }

  data {
    "config.yml" = <<EOF
hostPort: localhost:9999
EOF
  }
}

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
  depends_on = ["kubernetes_stateful_set.zookeeper"]

  metadata {
    name      = "kafka"  #???
    namespace = "${var.kube_namespace}"

    labels {
      app       = "kafka"
    }
  }

  spec {
    service_name = "kafka"
    replicas     = "${var.kafka_replicas}"

    selector {
      match_labels {
        app = "kafka"
      }
    }

    template {
      metadata {
        labels = {
          app = "kafka"
        }

        annotations {
          "prometheus.io/scrape" = "true"
          "prometheus.io/path"   = "/"
          "prometheus.io/port"   = 5556
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

          resources {
            requests {
              memory = "${lookup(var.bam_resource_requests["kafka"], "memory")}"
              cpu    = "${lookup(var.bam_resource_requests["kafka"], "cpu")}"
            }

            limits {
              memory = "${lookup(var.bam_resource_limits["kafka"], "memory")}"
              cpu    = "${lookup(var.bam_resource_limits["kafka"], "cpu")}"
            }
          }

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
            value = "${join(",", data.template_file.zookeeper_host_names.*.rendered)}"
          }
          env {
            name = "KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR"
            value = "${var.kafka_replicas}"
          }
          env {
            name  = "KAFKA_NUM_PARTITIONS"
            value = "${var.kafka_replicas}"
          }
          env {
            name  = "KAFKA_DEFAULT_REPLICATION_FACTOR"
            value = "${var.kafka_replicas}"
          }
          env {
            name  = "KAFKA_JMX_HOSTNAME"
            value = "localhost"
          }
          env {
            name  = "KAFKA_JMX_PORT"
            value = 9999
          }
          env {
            name  = "KAFKA_CONFLUENT_SUPPORT_METRICS_ENABLE"
            value = "false"
          }

          volume_mount {
            name = "kafka-data"
            mount_path = "/opt/kafka/data"
          }
        }

        container {
          image = "sscaling/jmx-prometheus-exporter:0.11.0"
          name  = "jmx-exporter"

          port {
            container_port = "5556"
          }

          env {
            name  = "CONFIG_YML"
            value = "/var/jmx_exporter/config.yml"
          }

          volume_mount {
            name       = "jmx-exporter-config"
            mount_path = "/var/jmx_exporter"
          }
        }

        volume {
          name = "jmx-exporter-config"

          config_map {
            name = "${kubernetes_config_map.kafka_jmx_exporter_config.metadata.0.name}"

            items {
              key  = "config.yml"
              path = "config.yml"
            }
          }
        }

        volume {
          name      = "data"
          empty_dir = {}
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
