# dbt Testing Strategy & Execution Guidelines

This reference details CI/CD integration, test selection commands, and performance optimization for dbt test suites.

---

## 1. Test Selection Syntax

Run targeted test subsets during local development and CI pipelines to maintain fast feedback loops:

```bash
# Run tests for a single model
dbt test --select fct_orders

# Run tests for a model and all its downstream dependencies
dbt test --select fct_orders+

# Run tests for all staging models
dbt test --select staging

# Run only generic data tests (excluding singular tests)
dbt test --select test_type:generic

# Run only tests defined on sources (freshness & null checks)
dbt source freshness && dbt test --select source:*
```

---

## 2. CI/CD Pipeline Strategy

Structure dbt testing into distinct stages in your CI workflow:

```
[Git PR Created] ──> 1. Slim CI (dbt build --select state:modified+) ──> 2. Data Freshness Checks
```

### Recommended CI Command Sequence
1. **Source Freshness**: `dbt source freshness`
2. **Slim CI Execution**: `dbt build --select state:modified+ --defer --state path/to/prod/artifacts` (Runs models AND tests for changed files only).
3. **Data Quality Gate**: Fail CI if any `severity: error` test fails.

---

## 3. Recommended dbt Test Packages

- **`dbt-labs/dbt_utils`**: Additional generic tests (`equal_rowcount`, `expression_is_true`, `recency`, `at_least_one`).
- **`calogica/dbt_expectations`**: Great Expectations port for dbt (`expect_table_row_count_to_be_between`, `expect_column_values_to_be_in_type_list`).
