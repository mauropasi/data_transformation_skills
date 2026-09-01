# Data Transformation Skills

Modular, production-ready AI coding skills for **dbt Data Transformation** (Source Discovery, Data Modeling & Test Writing) designed for Google Antigravity (AGY) and Claude Agentic Workflows.

---

## 📦 Included Skills

This repository contains a modular catalog of AI skills:

| Skill | Directory | Purpose & Scope |
| :--- | :--- | :--- |
| **dbt Source Discovery** | [`skills/dbt-source-discovery`](./skills/dbt-source-discovery/SKILL.md) | Inspects raw tables, infers ingestion patterns (`full_reload`, `incremental_append`, `cdc`), detects delivery guarantees (`at_least_once`), soft deletes, and retention TTLs, enforcing mandatory metadata in `sources.yml`. |
| **dbt Data Modeling** | [`skills/dbt-data-modeling`](./skills/dbt-data-modeling/SKILL.md) | Opinionated standards for dbt model architecture (`staging`, `intermediate`, `marts`), defensive SQL patterns (CDC window deduplication, status bucketing), materialization decision matrix, and CTE layout. |
| **dbt Testing Best Practices** | [`skills/dbt-testing-best-practices`](./skills/dbt-testing-best-practices/SKILL.md) | Signal-driven test writing structured by layer: Staging raw data testing (`unique`, `not_null`, `relationships`, `accepted_values` with `severity: warn`), Marts contracts (`contract: enforced: true`), and $0-cost **dbt 1.8+ Unit Testing**. |

---

## 🛠 How to Use & Import

### Option A: Import into a Target Project (Recommended)
Copy or symlink the `skills/` directory into your target project's `.agents/skills/` folder:

```bash
mkdir -p /path/to/my_dbt_project/.agents/skills
cp -r skills/* /path/to/my_dbt_project/.agents/skills/
```

### Option B: Install Globally on Your Machine
Copy skills into your personal Antigravity global configuration directory:

```bash
mkdir -p ~/.gemini/config/skills
cp -r skills/* ~/.gemini/config/skills/
```

---

## 🚀 Skill Architecture & Modularity

Each skill follows the standard **Antigravity / Claude Agentic Skill Specification**:
- **`SKILL.md`**: Main instruction document with frontmatter metadata (`name`, `description`).
- **`examples/`**: Reference implementations and code templates (`sources_template.yml`, `model_template.sql`, `schema_template.yml`).
- **`references/`**: In-depth operational guides loaded on-demand (progressive disclosure).
