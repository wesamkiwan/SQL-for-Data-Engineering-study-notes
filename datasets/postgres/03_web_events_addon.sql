-- =============================================================================
-- NorthStar Retail — Web Events Add-on
-- =============================================================================
-- Adds ONE extra table, web_events, used only in
-- 02-intermediate-advanced-sql/06-json-and-semistructured-data.
-- Run this AFTER 00_schema.sql and 01_seed_data.sql.
--
-- This models a very common real-world source: a stream of semi-structured
-- clickstream/event data, where different event types carry different
-- shaped payloads — exactly why JSON, not rigid columns, is the natural fit.
-- =============================================================================

SET search_path TO northstar;

SELECT setseed(0.99);

CREATE TABLE web_events (
    event_id    SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(customer_id),
    event_type  VARCHAR(30) NOT NULL CHECK (event_type IN ('page_view', 'add_to_cart', 'search')),
    event_time  TIMESTAMP NOT NULL,
    payload     JSONB NOT NULL
);

CREATE INDEX idx_web_events_customer_id ON web_events(customer_id);
-- A GIN index makes containment/key-existence queries on JSONB fast at scale
-- (see 05-performance-and-optimization/02-indexing-strategies for why).
CREATE INDEX idx_web_events_payload ON web_events USING GIN (payload);

INSERT INTO web_events (customer_id, event_type, event_time, payload)
SELECT
    c.customer_id,
    et.event_type,
    (TIMESTAMP '2024-01-01' + (random() * 730) * INTERVAL '1 day'),
    CASE et.event_type
        WHEN 'page_view' THEN jsonb_build_object(
            'url', '/products/' || (1 + floor(random() * 40))::int,
            'referrer', (ARRAY['google', 'direct', 'email', 'social'])[1 + floor(random() * 4)::int],
            'device', (ARRAY['desktop', 'mobile', 'tablet'])[1 + floor(random() * 3)::int]
        )
        WHEN 'add_to_cart' THEN jsonb_build_object(
            'product_id', (1 + floor(random() * 40))::int,
            'quantity', (1 + floor(random() * 3))::int
        )
        WHEN 'search' THEN jsonb_build_object(
            'query', (ARRAY['blender','backpack','headphones','watch','tent','journal','lamp','sneakers'])[1 + floor(random() * 8)::int],
            'results_count', floor(random() * 50)::int
        )
    END AS payload
FROM generate_series(1, 300) AS n
JOIN LATERAL (
    SELECT customer_id FROM customers ORDER BY customer_id OFFSET floor(random() * 200) LIMIT 1
) c ON TRUE
JOIN LATERAL (
    SELECT (ARRAY['page_view', 'add_to_cart', 'search'])[1 + floor(random() * 3)::int] AS event_type
) et ON TRUE;
