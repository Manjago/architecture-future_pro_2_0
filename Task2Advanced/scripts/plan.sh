#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# plan.sh — Terraform init + plan для указанного окружения
#
# Использование:
#   ./scripts/plan.sh <env>        # env = dev | stage | prod
#
# Пример:
#   ./scripts/plan.sh dev
#   ./scripts/plan.sh prod
#
# Скрипт:
#   1. Выполняет terraform init с backend-config key=<env>/terraform.tfstate
#   2. Выполняет terraform plan -var-file=envs/<env>.tfvars
#   3. Сохраняет план в файл tfplan-<env> (бинарный артефакт для apply)
# -----------------------------------------------------------------------------

set -euo pipefail

# --- Валидация аргументов ---

ENV="${1:-}"

if [[ -z "${ENV}" ]]; then
  echo "Ошибка: не указано окружение."
  echo "Использование: $0 <dev|stage|prod>"
  exit 1
fi

if [[ ! "${ENV}" =~ ^(dev|stage|prod)$ ]]; then
  echo "Ошибка: окружение '${ENV}' не поддерживается. Допустимые: dev, stage, prod."
  exit 1
fi

TFVARS_FILE="envs/${ENV}.tfvars"
PLAN_FILE="tfplan-${ENV}"

if [[ ! -f "${TFVARS_FILE}" ]]; then
  echo "Ошибка: файл ${TFVARS_FILE} не найден."
  exit 1
fi

echo "=== Окружение: ${ENV} ==="
echo ""

# --- Init с правильным ключом state ---

echo "=== terraform init ==="
terraform init \
  -reconfigure \
  -backend-config="key=${ENV}/terraform.tfstate"

echo ""

# --- Validate ---

echo "=== terraform validate ==="
terraform validate

echo ""

# --- Plan ---

echo "=== terraform plan ==="
terraform plan \
  -var-file="${TFVARS_FILE}" \
  -out="${PLAN_FILE}"

echo ""
echo "=== План сохранён: ${PLAN_FILE} ==="
echo "Следующий шаг:"
echo "  ./scripts/apply.sh ${ENV}"
