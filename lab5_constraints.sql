-- =====================================================================
-- Database Constraints - Laboratory Work
-- File:  lab5_constraints.sql
-- Student: ______________________   Student ID: ______________
-- DBMS:  PostgreSQL (run with psql:  psql -U postgres -f lab5_constraints.sql)
--
-- How to read this file:
--   * Valid INSERTs are executed normally.
--   * INSERTs that are SUPPOSED to fail are commented out (as required),
--     each followed by the exact error PostgreSQL returned when it was run,
--     and an explanation of which constraint was violated and why.
--   * To re-test a failing case, uncomment it and run it on its own.
-- =====================================================================

DROP DATABASE IF EXISTS constraints_lab;
CREATE DATABASE constraints_lab;
\c constraints_lab


-- =====================================================================
-- PART 1: CHECK CONSTRAINTS
-- =====================================================================

-- Task 1.1: Basic CHECK Constraint
-- CHECK (age BETWEEN 18 AND 65) -> rejects any age outside 18..65
-- CHECK (salary > 0)            -> rejects zero or negative salary
-- Column-level checks get automatic names: employees_age_check,
-- employees_salary_check.
CREATE TABLE employees (
    employee_id  INTEGER,
    first_name   TEXT,
    last_name    TEXT,
    age          INTEGER CHECK (age BETWEEN 18 AND 65),
    salary       NUMERIC CHECK (salary > 0)
);

-- Task 1.2: Named CHECK Constraint
-- valid_discount: both prices positive AND the discount price is lower
-- than the regular price. Naming it makes error messages readable and
-- lets us drop it later with ALTER TABLE ... DROP CONSTRAINT valid_discount.
CREATE TABLE products_catalog (
    product_id      INTEGER,
    product_name    TEXT,
    regular_price   NUMERIC,
    discount_price  NUMERIC,
    CONSTRAINT valid_discount CHECK (
        regular_price  > 0
        AND discount_price > 0
        AND discount_price < regular_price
    )
);

-- Task 1.3: Multiple Column CHECK
-- num_guests between 1 and 10 (column-level check)
-- check_out_date after check_in_date (table-level check: it compares two
-- columns, so it must be written at table level)
CREATE TABLE bookings (
    booking_id      INTEGER,
    check_in_date   DATE,
    check_out_date  DATE,
    num_guests      INTEGER CHECK (num_guests BETWEEN 1 AND 10),
    CHECK (check_out_date > check_in_date)
);

-- Task 1.4: Testing CHECK Constraints

-- employees: valid rows
INSERT INTO employees VALUES (1, 'Aibek', 'Nurlanov', 30, 450000);
INSERT INTO employees VALUES (2, 'Dana',  'Seitkali', 45, 620000);

-- employees: invalid rows
-- INSERT INTO employees VALUES (3, 'Timur', 'Ospanov', 17, 300000);
-- ERROR:  new row for relation "employees" violates check constraint "employees_age_check"
-- Why: age 17 is below the allowed minimum of 18.

-- INSERT INTO employees VALUES (4, 'Saule', 'Akhmetova', 70, 300000);
-- ERROR:  new row for relation "employees" violates check constraint "employees_age_check"
-- Why: age 70 is above the allowed maximum of 65.

-- INSERT INTO employees VALUES (5, 'Arman', 'Zhumabayev', 25, 0);
-- ERROR:  new row for relation "employees" violates check constraint "employees_salary_check"
-- Why: salary must be strictly greater than 0.

-- products_catalog: valid rows
INSERT INTO products_catalog VALUES (1, 'Laptop', 500000, 450000);
INSERT INTO products_catalog VALUES (2, 'Mouse',    8000,   6500);

-- products_catalog: invalid rows (all violate valid_discount, each for a
-- different reason)
-- INSERT INTO products_catalog VALUES (3, 'Keyboard', 0, 10);
-- ERROR:  new row for relation "products_catalog" violates check constraint "valid_discount"
-- Why: regular_price = 0 is not greater than 0.

