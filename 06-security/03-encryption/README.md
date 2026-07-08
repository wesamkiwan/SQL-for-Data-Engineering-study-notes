# 03. Encryption

*Part of [Part 6 — Security](../). Previous: [02. Authentication & Authorization](../02-authentication-and-authorization/).*

Access control ([Module 02](../02-authentication-and-authorization/))
determines *who* can query your data through the database's normal access
paths. Encryption protects data even if that access control is somehow
bypassed entirely — someone steals a physical hard drive, intercepts
network traffic, or gains unauthorized filesystem access. This module
covers the three levels at which encryption matters.

## Encryption at rest

> **New term — encryption at rest**: encrypting data as it's stored on
> disk, so that anyone who gains access to the raw storage (a stolen hard
> drive, an improperly discarded backup tape, unauthorized filesystem
> access) sees only unreadable ciphertext, not your actual data.

Every major cloud data platform (covered fully in
[Part 7](../../07-cloud-data-platforms/)) encrypts data at rest **by
default**, transparently, using platform-managed encryption keys — you
don't write SQL to enable this; it's a platform/infrastructure
configuration, not a query-level concern. What you, as a data engineer, are
responsible for:

- **Confirming it's actually enabled** — it usually is by default on major
  clouds, but verifying is a real, standard part of a security review
  (see [`power-pages:security-review`](../../09-career-prep/)-style checks,
  generalized to any platform).
- **Understanding key management options**: most platforms offer a choice
  between *platform-managed keys* (the cloud provider handles everything)
  and *customer-managed keys* (you control the encryption key itself,
  through a service like AWS KMS, Google Cloud KMS, or Azure Key Vault) —
  the latter gives you the ability to revoke access to *all* data instantly
  by revoking the key, and is often required for stricter compliance regimes.

## Encryption in transit

> **New term — encryption in transit**: encrypting data as it travels over
> a network — between your client and the database server, or between
> systems — typically using **TLS** (Transport Layer Security), so anyone
> intercepting network traffic sees only ciphertext.

```bash
# Connecting to PostgreSQL WITHOUT enforcing TLS — vulnerable to network interception
psql "host=mydb.example.com dbname=northstar user=analyst"

# Enforcing an encrypted connection
psql "host=mydb.example.com dbname=northstar user=analyst sslmode=require"
```

> ⚠️ **Common misconfiguration**: many database drivers default to
> *allowing* an unencrypted connection if the server doesn't insist on TLS,
> rather than *requiring* one. Always explicitly require TLS
> (`sslmode=require` or stricter in PostgreSQL) in production configuration
> — don't rely on the server-side default alone. This matters enormously
> for any connection crossing a public network, and is standard practice
> even within private cloud networks as a defense-in-depth measure.

## Column-level (field-level) encryption

Encryption at rest and in transit protect data in bulk — but sometimes a
*specific*, especially sensitive column (a national ID number, a payment
card number) needs protection even from people who have otherwise
legitimate database access — for example, so a database administrator with
broad access still can't casually read raw values in a `SELECT * FROM
customers` query.

```sql
-- PostgreSQL's pgcrypto extension provides column-level encryption functions
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE customer_sensitive_data (
    customer_id INTEGER PRIMARY KEY REFERENCES customers(customer_id),
    ssn_encrypted BYTEA NOT NULL
);

-- Encrypting a value on insert (the encryption key should come from a
-- secrets manager at query time in real code — never hardcoded like this
-- example; see Module 06)
INSERT INTO customer_sensitive_data (customer_id, ssn_encrypted)
VALUES (1, pgp_sym_encrypt('123-45-6789', 'encryption-key-from-secrets-manager'));

