---
name: dbt-data-modeling
description: >-
  Provides opinionated data modeling standards, dbt architectural layering rules (staging, intermediate, marts), materialization matrix guidelines, and CTE layout conventions for dbt projects. Use when designing, creating, or refactoring dbt models, deciding materialization types, or structuring SQL transformations.
---

# dbt Data Modeling Standards & Guidelines

This skill defines the opinionated architectural principles, layer responsibilities, materialization selection, and SQL/CTE layout standards for dbt data transformations.

---

## 1. Architectural Layers & Responsibilities

dbt projects MUST strictly separate transformations into three core architectural layers:

```
[Raw Sources] ──> Staging (stg_) ──> Intermediate (int_) ──> Marts (fct_ / dim_ / rpt_)
```

### Layer Comparison Matrix

| Layer | Prefix | Granularity / Scope | Materialization | Allowed Upstream References | Key Responsibilities |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Staging** | `stg_<source>__<entity>` | 1-to-1 with raw source table | `view` (default) | Raw `source()` only | Renaming, light casting, column selection, basic cleanup. NO joins, aggregations, or business logic. |
| **Intermediate** | `int_<entity>__<verb>` | Transformed state / abstraction | `ephemeral` or `view` | Staging (`stg_`) or other Intermediate (`int_`) models | Multi-source joins, complex business logic abstractions, window functions, deduplication. |
| **Marts** | `fct_`, `dim_`, `rpt_` | Business entity / Dimensional grain | `table` or `incremental` | Intermediate (`int_`) or Staging (`stg_`) models | Star schema entities (Facts & Dimensions) or wide analytical reporting tables. Final presentation for BI/consumers. |

---

## 2. Layering Rules & Guidelines

### Staging Layer (`stg_`)
- **Naming Rule**: `stg_<source_name>__<table_name>.sql` (e.g. `stg_stripe__payments.sql`).
- **Input Rule**: MUST query raw sources using `{{ source('source_name', 'table_name') }}`. NEVER reference `{{ ref(...) }}` in staging.
- **Transformation Scope**:
  - Rename columns to consistent `snake_case` standards.
  - Explicitly cast data types (e.g., timestamps to UTC, strings to trimmed lowercase).
  - Perform simple column calculations (e.g., `amount_cents / 100.0 as amount_usd`).
  - Do NOT join tables or perform aggregations (`GROUP BY`).

### Intermediate Layer (`int_`)
- **Naming Rule**: `int_<entity>__<transformation_purpose>.sql` (e.g. `int_orders__pivoted_payments.sql`).
- **Input Rule**: MUST query staging models or other intermediate models via `{{ ref(...) }}`.
- **Transformation Scope**:
  - Complex multi-table joins.
  - Structural transformations (pivoting, deduplication via `row_number()`, filtering active records).
  - Business logic encapsulation.

### Marts Layer (`fct_`, `dim_`, `rpt_`)
- **Naming Rule**:
  - `fct_<entity>` for immutable business events/transactions (e.g., `fct_orders.sql`).
  - `dim_<entity>` for core state entities/dimensions (e.g., `dim_customers.sql`).
  - `rpt_<domain>_<use_case>` for aggregated reporting tables (e.g., `rpt_finance_monthly_revenue.sql`).
- **Transformation Scope**:
  - Expose clean, consumer-ready schemas.
  - Every table MUST have a single, explicit grain (e.g., "One row per customer ID").

---

## 3. Materialization Decision Matrix

Refer to [Materialization Guide](./references/materialization_guide.md) for warehouse-specific tuning.

| Scenario | Recommended Materialization | Rationale |
| :--- | :--- | :--- |
| Staging models | `view` | Ensures downstream models always fetch raw source updates without materialization overhead. |
| Single-use intermediate models | `ephemeral` | Eliminates storage/view clutter in database schemas; CTE is inlined by dbt compiler. |
| Complex/heavy intermediate models | `view` or `table` | Use `view` by default; switch to `table` if downstream models query it repeatedly causing query performance bottlenecks. |
| Mart Fact & Dimension tables | `table` | Delivers fast query response times for BI tools and end consumers. |
| High-volume Fact tables (> 10M+ rows or daily append) | `incremental` | Processes only new/updated records to save compute cost and run time. |

---

## 4. SQL Code Formatting & CTE Layout

All dbt models MUST follow the standard Common Table Expression (CTE) structural pattern.

### Standard CTE Pattern

1. **Import CTEs**: Reference all upstream tables at the top of the file.
2. **Logical CTEs**: Apply transformations step-by-step in descriptive CTEs.
3. **Final CTE**: Select final columns with explicit formatting.
4. **Final Select**: `select * from final` (keeps troubleshooting simple).

### Formatting Conventions
- **Keywords**: Use lowercase for all SQL keywords (`select`, `from`, `where`, `left join`, `group by`).
- **Trailing Commas**: Place commas at the end of lines (Standard ANSI SQL style).
- **Column Aliases**: Always use explicit `as` when aliasing (`select customer_id as user_id`).
- **Column Ordering**:
  1. Primary key(s)
  2. Foreign key(s)
  3. Attributes & dimensions (alphabetical or logical grouping)
  4. Metrics & measures
  5. Timestamps / Metadata

---

## 5. Templates & Code References

- See [Model SQL Template](./examples/model_template.sql) for a complete reference dbt model.
- See [Materialization Guide](./references/materialization_guide.md) for partition and clustering strategies.

---

## 6. Model Verification Checklist

Before opening a Pull Request or running in production:

- [ ] Model is placed in the correct directory (`models/staging/`, `models/intermediate/`, or `models/marts/`).
- [ ] File and model name follow naming conventions (`stg_`, `int_`, `fct_`, `dim_`, `rpt_`).
- [ ] Staging models only query `source()`; intermediate/marts only query `ref()`.
- [ ] Materialization setting in `config()` or `dbt_project.yml` matches the decision matrix.
- [ ] CTE structure follows Import -> Logical -> Final -> Select *.
- [ ] All columns are in lowercase `snake_case`.
