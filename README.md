# Data Transformation Skills

Opinionated, production-ready AI coding skills for **dbt Data Transformation** (Data Modeling & Test Writing) designed for Google Antigravity (AGY) and Claude Agentic Workflows.

---

## 📦 Included Skills

This repository contains a modular catalog of AI skills:

| Skill | Folder | Purpose & Scope |
| :--- | :--- | :--- |
| **dbt Data Modeling** | [`skills/dbt-data-modeling`](./skills/dbt-data-modeling/SKILL.md) | Opinionated standards for dbt model architecture (`staging`, `intermediate`, `marts`), materialization decision matrix (`view`, `table`, `incremental`, `ephemeral`), and CTE layout conventions. |
| **dbt Testing Best Practices** | [`skills/dbt-testing-best-practices`](./skills/dbt-testing-best-practices/SKILL.md) | Opinionated rules for dbt test coverage, layer-by-layer expectations, generic vs. singular test selection, severity thresholds, and data contracts. |

---

## 🛠 How to Use & Iterate

### Option A: Import into a Target Project (Recommended)
Copy or symlink the `skills/` directory into your target project's `.agents/skills/` folder:

```bash
# Copying skills to a target project
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

## 🚀 Skill Standard Format

Each skill follows the standard **Antigravity / Claude Agentic Skill Specification**:
- **`SKILL.md`**: Main instruction document with frontmatter metadata (`name`, `description`).
- **`examples/`**: Reference implementations and code templates.
- **`references/`**: In-depth operational guides loaded on-demand (progressive disclosure).
