# Source Metadata Specification Reference

This document details the mandatory metadata fields enforced in `sources.yml` by the `dbt-source-discovery` skill.

---

## Field Specifications

### 1. `loaded_at_field` (string, required for freshness)
- **Description**: The timestamp column used by dbt to measure data freshness (`dbt source freshness`).
- **Common Names**: `_fivetran_synced`, `_airbyte_emitted_at`, `_loaded_at`, `updated_at`, `created_at`.

### 2. `meta.ingestion_type` (string, required)
- **Allowed Values**:
  - `full_reload`: Raw source is truncated and reloaded on every sync. Raw IDs are 100% unique.
  - `incremental_append`: New records are appended over time without in-place updates.
  - `cdc`: Change Data Capture log stream containing multiple updated versions of the same primary key.
- **Impact**: CDC sources MUST be window-deduplicated in Staging models (`QUALIFY ROW_NUMBER()`).

### 3. `meta.delivery_guarantee` (string, required)
- **Allowed Values**:
  - `at_least_once` (Default): Retries or re-deliveries can introduce duplicate payloads in RAW. Uniqueness tests MUST be placed on Staging after deduplication.
  - `exactly_once`: Atomic delivery guarantee; raw tables are guaranteed duplicate-free.

### 4. `meta.soft_delete_column` (string, optional)
- **Description**: Column name tracking soft-deleted source records (e.g. `_fivetran_deleted`, `is_deleted`).
- **Impact**: Staging models MUST filter `WHERE <soft_delete_column> IS FALSE`.

### 5. `meta.retention_days` (integer, optional)
- **Description**: Number of days raw partitions are retained before warehouse TTL purges them.
- **Impact**: Downstream Mart models MUST be materialized as `incremental` or `table` to preserve historical data physically before raw data expires.

### 6. `meta.lookback_days` (integer, optional)
- **Description**: Number of days of late-arriving backfills or out-of-order data to process in incremental models.
- **Impact**: Downstream incremental models use `WHERE updated_at >= max(updated_at) - interval '<lookback_days> day'`.
