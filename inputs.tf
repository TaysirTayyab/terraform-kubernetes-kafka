variable "kube_namespace" {

  default = ""
}

variable "kafka-replicas" {
  default = ""
}
variable "zookeeper-replicas" {
  default = ""
}

variable "kafka_container_image_version" {
  description = "The Confluent Kafka image version."
  default     = "5.3.0"
}

variable "zookeeper_replicas" {
  description = "The number of Zookeeper replicas to run. 3 is recommended for production."
  default     = 1
}

variable "zookeeper_container_image_version" {
  description = "The Confluent Zookeeper image version."
  default     = "5.3.0"
}


variable "bam_resource_limits" {
  type = "map"
}

variable "bam_resource_requests" {
  type = "map"
}
