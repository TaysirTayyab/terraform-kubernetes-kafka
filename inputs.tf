variable "kube_namespace" {
  description = "The namespace where the kafka cluster will be deployed."
}

variable "kafka_replicas" {
  description = "The number of Kafka brokers to run. 3 is recommended for production."
  default     = 1
}

variable "kafka_min_insync_replicas" {
  description = "Minimum number of online replicas in sync"
  default     = 1
}

variable "kafka_jvm_memory_allocation" {
  type = "map"
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

variable "kafka_resource_requests" {
  type        = "map"
  description = <<EOF
The requested resources for kafka from the kubernetes master. Should be a map
with keys "cpu" and "memory".
EOF

  default = {
    cpu    = "500m"
    memory = "1280Mi"
  }
}

variable "kafka_resource_limits" {
  type        = "map"
  description = <<EOF
The resource limit for Kafka. Brokers exceeding these limits will be evicted.
Should be a map with keys "cpu" and "memory".
EOF

  default = {
    cpu     = "500m"
    memory  = "1280Mi"
  }
}

variable "zookeeper_resource_requests" {
  type        = "map"
  description = <<EOF
The requested resources for zookeeper from the kubernetes master. Should be a
map with keys "cpu" and "memory".
EOF

  default = {
    cpu    = "250m"
    memory = "512Mi"
  }
}

variable "zookeeper_resource_limits" {
  description = <<EOF
The resource limit for Zookeeper. Replicas exceeding these limits will be
evicted. Should be a map with keys "cpu" and "memory".
EOF

  default = {
    cpu    = "250m"
    memory = "512Mi"
  }
}
