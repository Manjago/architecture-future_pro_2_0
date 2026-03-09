#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# apply.sh — Terraform apply для указанного окружения
#
# Использование:
#   ./scripts/apply.sh <env>               # интерактивный режим (с подтверждением)
#   ./scripts/apply.sh <env> --auto        # автоматический режим (для CI/CD)
#
# Пример:
#   ./scripts/apply.sh dev
#   ./scripts/apply.sh prod --auto
#
# Скрипт:
#   1. Проверяет наличие сохранённого плана (tfplan-<env>)
#   2. Применяет план через terraform apply
#
# ВАЖНО: apply использует сохранённый план, а не пересчитывает с нуля.
# Это гарантирует, что применяется именно то, что было показано на этапе plan.
# -----------------------------------------------------------------------------

set -euo pipefail

# --- Валидация аргументов ---

ENV="${1:-}"
AUTO_APPROVE="${2:-}"

if [[ -z "${ENV}" ]]; then
  echo "Ошибка: не указано окружение."
  echo "Использование: $0 <dev|stage|prod> [--auto]"
  exit 1
fi

if [[ ! "${ENV}" =~ ^(dev|stage|prod)$ ]]; then
  echo "Ошибка: окружение '${ENV}' не поддерживается. Допустимые: dev, stage, prod."
  exit 1
fi

PLAN_FILE="tfplan-${ENV}"

if [[ ! -f "${PLAN_FILE}" ]]; then
  echo "Ошибка: файл плана '${PLAN_FILE}' не найден."
  echo "Сначала выполните: ./scripts/plan.sh ${ENV}"
  exit 1
fi

echo "=== Окружение: ${ENV} ==="
echo ""

# --- Apply ---

if [[ "${AUTO_APPROVE}" == "--auto" ]]; then
  echo "=== terraform apply (auto-approve) ==="
  terraform apply "${PLAN_FILE}"
else
  echo "=== terraform apply ==="
  echo "План: ${PLAN_FILE}"
  echo ""
  read -p "Применить план для окружения '${ENV}'? (yes/no): " CONFIRM
  if [[ "${CONFIRM}" == "yes" ]]; then
    terraform apply "${PLAN_FILE}"
  else
    echo "Отменено."
    exit 0
  fi
fi

echo ""
echo "=== Apply завершён ==="
echo ""
echo "Проверка:"
echo "  terraform output"
echo "  docker ps --filter 'label=environment=${ENV}'"
