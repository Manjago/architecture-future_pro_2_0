# Task1Advanced — Модульная инфраструктура Terraform

## Описание

Переиспользуемый модуль Terraform `vm_module`, который создаёт compute-ресурс с ограничениями CPU, RAM, подключаемым диском и сетевой изоляцией. Модуль применяется для трёх окружений (dev, stage, prod) с разными конфигурациями.

### Выбор провайдера

В качестве провайдера используется **Docker** (`kreuzwerker/docker`). Это позволяет запустить и проверить всю инфраструктуру локально, без облачных аккаунтов и сетевых эффектов.

Docker-контейнер выступает аналогом виртуальной машины: имеет ограничения CPU/RAM, подключаемый том (volume) и привязку к изолированной сети. Принципы модульности и параметризации полностью идентичны облачному провайдеру — при переезде в облако меняются только ресурсы в `main.tf` модуля, интерфейс (`variables.tf`, `outputs.tf`) остаётся тем же.

| Концепция задания | Реализация (Docker) | Облачный аналог |
|---|---|---|
| Виртуальная машина | `docker_container` | `yandex_compute_instance` |
| Количество ядер | `cpu_shares` | `resources.cores` |
| Объём RAM | `memory` | `resources.memory` |
| Подключаемый диск | `docker_volume` + mount | `yandex_compute_disk` |
| Subnet ID | `docker_network` | `yandex_vpc_subnet` |
| SSH-ключ | Environment variable | `metadata.ssh-keys` |

## Структура

```
Task1Advanced/
├── modules/
│   └── vm/
│       ├── main.tf          # Ресурсы: image, volume, container
│       ├── variables.tf     # Входные параметры модуля
│       └── outputs.tf       # Выходные значения
├── envs/
│   ├── dev/
│   │   ├── provider.tf      # Провайдер Docker
│   │   ├── main.tf          # Сеть + вызов модуля
│   │   ├── variables.tf     # Переменные окружения
│   │   ├── outputs.tf       # Выходные значения окружения
│   │   └── terraform.tfvars # Конфигурация dev
│   ├── stage/
│   │   └── ...              # Аналогичная структура
│   └── prod/
│       └── ...              # Аналогичная структура
└── README.md                # Этот файл
```

## Параметры модуля (variables.tf)

| Параметр | Тип | По умолчанию | Описание |
|---|---|---|---|
| `environment` | `string` | — (обязательный) | Имя окружения: `dev`, `stage`, `prod` |
| `container_name` | `string` | `"vm"` | Базовое имя контейнера |
| `image` | `string` | `"ubuntu:22.04"` | Docker-образ |
| `cpu_shares` | `number` | `256` | CPU shares (1024 = 1 ядро) |
| `memory` | `number` | `256` | RAM в МБ |
| `disk_size_gb` | `number` | `5` | Размер подключаемого диска в ГБ |
| `disk_mount_path` | `string` | `"/mnt/data"` | Точка монтирования диска |
| `network_name` | `string` | — (обязательный) | Имя Docker-сети |
| `ssh_public_key` | `string` | `""` | Публичный SSH-ключ |
| `labels` | `map(string)` | `{}` | Дополнительные метки |

## Выходные значения модуля (outputs.tf)

| Выход | Описание |
|---|---|
| `container_id` | ID контейнера |
| `container_name` | Имя контейнера |
| `image_id` | ID Docker-образа |
| `volume_name` | Имя подключаемого volume |
| `volume_mountpoint` | Точка монтирования volume на хосте |
| `network_name` | Имя сети |
| `ip_address` | IP-адрес контейнера |
| `environment` | Имя окружения |

## Конфигурации окружений

| Параметр | dev | stage | prod |
|---|---|---|---|
| CPU shares | 256 (¼ ядра) | 512 (½ ядра) | 1024 (1 ядро) |
| Memory | 256 МБ | 512 МБ | 1024 МБ |
| Disk | 5 ГБ | 10 ГБ | 20 ГБ |
| Image | ubuntu:22.04 | ubuntu:22.04 | ubuntu:22.04 |

## Предварительные требования

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.3.0
- [Docker](https://docs.docker.com/get-docker/) (запущен, доступен через `/var/run/docker.sock`)

## Как запустить

### 1. Инициализация

```bash
cd envs/dev
terraform init
```

### 2. Просмотр плана

```bash
terraform plan
```

Автоматически подхватит `terraform.tfvars` из текущей директории.

### 3. Применение

```bash
terraform apply
```

### 4. Проверка

```bash
# Посмотреть outputs
terraform output

# Проверить контейнер
docker ps --filter "label=managed-by=terraform"

# Зайти в контейнер
docker exec -it future20-vm-dev bash
```

### 5. Удаление

```bash
terraform destroy
```

### Запуск другого окружения

```bash
cd envs/stage
terraform init
terraform apply

cd envs/prod
terraform init
terraform apply
```

Каждое окружение независимо: свой state, своя сеть, свой контейнер. Можно запустить все три одновременно.

### Использование с явным var-file

```bash
terraform apply -var-file=terraform.tfvars
```

## Принципы

- **Никакого хардкода в модуле.** Все значения — через переменные. Модуль не знает, в каком окружении работает.
- **Валидация входов.** Переменные `environment`, `cpu_shares`, `memory`, `disk_size_gb` валидируются на уровне модуля.
- **Метки (labels).** Все ресурсы помечены: `managed-by=terraform`, `environment={env}`, `module=vm`. Упрощает аудит и фильтрацию.
- **Изоляция окружений.** Каждое окружение — отдельная Docker-сеть, отдельный state, отдельные ресурсы.
