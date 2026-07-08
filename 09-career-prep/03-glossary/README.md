# 03. Glossary of Terms

*Part of [Part 9 — Career Prep](../). Previous: [02. Cheat Sheets](../02-cheat-sheets/).*

Every term introduced with a "**New term**" callout across this entire
repo, alphabetized, with a link back to where it's explained in full. Use
`Ctrl+F` / `Cmd+F` to jump straight to what you need.

- **ACID** — the four guarantees (Atomicity, Consistency, Isolation,
  Durability) a database provides for transactions. [Part 2, Module 03](../../02-intermediate-advanced-sql/03-data-modification-and-transactions/)
- **Additive measure** — a fact table measure that can be summed across any
  dimension safely (e.g., revenue). [Part 3, Module 02](../../03-database-design-and-modeling/02-dimensional-modeling/)
- **Aggregate function** — a function that summarizes many rows into one
  value (`COUNT`, `SUM`, `AVG`, `MIN`, `MAX`). [Part 1, Module 04](../../01-sql-foundations/04-aggregations/)
- **Apache Airflow** — an open-source platform for defining, scheduling, and
  monitoring workflows (DAGs) as code. [Part 4, Module 03](../../04-data-engineering-with-sql/03-orchestration-basics/)
- **Audit log** — a recorded history of who accessed or changed data, and
  when. [Part 6, Module 05](../../06-security/05-compliance-and-governance/)
- **Authentication** — verifying who someone is. [Part 6, Module 02](../../06-security/02-authentication-and-authorization/)
- **Authorization** — determining what an authenticated identity is allowed
  to do. [Part 6, Module 02](../../06-security/02-authentication-and-authorization/)
- **B-tree** — a balanced, sorted tree data structure underlying most
  database indexes. [Part 5, Module 02](../../05-performance-and-optimization/02-indexing-strategies/)
- **Broadcast join** — copying a small table in full to every compute node
  to avoid shuffling both sides of a join. [Part 5, Module 05](../../05-performance-and-optimization/05-distributed-query-engines/)
- **Candidate key** — any column(s) that could uniquely identify a row.
  [Part 3, Module 01](../../03-database-design-and-modeling/01-normalization-and-keys/)
- **Casting** — explicitly converting a value from one data type to
  another. [Part 1, Module 08](../../01-sql-foundations/08-string-date-numeric-functions/)
- **Change Data Capture (CDC)** — detecting exactly which source rows
  changed, typically via a database's transaction log. [Part 4, Module 02](../../04-data-engineering-with-sql/02-sql-for-pipelines/)
- **Clause** — one labeled part of a SQL statement (`SELECT`, `FROM`,
  `WHERE`, etc.). [Part 1, Module 02](../../01-sql-foundations/02-basic-queries/)
- **Clustering** (table) — physically reordering a table's rows on disk to
  match a column's order, speeding up range queries. [Part 5, Module 03](../../05-performance-and-optimization/03-partitioning-and-clustering/)
- **Column** — one property shared by every row in a table. [Part 1, Module 01](../../01-sql-foundations/01-databases-101/)
- **Composite key** — a primary key made of multiple columns together.
  [Part 3, Module 01](../../03-database-design-and-modeling/01-normalization-and-keys/)
- **Constraint** — a rule the database enforces automatically (`NOT NULL`,
  `UNIQUE`, `CHECK`, foreign keys). [Part 1, Module 01](../../01-sql-foundations/01-databases-101/)
- **Correlated subquery** — a subquery that references a column from the
  outer query. [Part 1, Module 06](../../01-sql-foundations/06-subqueries-and-ctes/)
- **Covering index** — an index containing every column a query needs, so
  no separate table lookup is required. [Part 5, Module 02](../../05-performance-and-optimization/02-indexing-strategies/)
- **CTE (Common Table Expression)** — a named, temporary result set defined
  with `WITH`. [Part 1, Module 06](../../01-sql-foundations/06-subqueries-and-ctes/)
- **DAG (Directed Acyclic Graph)** — tasks and dependencies represented as
  nodes and arrows, with no cycles. [Part 4, Module 03](../../04-data-engineering-with-sql/03-orchestration-basics/)
