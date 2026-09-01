---
name: dbt-testing-best-practices
description: >-
  Provides opinionated, signal-driven dbt test writing standards structured by layer (Staging raw data testing, Marts contracts, and $0-cost unit testing). Consumes source metadata signals (ingestion_type, delivery_guarantee, retention) and profiling metrics to determine test selection, severity: warn vs severity: error, and statistical anomaly checks. Applies Guided Autonomy and provides structured reviews highlighting trade-offs. Use when adding tests to schema.yml, defining unit tests, or configuring test suites for dbt projects.
---

# dbt Testing Best Practices & Standards

This skill defines opinionated, signal-driven testing strategies for dbt analytics engineering projects using **Guided Autonomy**.

---

## 1. Guided Autonomy & Review Principles

- **High Signal $\rightarrow$ Act Autonomously**: When profiling signals and lineage are clear (e.g. 100% unique primary key, clean foreign keys, standard status enums), act with full autonomy.
- **Ambiguity $\rightarrow$ Ask the User**: When data signals are non-obvious (e.g. FK orphan rate > 0%, or ambiguous business value vs descriptive attribute), prompt the user for clarification.
- **Structured Review Output**: Always accompany generated test suites with a structured engineering summary:
  - **Intent**: Purpose of the test suite.
  - **Straightforward Actions**: Tests generated automatically based on strong data signals.
  - **Trade-Offs & Compromises**: Explicit engineering compromises made (e.g., *"Compromised on multi-table `relationships` tests on view `X` due to high volume, using $0-cost Unit Tests instead."*).
  - **Questions for User Review**: Non-obvious decisions requiring user sign-off.

---

## 2. Testing Philosophy by Architectural Layer

Testing responsibilities are strictly separated by architectural layer:

```
[Raw Sources] ──> STAGING LAYER (Raw Data Testing)
                       │  - Primary Keys (unique, not_null)
                       │  - Foreign Key Relationships & Orphan Rate Signals
                       │  - Categorical Attributes (accepted_values with severity: warn)
                       │  - Descriptive Attributes (Explicitly SKIPPED)
                       ▼
                 INTERMEDIATE & MARTS LAYERS (Logic & Integration)
                       │  - SQL Logic Validation via $0-Cost dbt 1.8+ Unit Tests
                       │  - Incremental Integration Testing (Batch Merges)
                       │  - Data Contracts (contract: enforced: true) for BI Consumers
                       │  - Statistical Anomaly & Proportion Checks
```

---

## 3. Signal-Driven Staging Layer Testing (`staging`)

Before generating Staging tests, consume source metadata signals from `sources.yml` (via `dbt-source-discovery`) and delegate profiling statistics to profiling tools (e.g. `profiling-tables`).

### Autonomous Staging Decision Table

| Attribute Category | Profiling / Metadata Signal | Autonomous Test Action |
| :--- | :--- | :--- |
| **Primary Key (Clean)** | `meta.ingestion_type: full_reload` OR 100% Unique / 0% Nulls in profiling. | Apply `unique` & `not_null` (`severity: error`). |
| **Primary Key (CDC / Appends)** | `meta.ingestion_type: cdc` OR `delivery_guarantee: at_least_once`. | **DO NOT place `unique` test on raw source.** Apply `unique` test ONLY on the window-deduplicated Staging model. |
| **Foreign Key (Clean)** | Column ends in `_id`; Anti-join orphan rate against parent model = 0%. | Apply `relationships` (`severity: error`). |
| **Foreign Key (Ambiguous / Orphans)** | Anti-join orphan rate > 0% (e.g., 0.1% orphaned records). | Apply `relationships` with **`severity: warn`** AND prompt user to confirm if orphans are expected. |
| **Categorical Attribute** | Distinct count $\le 20$ representing > 95% of rows. | Apply `accepted_values` with **`severity: warn`**.<br>*(Pair with defensive `CASE WHEN ... ELSE 'other'` in Staging SQL)*. |
| **Descriptive / Metadata** | High distinct count (> 100), max length > 50 chars, free-text notes/descriptions. | **EXPLICITLY SKIP** generic assertions (`not_null`, `accepted_values`) to prevent brittle test bloat. |

---

## 4. Marts & Intermediate Layer Testing (Unit Tests & Contracts)

### A. $0-Cost dbt 1.8+ Unit Tests (`unit_tests:`)
Use in-memory Unit Tests to validate complex SQL logic (CASE statements, window functions, business math) without executing warehouse data queries:

```yaml
unit_tests:
  - name: test_order_discount_calculation
    model: fct_orders
    given:
      - input: ref('stg_ecommerce__orders')
        rows:
          - {order_id: '1', subtotal_amount_usd: 100.0, discount_amount_usd: 10.0}
    expect:
      rows:
        - {order_id: '1', final_amount_usd: 90.0}
```

### B. Public Data Contracts (`contract: enforced: true`)
For Marts models consumed by BI tools, reverse ETL, or external teams, enforce Data Contracts:

```yaml
models:
  - name: fct_orders
    config:
      contract:
        enforced: true
    columns:
      - name: order_id
        data_type: string
        tests:
          - unique:
              severity: error
          - not_null:
              severity: error
```

---

## 5. Statistical Anomaly & Proportion Testing

To detect silent data pipeline bugs (e.g., an API bug causing 90% of events to get stuck in `processing`), apply volumetric & ratio tests on key business metrics:

```yaml
models:
  - name: fct_orders
    columns:
      - name: order_status
        tests:
          - dbt_expectations.expect_column_proportions_to_be_between:
              row_condition: "ordered_at >= current_date() - interval '1 day'"
              partition_column: order_status
              values: ['delivered', 'shipped']
              min_value: 0.70
              max_value: 0.95
              severity: warn
```

---

## 6. Performance & Cost Optimization Rules

1. **BAN Heavy Tests on Views**: NEVER place `unique` or `relationships` tests on complex `view` or `ephemeral` models (which re-execute multi-table joins for every test). Move tests to raw `staging` or materialized `table`/`incremental` Marts.
2. **Restrict `dbt_utils.equality`**: Use `equality` ONLY during temporary migration PRs. Remove before merging to production.
3. **Scope Date Range Tests**: When `meta.retention_days` is present on a source, scope date tests to `WHERE _loaded_at >= current_date() - interval '<retention_days> day'`.

---

## 7. References & Templates

- See [Testing Decision Matrix Reference](./references/testing_decision_matrix.md) for profiling signal lookup.
- See [Schema Test Template](./examples/schema_template.yml) for complete YAML syntax.
