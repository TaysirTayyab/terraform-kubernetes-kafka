output "kafka_service_addresses" {
  description = "A list of client service address for each of the Kafka replicas as host:port."
  value       = "${formatlist("%s:9092", data.template_file.kafka_host_names.*.rendered)}"
}

output "zookeeper_service_addresses" {
  description = "A list of client service addresses for each of the Zookeeper replicas as host:port."
  value       = "${formatlist("%s:2181", data.template_file.zookeeper_host_names.*.rendered)}"
}
