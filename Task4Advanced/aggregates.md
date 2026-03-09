# Агрегаты «Будущее 2.0»

Описание ключевых агрегатов по каждому Bounded Context: корень, границы, инварианты, идентификатор, публикуемые события.

> **Принцип:** ссылки между агрегатами — только по ID (не прямые ссылки на объекты). Один агрегат — одна транзакция. Согласованность между агрегатами — через доменные события (eventual consistency).

---

## Patient Management

### Агрегат: Patient

| Поле | Значение |
|------|----------|
| **Корень** | Patient |
| **Идентификатор** | `patientId: UUID` |
| **Внутренние объекты** | ContactInfo (VO), InsurancePolicy (VO), MedicalCardRef (VO — ссылка по ID) |
| **Ссылки по ID** | `clinicId: UUID` |

**Инварианты:**
- У пациента обязательны ФИО и дата рождения.
- Номер полиса (если указан) уникален в рамках системы.
- Пациент привязан ровно к одной клинике при регистрации.

**Публикуемые события:**
- `PatientRegistered` — при первичной регистрации.
- `PatientUpdated` — при обновлении контактных данных или полиса.

---

## Diagnostics

### Агрегат: DiagnosticOrder

| Поле | Значение |
|------|----------|
| **Корень** | DiagnosticOrder |
| **Идентификатор** | `orderId: UUID` |
| **Внутренние объекты** | OrderItems (список назначенных исследований, VOs), DiagnosticResult (VO — результат исследования) |
| **Ссылки по ID** | `patientId: UUID`, `doctorId: UUID`, `clinicId: UUID` |

**Инварианты:**
- Заказ содержит хотя бы одно исследование.
- Заказ не может быть завершён, пока все исследования не получили результат.
- Результат исследования иммутабелен после записи (нельзя изменить, можно только добавить новый заказ).

**Публикуемые события:**
- `ResearchOrdered` — при создании заказа на исследование.
- `ResearchCompleted` — когда все исследования в заказе завершены.

---

## AI Diagnostics

### Агрегат: AIAnalysis

| Поле | Значение |
|------|----------|
| **Корень** | AIAnalysis |
| **Идентификатор** | `analysisId: UUID` |
| **Внутренние объекты** | AnalysisResult (VO), ModelVersion (VO), Confidence (VO — уровень уверенности модели) |
| **Ссылки по ID** | `orderId: UUID` (ссылка на DiagnosticOrder), `patientId: UUID`, `modelId: UUID` |

**Инварианты:**
- Анализ привязан к конкретной версии модели (фиксируется при запуске).
- Результат содержит уровень уверенности (confidence score) в диапазоне [0.0, 1.0].
- Анализ может завершиться либо успешно, либо с ошибкой — третьего состояния нет.

**Публикуемые события:**
- `AIDiagnosisCompleted` — при успешном завершении анализа.
- `AIDiagnosisFailed` — при ошибке (таймаут модели, некорректные входные данные).

### Агрегат: ScoringModel

| Поле | Значение |
|------|----------|
| **Корень** | ScoringModel |
| **Идентификатор** | `scoringId: UUID` |
| **Внутренние объекты** | ScoringResult (VO), RiskCategory (VO) |
| **Ссылки по ID** | `creditContractId: UUID`, `patientId: UUID`, `modelId: UUID` |

**Инварианты:**
- Скоринг привязан к конкретной версии модели.
- Результат включает категорию риска (low / medium / high / critical).
- Один кредитный договор — один активный скоринг (повторный скоринг создаёт новый агрегат).

**Публикуемые события:**
- `ScoringCompleted` — при завершении скоринга.

---

## Billing

### Агрегат: Invoice

| Поле | Значение |
|------|----------|
| **Корень** | Invoice |
| **Идентификатор** | `invoiceId: UUID` |
| **Внутренние объекты** | LineItems (список позиций, VOs), Money (VO — сумма и валюта из Shared Kernel) |
| **Ссылки по ID** | `patientId: UUID`, `clinicId: UUID` |

**Инварианты:**
- Счёт содержит хотя бы одну позицию.
- Сумма счёта > 0.
- Сумма оплат по счёту не может превышать сумму счёта.
- Счёт не может быть изменён после полной оплаты (статус Paid — финальный).

**Публикуемые события:**
- `InvoiceCreated` — при создании счёта.

### Агрегат: Payment