-- INSERT INTO products_catalog VALUES (4, 'Monitor', 90000, -5);
-- ERROR:  new row for relation "products_catalog" violates check constraint "valid_discount"
-- Why: discount_price = -5 is not greater than 0.

-- INSERT INTO products_catalog VALUES (5, 'Headset', 20000, 25000);
-- ERROR:  new row for relation "products_catalog" violates check constraint "valid_discount"
-- Why: discount_price (25000) is not less than regular_price (20000).

-- bookings: valid rows
INSERT INTO bookings VALUES (1, '2026-11-01', '2026-11-05', 2);
INSERT INTO bookings VALUES (2, '2026-12-20', '2026-12-27', 4);

-- bookings: invalid rows
-- INSERT INTO bookings VALUES (3, '2026-11-01', '2026-11-03', 0);
-- ERROR:  new row for relation "bookings" violates check constraint "bookings_num_guests_check"
-- Why: 0 guests is below the minimum of 1.

-- INSERT INTO bookings VALUES (4, '2026-11-01', '2026-11-03', 12);
-- ERROR:  new row for relation "bookings" violates check constraint "bookings_num_guests_check"
-- Why: 12 guests is above the maximum of 10.

-- INSERT INTO bookings VALUES (5, '2026-11-10', '2026-11-08', 2);
-- ERROR:  new row for relation "bookings" violates check constraint "bookings_check"
-- Why: check_out_date is before check_in_date.

-- INSERT INTO bookings VALUES (6, '2026-11-10', '2026-11-10', 2);
-- ERROR:  new row for relation "bookings" violates check constraint "bookings_check"
-- Why: same-day check-out is not AFTER check-in (strict ">").

-- Note: a CHECK passes when the expression is NULL (unknown), so
-- e.g. age = NULL is accepted. Combine with NOT NULL to forbid that.


-- =====================================================================
-- PART 2: NOT NULL CONSTRAINTS
-- =====================================================================

-- Task 2.1: NOT NULL Implementation
-- NOT NULL forbids missing values; phone has no NOT NULL so it is optional.
CREATE TABLE customers (
    customer_id        INTEGER NOT NULL,
    email              TEXT    NOT NULL,
    phone              TEXT,
    registration_date  DATE    NOT NULL
);

-- Task 2.2: Combining Constraints (NOT NULL + CHECK on the same column)
CREATE TABLE inventory (
    item_id       INTEGER   NOT NULL,
    item_name     TEXT      NOT NULL,
    quantity      INTEGER   NOT NULL CHECK (quantity >= 0),
    unit_price    NUMERIC   NOT NULL CHECK (unit_price > 0),
    last_updated  TIMESTAMP NOT NULL
);

-- Task 2.3: Testing NOT NULL

-- 1. Complete records (succeed)
INSERT INTO customers VALUES (1, 'aibek@mail.kz', '+77011234567', '2026-01-15');
INSERT INTO customers VALUES (2, 'dana@mail.kz',  '+77027654321', '2026-02-20');

INSERT INTO inventory VALUES (1, 'Cement M400', 120, 3500, NOW());
INSERT INTO inventory VALUES (2, 'Rebar 12mm',    0,  950, NOW());  -- 0 is allowed (>= 0)

-- 2. NULL in NOT NULL columns (fail)
-- INSERT INTO customers VALUES (3, NULL, '+77001112233', '2026-03-01');
-- ERROR:  null value in column "email" of relation "customers" violates not-null constraint
-- Why: email is declared NOT NULL.

-- INSERT INTO customers VALUES (NULL, 'x@mail.kz', NULL, '2026-03-01');
-- ERROR:  null value in column "customer_id" of relation "customers" violates not-null constraint
-- Why: customer_id is declared NOT NULL.

-- INSERT INTO customers (customer_id, email) VALUES (4, 'y@mail.kz');
-- ERROR:  null value in column "registration_date" of relation "customers" violates not-null constraint
-- Why: an omitted column with no DEFAULT becomes NULL, and registration_date is NOT NULL.

