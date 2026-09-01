---
name: dbt-data-modeling
description: >-
  Provides opinionated data modeling standards, dbt architectural layering rules (staging, intermediate, marts), defensive SQL transformations (CDC deduplication, soft deletes, status bucketing), materialization selection, and CTE block conventions. Consumes source metadata signals (ingestion_type, delivery_guarantee, retention) to build resilient dbt pipelines. Applies Guided Autonomy and provides structured reviews highlighting trade-offs. Use when designing, creating, or refactoring dbt models.
---

# dbt Data Modeling Standards & Guidelines

This skill defines opinionated architectural principles, defensive SQL transformation patterns, layer responsibilities, materialization selection, and SQL/CTE layout standards using **Guided Autonomy**.

---

## 1. Guided Autonomy & Review Principles

- **High Signal $\rightarrow$ Act Autonomously**: When profiling signals and lineage are clear (e.g. CDC ingestion, soft delete columns, standard status enums), act with full autonomy.
- **Ambiguity $\rightarrow$ Ask the User**: When data signals are non-obvious (e.g. un-indexed high-volume tables without clear partition timestamps, or ambiguous business logic), prompt the user for clarification.
- **Structured Review Output**: Always accompany generated models with a structured engineering summary:
  - **Intent**: Business and analytical purpose of the model.
  - **Straightforward Actions**: Transformations generated automatically based on strong data signals.
  - **Trade-Offs & Compromises**: Explicit engineering compromises made (e.g., *"Selected `incremental` materialization with a 3-day lookback window due to 20M row volume and late-arriving Fivetran CDC updates."*).
  - **Questions for User Review**: Non-obvious modeling choices requiring user sign-off.

---

## 2. Architectural Layers & Responsibilities

dbt projects MUST strictly separate transformations into three core architectural layers:

```
[Raw Sources] ──> Staging (stg_) ──> Intermediate (int_) ──> Marts (fct_ / dim_ / rpt_)
```

### Layer Comparison Matrix

| Layer | Prefix | Granularity / Scope | Materialization | Allowed Upstream References | Key Responsibilities |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Staging** | `stg_<source>__<entity>` | 1-to-1 with raw source table | `view` (default) | Raw `source()` only | Renaming, light casting, CDC deduplication, soft delete filtering, defensive enum bucketing. NO multi-table joins. |
| **Intermediate** | `int_<entity>__<verb>` | Transformed state / abstraction | `ephemeral` or `view` | Staging (`stg_`) or Intermediate (`int_`) | Multi-source joins, business logic abstractions, window functions, deduplication. |
| **Marts** | `fct_`, `dim_`, `rpt_` | Business entity / Dimensional grain | `table` or `incremental` | Intermediate (`int_`) or Staging (`stg_`) | Star schema entities (Facts & Dimensions) or wide reporting tables. Final presentation for BI/consumers. |

---

## 3. Defensive Staging SQL Patterns

Before writing Staging SQL, read source metadata from `sources.yml` (via `dbt-source-discovery`). Apply these mandatory defensive transformation patterns:

### Pattern A: CDC / Append Window Deduplication
When `meta.ingestion_type: cdc` or `delivery_guarantee: at_least_once`, raw sources contain duplicate record IDs over time. Window-deduplicate in Staging:

```sql
select
    id as order_id,
    customer_id,
    order_status,
    _fivetran_synced
from {{ source('ecommerce', 'raw_orders') }}
qualify row_number() over (
    partition by id
    order by _fivetran_synced desc
) = 1
```

### Pattern B: Soft Delete Filtering
When `meta.soft_delete_column` exists (e.g. `_fivetran_deleted`), filter out deleted records:

```sql
where _fivetran_deleted is false
```

### Pattern C: Defensive Categorical Bucketing
To prevent unannounced raw status additions from breaking downstream models or executive dashboards, bucket unknown values into `'other'`:

```sql
case
    when raw_status in ('placed', 'shipped', 'delivered', 'cancelled') then raw_status
    when raw_status is null then 'unspecified'
    else 'other'
end as order_status
```

---

## 4. Materialization Decision Matrix

Refer to [Materialization Guide](./references/materialization_guide.md) for warehouse-specific tuning.

| Scenario | Recommended Materialization | Rationale |
| :--- | :--- | :--- |
| Staging models | `view` | Downstream models always fetch raw source updates without materialization overhead. |
| Single-use intermediate models | `ephemeral` | Eliminates schema clutter; CTE is inlined by dbt compiler. |
| Mart Fact & Dimension tables | `table` | Delivers fast query response times for BI tools and end consumers. |
| High-volume Fact tables (> 10M+ rows) | `incremental` | Processes only new/updated records to save compute cost and run time. |
| Mart referencing source with `meta.retention_days` | `table` or `incremental` | **MANDATORY**: Physically materializes table before raw historical partitions expire! |

---

## 5. SQL Code Formatting & CTE Layout

All dbt models MUST follow the standard Common Table Expression (CTE) structural pattern.

### Standard CTE Pattern

1. **Import CTEs**: Reference all upstream tables at the top of the file.
2. **Logical CTEs**: Apply transformations step-by-step in descriptive CTEs.
3. **Final CTE**: Select final columns with explicit formatting.
4. **Final Select**: `select * from final` (keeps troubleshooting simple).

---

## 6. Templates & Code References

- See [Model SQL Template](./examples/model_template.sql) for a complete reference dbt model.
- See [Materialization Guide](./references/materialization_guide.md) for partition and clustering strategies.
