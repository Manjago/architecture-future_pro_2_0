# -----------------------------------------------------------------------------
# vm_module — входные параметры
# -----------------------------------------------------------------------------

variable "environment" {
  description = "Имя окружения (dev, stage, prod). Используется в именах ресурсов."
  type        = string

  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "environment должен быть одним из: dev, stage, prod."
  }
}

variable "container_name" {
  description = "Базовое имя контейнера. Итоговое имя: {container_name}-{environment}."
  type        = string
  default     = "vm"
}

variable "image" {
  description = "Docker-образ для контейнера (имитация ОС виртуальной машины)."
  type        = string
  default     = "ubuntu:22.04"
}

# --- Compute ресурсы ---

variable "cpu_shares" {
  description = "CPU shares (относительный вес CPU, аналог количества ядер). 1024 = 1 полное ядро."
  type        = number
  default     = 256

  validation {
    condition     = var.cpu_shares > 0
    error_message = "cpu_shares должен быть положительным числом."
  }
}

variable "memory" {
  description = "Ограничение оперативной памяти в МБ."
  type        = number
  default     = 256

  validation {
    condition     = var.memory >= 64
    error_message = "memory должен быть не менее 64 МБ."
  }
}

# --- Хранилище ---

variable "disk_size_gb" {
  description = "Размер подключаемого диска (Docker volume) в ГБ. Используется как метка — Docker volumes не имеют фиксированного размера, но параметр важен для документирования и совместимости с облачными провайдерами."
  type        = number
  default     = 5

  validation {
    condition     = var.disk_size_gb > 0
    error_message = "disk_size_gb должен быть положительным."
  }
}

variable "disk_mount_path" {
  description = "Путь монтирования подключаемого диска внутри контейнера."
  type        = string
  default     = "/mnt/data"
}

# --- Сеть ---

variable "network_name" {
  description = "Имя Docker-сети, к которой подключается контейнер (аналог Subnet ID)."
  type        = string
}

# --- Доступ ---

variable "ssh_public_key" {
  description = "Публичный SSH-ключ. Передаётся в контейнер через переменную окружения (в облачном провайдере — через metadata)."
  type        = string
  default     = ""
}

# --- Метки ---

variable "labels" {
  description = "Дополнительные метки для контейнера и volume."
  type        = map(string)
  default     = {}
}
