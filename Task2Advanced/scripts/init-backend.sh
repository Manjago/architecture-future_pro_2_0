#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# init-backend.sh — Инициализация MinIO и создание бакета для Terraform state
#
# Предварительные требования:
#   - Docker и docker-compose установлены и запущены
#   - MinIO Client установлен:
#       Arch/Manjaro: sudo pacman -S minio-client (бинарник: mcli)
#       Другие:       https://min.io/docs/minio/linux/reference/minio-mc.html (бинарник: mc)
#
# Использование:
#   ./scripts/init-backend.sh
# -----------------------------------------------------------------------------

set -euo pipefail

MINIO_ENDPOINT="http://localhost:9000"
MINIO_ACCESS_KEY="minioadmin"
MINIO_SECRET_KEY="minioadmin"
BUCKET_NAME="terraform-state"

# --- Определяем имя бинарника MinIO Client ---
# На Arch/Manjaro пакет minio-client ставит бинарник как 'mcli',
# чтобы не конфликтовать с Midnight Commander ('mc').
# На других дистрибутивах бинарник называется 'mc'.
if command -v mcli &> /dev/null; then
  MC=mcli
elif command -v mc &> /dev/null; then
  MC=mc
else
  echo "Ошибка: MinIO Client не найден."
  echo "  Arch/Manjaro: sudo pacman -S minio-client"
  echo "  Другие:       https://min.io/docs/minio/linux/reference/minio-mc.html"
  exit 1
fi
echo "MinIO Client: ${MC}"

echo ""
echo "=== 1. Запуск MinIO ==="
docker compose up -d

echo ""
echo "=== 2. Ожидание готовности MinIO ==="
for i in $(seq 1 30); do
  if curl -sf "${MINIO_ENDPOINT}/minio/health/live" > /dev/null 2>&1; then
    echo "MinIO готов."
    break
  fi
  if [ "$i" -eq 30 ]; then
    echo "Ошибка: MinIO не запустился за 60 секунд."
    exit 1
  fi
  echo "  Ожидание... ($i/30)"
  sleep 2
done

echo ""
echo "=== 3. Настройка MinIO Client ==="
${MC} alias set local "${MINIO_ENDPOINT}" "${MINIO_ACCESS_KEY}" "${MINIO_SECRET_KEY}" 2>/dev/null || true

echo ""
echo "=== 4. Создание бакета '${BUCKET_NAME}' ==="
if ${MC} ls local/"${BUCKET_NAME}" > /dev/null 2>&1; then
  echo "Бакет '${BUCKET_NAME}' уже существует."
else
  ${MC} mb local/"${BUCKET_NAME}"
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
