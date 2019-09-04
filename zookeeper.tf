data "template_file" "zookeeper_host_names" {
  count    = "${var.zookeeper_replicas}"
  template = "zookeeper-${count.index}.${kubernetes_service.zookeeper.metadata.0.name}.${var.kube_namespace}.svc.cluster.local"
}

resource "kubernetes_service" "zookeeper" {
  metadata {
    name      = "zookeeper"
    namespace = "${var.kube_namespace}"
  }

  spec {
    selector {
      app = "zookeeper"
    }

    port {
      port        = 2181
      target_port = 2181
      name        = "client"
    }

    port {
      port        = 2888
      target_port = 2888
      name        = "server"
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
      app = "zookeeper"
    }
  }

  spec {
    selector {
      app = "zookeeper"
    }

    service_name = "zookeeper"
    replicas     = "${var.zookeeper_replicas}"

    template {
      metadata {
        labels {
          app = "zookeeper"
        }
      }

      spec {
        container {
          name  = "zookeeper"
          image = "confluentinc/cp-zookeeper:${var.zookeeper_container_image_version}"

          # this hack is copied from the confluent helm chart
          # https://github.com/confluentinc/cp-helm-charts/blob/master/charts/cp-zookeeper/templates/statefulset.yaml
          command = [
            "bash",
            "-c",
            <<EOF
ZOOKEEPER_SERVER_ID=$(($${HOSTNAME##*-}+1)) \
/etc/confluent/docker/run
EOF
            ,
          ]

          resources {
            limits {
              cpu    = "100m"
              memory = "250Mi"
            }
          }

          env {
            name = "ZOOKEEPER_SERVER_ID"

            value_from {
              field_ref {
                field_path = "metadata.name"
              }
            }
          }

          env {
            name  = "ZOOKEEPER_CLIENT_PORT"
            value = 2181
          }

          env {
            name  = "ZOOKEEPER_SERVERS"
            value = "${join(";", formatlist("%s:2888:3888", data.template_file.zookeeper_host_names.*.rendered))}"
          }

          env {
            name  = "CONFLUENT_SUPPORT_METRICS_ENABLE"
            value = "0"
          }

          port {
            container_port = 2181
            name           = "client"
          }

          port {
            container_port = 2888
            name           = "server"
          }

          port {
            container_port = 3888
            name           = "election"
          }
        }
      }
    }
  }
}
