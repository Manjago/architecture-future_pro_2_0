#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# init-backend.sh — Инициализация MinIO и создание бакета для Terraform state
#
# Предварительные требования:
#   - Docker и docker-compose установлены и запущены
#   - mc (MinIO Client) установлен: https://min.io/docs/minio/linux/reference/minio-mc.html
#
# Использование:
#   ./scripts/init-backend.sh
# -----------------------------------------------------------------------------

set -euo pipefail

MINIO_ENDPOINT="http://localhost:9000"
MINIO_ACCESS_KEY="minioadmin"
MINIO_SECRET_KEY="minioadmin"
BUCKET_NAME="terraform-state"

echo "=== 1. Запуск MinIO ==="
docker compose up -d

echo ""
echo "=== 2. Ожидание готовности MinIO ==="
for i in $(seq 1 30); do
  if curl -sf "${MINIO_ENDPOINT}/minio/health/live" > /dev/null 2>&1; then
    echo "MinIO готов."
    break
  fi
  echo "  Ожидание... ($i/30)"
  sleep 2
done

echo ""
echo "=== 3. Настройка MinIO Client ==="
mc alias set local "${MINIO_ENDPOINT}" "${MINIO_ACCESS_KEY}" "${MINIO_SECRET_KEY}" 2>/dev/null || true

echo ""
echo "=== 4. Создание бакета '${BUCKET_NAME}' ==="
if mc ls local/"${BUCKET_NAME}" > /dev/null 2>&1; then
  echo "Бакет '${BUCKET_NAME}' уже существует."
else
  mc mb local/"${BUCKET_NAME}"
  echo "Бакет '${BUCKET_NAME}' создан."
fi

echo ""
echo "=== Готово ==="
echo "MinIO:       ${MINIO_ENDPOINT}"
echo "Консоль:     http://localhost:9001 (minioadmin/minioadmin)"
echo "Бакет:       ${BUCKET_NAME}"
echo ""
echo "Следующий шаг:"
echo "  ./scripts/plan.sh dev    # plan для dev-окружения"
