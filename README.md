# terraform-kubernetes-kafka
Terraform Module for Deploying Kafka in Kubernetes

Usage

module "wxt_integration_kafka" {
  source = "git::ssh://git@wwwin-github.cisco.com:padunne/terraform-kubernetes-kafka.git"
  kube_namespace = "${var.kube_namespace}"
  kafka-replicas = "3"
  zookeeper-replicas = "1"
}

Often we run 3 kafka nodes so set kafka-replicas to 3
For this many nodes a single zookeeper node should suffice
However we have in the past run 3 zookeeper nodes so change zookeeper-replicas as required