- **Data contract** — an explicit agreement on a dataset's schema, types,
  and update guarantees between producing and consuming teams. [Part 4, Module 04](../../04-data-engineering-with-sql/04-data-quality-and-testing/)
- **Data engineering** — building and maintaining systems that collect,
  move, store, and prepare data for others to use. [Part 0](../../00-orientation/)
- **Data lake** — a storage system holding data of any format cheaply, with
  schema-on-read. [Part 3, Module 03](../../03-database-design-and-modeling/03-warehouse-lake-lakehouse/)
- **Data lineage** — a complete record of where data came from and every
  transformation it passed through. [Part 6, Module 05](../../06-security/05-compliance-and-governance/)
- **Data retention policy** — a defined rule for how long data categories
  are kept before deletion/archival. [Part 6, Module 05](../../06-security/05-compliance-and-governance/)
- **Data swamp** — a disorganized, low-quality, untrusted data lake.
  [Part 3, Module 03](../../03-database-design-and-modeling/03-warehouse-lake-lakehouse/)
- **Data Vault** — a modeling methodology (hubs, links, satellites) for
  auditable, flexible multi-source integration. [Part 3, Module 04](../../03-database-design-and-modeling/04-modern-modeling-patterns/)
- **Data warehouse** — a system for storing structured, modeled data for
  fast SQL analytics, schema-on-write. [Part 3, Module 03](../../03-database-design-and-modeling/03-warehouse-lake-lakehouse/)
- **Database** — an organized, electronically stored collection of data.
  [Part 1, Module 01](../../01-sql-foundations/01-databases-101/)
- **Dedicated SQL pool** (Synapse) — provisioned, pre-allocated Synapse
  compute and storage. [Part 7, Module 05](../../07-cloud-data-platforms/05-azure-synapse-and-fabric/)
- **Defense in depth** — applying multiple, independent security layers so
  no single failure is catastrophic. [Part 6, Module 01](../../06-security/01-sql-injection-and-prevention/)
- **Dimension table** — a table storing descriptive context used to filter
  or group facts. [Part 3, Module 02](../../03-database-design-and-modeling/02-dimensional-modeling/)
- **Dynamic data masking** — automatically masking sensitive column values
  based on who's querying. [Part 6, Module 04](../../06-security/04-data-masking-and-row-column-security/)
- **Encryption at rest** — encrypting stored data so raw storage access
  reveals only ciphertext. [Part 6, Module 03](../../06-security/03-encryption/)
- **Encryption in transit** — encrypting data as it travels over a network
  (typically via TLS). [Part 6, Module 03](../../06-security/03-encryption/)
- **Extract / Transform / Load** — the three stages of moving and preparing
  data for a destination system. [Part 4, Module 01](../../04-data-engineering-with-sql/01-etl-vs-elt/)
- **Fact table** — a table storing measurements or events, usually one row
  per occurrence. [Part 3, Module 02](../../03-database-design-and-modeling/02-dimensional-modeling/)
- **Foreign key** — a column referring to another table's primary key.
  [Part 1, Module 01](../../01-sql-foundations/01-databases-101/)
- **Full refresh** — reprocessing all data every pipeline run, from
  scratch. [Part 4, Module 02](../../04-data-engineering-with-sql/02-sql-for-pipelines/)
- **Grain** — what a single row in a table represents. [`datasets/README.md`](../../datasets/) and [Part 1, Module 05](../../01-sql-foundations/05-joins/)
- **Hashing** — a one-way transformation used for verification, not
  recovery (e.g., passwords). [Part 6, Module 03](../../06-security/03-encryption/)
- **Idempotent** — an operation producing the same result no matter how
  many times it runs. [Part 4, Module 02](../../04-data-engineering-with-sql/02-sql-for-pipelines/)
- **Incremental load** — processing only new/changed data since the last
  run. [Part 4, Module 02](../../04-data-engineering-with-sql/02-sql-for-pipelines/)
