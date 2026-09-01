---
name: dbt-testing-best-practices
description: >-
  Provides opinionated test writing standards, layer-by-layer test coverage expectations, generic vs singular test guidelines, severity thresholds, and data contract enforcement in dbt. Use when adding tests to schema.yml, defining custom singular tests, or configuring test coverage for dbt models and sources.
---

# dbt Testing Best Practices & Standards

This skill defines the opinionated rules, layer-by-layer test expectations, generic vs. singular test selection, severity configurations, and data contract enforcement for dbt data transformations.

---

## 1. Testing Philosophy & Core Principles

1. **Every Model Must Have Tests**: No model should be merged to production without at least primary key uniqueness and non-null assertions.
2. **Fail Early at Source/Staging**: Catch missing values and schema anomalies in `sources` and `staging` before they propagate to `marts`.
3. **Test Business Rules at Marts**: Validate aggregations, non-negative metrics, and referential integrity in final fact/dimension tables.

---

## 2. Layer-by-Layer Test Expectations

```
Sources ──> Staging ──> Intermediate ──> Marts
  │           │              │             │
  ▼           ▼              ▼             ▼
Freshness   PK: Unique      Cardinality   Grain Uniqueness
Nullability PK: Not Null    Join Safety   Metric Non-Negativity
            FK: Rel.                      Enum Validity
```

### Layer Matrix

| Layer | Target Objects | Mandatory Tests | Recommended Optional Tests |
| :--- | :--- | :--- | :--- |
| **Sources** | Raw source tables | `loaded_at_field` freshness checks, `not_null` on primary keys | `dbt_expectations.expect_table_columns_to_match_ordered_list` |
| **Staging** | `stg_` models | `unique` & `not_null` on primary key, `accepted_values` on status/type columns | `relationships` targeting parent staging/source models |
| **Intermediate** | `int_` models | `unique` & `not_null` on composite/surrogate key, join cardinality validation | `dbt_utils.expression_is_true` for logical invariants |
| **Marts** | `fct_`, `dim_`, `rpt_` | `unique` & `not_null` on primary key, `relationships` on foreign keys | `dbt_expectations.expect_column_values_to_be_between` for numeric metrics |

---

## 3. Generic vs. Singular Tests

### Generic Tests (Preferred by Default)
Defined inline in `schema.yml`. Always use generic tests for standard column assertions:
- Standard dbt built-ins: `unique`, `not_null`, `relationships`, `accepted_values`.
- Package generic tests: `dbt_utils`, `dbt_expectations`.

### Singular Tests (Custom SQL)
Created as `.sql` files inside the `tests/` directory. Use singular tests ONLY when:
- Testing complex multi-table business logic that cannot be expressed as a generic test (e.g., "Total order payments across payment methods must equal order total amount").
- Asserting zero-row conditions for illegal states (e.g., "Shipped date cannot precede ordered date").

---

## 4. Test Severity & Thresholds

Configure test severity in `schema.yml` to differentiate between pipeline breakers and warnings:

```yaml
columns:
  - name: order_id
    tests:
      - unique:
          severity: error
      - not_null:
          severity: error

  - name: discount_amount_usd
    tests:
      - dbt_utils.expression_is_true:
          expression: "discount_amount_usd >= 0"
          severity: warn
          warn_if: ">10"  # Allow up to 10 anomalous rows before warning
```

- **`severity: error` (Default)**: Use for Primary Key uniqueness, non-null constraints, and mandatory foreign keys. Halts CI/CD pipelines.
- **`severity: warn`**: Use for non-critical metrics, soft data quality checks, or known data drift issues under investigation.

---

## 5. Data Contracts & Documentation

For critical Marts models shared with external teams or BI tools, enable **Data Contracts**:

```yaml
models:
  - name: fct_orders
    config:
      contract:
        enforced: true
    columns:
      - name: order_id
        data_type: string
        description: "Primary key of the order."
        tests:
          - unique
          - not_null
```

---

## 6. Templates & Code References

- See [Schema Test Template](./examples/schema_template.yml) for complete YAML syntax.
- See [Testing Strategy Reference](./references/testing_strategy.md) for CI execution guidelines.

---

## 7. Test Verification Checklist

Before merging a model:

- [ ] Primary key has both `unique` and `not_null` tests.
- [ ] Foreign keys have `relationships` tests linking to valid parent models.
- [ ] Status/Enum columns have `accepted_values` defined.
- [ ] Severity levels are explicitly specified (`error` vs `warn`).
- [ ] Test command succeeds locally (`dbt test --select <model_name>`).
