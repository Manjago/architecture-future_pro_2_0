# Task2Advanced — CI/CD и удалённое хранение состояния

## Описание

Автоматизация развёртывания инфраструктуры через CI/CD с удалённым хранением Terraform state в S3-совместимом хранилище (MinIO).

Задание расширяет Task1Advanced: используется тот же модуль `vm_module`, но теперь state хранится удалённо, а развёртывание автоматизировано через pipeline.

## Структура

```
Task2Advanced/
├── provider.tf              # Провайдер Docker + S3 backend (MinIO)
├── main.tf                  # Сеть + вызов модуля vm из Task1Advanced
├── variables.tf             # Входные переменные
├── outputs.tf               # Выходные значения
├── envs/
│   ├── dev.tfvars           # Конфигурация dev
│   ├── stage.tfvars         # Конфигурация stage
│   └── prod.tfvars          # Конфигурация prod
├── docker-compose.yml       # MinIO (локальный S3)
├── scripts/
│   ├── init-backend.sh      # Запуск MinIO + создание бакета
│   ├── plan.sh              # terraform init + validate + plan
│   ├── apply.sh             # terraform apply (из сохранённого плана)
│   └── destroy.sh           # terraform destroy
├── .github/
│   └── workflows/
│       └── terraform.yml    # GitHub Actions CI/CD pipeline
└── README.md                # Этот файл
```

## Remote backend — MinIO

### Почему remote state

- **Коллаборация.** State доступен всей команде и CI/CD runner'ам.
- **Бэкап.** State не потеряется при потере рабочей машины.
- **CI/CD.** Pipeline запускается на чистом runner'е — ему нужен доступ к state.
- **Изоляция.** Каждое окружение хранит state в отдельном ключе — apply в dev не затрагивает prod.

### Как работает

MinIO запускается локально через Docker Compose и предоставляет S3-совместимый API. Terraform использует S3 backend для хранения state.

```
terraform init -backend-config="key=dev/terraform.tfstate"
                                     ^^^
                                     Ключ зависит от окружения
```

Структура state в бакете `terraform-state`:

```
terraform-state/
├── dev/terraform.tfstate
├── stage/terraform.tfstate
└── prod/terraform.tfstate
```

### Безопасность

- Секреты (access_key, secret_key) в продакшн-сценарии хранятся в **CI/CD Secrets** (GitHub Secrets), не в коде.
- В `provider.tf` указаны значения MinIO по умолчанию для локального запуска — в реальном проекте они были бы вынесены в переменные окружения.
- State может содержать чувствительные данные (пароли, ключи) — доступ к бакету ограничивается на уровне IAM.

## CI/CD — GitHub Actions

### Pipeline

```
PR создан
  └─→ validate (fmt + validate)
  └─→ plan (dev, stage, prod — параллельно)

Push в main
  └─→ validate
  └─→ plan (dev, stage, prod)
  └─→ apply dev     (автоматически)
  └─→ apply stage   (автоматически, после dev)
  └─→ apply prod    (РУЧНОЕ подтверждение, после stage)
```

### Ключевые решения

| Решение | Почему |
|---------|--------|
| **Plan → артефакт → Apply** | Apply использует сохранённый план, а не пересчитывает. Гарантия: применяется то, что показал plan. |
| **Matrix strategy для plan** | Все три окружения планируются параллельно — быстрая обратная связь. |
| **Последовательный apply: dev → stage → prod** | Каскад: сначала dev, потом stage, потом prod. Проблема на dev не доедет до prod. |
| **Ручное подтверждение для prod** | `environment: production` + GitHub Environment Protection Rules. Кто-то должен нажать кнопку. |
| **Concurrency group** | Параллельные pipeline для одного окружения не запускаются — защита от конфликтов state. |
| **Секреты через GitHub Secrets** | `MINIO_ACCESS_KEY`, `MINIO_SECRET_KEY` — не в коде. |
| **Path filter** | Pipeline запускается только при изменениях в Task2Advanced/ или Task1Advanced/modules/ — не тратит время на нерелевантные коммиты. |

### Секреты GitHub

Для работы pipeline нужно настроить в GitHub Settings → Secrets:

| Secret | Описание | Пример |
|--------|----------|--------|
| `MINIO_ACCESS_KEY` | Access key для S3/MinIO | `minioadmin` |
| `MINIO_SECRET_KEY` | Secret key для S3/MinIO | `minioadmin` |
| `MINIO_ENDPOINT` | Endpoint MinIO | `http://minio:9000` |

### Environments

Для ручного подтверждения prod нужно создать environment `production` в GitHub Settings → Environments → Protection Rules → Required reviewers.

## Локальный запуск

### Предварительные требования

- Docker и Docker Compose
- Terraform >= 1.3.0
- MinIO Client (`mc`) — [установка](https://min.io/docs/minio/linux/reference/minio-mc.html)

### Пошаговый запуск

```bash
cd Task2Advanced

# 1. Запуск MinIO + создание бакета
chmod +x scripts/*.sh
./scripts/init-backend.sh

# 2. Plan для dev
./scripts/plan.sh dev

# 3. Apply для dev
./scripts/apply.sh dev

# 4. Проверка
terraform output
docker ps --filter "label=environment=dev"

# 5. Проверка state в MinIO
mc ls local/terraform-state/dev/

# 6. Очистка
./scripts/destroy.sh dev
```

### Запуск для другого окружения

```bash
./scripts/plan.sh stage
./scripts/apply.sh stage

./scripts/plan.sh prod
./scripts/apply.sh prod
```

### Остановка MinIO

```bash
docker compose down          # остановить (данные сохраняются)
docker compose down -v       # остановить + удалить данные
```

## Скрипты

| Скрипт | Назначение | Аргументы |
|--------|-----------|-----------|
| `init-backend.sh` | Запуск MinIO, ожидание готовности, создание бакета `terraform-state` | — |
| `plan.sh` | `terraform init` + `validate` + `plan` с сохранением артефакта | `<dev\|stage\|prod>` |
| `apply.sh` | `terraform apply` из сохранённого плана | `<dev\|stage\|prod>` `[--auto]` |
| `destroy.sh` | `terraform destroy` для указанного окружения | `<dev\|stage\|prod>` |

## Связь с Task1Advanced

Task2Advanced **переиспользует модуль** из Task1Advanced:

```hcl
module "vm" {
  source = "../Task1Advanced/modules/vm"
  # ...
}
```

Это демонстрирует ключевое свойство модулей Terraform — один модуль, множество вызовов с разными конфигурациями и в разных контекстах.