- **Index** — a data structure mapping column values to row locations, for
  fast lookups. [Part 1, Module 01](../../01-sql-foundations/01-databases-101/), [Part 5, Module 02](../../05-performance-and-optimization/02-indexing-strategies/)
- **Index scan** — using an index to jump directly to matching rows.
  [Part 5, Module 01](../../05-performance-and-optimization/01-how-databases-execute-queries/)
- **Isolation level** — how strictly a database prevents transactions from
  seeing each other's in-progress changes. [Part 2, Module 03](../../02-intermediate-advanced-sql/03-data-modification-and-transactions/)
- **Join** — combining rows from two or more tables based on a related
  column. [Part 1, Module 05](../../01-sql-foundations/05-joins/)
- **JSON** — a lightweight, text-based format for structured data as
  key-value pairs. [Part 2, Module 06](../../02-intermediate-advanced-sql/06-json-and-semistructured-data/)
- **Lakehouse** — an architecture adding warehouse-like ACID/schema
  guarantees on top of data lake storage. [Part 3, Module 03](../../03-database-design-and-modeling/03-warehouse-lake-lakehouse/)
- **Least privilege** — granting only the minimum permissions genuinely
  necessary. [Part 6, Module 02](../../06-security/02-authentication-and-authorization/)
- **Materialized view** — a view whose result is computed once and stored,
  refreshed on demand. [Part 2, Module 04](../../02-intermediate-advanced-sql/04-views-and-materialized-views/)
- **Medallion architecture** — organizing pipelines into bronze (raw),
  silver (cleaned), and gold (modeled) layers. [Part 3, Module 04](../../03-database-design-and-modeling/04-modern-modeling-patterns/)
- **MERGE** — an ANSI-standard statement combining insert, update, and
  delete in one operation. [Part 2, Module 03](../../02-intermediate-advanced-sql/03-data-modification-and-transactions/), [Part 4, Module 02](../../04-data-engineering-with-sql/02-sql-for-pipelines/)
- **Micro-partition** (Snowflake) — small, automatically-managed storage
  units with pruning metadata. [Part 7, Module 03](../../07-cloud-data-platforms/03-snowflake/)
- **MPP (Massively Parallel Processing)** — many nodes processing a query
  simultaneously. [Part 5, Module 05](../../05-performance-and-optimization/05-distributed-query-engines/)
- **N+1 query problem** — running one query for a list, then N more
  queries for each item's related data, instead of one join. [Part 5, Module 04](../../05-performance-and-optimization/04-query-optimization-techniques/)
- **Non-additive measure** — a measure that can never be meaningfully
  summed (e.g., a ratio/percentage). [Part 3, Module 02](../../03-database-design-and-modeling/02-dimensional-modeling/)
- **Normal form** — a formal rule about how well-structured a table is
  (1NF, 2NF, 3NF). [Part 3, Module 01](../../03-database-design-and-modeling/01-normalization-and-keys/)
- **OLTP vs. OLAP** — transactional (many small fast writes) vs. analytical
  (large complex reads) system design. [Part 3, Module 01](../../03-database-design-and-modeling/01-normalization-and-keys/)
- **On-demand pricing** — cloud pricing based on data processed per query.
  [Part 5, Module 06](../../05-performance-and-optimization/06-cloud-cost-optimization/)
- **One Big Table (OBT)** — a single, wide, fully denormalized table
  pre-joining facts and dimensions. [Part 3, Module 04](../../03-database-design-and-modeling/04-modern-modeling-patterns/)
- **Orchestration** — automatically running interdependent tasks in order,
  on a schedule, with retries and monitoring. [Part 4, Module 03](../../04-data-engineering-with-sql/03-orchestration-basics/)
- **Parameterized query / prepared statement** — a query sent with its
  structure separate from user-supplied values, preventing injection.
  [Part 6, Module 01](../../06-security/01-sql-injection-and-prevention/)
- **Parquet** — a columnar file format designed for analytics. [Part 3, Module 03](../../03-database-design-and-modeling/03-warehouse-lake-lakehouse/)
- **Partition pruning** — skipping partitions that can't contain matching
  rows. [Part 5, Module 03](../../05-performance-and-optimization/03-partitioning-and-clustering/)
