#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# destroy.sh — Terraform destroy для указанного окружения
#
# Использование:
#   ./scripts/destroy.sh <env>
#
# Пример:
#   ./scripts/destroy.sh dev
# -----------------------------------------------------------------------------

set -euo pipefail

ENV="${1:-}"

if [[ -z "${ENV}" ]]; then
  echo "Ошибка: не указано окружение."
  echo "Использование: $0 <dev|stage|prod>"
  exit 1
fi

if [[ ! "${ENV}" =~ ^(dev|stage|prod)$ ]]; then
  echo "Ошибка: окружение '${ENV}' не поддерживается."
  exit 1
fi

TFVARS_FILE="envs/${ENV}.tfvars"

echo "=== Окружение: ${ENV} ==="
echo ""

echo "=== terraform init ==="
terraform init \
  -reconfigure \
  -backend-config="key=${ENV}/terraform.tfstate"

echo ""
echo "=== terraform destroy ==="
terraform destroy \
  -var-file="${TFVARS_FILE}"
