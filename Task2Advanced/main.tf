# -----------------------------------------------------------------------------
# Task2Advanced — CI/CD и удалённое хранение состояния
#
# Использует модуль vm_module из Task1Advanced.
# State хранится удалённо в MinIO (S3-совместимый backend).
# Окружение выбирается через .tfvars и backend-config key.
# -----------------------------------------------------------------------------

# --- Сеть окружения (аналог VPC Subnet) ---

resource "docker_network" "env_network" {
  name = "future20-${var.environment}"

  labels {
    label = "managed-by"
    value = "terraform"
  }

  labels {
    label = "environment"
    value = var.environment
  }
}

# --- Вызов модуля VM из Task1Advanced ---

module "vm" {
  source = "../Task1Advanced/modules/vm"

  environment    = var.environment
  container_name = var.container_name
  image          = var.image
  cpu_shares     = var.cpu_shares
  memory         = var.memory
  disk_size_gb   = var.disk_size_gb
  network_name   = docker_network.env_network.name
  ssh_public_key = var.ssh_public_key

  labels = {
    "project"  = "future-2.0"
    "pipeline" = "ci-cd"
  }
}
