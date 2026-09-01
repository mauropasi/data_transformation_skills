# Testing Decision Matrix Reference

This reference details the autonomous signal-to-action heuristics used by the `dbt-testing-best-practices` skill.

---

## 1. Signal-to-Action Decision Engine

| Input Signal | Profiling Method | Autonomous Action |
| :--- | :--- | :--- |
| **PK Uniqueness = 100%, Nulls = 0%** | Profiling table stats (`profiling-tables`) | Apply `unique` & `not_null` (`severity: error`). |
| **Raw PK Duplicates + CDC Metadata** | `meta.ingestion_type: cdc` in `sources.yml` | Skip `unique` on raw source. Apply `unique` on deduplicated Staging model (`QUALIFY ROW_NUMBER()`). |
| **FK Anti-join Orphan Rate = 0%** | Query: `SELECT child.fk FROM child LEFT JOIN parent ... WHERE parent.pk IS NULL` | Apply `relationships` (`severity: error`). |
| **FK Anti-join Orphan Rate > 0%** | Anti-join returns 1+ orphan rows | Apply `relationships` with `severity: warn` (emits Slack/email alert without breaking build). |
| **Categorical Enum ($\le 20$ values)** | Distinct count $\le 20$ representing > 95% of rows | Apply `accepted_values` (`severity: warn`). Pair with defensive `CASE WHEN ... ELSE 'other'` in Staging SQL. |
| **Descriptive Field (Notes, Raw JSON)** | High distinct count (> 100), max length > 50 chars | **EXPLICITLY SKIP** generic assertions (`not_null`, `accepted_values`). |
| **Complex SQL Logic (`CASE WHEN`, math)** | Model has nested conditional branches | Generate **dbt 1.8+ Unit Test** (`unit_tests:`) using mock YAML rows ($0 warehouse cost). |
| **Public BI Exposure Model** | Model is tagged/consumed by BI or reverse ETL | Enforce **Data Contract** (`contract: enforced: true`). |
