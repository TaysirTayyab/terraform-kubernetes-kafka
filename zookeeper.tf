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
      app = "zookeeper"
    }
  }

  spec {
    service_name = "zookeeper"
    replicas     = "${var.zookeeper_replicas}"

    update_strategy {
      type = "RollingUpdate"
    }

    selector {
      match_labels {
        app = "zookeeper"
      }
    }

    template {
      metadata {
        labels = {
          app = "zookeeper"
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
                    key      = "app"
                    operator = "In"
                    values   = ["zookeeper"]
                  }
                }
              }
            }
          }
        }

        container {
          image = "confluentinc/cp-zookeeper:${var.zookeeper_container_image_version}"
          name  = "zookeeper"

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
            requests {
              memory = "${lookup(var.zookeeper_resource_requests, "memory")}"
              cpu    = "${lookup(var.zookeeper_resource_requests, "cpu")}"
            }

            limits {
              memory = "${lookup(var.zookeeper_resource_limits, "memory")}"
              cpu    = "${lookup(var.zookeeper_resource_limits, "cpu")}"
            }
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

          env {
            name  = "ZOOKEEPER_CLIENT_PORT"
            value = "2181"
          }

          env {
            name  = "ZOOKEEPER_SERVERS"
            value = "${join(";", formatlist("%s:2888:3888", data.template_file.zookeeper_host_names.*.rendered))}"
          }

          volume_mount {
            name       = "data"
            mount_path = "/zookeeper/data"
          }
          
          volume_mount {
            name       = "wal"
            mount_path = "/zookeeper/wal"
          }
        }

        volume {
          name      = "data"
          empty_dir = {}
        }

        volume {
          name = "wal"

          empty_dir {
            medium = "Memory"
          }
        }
      }
    }
  }
}
