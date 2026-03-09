# -----------------------------------------------------------------------------
# Выходные значения
# -----------------------------------------------------------------------------

output "container_id" {
  description = "ID контейнера"
  value       = module.vm.container_id
}

output "container_name" {
  description = "Имя контейнера"
  value       = module.vm.container_name
}

output "ip_address" {
  description = "IP-адрес контейнера"
  value       = module.vm.ip_address
}

output "volume_name" {
  description = "Имя подключаемого диска"
  value       = module.vm.volume_name
}

output "network_name" {
  description = "Имя сети окружения"
  value       = docker_network.env_network.name
}

output "environment" {
  description = "Имя окружения"
  value       = module.vm.environment
}
