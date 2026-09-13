-- Sample table: 5 columns, 5 rows
-- Run: psql -U ericho -d postgres -f sample_table.sql

DROP TABLE IF EXISTS sample_products;

CREATE TABLE sample_products (
    id          INTEGER PRIMARY KEY,
    name        TEXT    NOT NULL,
    category    TEXT    NOT NULL,
    price       NUMERIC(10,2),
    stock       INTEGER
);

INSERT INTO sample_products (id, name, category, price, stock) VALUES
    (1, 'Wireless Mouse',   'Electronics', 29.99, 120),
    (2, 'Mechanical Keyboard', 'Electronics', 89.50, 45),
    (3, 'Desk Organizer',   'Office',      12.75, 300),
    (4, 'USB-C Hub',        'Electronics', 45.00, 80),
    (5, 'Notebook Set',     'Office',      8.99,  500);

-- Verify
SELECT * FROM sample_products;