-- INSERT INTO inventory VALUES (3, 'Sand', NULL, 2000, NOW());
-- ERROR:  null value in column "quantity" of relation "inventory" violates not-null constraint
-- Why: quantity is NOT NULL (the CHECK alone would have let NULL through).

-- INSERT INTO inventory VALUES (4, 'Gravel', -5, 1500, NOW());
-- ERROR:  new row for relation "inventory" violates check constraint "inventory_quantity_check"
-- Why: quantity cannot be negative.

-- 3. NULL in nullable columns (succeeds)
INSERT INTO customers VALUES (3, 'arman@mail.kz', NULL, '2026-03-05');   -- phone is optional

SELECT * FROM customers;


-- =====================================================================
-- PART 3: UNIQUE CONSTRAINTS
-- =====================================================================

-- Task 3.1: Single Column UNIQUE
-- Auto-named constraints: users_username_key, users_email_key
CREATE TABLE users (
    user_id     INTEGER,
    username    TEXT UNIQUE,
    email       TEXT UNIQUE,
    created_at  TIMESTAMP
);

-- Task 3.2: Multi-Column UNIQUE
-- The COMBINATION must be unique: a student can take the same course in
-- different semesters, and different courses in the same semester, but
-- cannot enroll twice in the same course in the same semester.
CREATE TABLE course_enrollments (
    enrollment_id  INTEGER,
    student_id     INTEGER,
    course_code    TEXT,
    semester       TEXT,
    UNIQUE (student_id, course_code, semester)
);

INSERT INTO course_enrollments VALUES (1, 101, 'CS201', 'Fall 2026');
INSERT INTO course_enrollments VALUES (2, 101, 'CS202', 'Fall 2026');    -- other course: OK
INSERT INTO course_enrollments VALUES (3, 101, 'CS201', 'Spring 2027');  -- other semester: OK
INSERT INTO course_enrollments VALUES (4, 102, 'CS201', 'Fall 2026');    -- other student: OK

-- INSERT INTO course_enrollments VALUES (5, 101, 'CS201', 'Fall 2026');
-- ERROR:  duplicate key value violates unique constraint "course_enrollments_student_id_course_code_semester_key"
-- DETAIL:  Key (student_id, course_code, semester)=(101, CS201, Fall 2026) already exists.
-- Why: the same (student, course, semester) combination already exists.

-- Task 3.3: Named UNIQUE Constraints
-- Replace the automatically named constraints with named ones.
ALTER TABLE users DROP CONSTRAINT users_username_key;
ALTER TABLE users DROP CONSTRAINT users_email_key;
ALTER TABLE users ADD CONSTRAINT unique_username UNIQUE (username);
ALTER TABLE users ADD CONSTRAINT unique_email    UNIQUE (email);

INSERT INTO users VALUES (1, 'aibek', 'aibek@mail.kz', NOW());
INSERT INTO users VALUES (2, 'dana',  'dana@mail.kz',  NOW());

-- INSERT INTO users VALUES (3, 'aibek', 'other@mail.kz', NOW());
-- ERROR:  duplicate key value violates unique constraint "unique_username"
-- DETAIL:  Key (username)=(aibek) already exists.
-- Why: username 'aibek' is already taken.

-- INSERT INTO users VALUES (4, 'arman', 'dana@mail.kz', NOW());
-- ERROR:  duplicate key value violates unique constraint "unique_email"
-- DETAIL:  Key (email)=(dana@mail.kz) already exists.
-- Why: email 'dana@mail.kz' is already used.

-- UNIQUE allows several NULLs (NULLs are not equal to each other):
INSERT INTO users VALUES (5, NULL, 'n1@mail.kz', NOW());
INSERT INTO users VALUES (6, NULL, 'n2@mail.kz', NOW());   -- succeeds


