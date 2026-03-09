# -----------------------------------------------------------------------------
# Переменные — единый набор для всех окружений
# Значения задаются через .tfvars файлы
# -----------------------------------------------------------------------------

variable "environment" {
  description = "Имя окружения (dev, stage, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "environment должен быть одним из: dev, stage, prod."
  }
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
  description = "CPU shares (1024 = 1 ядро)"
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
