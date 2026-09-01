# dbt Materialization Guide & Optimization Strategies

This reference provides deep guidance on choosing materializations, managing incremental logic, and configuring partitioning and clustering for cloud data warehouses (BigQuery, Snowflake, Redshift, Databricks).

---

## 1. Materialization Overview

| Materialization | How It Works | Best For | Trade-offs |
| :--- | :--- | :--- | :--- |
| `view` | Re-executes SQL query on every downstream query | Light transformations, Staging models, low-volume Intermediate models | Low storage cost; high query latency if chained deeply. |
| `table` | Executes SQL query and materializes physical table | Marts (Facts/Dims), frequently queried intermediate tables | High build performance for BI; rebuilds entire table on `dbt run`. |
| `incremental` | Materializes physical table and inserts/updates only new or changed rows | High-volume fact tables (10M+ rows), event streams | Complex SQL logic required for updates; fast execution and lower compute cost. |
| `ephemeral` | Inlines SQL as a CTE into downstream models | Single-use helper logic, zero schema footprint | Clean database schemas; cannot be queried directly via standard SQL CLI. |

---

## 2. Incremental Model Strategy

When configuring `materialized='incremental'`, always specify:
1. `unique_key`: Column(s) defining uniqueness (used to merge/update existing rows).
2. `on_schema_change`: Behaviour when schema changes (`sync_all_columns`, `append_new_columns`, `fail`).
3. `incremental_strategy`: Engine-specific strategy (`merge`, `insert_overwrite`, `append`).

### Standard Incremental Block Template

```sql
{{
    config(
        materialized='incremental',
        unique_key='order_id',
        on_schema_change='sync_all_columns',
        incremental_strategy='merge'
    )
}}

select
    order_id,
    customer_id,
    order_status,
    total_amount_usd,
    updated_at
from {{ ref('stg_ecommerce__orders') }}

{% if is_incremental() %}

  -- Look back 3 days to account for late-arriving updates/data drift
  where updated_at >= (select max(updated_at) - interval '3 day' from {{ this }})

{% endif %}
```

---

## 3. Warehouse Optimization Matrix

### BigQuery (Partitioning & Clustering)
- **Partitioning**: Partition fact tables on event date/timestamp columns (`partition_by={"field": "ordered_at", "data_type": "timestamp", "granularity": "day"}`).
- **Clustering**: Cluster on high-cardinality columns used in `WHERE` or `JOIN` filters (up to 4 columns, e.g., `cluster_by=["customer_id", "order_status"]`).

### Snowflake (Clustering Keys)
- Set `cluster_by=['date_trunc("day", ordered_at)', 'customer_id']` for tables > 100 GB.

### Databricks (Delta / Iceberg)
- Use `file_format='delta'` with liquid clustering `cluster_by=['ordered_at', 'customer_id']`.
