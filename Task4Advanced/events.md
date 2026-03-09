# Каталог доменных событий «Будущее 2.0»

Каталог описывает все доменные события платформы: источник, семантику, подписчиков и минимальный контракт (обязательные поля payload). Все события передаются через Event Bus (Apache Kafka) в формате Avro, версионируются через Schema Registry.

> **Конвенция:** все события содержат стандартный конверт (envelope), описанный ниже. В таблицах указан только **payload** — бизнес-содержимое.

## Стандартный конверт события

```json
{
  "eventType": "PatientRegistered",
  "eventId": "uuid-v4",
  "timestamp": "2025-06-15T10:30:00Z",
  "source": "patient-management",
  "aggregateType": "Patient",
  "aggregateId": "uuid-v4",
  "version": 1,
  "correlationId": "uuid-v4",
  "payload": { ... }
}
```

| Поле | Тип | Описание |
|------|-----|----------|
| `eventType` | string | Название события (PascalCase) |
| `eventId` | UUID | Уникальный идентификатор экземпляра события |
| `timestamp` | ISO 8601 | Время возникновения события |
| `source` | string | Bounded Context — источник |
| `aggregateType` | string | Тип агрегата-источника |
| `aggregateId` | UUID | ID экземпляра агрегата |
| `version` | int | Версия схемы события |
| `correlationId` | UUID | ID для сквозной трассировки (связывает цепочку событий) |
| `payload` | object | Бизнес-содержимое (специфично для каждого события) |

---

## Patient Management

### PatientRegistered

| Поле | Значение |
|------|----------|
| **Источник** | Patient Management |
| **Агрегат** | Patient |
| **Семантика** | Новый пациент зарегистрирован в системе. Триггер для создания счёта в Billing и обновления аналитических проекций. |
| **Подписчики** | Billing (создание счёта), Analytics & BI (проекции) |

**Минимальный контракт (payload):**

| Поле | Тип | Описание |
|------|-----|----------|
| `patientId` | UUID | ID пациента |
| `fullName` | string | ФИО пациента |
| `dateOfBirth` | date | Дата рождения |
| `clinicId` | UUID | ID клиники регистрации |
| `insurancePolicyNumber` | string? | Номер полиса (опционально) |

### PatientUpdated

| Поле | Значение |
|------|----------|
| **Источник** | Patient Management |
| **Агрегат** | Patient |
| **Семантика** | Контактные данные или полис пациента обновлены. Информационное событие для синхронизации. |
| **Подписчики** | Analytics & BI (проекции) |

**Минимальный контракт (payload):**

| Поле | Тип | Описание |
|------|-----|----------|
| `patientId` | UUID | ID пациента |
| `changedFields` | string[] | Список изменённых полей |
| `clinicId` | UUID | ID клиники |

---

## Diagnostics

### ResearchOrdered

| Поле | Значение |
|------|----------|
| **Источник** | Diagnostics |
| **Агрегат** | DiagnosticOrder |
| **Семантика** | Врач назначил диагностическое исследование. Триггер для запуска ИИ-анализа (если применимо). |
| **Подписчики** | AI Diagnostics (запуск ИИ-анализа), Analytics & BI (проекции) |

**Минимальный контракт (payload):**

| Поле | Тип | Описание |
|------|-----|----------|
| `orderId` | UUID | ID заказа |
| `patientId` | UUID | ID пациента |
| `doctorId` | UUID | ID врача |
| `clinicId` | UUID | ID клиники |
| `researchTypes` | string[] | Типы назначенных исследований |

### ResearchCompleted

| Поле | Значение |
|------|----------|
| **Источник** | Diagnostics |
| **Агрегат** | DiagnosticOrder |
| **Семантика** | Все исследования в заказе завершены, результаты получены. Триггер для ИИ-анализа результатов. |
| **Подписчики** | AI Diagnostics (анализ результатов), Analytics & BI (проекции) |

**Минимальный контракт (payload):**

| Поле | Тип | Описание |
|------|-----|----------|
| `orderId` | UUID | ID заказа |
| `patientId` | UUID | ID пациента |
| `doctorId` | UUID | ID врача |
| `completedAt` | ISO 8601 | Время завершения |
| `researchCount` | int | Количество завершённых исследований |

> **Примечание:** сами результаты исследований (снимки, данные) **не включаются** в событие. Потребитель, которому нужны детали, запрашивает их через API Diagnostics по `orderId`.

---

## AI Diagnostics

### AIDiagnosisCompleted

