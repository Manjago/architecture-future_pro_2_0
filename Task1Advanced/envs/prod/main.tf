# -----------------------------------------------------------------------------
# Окружение: prod
#
# Создаёт Docker-сеть и вызывает модуль vm_module.
# Конфигурация задаётся через terraform.tfvars.
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

# --- Вызов модуля VM ---

module "vm" {
  source = "../../modules/vm"

  environment    = var.environment
  container_name = var.container_name
  image          = var.image
  cpu_shares     = var.cpu_shares
  memory         = var.memory
  disk_size_gb   = var.disk_size_gb
  network_name   = docker_network.env_network.name
  ssh_public_key = var.ssh_public_key

  labels = {
    "project" = "future-2.0"
  }
}