- **Partitioning** — dividing a large table into smaller physical segments.
  [Part 5, Module 03](../../05-performance-and-optimization/03-partitioning-and-clustering/)
- **PII (Personally Identifiable Information)** — data that could identify
  a specific individual. [Part 6, Module 05](../../06-security/05-compliance-and-governance/)
- **Pivot** — reshaping rows into columns. [Part 2, Module 02](../../02-intermediate-advanced-sql/02-advanced-aggregation/)
- **Primary key** — the column(s) chosen to uniquely identify a table's
  rows. [Part 1, Module 01](../../01-sql-foundations/01-databases-101/)
- **Provisioned pricing** — cloud pricing based on compute resources
  running over time. [Part 5, Module 06](../../05-performance-and-optimization/06-cloud-cost-optimization/)
- **Query optimizer** — the database component choosing how to execute a
  declarative SQL query. [Part 5, Module 01](../../05-performance-and-optimization/01-how-databases-execute-queries/)
- **RBAC (Role-Based Access Control)** — organizing permissions around
  roles representing job functions. [Part 6, Module 02](../../06-security/02-authentication-and-authorization/)
- **RDBMS** — a Relational Database Management System, storing data as
  linked tables. [Part 1, Module 01](../../01-sql-foundations/01-databases-101/)
- **Recursive CTE** — a CTE that references itself to walk a hierarchy.
  [Part 1, Module 06](../../01-sql-foundations/06-subqueries-and-ctes/)
- **Redshift Spectrum** — querying data directly in S3 as if it were a
  Redshift table. [Part 7, Module 04](../../07-cloud-data-platforms/04-aws-redshift/)
- **Role** — PostgreSQL's unified concept for a user and/or a permission
  group. [Part 6, Module 02](../../06-security/02-authentication-and-authorization/)
- **Row** — one complete entry in a table. [Part 1, Module 01](../../01-sql-foundations/01-databases-101/)
- **Row-Level Security (RLS)** — automatically filtering which rows a query
  can see based on who's running it. [Part 6, Module 04](../../06-security/04-data-masking-and-row-column-security/)
- **Sargable** — a filter condition written so the database can use an
  index directly. [Part 5, Module 04](../../05-performance-and-optimization/04-query-optimization-techniques/)
- **Scalar function** — a function transforming one input row's value into
  one output value. [Part 1, Module 08](../../01-sql-foundations/08-string-date-numeric-functions/)
- **Schema** — a table's column structure, or a named container of tables
  (context-dependent). [Part 1, Module 01](../../01-sql-foundations/01-databases-101/)
- **SCD (Slowly Changing Dimension)** — a strategy for handling dimension
  data that changes over time. [Part 3, Module 02](../../03-database-design-and-modeling/02-dimensional-modeling/)
- **Secret** — any value granting access or protecting data that must stay
  confidential. [Part 6, Module 06](../../06-security/06-secrets-management/)
- **Secrets manager** — a dedicated service for storing, rotating, and
  auditing access to secrets. [Part 6, Module 06](../../06-security/06-secrets-management/)
- **Selectivity** — how well a column narrows down a search (distinct
  values relative to table size). [Part 5, Module 02](../../05-performance-and-optimization/02-indexing-strategies/)
- **Semi-structured data** — data with some structure but no fixed, uniform
  schema across records. [Part 2, Module 06](../../02-intermediate-advanced-sql/06-json-and-semistructured-data/)
- **Semi-additive measure** — a measure summable across some dimensions but
  not others (e.g., account balance). [Part 3, Module 02](../../03-database-design-and-modeling/02-dimensional-modeling/)
- **Sequential scan (Seq Scan)** — reading every row in a table to check a
  filter. [Part 5, Module 01](../../05-performance-and-optimization/01-how-databases-execute-queries/)
- **Serverless SQL pool** (Synapse) — an on-demand engine querying data
  lake files directly. [Part 7, Module 05](../../07-cloud-data-platforms/05-azure-synapse-and-fabric/)