-- Decrypting requires the same key — anyone without it sees only ciphertext
SELECT customer_id, pgp_sym_decrypt(ssn_encrypted, 'encryption-key-from-secrets-manager') AS ssn
FROM customer_sensitive_data
WHERE customer_id = 1;
```

Without the correct key, `ssn_encrypted` is meaningless binary data — even
to someone with full `SELECT` access to the table. The tradeoff: encrypted
columns generally **can't be indexed or searched efficiently** in their
encrypted form (you can't do `WHERE ssn_encrypted LIKE '123%'` meaningfully
on ciphertext), and every read/write needs the key available, which shifts
the security question toward *how the key itself is protected*
([Module 06](../06-secrets-management/)) — encryption doesn't eliminate the
need for access control, it adds another layer on top of it.

## Tokenization: an alternative to encryption for some cases

> **New term — tokenization**: replacing a sensitive value with a
> non-sensitive placeholder ("token") that has no mathematical relationship
> to the original value, while the real value is stored separately in a
> highly restricted, dedicated system (a "token vault").

```sql
-- Instead of storing an encrypted card number, store a reference token —
-- the actual card number lives ONLY in a separate, specialized payment
-- processor's vault (this is exactly how most companies handle credit card
-- data in practice, specifically to avoid taking on PCI-DSS compliance
-- scope for storing real card numbers at all)
CREATE TABLE payments (
    payment_id     SERIAL PRIMARY KEY,
    order_id       INTEGER NOT NULL REFERENCES orders(order_id),
    card_token     VARCHAR(64) NOT NULL,  -- meaningless without the vault; e.g. 'tok_9f8a3b...'
    amount         NUMERIC(10,2) NOT NULL
);
```

Unlike encryption, tokenization can't be "decrypted" from the token alone —
the mapping only exists inside the vault system. This is *why* real payment
systems (Stripe, PayPal, and similar) heavily favor tokenization: even a
full breach of your own database exposes only meaningless tokens, not
actual card numbers, and dramatically reduces your own compliance burden
(directly relevant to [Module 05 — Compliance & Governance](../05-compliance-and-governance/)).

| | Encryption | Tokenization |
|---|---|---|
| Reversible with the right key? | Yes | No — requires the separate vault system |
| Can be done entirely within your own database? | Yes | Usually requires an external vault/service |
| Common use | Protecting data you must store and later retrieve | Removing highly regulated data (card numbers) from your systems entirely |

## Hashing: for data you never need to reverse

A related but distinct concept worth naming precisely: for data you only
ever need to **compare**, never retrieve in original form (most commonly,
passwords), use a one-way **hash** function, not encryption:

```sql
-- Never store a password in plain text OR with reversible encryption.
-- Use a purpose-built password hashing function (bcrypt, Argon2, scrypt) —
-- these are DELIBERATELY slow and use per-password random "salts" to
-- resist brute-force and pre-computed rainbow-table attacks, unlike a
-- plain, fast general-purpose hash function.
```

> **New term — hashing**: a one-way transformation — you can check whether
> a given input matches a stored hash, but you cannot recover the original
> input from the hash itself. This is fundamentally different from
> encryption (which is reversible, given the right key) — using encryption
> for passwords is a real mistake precisely because it implies a recovery
> path an attacker could exploit if they obtain the key.

This topic mostly lives in application code rather than SQL directly, but
recognizing the distinction — hashing for one-way verification, encryption
for reversible protection, tokenization for removing sensitive data from
your systems altogether — is a genuinely important piece of security
vocabulary for a data engineer to have precise, correct, in a compliance
review or an interview.

## ✅ Try it yourself

```sql
SET search_path TO northstar;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Try encrypting and decrypting a value yourself
SELECT pgp_sym_encrypt('sensitive-value', 'my-test-key') AS encrypted;
SELECT pgp_sym_decrypt(pgp_sym_encrypt('sensitive-value', 'my-test-key'), 'my-test-key') AS decrypted;

-- Try decrypting with the WRONG key — observe it fails loudly, as it should
SELECT pgp_sym_decrypt(pgp_sym_encrypt('sensitive-value', 'my-test-key'), 'wrong-key');
```

### Exercises

1. Explain why a database administrator having full `SELECT` access to a
   table is not, by itself, sufficient to read a `pgcrypto`-encrypted
   column's real value — what else would they additionally need?
2. A company wants to let customer support agents look up "the last 4
   digits of a customer's card" without agents ever being able to see the
   full card number. Would tokenization or column-level encryption more
   naturally support this specific requirement, and why?
3. Explain, precisely, why using AES encryption (reversible) to store user
   passwords is a worse practice than using bcrypt (a one-way hash),
   even if the encryption key is very well protected.

<details>
<summary>💡 Solutions</summary>

```text
1. They would additionally need the encryption KEY used to encrypt that
   column. Access to the TABLE and access to the KEY are deliberately
   separate concerns — an administrator managing the database doesn't
   automatically also have (or need) the key, which is typically stored
   and controlled through a separate secrets manager / key management
   service (Module 06), often governed by a different team or approval
   process entirely.

2. Tokenization more naturally fits, IF the token vault (typically a
   payment processor) can be asked to return a partial/masked
   representation (like "last 4 digits") without exposing the full number
   at all — many payment providers explicitly support this exact use case.
   Column-level encryption technically COULD support it too (decrypt, then
   truncate to 4 digits before showing the agent), but that still requires
   giving that decryption capability to the support tooling, which is a
   larger exposure surface than a vault that's specifically designed to
   safely reveal only a masked subset.

3. Even a well-protected encryption key represents a single point of
   failure: if that key is ever compromised (leaked, stolen, or obtained
   through a future vulnerability), EVERY password ever encrypted with it
   becomes immediately readable in plain text, all at once. A one-way hash
   has no equivalent "master key" that can undo it — even if an attacker
   steals the entire hashed password database, they still can't directly
   recover any password; they'd have to attempt a slow, resource-intensive
   brute-force/guessing attack against each hash individually, which
   purpose-built password hashing functions are specifically designed to
   make impractically slow.
```
</details>

## 🧠 Quick check

<details>
<summary>Q: What's the key structural difference between encryption and hashing?</summary>

Encryption is reversible — with the correct key, the original data can be
recovered from the encrypted form. Hashing is one-way — there is no key
that reverses a hash back into its original input; you can only check
whether a given input produces a matching hash.
</details>

<details>
<summary>Q: Why might a company choose tokenization over encryption specifically for credit card data?</summary>

Tokenization removes the actual sensitive value from your own systems
entirely (it lives only in a specialized external vault), which
dramatically reduces your own compliance burden and breach exposure —
even a full breach of your database only exposes meaningless tokens, not
real card numbers, and never requires managing your own encryption keys
for that data at all.
</details>

---
⬅ [Back to Part 6](../) | ➡ Next: [04. Data Masking & Row/Column Security](../04-data-masking-and-row-column-security/)