| Поле | Значение |
|------|----------|
| **Источник** | AI Diagnostics |
| **Агрегат** | AIAnalysis |
| **Семантика** | ИИ-модель успешно завершила анализ диагностических данных. |
| **Подписчики** | Analytics & BI (проекции) |

**Минимальный контракт (payload):**

| Поле | Тип | Описание |
|------|-----|----------|
| `analysisId` | UUID | ID анализа |
| `orderId` | UUID | ID связанного заказа |
| `patientId` | UUID | ID пациента |
| `modelId` | UUID | ID модели |
| `modelVersion` | string | Версия модели |
| `confidence` | float | Уровень уверенности [0.0–1.0] |
| `resultSummary` | string | Краткое описание результата |

### AIDiagnosisFailed

| Поле | Значение |
|------|----------|
| **Источник** | AI Diagnostics |
| **Агрегат** | AIAnalysis |
| **Семантика** | ИИ-анализ завершился с ошибкой. Врач должен принять решение без ИИ-поддержки. |
| **Подписчики** | Analytics & BI (проекции, мониторинг качества моделей) |

**Минимальный контракт (payload):**

| Поле | Тип | Описание |
|------|-----|----------|
| `analysisId` | UUID | ID анализа |
| `orderId` | UUID | ID связанного заказа |
| `patientId` | UUID | ID пациента |
| `failureReason` | string | Причина ошибки |
| `modelId` | UUID | ID модели |
| `modelVersion` | string | Версия модели |

### ScoringCompleted

| Поле | Значение |
|------|----------|
| **Источник** | AI Diagnostics |
| **Агрегат** | ScoringModel |
| **Семантика** | Скоринг завершён, результат готов для кредитного решения. Триггер для Credit. |
| **Подписчики** | Credit (кредитное решение), Analytics & BI (проекции) |

**Минимальный контракт (payload):**

| Поле | Тип | Описание |
|------|-----|----------|
| `scoringId` | UUID | ID скоринга |
| `creditContractId` | UUID | ID кредитного договора |
| `riskCategory` | enum | low / medium / high / critical |
| `score` | float | Числовой скоринг-балл |
| `modelId` | UUID | ID модели |
| `modelVersion` | string | Версия модели |

---

## Billing

### InvoiceCreated

| Поле | Значение |
|------|----------|
| **Источник** | Billing |
| **Агрегат** | Invoice |
| **Семантика** | Создан новый счёт для пациента. |
| **Подписчики** | Analytics & BI (проекции) |

**Минимальный контракт (payload):**

| Поле | Тип | Описание |
|------|-----|----------|
| `invoiceId` | UUID | ID счёта |
| `patientId` | UUID | ID пациента |
| `clinicId` | UUID | ID клиники |
| `totalAmount` | decimal | Сумма счёта |
| `currency` | string | Валюта (ISO 4217) |
| `lineItemCount` | int | Количество позиций |

### PaymentReceived

| Поле | Значение |
|------|----------|
| **Источник** | Billing |
| **Агрегат** | Payment |
| **Семантика** | Платёж по счёту подтверждён платёжной системой. |
| **Подписчики** | Analytics & BI (проекции) |

**Минимальный контракт (payload):**

| Поле | Тип | Описание |
|------|-----|----------|
| `paymentId` | UUID | ID платежа |
| `invoiceId` | UUID | ID счёта |
| `amount` | decimal | Сумма платежа |
| `currency` | string | Валюта (ISO 4217) |
| `paymentMethod` | string | Способ оплаты |
| `externalTransactionId` | string | ID транзакции в платёжной системе |

---

## Credit

### CreditContractCreated

| Поле | Значение |
|------|----------|
| **Источник** | Credit |
| **Агрегат** | CreditContract |
| **Семантика** | Создан новый кредитный договор. Триггер для запуска скоринга в AI Diagnostics. |
| **Подписчики** | AI Diagnostics (запуск скоринга), Analytics & BI (проекции) |

**Минимальный контракт (payload):**

| Поле | Тип | Описание |
|------|-----|----------|
| `contractId` | UUID | ID договора |
| `borrowerId` | UUID | ID заёмщика |
| `requestedAmount` | decimal | Запрашиваемая сумма |
| `currency` | string | Валюта (ISO 4217) |
| `termMonths` | int | Срок кредита в месяцах |

### CreditApproved

| Поле | Значение |
|------|----------|
| **Источник** | Credit |
| **Агрегат** | CreditContract |
| **Семантика** | Кредит одобрен, договор переходит в статус Active. |
| **Подписчики** | Analytics & BI (проекции) |