- **Service account** — a non-human identity used by an application or
  pipeline to authenticate. [Part 6, Module 02](../../06-security/02-authentication-and-authorization/)
- **Shared-disk architecture** — all compute nodes access the same
  underlying storage layer. [Part 5, Module 05](../../05-performance-and-optimization/05-distributed-query-engines/)
- **Shared-nothing architecture** — each node has its own dedicated
  CPU/memory/storage. [Part 5, Module 05](../../05-performance-and-optimization/05-distributed-query-engines/)
- **Shuffle** — redistributing rows across nodes mid-query so matching keys
  land together. [Part 5, Module 05](../../05-performance-and-optimization/05-distributed-query-engines/)
- **Sort key** (Redshift) — the column(s) a table's data is physically
  ordered by within each node. [Part 7, Module 04](../../07-cloud-data-platforms/04-aws-redshift/)
- **SQL** — a declarative language for asking questions of structured data.
  [Part 0](../../00-orientation/)
- **SQL injection** — a vulnerability letting attacker input change a
  query's logic. [Part 6, Module 01](../../06-security/01-sql-injection-and-prevention/)
- **Star schema** — a fact table connected directly to denormalized
  dimension tables. [Part 3, Module 02](../../03-database-design-and-modeling/02-dimensional-modeling/)
- **Snowflake schema** — a star schema with dimensions further normalized
  into sub-dimensions. [Part 3, Module 02](../../03-database-design-and-modeling/02-dimensional-modeling/)
- **Subquery** — a `SELECT` statement nested inside another SQL statement.
  [Part 1, Module 06](../../01-sql-foundations/06-subqueries-and-ctes/)
- **Surrogate key** — an artificial, meaningless identifier created purely
  to identify rows. [Part 3, Module 01](../../03-database-design-and-modeling/01-normalization-and-keys/)
- **Time Travel** (Snowflake) — querying a table's data as it existed at a
  past point in time. [Part 7, Module 03](../../07-cloud-data-platforms/03-snowflake/)
- **Tokenization** — replacing a sensitive value with a non-sensitive
  placeholder, mapped in a separate vault. [Part 6, Module 03](../../06-security/03-encryption/)
- **Transaction** — a group of statements executed as a single,
  all-or-nothing unit. [Part 2, Module 03](../../02-intermediate-advanced-sql/03-data-modification-and-transactions/)
- **Trigger** — a function the database calls automatically on
  `INSERT`/`UPDATE`/`DELETE` events. [Part 2, Module 05](../../02-intermediate-advanced-sql/05-stored-procedures-functions-triggers/)
- **Unity Catalog** (Databricks) — a unified governance layer across an
  entire lakehouse workspace. [Part 7, Module 06](../../07-cloud-data-platforms/06-databricks-sql/)
- **Upsert** — insert a row, or update it if a conflicting key already
  exists. [Part 2, Module 03](../../02-intermediate-advanced-sql/03-data-modification-and-transactions/)
- **User-defined function (UDF)** — a named, reusable piece of logic stored
  in the database. [Part 2, Module 05](../../02-intermediate-advanced-sql/05-stored-procedures-functions-triggers/)
- **View** — a stored `SELECT` query, queryable like a table, holding no
  data of its own. [Part 2, Module 04](../../02-intermediate-advanced-sql/04-views-and-materialized-views/)
- **Virtual warehouse** (Snowflake) — a named, resizable cluster of compute
  resources. [Part 7, Module 03](../../07-cloud-data-platforms/03-snowflake/)
- **Watermark** — a stored value marking how far an incremental pipeline
  has already processed. [Part 4, Module 02](../../04-data-engineering-with-sql/02-sql-for-pipelines/)
- **Window function** — a function computing across related rows without
  collapsing the result. [Part 2, Module 01](../../02-intermediate-advanced-sql/01-window-functions/)
- **Zero-copy cloning** (Snowflake) — instantly creating a full table/database
  copy without duplicating underlying data. [Part 7, Module 03](../../07-cloud-data-platforms/03-snowflake/)

---
⬅ [Back to Part 9](../) | ➡ Next: [04. Further Resources & What's Next](../04-further-resources/)
