# 01. SQL Injection & Prevention

*Part of [Part 6 — Security](../). Previous: [Part 5 — Performance & Optimization](../../05-performance-and-optimization/).*

SQL injection has been on the OWASP Top 10 list of critical web application
security risks for over two decades, and it remains one of the most common
causes of real-world data breaches. Every data professional — not just
security specialists — needs to understand it deeply enough to never
introduce it.

> ⚠️ **Scope note**: this repo teaches SQL injection for **defensive**
> purposes — recognizing, preventing, and fixing it in your own systems.
> Everything here is standard, widely-taught security education (the same
> concepts covered in OWASP's own documentation), aimed at building secure
> systems, not attacking ones you don't own or have authorization to test.

## What SQL injection actually is

> **New term — SQL injection**: a vulnerability where an attacker supplies
> input that gets inserted directly into a SQL query's *text*, letting them
> change the query's actual logic — rather than being treated as pure data.

It happens when application code builds SQL by directly concatenating
user-supplied input into a query string, instead of treating that input as
data that's kept separate from the query's logic.

## A concrete example

Imagine an application's login check, built by (unsafely) concatenating a
user-supplied email directly into a query string (shown here in
pseudocode, since the vulnerability is about *how the SQL string gets
built* in application code, not about SQL syntax itself):

```python
# ❌ VULNERABLE — do not do this
email = request.form["email"]   # attacker-controlled input
query = "SELECT * FROM customers WHERE email = '" + email + "'"
db.execute(query)
```

If a normal user enters `emma.smith1@example.com`, the resulting query is exactly what was intended:

```sql
SELECT * FROM customers WHERE email = 'emma.smith1@example.com'
```

But an attacker doesn't have to enter a normal email. What if they enter
this as the "email" value instead?

```
' OR '1'='1
```

The concatenated query becomes:

```sql
SELECT * FROM customers WHERE email = '' OR '1'='1'
```

`'1'='1'` is always true, so `WHERE email = '' OR '1'='1'` is true for
**every row** — the attacker just bypassed the entire filter and retrieved
every customer's data, without knowing anyone's actual email. This is the
essence of SQL injection: **user input was allowed to change the query's
logic, not just supply a value.**

### It gets much worse: multi-statement injection

Depending on how the application executes the query, an attacker might be
able to submit input like:

```
'; DROP TABLE customers; --
```

Producing:

```sql
SELECT * FROM customers WHERE email = ''; DROP TABLE customers; --'
```

If the database driver allows multiple statements in one call, this
**deletes the entire `customers` table**. The `--` comments out the
trailing stray quote so the injected SQL remains syntactically valid. This
is exactly why SQL injection is treated as a critical-severity
vulnerability, not a minor bug — it can lead to complete data theft, data
destruction, or full system compromise.

## The fix: parameterized queries (prepared statements)

> **New term — parameterized query** (also called a **prepared statement**):
> a query where the SQL structure is sent to the database **separately**
> from any user-supplied values, using placeholders. The database compiles
> the query structure first, then substitutes the values in as pure data —
> never as executable SQL — no matter what they contain.

```python
# ✅ SAFE — the placeholder (%s here; syntax varies by language/driver)
# keeps user input strictly separated from the SQL structure
email = request.form["email"]
query = "SELECT * FROM customers WHERE email = %s"
db.execute(query, (email,))
```

Now, even if `email` contains `' OR '1'='1`, the database treats the
**entire string**, quotes and all, as a single literal value to compare
against the `email` column — it can never be interpreted as SQL syntax,
because the query's structure was already fixed before the value was ever
substituted in. This isn't just "better escaping" — it's a fundamentally
different, structurally safe mechanism.

```sql
-- What actually happens conceptually: the malicious string is compared
-- literally, as data, and matches nothing (as expected)
SELECT * FROM customers WHERE email = '''' OR ''1''=''1';
-- (illustrative — the exact internal representation varies by driver,
-- but the key guarantee is: it is NEVER interpreted as SQL logic)
```

**Every mainstream programming language and database driver supports
parameterized queries** — Python's `psycopg2`/`sqlalchemy`, Java's
`PreparedStatement`, Node's `pg` library, and more. There is essentially
never a good reason to build a SQL query by string-concatenating untrusted
input, in any language, for any reason.

## Where does raw SQL (not application code) fit into this?

You might wonder why this module belongs in a *SQL* curriculum at all, if
the vulnerability lives in application code. Two direct reasons:

1. **You'll write dynamic SQL yourself.** Stored procedures/functions
   ([Part 2, Module 05](../../02-intermediate-advanced-sql/05-stored-procedures-functions-triggers/))
   sometimes need to build SQL dynamically at runtime — and the exact same
   injection risk applies *inside the database* if you do this carelessly:

```sql
-- ❌ VULNERABLE, even inside the database — string concatenation building SQL
CREATE FUNCTION unsafe_lookup(p_email TEXT)
RETURNS SETOF customers
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY EXECUTE 'SELECT * FROM customers WHERE email = ''' || p_email || '''';
END;
$$;

-- ✅ SAFE — use format() with %L (literal) or, better, EXECUTE ... USING
CREATE FUNCTION safe_lookup(p_email TEXT)
RETURNS SETOF customers
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY EXECUTE 'SELECT * FROM customers WHERE email = $1' USING p_email;
END;
$$;
```

2. **As a data engineer, you're often the one reviewing or writing the SQL
   an application, BI tool, or pipeline generates dynamically** — recognizing
   unsafe string-built SQL in a code review is a real, expected skill.

## Defense in depth: layers beyond parameterized queries

Parameterized queries are the primary, essential fix — but good security
never relies on just one layer:

> **New term — defense in depth**: applying multiple, independent layers of
> security controls, so that if one fails, others still limit the damage.

- **Least privilege** ([Module 02](../02-authentication-and-authorization/)):
  even if an injection somehow succeeded, an application's database account
  should only have the minimum permissions it actually needs — an
  application that only ever reads customer data should connect with a
  read-only account that structurally *cannot* run `DROP TABLE`, regardless
  of what SQL an attacker manages to inject.
- **Input validation**: reject or sanitize input that clearly doesn't match
  the expected format (an email field should look like an email) — a
  helpful extra layer, though never a substitute for parameterized queries,
  since validation logic can always have gaps or be bypassed in ways
  parameterization structurally prevents.
- **Web application firewalls (WAFs)**: can detect and block many common
  injection patterns at the network level, as an additional outer layer.
- **ORMs (Object-Relational Mappers)**: tools like SQLAlchemy or Django's
  ORM generate parameterized SQL for you automatically in normal use —
  reducing the chance of a developer accidentally writing unsafe raw SQL —
  though ORMs can still be misused unsafely if raw/"escape hatch" SQL
  methods are used carelessly.

## ✅ Try it yourself

There's no destructive SQL to run here — this module is about recognizing
the pattern. Instead, review this pseudocode and identify the vulnerability:

```python
category = request.args.get("category")
query = f"SELECT * FROM products WHERE category = '{category}'"
db.execute(query)
```

<details>
<summary>💡 What's wrong, and the fix</summary>

This is vulnerable in exactly the same way as the login example — `category`
is concatenated directly into the query string via an f-string, so any SQL
metacharacters in it change the query's logic. An attacker could supply
`Electronics' OR '1'='1` to bypass the intended filter entirely, or worse.

```python
query = "SELECT * FROM products WHERE category = %s"
db.execute(query, (category,))
```
</details>

### Exercises

1. Explain why simply "escaping" special characters (like turning `'` into
   `\'`) is a weaker defense than a true parameterized query, even though
   it can prevent some basic injection attempts.
2. A stored procedure needs to let a caller sort results by a
   caller-supplied column name (something that genuinely can't be
   parameterized as a plain value, since column names aren't data).
   Research and describe, in words, one safe approach to this (hint: think
   about validating the input against a fixed allow-list of known-safe
   column names before using it).
3. Why does "least privilege" matter as a *second* layer of defense, even
   if you're confident your parameterized queries are correctly implemented everywhere?

<details>
<summary>💡 Solutions</summary>

```text
1. Manual escaping requires the developer to correctly anticipate and
   handle every special character and edge case for a given database's
   specific syntax rules — a small mistake (a missed character, a
   database-specific quoting quirk, encoding issues) can reopen the exact
   same vulnerability. Parameterized queries don't rely on correctly
   guessing what needs escaping at all — the value is NEVER interpreted as
   SQL syntax in the first place, structurally, regardless of its content.

2. Since a column name can't be safely passed as a bound parameter (it's
   part of the query's STRUCTURE, not a value being compared), the safe
   approach is to validate the caller's input against a fixed, hard-coded
   allow-list of legitimate column names in application/procedure code
   (e.g., "only allow 'order_date', 'order_status', or 'customer_id' —
   reject anything else"), and only then build that specific, pre-validated
   identifier into the SQL — never trusting arbitrary input to control
   query structure directly.

3. Because it's a genuine safety net against mistakes, not a substitute for
   correct code. Any real system has many contributors, evolves over time,
   and can have an overlooked raw SQL query somewhere despite best efforts.
   If an injection vulnerability DOES slip through, a least-privilege
   database account limits the actual damage possible (e.g., an attacker
   might read data they shouldn't, but a read-only account structurally
   cannot DROP a table) — defense in depth means no single mistake is
   catastrophic on its own.
```
</details>

## 🧠 Quick check

<details>
<summary>Q: What is the fundamental mechanism that makes parameterized queries safe against SQL injection?</summary>

The SQL query's structure is sent to (and compiled by) the database
separately from any user-supplied values. Values are substituted in
afterward purely as data, never re-parsed as SQL syntax — so no matter what
characters or content a value contains, it can never change the query's logic.
</details>

<details>
<summary>Q: Why is "least privilege" considered a form of SQL injection defense, even though it doesn't prevent injection itself?</summary>

It doesn't stop an injection attempt from happening, but it limits the
*damage* an attacker can do if one somehow succeeds — a database account
with only the minimum necessary permissions structurally can't perform
actions (like dropping tables, or reading unrelated sensitive tables) that
exceed what it's been granted, regardless of what SQL gets executed under that account.
</details>

---
⬅ [Back to Part 6](../) | ➡ Next: [02. Authentication & Authorization](../02-authentication-and-authorization/)
