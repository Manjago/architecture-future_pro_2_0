# -----------------------------------------------------------------------------
# vm_module — ресурсы
#
# Модуль создаёт Docker-контейнер с ограничениями CPU/RAM,
# подключаемым volume и сетью.
#
# Docker используется как локальная замена облачного провайдера.
# Принципы модульности и параметризации идентичны — меняется только провайдер.
# -----------------------------------------------------------------------------

locals {
  full_name = "${var.container_name}-${var.environment}"

  default_labels = {
    "managed-by"  = "terraform"
    "environment" = var.environment
    "module"      = "vm"
  }

  all_labels = merge(local.default_labels, var.labels)
}

# --- Docker Image ---

resource "docker_image" "vm" {
  name         = var.image
  keep_locally = true
}

# --- Подключаемый диск (Docker Volume) ---

resource "docker_volume" "data" {
  name = "${local.full_name}-data"

  labels {
    label = "managed-by"
    value = "terraform"
  }

  labels {
    label = "environment"
    value = var.environment
  }

  labels {
    label = "disk-size-gb"
    value = tostring(var.disk_size_gb)
  }
}

# --- Контейнер (аналог VM) ---

resource "docker_container" "vm" {
  name  = local.full_name
  image = docker_image.vm.image_id

  # --- Compute ресурсы ---
  cpu_shares = var.cpu_shares
  memory     = var.memory * 1024 * 1024 # МБ → байты

  # --- Подключаемый диск ---
  volumes {
    volume_name    = docker_volume.data.name
    container_path = var.disk_mount_path
  }

  # --- Сеть ---
  networks_advanced {
    name = var.network_name
  }

  # --- SSH-ключ (через переменную окружения) ---
  env = var.ssh_public_key != "" ? [
    "SSH_PUBLIC_KEY=${var.ssh_public_key}",
    "ENVIRONMENT=${var.environment}"
  ] : [
    "ENVIRONMENT=${var.environment}"
  ]

  # --- Метки ---
  dynamic "labels" {
    for_each = local.all_labels
    content {
      label = labels.key
      value = labels.value
    }
  }

  # Контейнер работает как long-running процесс (имитация VM)
  command = ["sleep", "infinity"]

  # Перезапуск при сбое
  restart = "unless-stopped"

  # Не удалять контейнер при terraform destroy, если он запущен — сначала остановить
  must_run = true
}
