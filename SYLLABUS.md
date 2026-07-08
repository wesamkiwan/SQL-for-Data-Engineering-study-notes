# Detailed Syllabus & Learning Plan

This is the full curriculum behind [`README.md`](README.md), with learning objectives,
key topics, and estimated time for every module. Estimates assume a complete beginner
working through examples and exercises hands-on, not just reading.

**Total estimated time: ~90–120 hours** (spread it out — 5-8 hours/week gets you through
in about 3 months). There is no clock running; go as slowly as you need to.

## How to read this document

Each row is one module (one folder in the repo). "Prerequisites" lists the modules you
need before starting that one — almost always just "the previous module," except where
noted (e.g., Part 5 and Part 6 both only require Part 2, so you can do them in either order).

---

## Part 0 — Orientation (~2 hours)

| Module | Learning objectives | Prerequisites |
|---|---|---|
| [Orientation](00-orientation/) | Define *data engineering* and where SQL fits in the modern data stack. Install PostgreSQL locally or set up a free cloud sandbox. Load the shared NorthStar Retail dataset. | None |

## Part 1 — SQL Foundations (~18 hours)

| Module | Learning objectives | Key topics |
|---|---|---|
| [01. Databases 101](01-sql-foundations/01-databases-101/) | Explain what a database, RDBMS, table, row, column, schema, and data type are. Explain client-server architecture. | RDBMS vs NoSQL, primary concepts, connecting with a client |
| [02. Basic Queries](01-sql-foundations/02-basic-queries/) | Retrieve, filter, sort, and limit rows from a single table. | `SELECT`, `WHERE`, `ORDER BY`, `LIMIT`/`OFFSET`, `DISTINCT`, aliases, comments |
| [03. Filtering & Operators](01-sql-foundations/03-filtering-and-operators/) | Use comparison, logical, range, set, and pattern operators; reason correctly about `NULL`. | `AND/OR/NOT`, `BETWEEN`, `IN`, `LIKE`/`ILIKE`, `IS NULL` |
| [04. Aggregations](01-sql-foundations/04-aggregations/) | Summarize data across groups of rows. | `COUNT/SUM/AVG/MIN/MAX`, `GROUP BY`, `HAVING` vs `WHERE` |
| [05. Joins](01-sql-foundations/05-joins/) | Combine rows across related tables correctly, and recognize/avoid duplicate-row bugs. | `INNER/LEFT/RIGHT/FULL/CROSS/SELF JOIN`, join diagrams, table grain |
| [06. Subqueries & CTEs](01-sql-foundations/06-subqueries-and-ctes/) | Break complex problems into named, reusable steps. | Scalar/correlated subqueries, `WITH` (CTEs), recursive CTEs (intro) |
| [07. Set Operations](01-sql-foundations/07-set-operations/) | Combine or compare result sets from multiple queries. | `UNION`, `UNION ALL`, `INTERSECT`, `EXCEPT` |
| [08. String, Date & Numeric Functions](01-sql-foundations/08-string-date-numeric-functions/) | Clean, transform, and compute over text, dates, and numbers. | `CONCAT`, `TRIM`, `SUBSTRING`, date truncation/intervals, rounding/casting |
| [09. CASE & Conditional Logic](01-sql-foundations/09-case-and-conditional-logic/) | Write conditional expressions inside queries. | `CASE WHEN`, `COALESCE`, `NULLIF` |

## Part 2 — Intermediate & Advanced SQL (~16 hours)

*Prerequisite: all of Part 1.*

| Module | Learning objectives | Key topics |
|---|---|---|
| [01. Window Functions](02-intermediate-advanced-sql/01-window-functions/) | Compute running totals, rankings, and row-to-row comparisons without collapsing rows. | `OVER()`, `PARTITION BY`, `ROW_NUMBER/RANK/DENSE_RANK`, `LAG/LEAD`, frames |
| [02. Advanced Aggregation](02-intermediate-advanced-sql/02-advanced-aggregation/) | Produce multi-level summaries and reshape rows into columns. | `GROUPING SETS`, `ROLLUP`, `CUBE`, `PIVOT`/crosstab patterns |
| [03. Data Modification & Transactions](02-intermediate-advanced-sql/03-data-modification-and-transactions/) | Safely change data and reason about concurrency. | `INSERT/UPDATE/DELETE`, `MERGE`/upsert, `BEGIN/COMMIT/ROLLBACK`, ACID, isolation levels |
| [04. Views & Materialized Views](02-intermediate-advanced-sql/04-views-and-materialized-views/) | Decide when to encapsulate logic in a view vs. pre-compute it. | `CREATE VIEW`, materialized views, refresh strategies |
| [05. Stored Procedures, Functions & Triggers](02-intermediate-advanced-sql/05-stored-procedures-functions-triggers/) | Package reusable logic inside the database, and know when *not* to. | User-defined functions, stored procedures, triggers, pros/cons vs. application code |
| [06. JSON & Semi-Structured Data](02-intermediate-advanced-sql/06-json-and-semistructured-data/) | Query nested/semi-structured data the way modern warehouses store event and API data. | `JSONB`, `->`/`->>`, `UNNEST`/arrays, when to model vs. leave nested |

