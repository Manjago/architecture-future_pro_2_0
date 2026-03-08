# -----------------------------------------------------------------------------
# vm_module — выходные значения
# -----------------------------------------------------------------------------

output "container_id" {
  description = "ID созданного контейнера."
  value       = docker_container.vm.id
}

output "container_name" {
  description = "Имя контейнера."
  value       = docker_container.vm.name
}

output "image_id" {
  description = "ID используемого Docker-образа."
  value       = docker_image.vm.image_id
}

output "volume_name" {
  description = "Имя подключаемого volume (диска)."
  value       = docker_volume.data.name
}

output "volume_mountpoint" {
  description = "Точка монтирования volume на хост-машине."
  value       = docker_volume.data.mountpoint
}

output "network_name" {
  description = "Имя сети, к которой подключен контейнер."
  value       = var.network_name
}

output "ip_address" {
  description = "IP-адрес контейнера в Docker-сети."
  value       = docker_container.vm.network_data[0].ip_address
}

output "environment" {
  description = "Имя окружения."
  value       = var.environment
}