-- =====================================================================
-- PART 4: PRIMARY KEY CONSTRAINTS
-- =====================================================================

-- Task 4.1: Single Column Primary Key
-- PRIMARY KEY = UNIQUE + NOT NULL; identifies each row.
CREATE TABLE departments (
    dept_id    INTEGER PRIMARY KEY,
    dept_name  TEXT NOT NULL,
    location   TEXT
);

INSERT INTO departments VALUES (1, 'IT',      'Almaty');
INSERT INTO departments VALUES (2, 'Finance', 'Astana');
INSERT INTO departments VALUES (3, 'HR',      'Taraz');

-- 1. Duplicate dept_id
-- INSERT INTO departments VALUES (1, 'Marketing', 'Shymkent');
-- ERROR:  duplicate key value violates unique constraint "departments_pkey"
-- DETAIL:  Key (dept_id)=(1) already exists.
-- Why: primary key values must be unique.

-- 2. NULL dept_id
-- INSERT INTO departments VALUES (NULL, 'Marketing', 'Shymkent');
-- ERROR:  null value in column "dept_id" of relation "departments" violates not-null constraint
-- Why: primary key columns are implicitly NOT NULL.

-- Task 4.2: Composite Primary Key
-- A student can appear many times and a course many times, but each
-- (student_id, course_id) pair only once.
CREATE TABLE student_courses (
    student_id       INTEGER,
    course_id        INTEGER,
    enrollment_date  DATE,
    grade            TEXT,
    PRIMARY KEY (student_id, course_id)
);

INSERT INTO student_courses VALUES (101, 1, '2026-09-01', 'A');
INSERT INTO student_courses VALUES (101, 2, '2026-09-01', 'B+');
INSERT INTO student_courses VALUES (102, 1, '2026-09-02', 'A-');

-- INSERT INTO student_courses VALUES (101, 1, '2026-09-05', 'C');
-- ERROR:  duplicate key value violates unique constraint "student_courses_pkey"
-- DETAIL:  Key (student_id, course_id)=(101, 1) already exists.
-- Why: the pair (101, 1) already exists.

-- Task 4.3: Comparison Exercise
/*
1. Difference between UNIQUE and PRIMARY KEY
   - Both guarantee that values (or combinations of values) are not
     repeated, and both create a unique index automatically.
   - PRIMARY KEY additionally implies NOT NULL: every row must have a key.
     A UNIQUE column may contain NULLs (and several of them, because NULL
     is never equal to another NULL).
   - PRIMARY KEY is THE identifier of a row; it is what FOREIGN KEYs in
     other tables reference by default. UNIQUE marks other columns that
     must also be distinct (e.g. email, username, ISBN) - "alternate keys".
   - A table can have only one PRIMARY KEY but any number of UNIQUE
     constraints.

2. Single-column vs composite PRIMARY KEY
   - Single-column: when one attribute identifies the row by itself,
     usually a surrogate id (dept_id, customer_id, SERIAL/IDENTITY).
     Simple, small, easy to reference from other tables.
   - Composite: when the row is identified only by a combination of
     columns, typically in junction (many-to-many) tables such as
     student_courses(student_id, course_id) or order lines. It also
     enforces the business rule "a student cannot enroll in the same
     course twice" without an extra constraint. Drawback: foreign keys
     pointing to it must carry all the columns.

3. Why only one PRIMARY KEY but many UNIQUE constraints
   - The primary key is by definition the single, main way to identify a
     row; the relational model chooses one candidate key as primary.
     Having two "main" identifiers would be contradictory, and foreign
     keys / tools (ORMs, replication) rely on there being exactly one.
   - Other candidate keys still need to be protected from duplicates, so
     they are declared as UNIQUE - a table may have as many as needed
     (e.g. users: PK user_id, UNIQUE username, UNIQUE email).
*/


-- =====================================================================
-- PART 5: FOREIGN KEY CONSTRAINTS
-- =====================================================================

