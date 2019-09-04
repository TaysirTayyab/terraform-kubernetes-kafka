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
    name      = "kafka"
    namespace = "${var.kube_namespace}"

    labels {
      app       = "kafka"
    }
  }

  spec {
    replicas = "${var.kafka-replicas}"
    selector {
      app = "kafka"
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
        hostname = "kafka"

        container {
          image = "wurstmeister/kafka"   # Need to use this image to work with stateful sets
          name = "kafka"

          port {
            container_port = 9092
          }

//          env {
//            name  = "KAFKA_BROKER_ID"
//            value = "${HOSTNAME##*-}"
//          }

          env {
            name  = "BROKER_ID_COMMAND"
            value = "hostname | awk -F '-' '{print $2}'"
            # value = "hostname"
          }

          # ????
          env {
            name = "KAFKA_ADVERTISED_HOST_NAME"
            value = "kafka"
          }

          env{
            name = "KAFKA_LISTENER_SECURITY_PROTOCOL_MAP"
            value = "INTERNAL:PLAINTEXT"
          }
          env{
            name = "KAFKA_INTER_BROKER_LISTENER_NAME"
            value = "INTERNAL"
          }

          env {
            name = "KAFKA_ZOOKEEPER_CONNECT"
            value = "kafka-zookeeper-client:2181"
          }
          env {
            name = "KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR"
            value = "${var.kafka-replicas}"
          }
          env {
            name = "DEFAULT_REPLICATION_FACTOR"
            value = "${var.kafka-replicas}"
          }



          env{
            name = "HOSTNAME_COMMAND"
            value = "echo $$HOSTNAME.kafka.${var.kube_namespace}.svc.cluster.local"
          }
          env{
            name = "PORT_COMMAND"
            value = "docker port $(HOSTNAME) 9092/tcp | cut -d: -f2"
          }
          env{
            name = "KAFKA_LISTENERS"
            value = "INTERNAL://_{HOSTNAME_COMMAND}:9092"
          }
          env{
            name = "KAFKA_ADVERTISED_LISTENERS"
            value = "INTERNAL://_{HOSTNAME_COMMAND}:9092"
          }


          volume_mount {
            name = "kafka-data"
            mount_path = "/opt/kafka/data"
          }
        }

      }
    }
    volume_claim_templates {
      metadata {
        name = "kafka-data"
      }
      spec {
        access_modes = ["ReadWriteOnce"]
        storage_class_name = "standard"
        resources {
          requests {
            storage = "1Gi"
          }
        }
      }
    }
  }
}

