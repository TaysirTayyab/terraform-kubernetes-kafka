output "kafka_service" {
  value = "${kubernetes_service.kafka.metadata.0.name}"
}

output "kafka_port" {
  value = "${kubernetes_service.kafka.spec.0.port.0.port}"
}

output "kafka_ip" {
  value = "${kubernetes_service.kafka.spec.0.cluster_ip}"
}