-- Task 5.1: Basic Foreign Key
-- dept_id must match an existing departments.dept_id (or be NULL).
CREATE TABLE employees_dept (
    emp_id     INTEGER PRIMARY KEY,
    emp_name   TEXT NOT NULL,
    dept_id    INTEGER REFERENCES departments,   -- references departments(dept_id)
    hire_date  DATE
);

-- 1. Valid dept_id
INSERT INTO employees_dept VALUES (1, 'Aibek Nurlanov', 1, '2024-03-01');
INSERT INTO employees_dept VALUES (2, 'Dana Seitkali',  2, '2025-06-15');
INSERT INTO employees_dept VALUES (3, 'Arman Zhumabayev', NULL, '2026-01-10'); -- NULL FK is allowed

-- 2. Non-existent dept_id
-- INSERT INTO employees_dept VALUES (4, 'Timur Ospanov', 99, '2026-02-01');
-- ERROR:  insert or update on table "employees_dept" violates foreign key constraint "employees_dept_dept_id_fkey"
-- DETAIL:  Key (dept_id)=(99) is not present in table "departments".
-- Why: there is no department with id 99.

-- Task 5.2: Multiple Foreign Keys - Library system
CREATE TABLE authors (
    author_id    INTEGER PRIMARY KEY,
    author_name  TEXT NOT NULL,
    country      TEXT
);

CREATE TABLE publishers (
    publisher_id    INTEGER PRIMARY KEY,
    publisher_name  TEXT NOT NULL,
    city            TEXT
);

CREATE TABLE books (
    book_id           INTEGER PRIMARY KEY,
    title             TEXT NOT NULL,
    author_id         INTEGER REFERENCES authors,      -- FK 1
    publisher_id      INTEGER REFERENCES publishers,   -- FK 2
    publication_year  INTEGER,
    isbn              TEXT UNIQUE                      -- no two books share an ISBN
);

INSERT INTO authors VALUES
    (1, 'Abai Kunanbaiuly',  'Kazakhstan'),
    (2, 'Mukhtar Auezov',    'Kazakhstan'),
    (3, 'Chingiz Aitmatov',  'Kyrgyzstan'),
    (4, 'George Orwell',     'United Kingdom');

INSERT INTO publishers VALUES
    (1, 'Atamura',          'Almaty'),
    (2, 'Foliant',          'Astana'),
    (3, 'Penguin Books',    'London');

INSERT INTO books VALUES
    (1, 'Book of Words',          1, 1, 1918, '9786010000011'),
    (2, 'The Path of Abai',       2, 1, 1942, '9786010000028'),
    (3, 'Jamilia',                3, 2, 1958, '9786010000035'),
    (4, 'The Day Lasts More Than a Hundred Years', 3, 2, 1980, '9786010000042'),
    (5, 'Nineteen Eighty-Four',   4, 3, 1949, '9780141036144');

-- INSERT INTO books VALUES (6, 'Unknown Book', 10, 1, 2000, '9786010000059');
-- ERROR:  insert or update on table "books" violates foreign key constraint "books_author_id_fkey"
-- DETAIL:  Key (author_id)=(10) is not present in table "authors".

-- INSERT INTO books VALUES (7, 'Copy', 1, 1, 2001, '9786010000011');
-- ERROR:  duplicate key value violates unique constraint "books_isbn_key"
-- DETAIL:  Key (isbn)=(9786010000011) already exists.

SELECT b.title, a.author_name, p.publisher_name, b.publication_year
FROM books b
JOIN authors a    ON a.author_id    = b.author_id
JOIN publishers p ON p.publisher_id = b.publisher_id
ORDER BY b.book_id;

-- Task 5.3: ON DELETE Options
CREATE TABLE categories (
    category_id    INTEGER PRIMARY KEY,
    category_name  TEXT NOT NULL
);

-- RESTRICT: a category cannot be deleted while products refer to it
CREATE TABLE products_fk (
    product_id    INTEGER PRIMARY KEY,
    product_name  TEXT NOT NULL,
    category_id   INTEGER REFERENCES categories ON DELETE RESTRICT
);