**Минимальный контракт (payload):**

| Поле | Тип | Описание |
|------|-----|----------|
| `contractId` | UUID | ID договора |
| `borrowerId` | UUID | ID заёмщика |
| `approvedAmount` | decimal | Одобренная сумма |
| `interestRate` | decimal | Процентная ставка |
| `scoringId` | UUID | ID скоринга, на основании которого принято решение |

### CreditRejected

| Поле | Значение |
|------|----------|
| **Источник** | Credit |
| **Агрегат** | CreditContract |
| **Семантика** | Кредит отклонён. Финальный статус. |
| **Подписчики** | Analytics & BI (проекции) |

**Минимальный контракт (payload):**

| Поле | Тип | Описание |
|------|-----|----------|
| `contractId` | UUID | ID договора |
| `borrowerId` | UUID | ID заёмщика |
| `rejectionReason` | string | Причина отклонения |
| `scoringId` | UUID | ID скоринга |

---

## Internal Operations

### EmployeeHired

| Поле | Значение |
|------|----------|
| **Источник** | Internal Operations |
| **Агрегат** | Employee |
| **Семантика** | Принят новый сотрудник. |
| **Подписчики** | Analytics & BI (проекции) |

**Минимальный контракт (payload):**

| Поле | Тип | Описание |
|------|-----|----------|
| `employeeId` | UUID | ID сотрудника |
| `fullName` | string | ФИО |
| `role` | string | Роль (врач, оператор, администратор, …) |
| `clinicId` | UUID | ID клиники |
| `departmentId` | UUID | ID подразделения |

### InventoryUpdated

| Поле | Значение |
|------|----------|
| **Источник** | Internal Operations |
| **Агрегат** | InventoryItem |
| **Семантика** | Изменение количества или локации единицы инвентаря. |
| **Подписчики** | Analytics & BI (проекции) |

**Минимальный контракт (payload):**

| Поле | Тип | Описание |
|------|-----|----------|
| `itemId` | UUID | ID единицы инвентаря |
| `clinicId` | UUID | ID клиники |
| `itemName` | string | Наименование |
| `quantityBefore` | int | Количество до изменения |
| `quantityAfter` | int | Количество после изменения |
| `reason` | string | Причина изменения (поставка, списание, перемещение) |

---

## Analytics & BI

### ReportGenerated

| Поле | Значение |
|------|----------|
| **Источник** | Analytics & BI |
| **Агрегат** | Report |
| **Семантика** | Отчёт успешно сформирован. Внутреннее событие домена (не межконтекстное). |
| **Подписчики** | — (внутреннее событие) |

**Минимальный контракт (payload):**

| Поле | Тип | Описание |
|------|-----|----------|
| `reportId` | UUID | ID отчёта |
| `authorId` | UUID | ID автора |
| `reportType` | string | Тип отчёта (ad-hoc / scheduled) |
| `domains` | string[] | Домены, данные которых использованы |
| `generatedAt` | ISO 8601 | Время формирования |

---

## Сводная таблица событий

| # | Событие | Источник | Агрегат | Подписчики |
|---|---------|----------|---------|------------|
| 1 | PatientRegistered | Patient Management | Patient | Billing, Analytics |
| 2 | PatientUpdated | Patient Management | Patient | Analytics |
| 3 | ResearchOrdered | Diagnostics | DiagnosticOrder | AI Diagnostics, Analytics |
| 4 | ResearchCompleted | Diagnostics | DiagnosticOrder | AI Diagnostics, Analytics |
| 5 | AIDiagnosisCompleted | AI Diagnostics | AIAnalysis | Analytics |
| 6 | AIDiagnosisFailed | AI Diagnostics | AIAnalysis | Analytics |
| 7 | ScoringCompleted | AI Diagnostics | ScoringModel | Credit, Analytics |
| 8 | InvoiceCreated | Billing | Invoice | Analytics |
| 9 | PaymentReceived | Billing | Payment | Analytics |
| 10 | CreditContractCreated | Credit | CreditContract | AI Diagnostics, Analytics |
| 11 | CreditApproved | Credit | CreditContract | Analytics |
| 12 | CreditRejected | Credit | CreditContract | Analytics |
| 13 | EmployeeHired | Internal Operations | Employee | Analytics |
| 14 | InventoryUpdated | Internal Operations | InventoryItem | Analytics |
| 15 | ReportGenerated | Analytics & BI | Report | — (внутреннее) |
