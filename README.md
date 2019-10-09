# Kafka Cluster w/ Zookeeper

This Terraform module deploys resources to a Kubernetes cluster to run a Kafka cluster. The following resources are deployed.

* a 1 node (configurable) Zookeeper cluster
* a 1 node (configurable) Kafka cluster which registers with the ZK cluster

## Usage

The module is designed to function with minimal bootstrapping. Just provide the namespace where the kafka and zookeeper clusters will go and the module will handle the rest.

```hcl
module "kafka_zk_cluster" {
  source = "git::https://wwwin-github.cisco.com/broadcloud-iac/terraform-kubernetes-kafka.git?v1.0.0"

  kube_namespace = "my-namespace"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| kafka\_container\_image\_version | The Confluent Kafka image version. | string | `"5.3.0"` | no |
| kafka\_replicas | The number of Kafka replicas to run. 3 is recommended for production. | string | `"1"` | no |
| kube\_namespace | The namespace where the kafka cluster will be deployed. | string | n/a | yes |
| zookeeper\_container\_image\_version | The Confluent Zookeeper image version. | string | `"5.3.0"` | no |
| zookeeper\_replicas | The number of Zookeeper replicas to run. 3 is recommended for production. | string | `"1"` | no |

## Outputs

| Name | Description |
|------|-------------|
| kafka\_service\_addresses | A list of client service address for each of the Kafka replicas as host:port. |
| zookeeper\_service\_addresses | A list of client service addresses for each of the Zookeeper replicas as host:port. |