CREATE TABLE orders (
    order_id    INTEGER PRIMARY KEY,
    order_date  DATE NOT NULL
);

-- CASCADE: deleting an order deletes its items automatically
CREATE TABLE order_items (
    item_id     INTEGER PRIMARY KEY,
    order_id    INTEGER REFERENCES orders ON DELETE CASCADE,
    product_id  INTEGER REFERENCES products_fk,     -- default: NO ACTION
    quantity    INTEGER CHECK (quantity > 0)
);

INSERT INTO categories VALUES (1, 'Electronics'), (2, 'Books'), (3, 'Garden');
INSERT INTO products_fk VALUES (1, 'Smartphone', 1), (2, 'Headphones', 1), (3, 'SQL Textbook', 2);
INSERT INTO orders VALUES (1, '2026-10-01'), (2, '2026-10-05');
INSERT INTO order_items VALUES
    (1, 1, 1, 1),
    (2, 1, 2, 2),
    (3, 2, 3, 1);

-- Scenario 1: delete a category that has products (RESTRICT)
-- DELETE FROM categories WHERE category_id = 1;
-- ERROR:  update or delete on table "categories" violates foreign key constraint "products_fk_category_id_fkey" on table "products_fk"
-- DETAIL:  Key (category_id)=(1) is still referenced from table "products_fk".
-- Result: the delete is blocked; category 1 and its products stay unchanged.

-- A category without products CAN be deleted:
DELETE FROM categories WHERE category_id = 3;   -- DELETE 1

-- Scenario 2: delete an order (CASCADE)
SELECT * FROM order_items WHERE order_id = 1;   -- before: 2 rows (items 1 and 2)
DELETE FROM orders WHERE order_id = 1;          -- DELETE 1
SELECT * FROM order_items WHERE order_id = 1;   -- after: 0 rows
SELECT * FROM order_items;                      -- only item 3 (order 2) remains
-- Result: deleting order 1 automatically removed its 2 order_items rows;
-- items of other orders are untouched.

-- Scenario 3 (extra): product referenced by order_items, default NO ACTION
-- DELETE FROM products_fk WHERE product_id = 3;
-- ERROR:  update or delete on table "products_fk" violates foreign key constraint "order_items_product_id_fkey" on table "order_items"
-- DETAIL:  Key (product_id)=(3) is still referenced from table "order_items".
-- Result: NO ACTION behaves like RESTRICT (the check is just deferred to
-- the end of the statement).


-- =====================================================================
-- PART 6: PRACTICAL APPLICATION - E-COMMERCE DATABASE
-- =====================================================================
-- The names customers / products / orders are already used in Parts 2
-- and 5, so the e-commerce schema lives in its own schema "ecommerce".
CREATE SCHEMA ecommerce;
SET search_path TO ecommerce;

-- Task 6.1: CREATE TABLE statements

CREATE TABLE customers (
    customer_id        SERIAL PRIMARY KEY,
    name               TEXT NOT NULL,
    email              TEXT NOT NULL UNIQUE,             -- one account per email
    phone              TEXT,                             -- optional
    registration_date  DATE NOT NULL DEFAULT CURRENT_DATE
);

CREATE TABLE products (
    product_id      SERIAL PRIMARY KEY,
    name            TEXT NOT NULL,
    description     TEXT,
    price           NUMERIC(10,2) NOT NULL CHECK (price >= 0),          -- non-negative
    stock_quantity  INTEGER       NOT NULL DEFAULT 0
                                  CHECK (stock_quantity >= 0)           -- non-negative
);