| Поле | Значение |
|------|----------|
| **Корень** | Payment |
| **Идентификатор** | `paymentId: UUID` |
| **Внутренние объекты** | Money (VO), PaymentMethod (VO) |
| **Ссылки по ID** | `invoiceId: UUID`, `externalTransactionId: String` (ID в платёжной системе) |

**Инварианты:**
- Платёж привязан к существующему счёту (по ID).
- Сумма платежа > 0.
- Платёж иммутабелен после подтверждения (отмена — через отдельный процесс возврата).

**Публикуемые события:**
- `PaymentReceived` — при подтверждении платежа.

---

## Credit

### Агрегат: CreditContract

| Поле | Значение |
|------|----------|
| **Корень** | CreditContract |
| **Идентификатор** | `contractId: UUID` |
| **Внутренние объекты** | CreditTerms (VO — срок, ставка, сумма), ContractStatus (VO) |
| **Ссылки по ID** | `borrowerId: UUID` (= `patientId` в Shared Kernel), `scoringId: UUID` |

**Инварианты:**
- Договор не может быть одобрен без завершённого скоринга.
- Сумма кредита > 0, срок > 0.
- Переходы статуса строго определены: Created → (Approved | Rejected). Approved → Active → Closed. Rejected — финальный.
- Одобренный договор не может быть отклонён (и наоборот).

**Публикуемые события:**
- `CreditContractCreated` — при создании договора.
- `CreditApproved` — при одобрении.
- `CreditRejected` — при отклонении.

---

## Internal Operations

### Агрегат: Employee

| Поле | Значение |
|------|----------|
| **Корень** | Employee |
| **Идентификатор** | `employeeId: UUID` |
| **Внутренние объекты** | EmployeeRole (VO), ContactInfo (VO) |
| **Ссылки по ID** | `clinicId: UUID`, `departmentId: UUID` |

**Инварианты:**
- У сотрудника обязательны ФИО, роль и привязка к подразделению.
- Сотрудник не может быть привязан к несуществующей клинике.

**Публикуемые события:**
- `EmployeeHired` — при приёме сотрудника.

### Агрегат: InventoryItem

| Поле | Значение |
|------|----------|
| **Корень** | InventoryItem |
| **Идентификатор** | `itemId: UUID` |
| **Внутренние объекты** | Quantity (VO), Location (VO) |
| **Ссылки по ID** | `clinicId: UUID` |

**Инварианты:**
- Количество на складе ≥ 0 (не может уйти в минус).
- У каждой единицы инвентаря есть привязка к клинике.

**Публикуемые события:**
- `InventoryUpdated` — при любом изменении количества или локации.

---

## Analytics & BI

### Агрегат: Report

| Поле | Значение |
|------|----------|
| **Корень** | Report |
| **Идентификатор** | `reportId: UUID` |
| **Внутренние объекты** | ReportDefinition (VO — срезы, фильтры, агрегации), Schedule (VO — расписание, опционально) |
| **Ссылки по ID** | `authorId: UUID` (бизнес-аналитик) |

**Инварианты:**
- Отчёт содержит хотя бы один срез данных.
- Автор отчёта имеет доступ к запрашиваемым доменам (проверяется через Access Control).
- Медицинские карты, истории болезни и результаты мед. исследований **не могут быть включены** в отчёт (бизнес-требование).

**Публикуемые события:**
- `ReportGenerated` — при успешном формировании отчёта.

---

## Сводная таблица

| Bounded Context | Агрегат | Ключ | Основные события |
|----------------|---------|------|-----------------|
| Patient Management | Patient | `patientId` | PatientRegistered, PatientUpdated |
| Diagnostics | DiagnosticOrder | `orderId` | ResearchOrdered, ResearchCompleted |
| AI Diagnostics | AIAnalysis | `analysisId` | AIDiagnosisCompleted, AIDiagnosisFailed |
| AI Diagnostics | ScoringModel | `scoringId` | ScoringCompleted |
| Billing | Invoice | `invoiceId` | InvoiceCreated |
| Billing | Payment | `paymentId` | PaymentReceived |
| Credit | CreditContract | `contractId` | CreditContractCreated, CreditApproved, CreditRejected |
| Internal Operations | Employee | `employeeId` | EmployeeHired |
| Internal Operations | InventoryItem | `itemId` | InventoryUpdated |
| Analytics & BI | Report | `reportId` | ReportGenerated |