## Part 3 — Database Design & Data Modeling (~14 hours)

*Prerequisite: Part 1. Part 2 recommended but not required.*

| Module | Learning objectives | Key topics |
|---|---|---|
| [01. Normalization & Keys](03-database-design-and-modeling/01-normalization-and-keys/) | Design a schema that avoids duplicate/inconsistent data, and know when to break the rules. | 1NF–3NF, primary/foreign/candidate keys, constraints, ER diagrams |
| [02. Dimensional Modeling](03-database-design-and-modeling/02-dimensional-modeling/) | Remodel an OLTP schema for fast analytics. | Facts vs. dimensions, star vs. snowflake schema, Slowly Changing Dimensions (SCD 0–2) |
| [03. Warehouse vs. Lake vs. Lakehouse](03-database-design-and-modeling/03-warehouse-lake-lakehouse/) | Choose the right storage paradigm for a given problem. | Data warehouse, data lake, lakehouse, when to use each |
| [04. Modern Modeling Patterns](03-database-design-and-modeling/04-modern-modeling-patterns/) | Recognize and apply patterns used in modern cloud data teams. | One Big Table (OBT), Data Vault basics, Medallion (bronze/silver/gold) architecture |

## Part 4 — Data Engineering with SQL (~12 hours)

*Prerequisite: Parts 1–3.*

| Module | Learning objectives | Key topics |
|---|---|---|
| [01. ETL vs. ELT](04-data-engineering-with-sql/01-etl-vs-elt/) | Explain the difference and when to use each pattern. | Extract/Transform/Load ordering, cloud warehouse implications |
| [02. SQL for Pipelines](04-data-engineering-with-sql/02-sql-for-pipelines/) | Write SQL that safely reruns without creating duplicates or corrupting data. | Incremental loads, watermarks, Change Data Capture (CDC), idempotency |
| [03. Orchestration Basics](04-data-engineering-with-sql/03-orchestration-basics/) | Understand how SQL fits into scheduled, dependency-aware pipelines. | DAGs, Airflow concepts, dbt models/tests/docs |
| [04. Data Quality & Testing](04-data-engineering-with-sql/04-data-quality-and-testing/) | Catch bad data before it reaches dashboards or ML models. | Constraints as tests, dbt-style tests, anomaly checks, data contracts |

## Part 5 — Performance & Optimization (~16 hours)

*Prerequisite: Parts 1–2 (can be studied in parallel with Part 6).*

| Module | Learning objectives | Key topics |
|---|---|---|
| [01. How Databases Execute Queries](05-performance-and-optimization/01-how-databases-execute-queries/) | Read an execution plan and understand what the optimizer is doing. | Parser/planner/optimizer/executor, `EXPLAIN` / `EXPLAIN ANALYZE`, statistics |
| [02. Indexing Strategies](05-performance-and-optimization/02-indexing-strategies/) | Choose the right index (or know not to add one). | B-tree indexes, clustered vs. non-clustered, covering indexes, index costs |
| [03. Partitioning & Clustering](05-performance-and-optimization/03-partitioning-and-clustering/) | Scale tables to billions of rows. | Range/list partitioning, partition pruning, cloud warehouse clustering keys |
| [04. Query Optimization Techniques](05-performance-and-optimization/04-query-optimization-techniques/) | Rewrite slow queries into fast ones. | Avoiding `SELECT *`, join order, sargable predicates, anti-patterns |
| [05. Distributed Query Engines](05-performance-and-optimization/05-distributed-query-engines/) | Explain how MPP (massively parallel processing) warehouses execute queries across many machines. | Shuffle, broadcast joins, data skew, shared-nothing vs. shared-disk |
| [06. Cloud Cost Optimization](05-performance-and-optimization/06-cloud-cost-optimization/) | Control what queries cost in usage-billed cloud warehouses. | Bytes-scanned billing, partition pruning for cost, warehouse sizing |

