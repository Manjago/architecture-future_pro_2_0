# -----------------------------------------------------------------------------
# Переменные окружения — передаются в модуль
# -----------------------------------------------------------------------------

variable "environment" {
  description = "Имя окружения"
  type        = string
}

variable "container_name" {
  description = "Базовое имя контейнера"
  type        = string
  default     = "future20-vm"
}

variable "image" {
  description = "Docker-образ"
  type        = string
  default     = "ubuntu:22.04"
}

variable "cpu_shares" {
  description = "CPU shares"
  type        = number
}

variable "memory" {
  description = "RAM в МБ"
  type        = number
}

variable "disk_size_gb" {
  description = "Размер диска в ГБ"
  type        = number
}

variable "ssh_public_key" {
  description = "Публичный SSH-ключ"
  type        = string
  default     = ""
}
