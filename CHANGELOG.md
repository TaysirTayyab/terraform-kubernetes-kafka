# CHANGELOG

## v1.1.1 

* SAASOPS-470: added the kafka min insync replicas option `kafka_min_insync_replicas` with default 1

## v1.1.0

* SAASOPS-461: Disable Confluent Metrics from ELK Kafka and ELK ZK
* standardized and genericized several variables names

### Breaking Changes

* **removed** `kafka-replicas` and replaced with `kafka_replicas`
* **removed** `zookeeper-replicas` and replaced with `zookeeper_replicas`
* **removed** `bam_resource_requests`, use `kafka_resource_requests`, and `zookeeper_resource_requests`
* **removed** `bam_resource_limits`, use `kafka_resource_limits` and `zookeeper_resource_limits`

* **added** `kafka_resource_requests["cpu"]` and `kafka_resource_requests["memory"]`
* **added** `kafka_resource_limits["cpu"]` and `kafka_resource_limits["memory"]`
* **added** `zookeeper_resource_requests["cpu"]` and `zookeeper_resource_requests["memory"]`
* **added** `zookeeper_resource_limits["cpu"]` and `zookeeper_resource_limits["memory"]`

## v1.0.0

Initial GA release.

## v0.1.0

Initial beta release.