## Part 6 — Security (~12 hours)

*Prerequisite: Parts 1–2 (can be studied in parallel with Part 5).*

| Module | Learning objectives | Key topics |
|---|---|---|
| [01. SQL Injection & Prevention](06-security/01-sql-injection-and-prevention/) | Identify and prevent the #1 SQL security vulnerability. | Parameterized queries, input validation, least privilege as defense-in-depth |
| [02. Authentication & Authorization](06-security/02-authentication-and-authorization/) | Design access control that follows least privilege. | Users/roles, RBAC, `GRANT`/`REVOKE`, service accounts |
| [03. Encryption](06-security/03-encryption/) | Explain how data is protected at rest and in transit. | TLS, encryption at rest, column-level encryption, tokenization |
| [04. Data Masking & Row/Column Security](06-security/04-data-masking-and-row-column-security/) | Restrict *which rows/columns* a user can see, not just which tables. | Dynamic data masking, Row-Level Security (RLS), column-level grants |
| [05. Compliance & Governance](06-security/05-compliance-and-governance/) | Handle personal data responsibly and know the major regulatory frameworks. | GDPR/CCPA basics, PII classification, auditing, data lineage |
| [06. Secrets Management](06-security/06-secrets-management/) | Never hardcode a credential again. | Secret managers, environment variables, connection security in pipelines |

## Part 7 — Cloud Data Platforms (~14 hours)

*Prerequisite: Parts 1–6.*

| Module | Learning objectives | Key topics |
|---|---|---|
| [01. Cloud Warehousing Overview](07-cloud-data-platforms/01-cloud-warehousing-overview/) | Compare the major platforms on architecture, pricing model, and fit. | Separation of storage/compute, comparison table |
| [02. Google BigQuery](07-cloud-data-platforms/02-google-bigquery/) | Run and optimize queries in BigQuery. | Serverless architecture, partitioning/clustering, `bytes billed` |
| [03. Snowflake](07-cloud-data-platforms/03-snowflake/) | Run and optimize queries in Snowflake. | Virtual warehouses, micro-partitions, Time Travel, zero-copy cloning |
| [04. AWS Redshift](07-cloud-data-platforms/04-aws-redshift/) | Run and optimize queries in Redshift. | Distribution styles, sort keys, Redshift Spectrum |
| [05. Azure Synapse & Fabric](07-cloud-data-platforms/05-azure-synapse-and-fabric/) | Run and optimize queries in Microsoft's cloud data stack. | Dedicated vs. serverless SQL pools, Fabric lakehouse/warehouse |
| [06. Databricks SQL](07-cloud-data-platforms/06-databricks-sql/) | Query a lakehouse with SQL. | Delta Lake, Unity Catalog, SQL warehouses |
| [07. Choosing the Right Platform](07-cloud-data-platforms/07-choosing-the-right-platform/) | Make (and justify) a platform recommendation for a given scenario. | Decision framework, cost/skills/ecosystem tradeoffs |

## Part 8 — Real-World Projects (~10 hours)

*Prerequisite: Parts 1–7.*

| Module | Learning objectives | Key topics |
|---|---|---|
| [01. Capstone: Mini Data Warehouse](08-real-world-projects/01-capstone-mini-warehouse/) | Build a complete pipeline: raw OLTP data → dimensional model → SCD2 dimension → incremental fact load. | End-to-end project combining Parts 3–5 |
| [02. Case Studies](08-real-world-projects/02-case-studies/) | Analyze how real-world data platforms are architected. | Applied architecture walkthroughs |

## Part 9 — Career Prep (~6 hours)

| Module | Learning objectives | Key topics |
|---|---|---|
| [01. SQL Interview Questions](09-career-prep/01-interview-questions/) | Answer common conceptual and coding interview questions with confidence. | Curated Q&A with explanations |
| [02. Cheat Sheets](09-career-prep/02-cheat-sheets/) | Quickly look up syntax across topics and platforms. | One-page references |
| [03. Glossary of Terms](09-career-prep/03-glossary/) | Speak the vocabulary of the field precisely. | Every "New term" callout in the repo, indexed |
| [04. Further Resources](09-career-prep/04-further-resources/) | Know where to go after finishing this repo. | Books, certifications, communities, advanced topics |

---

**Ready?** Start with [`00-orientation`](00-orientation/).
