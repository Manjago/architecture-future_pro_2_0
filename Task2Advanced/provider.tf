# -----------------------------------------------------------------------------
# Провайдер и backend
#
# State хранится в MinIO (S3-совместимое хранилище).
# Каждое окружение — отдельный ключ в бакете.
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }

  # -----------------------------------------------------------------------
  # Remote backend — S3-совместимый (MinIO)
  #
  # Параметры endpoint, access_key, secret_key можно переопределить через:
  #   - переменные окружения (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_S3_ENDPOINT)
  #   - флаги terraform init -backend-config="key=value"
  #   - файл backend.hcl: terraform init -backend-config=backend.hcl
  #
  # ВАЖНО: key меняется для каждого окружения — это обеспечивает изоляцию state.
  # При инициализации передаётся через -backend-config="key=<env>/terraform.tfstate"
  # -----------------------------------------------------------------------

  backend "s3" {
    bucket = "terraform-state"

    # key задаётся при init: -backend-config="key=dev/terraform.tfstate"
    # Это позволяет использовать один и тот же код для всех окружений
    key = "default/terraform.tfstate"

    region = "us-east-1" # MinIO требует region, значение не важно

    # --- MinIO-специфичные параметры ---
    endpoints = {
      s3 = "http://localhost:9000"
    }

    access_key = "minioadmin"
    secret_key = "minioadmin"

    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    skip_region_validation      = true
    use_path_style              = true
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}