CREATE TABLE orders (
    order_id      SERIAL PRIMARY KEY,
    -- RESTRICT: a customer with orders cannot be deleted (keeps sales history)
    customer_id   INTEGER NOT NULL REFERENCES customers ON DELETE RESTRICT,
    order_date    DATE NOT NULL DEFAULT CURRENT_DATE,
    total_amount  NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (total_amount >= 0),
    status        TEXT NOT NULL DEFAULT 'pending'
                  CHECK (status IN ('pending', 'processing', 'shipped',
                                    'delivered', 'cancelled'))
);

CREATE TABLE order_details (
    order_detail_id  SERIAL PRIMARY KEY,
    -- CASCADE: order lines have no meaning without their order
    order_id         INTEGER NOT NULL REFERENCES orders ON DELETE CASCADE,
    -- RESTRICT: a product that was ever sold cannot be deleted
    product_id       INTEGER NOT NULL REFERENCES products ON DELETE RESTRICT,
    quantity         INTEGER NOT NULL CHECK (quantity > 0),             -- positive
    unit_price       NUMERIC(10,2) NOT NULL CHECK (unit_price >= 0),
    UNIQUE (order_id, product_id)          -- one line per product in an order
);

-- Sample data (5+ rows per table)

INSERT INTO customers (name, email, phone, registration_date) VALUES
    ('Aibek Nurlanov',   'aibek@mail.kz',  '+77011234567', '2026-01-10'),
    ('Dana Seitkali',    'dana@mail.kz',   '+77027654321', '2026-02-14'),
    ('Arman Zhumabayev', 'arman@mail.kz',  NULL,           '2026-03-03'),
    ('Aliya Bekova',     'aliya@mail.kz',  '+77079998877', '2026-04-21'),
    ('Timur Ospanov',    'timur@mail.kz',  '+77051112233', '2026-05-30');

INSERT INTO products (name, description, price, stock_quantity) VALUES
    ('Laptop',     '15.6" laptop, 16 GB RAM',   450000.00, 10),
    ('Mouse',      'Wireless optical mouse',      6500.00, 150),
    ('Keyboard',   'Mechanical keyboard',        25000.00, 40),
    ('Monitor',    '27" IPS monitor',            95000.00, 15),
    ('USB Cable',  'USB-C to USB-C, 1 m',         2500.00, 0),
    ('Headphones', 'Noise-cancelling headphones', 60000.00, 25);

INSERT INTO orders (customer_id, order_date, total_amount, status) VALUES
    (1, '2026-09-01', 463000.00, 'delivered'),
    (2, '2026-09-15',  95000.00, 'shipped'),
    (3, '2026-10-01',  31500.00, 'processing'),
    (1, '2026-10-10',  60000.00, 'pending'),
    (4, '2026-10-12',   5000.00, 'cancelled');

INSERT INTO order_details (order_id, product_id, quantity, unit_price) VALUES
    (1, 1, 1, 450000.00),
    (1, 2, 2,   6500.00),
    (2, 4, 1,  95000.00),
    (3, 3, 1,  25000.00),
    (3, 2, 1,   6500.00),
    (4, 6, 1,  60000.00),
    (5, 5, 2,   2500.00);

-- Check that totals match the order lines
SELECT o.order_id, o.total_amount,
       SUM(d.quantity * d.unit_price) AS computed_total
FROM orders o
JOIN order_details d ON d.order_id = o.order_id
GROUP BY o.order_id, o.total_amount
ORDER BY o.order_id;

-- ---------------------------------------------------------------------
-- Test queries demonstrating that every constraint works
-- (failing statements commented out, with the observed error)
-- ---------------------------------------------------------------------

-- T1. PRIMARY KEY: duplicate id
-- INSERT INTO products (product_id, name, price, stock_quantity) VALUES (1, 'Dup', 100, 1);
-- ERROR:  duplicate key value violates unique constraint "products_pkey"
-- DETAIL:  Key (product_id)=(1) already exists.

-- T2. UNIQUE email
-- INSERT INTO customers (name, email) VALUES ('Fake Aibek', 'aibek@mail.kz');
-- ERROR:  duplicate key value violates unique constraint "customers_email_key"
-- DETAIL:  Key (email)=(aibek@mail.kz) already exists.

