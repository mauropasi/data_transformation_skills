---
name: dbt-source-discovery
description: >-
  Inspects raw source tables, infers ingestion pipeline patterns (full_reload, incremental_append, cdc), detects delivery guarantees (at_least_once, exactly_once), soft deletes, timestamp fields, and retention TTLs, and enforces mandatory metadata blocks in sources.yml. Use when discovering raw data sources, configuring sources.yml, or inspecting raw table ingestion characteristics before data modeling or test writing.
---

# dbt Source Discovery & Metadata Enforcement

This skill defines the procedures for inspecting raw database schemas, inferring ingestion pipeline characteristics, and enforcing mandatory metadata contracts in `sources.yml`.

It acts as the **Signal Supplier** for downstream dbt modeling (`dbt-data-modeling`) and testing (`dbt-testing-best-practices`) skills.

---

## 1. Mandatory `sources.yml` Metadata Contract

Every source table entry in `sources.yml` MUST contain an explicit `meta` block and `loaded_at_field` defining its pipeline characteristics:

```yaml
version: 2

sources:
  - name: <source_name>
    schema: <raw_schema>
    tables:
      - name: <table_name>
        loaded_at_field: <timestamp_column> # Required for freshness checks
        meta:
          ingestion_type: <pattern>          # Required: full_reload | incremental_append | cdc
          delivery_guarantee: <guarantee>    # Required: at_least_once | exactly_once
          soft_delete_column: <column_name>   # Optional: Set if soft deletes exist (_fivetran_deleted)
          retention_days: <integer>          # Optional: Set if RAW TTL partition expiration exists
          lookback_days: <integer>           # Optional: Set for late-arriving backfill tolerance
        description: "<table_description>"
```

---

## 2. Ingestion Pipeline Signal Matrix

| Ingestion Type (`meta.ingestion_type`) | Physical RAW Characteristics | Downstream Modeling & Testing Impact |
| :--- | :--- | :--- |
| **`full_reload`** | Source table is truncated & reloaded on every run. PK is 100% unique in RAW. | - Staging model uses simple `SELECT FROM {{ source() }}`.<br>- Tests CAN be placed directly on raw source or staging. |
| **`incremental_append`** | New rows are appended over time (no in-place updates). | - Freshness test enforced on `loaded_at_field`.<br>- Tests placed on Staging model. |
| **`cdc`** | Change Data Capture log stream (Fivetran, Airbyte, Debezium). Contains multiple versions of the same primary key! | - **DO NOT place `unique` test on raw source** (duplicates expected!).<br>- Staging model MUST use window deduplication (`QUALIFY ROW_NUMBER() OVER (PARTITION BY id ORDER BY updated_at DESC) = 1`).<br>- Test `unique` ONLY on deduplicated Staging. |

---

## 3. Autonomous Discovery & Enforcement Workflow

When inspecting or creating a source definition in `sources.yml`:

### Step 1: Delegate Table Profiling
Delegate raw table inspection to data profiling tools/skills (e.g. `profiling-tables`) to extract:
1. **Column Schema**: Identify timestamp columns (`_loaded_at`, `_fivetran_synced`, `created_at`) and boolean flags (`_fivetran_deleted`, `is_deleted`).
2. **Key Uniqueness Ratio**: Compare `COUNT(*)` vs `COUNT(DISTINCT id)`.

### Step 2: Infer Pipeline Metadata
- If `COUNT(*) > COUNT(DISTINCT id)` AND CDC timestamp exists $\rightarrow$ Infer `ingestion_type: cdc` and `delivery_guarantee: at_least_once`.
- If `_fivetran_deleted` or `is_deleted` column exists $\rightarrow$ Set `soft_delete_column: _fivetran_deleted`.
- If timestamp column exists $\rightarrow$ Set `loaded_at_field: <column_name>`.

### Step 3: Enforce & Auto-Write `sources.yml`
Update or create `sources.yml` to insert the missing `meta:` and `loaded_at_field` properties.

### Step 4: Notify User
Log a concise notification:
> *"Enforced mandatory metadata in `sources.yml`: Set `ingestion_type: cdc` and `delivery_guarantee: at_least_once` for `raw_orders` based on detected `_fivetran_synced` column."*

---

## 4. References & Templates

- See [Source Metadata Spec Reference](./references/source_metadata_spec.md) for full metadata field definitions.
- See [Source YAML Template](./examples/sources_template.yml) for complete YAML syntax.