-- T3. NOT NULL
-- INSERT INTO customers (name, email) VALUES (NULL, 'noname@mail.kz');
-- ERROR:  null value in column "name" of relation "customers" violates not-null constraint

-- T4. CHECK price >= 0
-- INSERT INTO products (name, price, stock_quantity) VALUES ('Broken', -100, 5);
-- ERROR:  new row for relation "products" violates check constraint "products_price_check"

-- T5. CHECK stock_quantity >= 0
-- UPDATE products SET stock_quantity = stock_quantity - 20 WHERE product_id = 1;
-- ERROR:  new row for relation "products" violates check constraint "products_stock_quantity_check"
-- (stock 10 - 20 = -10: overselling is prevented)

-- T6. CHECK status list
-- INSERT INTO orders (customer_id, status) VALUES (2, 'lost');
-- ERROR:  new row for relation "orders" violates check constraint "orders_status_check"

-- T7. CHECK quantity > 0
-- INSERT INTO order_details (order_id, product_id, quantity, unit_price) VALUES (2, 2, 0, 6500);
-- ERROR:  new row for relation "order_details" violates check constraint "order_details_quantity_check"

-- T8. FOREIGN KEY: non-existent customer
-- INSERT INTO orders (customer_id, total_amount) VALUES (99, 1000);
-- ERROR:  insert or update on table "orders" violates foreign key constraint "orders_customer_id_fkey"
-- DETAIL:  Key (customer_id)=(99) is not present in table "customers".

-- T9. FOREIGN KEY: non-existent product
-- INSERT INTO order_details (order_id, product_id, quantity, unit_price) VALUES (2, 99, 1, 100);
-- ERROR:  insert or update on table "order_details" violates foreign key constraint "order_details_product_id_fkey"
-- DETAIL:  Key (product_id)=(99) is not present in table "products".

-- T10. ON DELETE RESTRICT: customer with orders
-- DELETE FROM customers WHERE customer_id = 1;
-- ERROR:  update or delete on table "customers" violates foreign key constraint "orders_customer_id_fkey" on table "orders"
-- DETAIL:  Key (customer_id)=(1) is still referenced from table "orders".

-- T11. ON DELETE RESTRICT: product that was sold
-- DELETE FROM products WHERE product_id = 2;
-- ERROR:  update or delete on table "products" violates foreign key constraint "order_details_product_id_fkey" on table "order_details"
-- DETAIL:  Key (product_id)=(2) is still referenced from table "order_details".

-- T12. UNIQUE (order_id, product_id): same product twice in one order
-- INSERT INTO order_details (order_id, product_id, quantity, unit_price) VALUES (1, 1, 1, 450000);
-- ERROR:  duplicate key value violates unique constraint "order_details_order_id_product_id_key"
-- DETAIL:  Key (order_id, product_id)=(1, 1) already exists.

-- T13. Successful operations that respect the constraints
UPDATE orders SET status = 'shipped' WHERE order_id = 3;             -- valid status
DELETE FROM customers WHERE customer_id = 5;                          -- no orders -> allowed
DELETE FROM products  WHERE product_id = 6 AND NOT EXISTS
      (SELECT 1 FROM order_details WHERE product_id = 6);             -- sold -> 0 rows deleted

-- T14. ON DELETE CASCADE: deleting an order removes its lines
SELECT COUNT(*) AS lines_before FROM order_details WHERE order_id = 5;   -- 1
DELETE FROM orders WHERE order_id = 5;
SELECT COUNT(*) AS lines_after  FROM order_details WHERE order_id = 5;   -- 0

-- Final state
SELECT * FROM customers     ORDER BY customer_id;
SELECT * FROM products      ORDER BY product_id;
SELECT * FROM orders        ORDER BY order_id;
SELECT * FROM order_details ORDER BY order_detail_id;

RESET search_path;

-- =====================================================================
-- END OF LAB
-- =====================================================================
