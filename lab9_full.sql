-- ============================================================
-- Laboratory Work 9: Stored Procedures and User-Defined Functions
-- Part 1: Database Setup  (CityBike rental network)
-- ============================================================

DROP TABLE IF EXISTS rentals, bikes, members, stations CASCADE;

-- Create table: stations
CREATE TABLE stations (
    station_id   INT PRIMARY KEY,
    station_name VARCHAR(50) NOT NULL,
    city         VARCHAR(40) NOT NULL,
    capacity     INT NOT NULL
);

-- Create table: bikes
CREATE TABLE bikes (
    bike_id    INT PRIMARY KEY,
    model      VARCHAR(50) NOT NULL,
    station_id INT REFERENCES stations(station_id),
    daily_rate NUMERIC(8,2) NOT NULL
);

-- Create table: members
CREATE TABLE members (
    member_id INT PRIMARY KEY,
    full_name VARCHAR(60) NOT NULL,
    city      VARCHAR(40) NOT NULL,
    joined_on DATE NOT NULL
);

-- Create table: rentals
CREATE TABLE rentals (
    rental_id  INT PRIMARY KEY,
    member_id  INT REFERENCES members(member_id),
    bike_id    INT REFERENCES bikes(bike_id),
    start_date DATE NOT NULL,
    end_date   DATE,
    fee        NUMERIC(8,2)
);

INSERT INTO stations VALUES
 (10, 'Central Park', 'Almaty',   4),
 (20, 'Riverside',    'Almaty',   3),
 (30, 'Expo Gate',    'Astana',   5),
 (40, 'Old Town',     'Shymkent', 2),
 (50, 'Depot',        'Astana',   0);

INSERT INTO bikes VALUES
 (101, 'City Cruiser', 10,  4.50),
 (102, 'City Cruiser', 10,  4.50),
 (103, 'Mountain X',   20,  7.00),
 (104, 'Mountain X',   30,  7.00),
 (105, 'Road Sprint',  30,  9.25),
 (106, 'Folding Mini', 40,  3.75),
 (107, 'Cargo Hauler', 20, 12.00),
 (108, 'Road Sprint',  10,  9.25);

INSERT INTO members VALUES
 (1, 'Aisha Nurlanova', 'Almaty',   DATE '2023-03-14'),
 (2, 'Daniyar Serik',   'Almaty',   DATE '2023-07-02'),
 (3, 'Marta Kowalski',  'Astana',   DATE '2024-01-20'),
 (4, 'Chen Wei',        'Astana',   DATE '2024-05-11'),
 (5, 'Omar Haddad',     'Shymkent', DATE '2024-09-30'),
 (6, 'Elena Petrova',   'Almaty',   DATE '2025-02-05');

INSERT INTO rentals VALUES
 ( 1, 1, 101, DATE '2024-04-05', DATE '2024-04-08', 13.50),
 ( 2, 1, 103, DATE '2024-06-11', DATE '2024-06-16', 35.00),
 ( 3, 1, 108, DATE '2025-02-02', DATE '2025-02-04', 18.50),
 ( 4, 1, 102, DATE '2025-05-20', DATE '2025-05-27', 31.50),
 ( 5, 2, 101, DATE '2024-05-01', DATE '2024-05-02',  4.50),
 ( 6, 2, 107, DATE '2024-11-15', DATE '2024-11-19', 48.00),
 ( 7, 2, 107, DATE '2025-03-08', DATE '2025-03-14', 72.00),
 ( 8, 3, 104, DATE '2024-02-14', DATE '2024-02-18', 28.00),
 ( 9, 3, 105, DATE '2024-08-03', DATE '2024-08-06', 27.75),
 (10, 3, 104, DATE '2025-01-09', DATE '2025-01-10',  7.00),
 (11, 3, 105, DATE '2025-06-01', DATE '2025-06-09', 74.00),
 (12, 4, 104, DATE '2024-07-19', DATE '2024-07-21', 14.00),
 (13, 4, 105, DATE '2025-04-12', DATE '2025-04-15', 27.75),
 (14, 4, 103, DATE '2025-07-23', DATE '2025-07-29', 42.00),
 (15, 5, 106, DATE '2024-10-05', DATE '2024-10-12', 26.25),
 (16, 5, 106, DATE '2025-01-18', DATE '2025-01-20',  7.50),
 (17, 5, 106, DATE '2025-08-14', DATE '2025-08-21', 26.25),
 (18, 2, 102, DATE '2025-09-02', DATE '2025-09-05', 13.50),
 (19, 1, 101, DATE '2025-10-10', NULL,              NULL),
 (20, 4, 108, DATE '2024-12-28', DATE '2025-01-03', 55.50),
 (21, 3, 103, DATE '2025-02-26', DATE '2025-03-02', 28.00),
 (22, 5, 104, DATE '2025-05-05', DATE '2025-05-08', 21.00);


-- ============================================================
-- Laboratory Work 9: Stored Procedures and User-Defined Functions
-- Combined file: setup (Part 1) followed by the solution (Parts 2-7).
--   psql -d yourdb -f lab9_setup.sql
--   psql -d yourdb -f lab9_solution.sql
-- ============================================================

-- Clean-up: drop every function this script creates, so the file can be
-- re-run from a clean state (the setup script only drops tables).
DO $$
DECLARE f RECORD;
BEGIN
  FOR f IN SELECT oid::regprocedure AS sig FROM pg_proc
           WHERE pronamespace = 'public'::regnamespace
             AND proname = ANY (ARRAY['rental_days','member_rental_count','station_city',
                 'fee_with_discount','member_stats','apply_late_fee','fee_summary','total_fees',
                 'find_bikes','member_history','bike_list','station_board','fee_split',
                 'station_load','top_members','rental_invoice','city_report','city_report_where_demo'])
  LOOP
    EXECUTE 'DROP FUNCTION ' || f.sig;
  END LOOP;
END $$;

-- ============================================================
-- PART 2: Your first function
-- ============================================================

-- Exercise 2.1: function over one row
CREATE OR REPLACE FUNCTION rental_days(p_rental_id INT) RETURNS INT AS $$
DECLARE
    d INT;
BEGIN
    SELECT end_date - start_date INTO d
    FROM rentals
    WHERE rental_id = p_rental_id;
    RETURN d;
END; $$ LANGUAGE plpgsql;

\echo '>>> 2.1: SELECT rental_days(2), rental_days(11), rental_days(19), rental_days(999);'
SELECT rental_days(2) AS r2, rental_days(11) AS r11, rental_days(19) AS r19, rental_days(999) AS r999;

-- Exercise 2.2: function over many rows
CREATE OR REPLACE FUNCTION member_rental_count(p_member_id INT) RETURNS INT AS $$
DECLARE
    cnt INT;
BEGIN
    SELECT COUNT(*) INTO cnt FROM rentals WHERE member_id = p_member_id;
    RETURN cnt;
END; $$ LANGUAGE plpgsql;

\echo '>>> 2.2: member_rental_count for members 1, 5, 6 and 99'
SELECT member_rental_count(1) AS m1, member_rental_count(5) AS m5,
       member_rental_count(6) AS m6, member_rental_count(99) AS m99;

-- Exercise 2.3: returning text
CREATE OR REPLACE FUNCTION station_city(p_station_id INT) RETURNS VARCHAR AS $$
DECLARE
    c VARCHAR;
BEGIN
    SELECT city INTO c FROM stations WHERE station_id = p_station_id;
    RETURN c;
END; $$ LANGUAGE plpgsql;

\echo '>>> 2.3: station_city(30), station_city(77)'
SELECT station_city(30) AS st30, station_city(77) AS st77;

-- Exercise 2.4: function inside a query
\echo '>>> 2.4: rentals longer than 4 days'
SELECT rental_id, member_id, rental_days(rental_id) AS days
FROM rentals
WHERE rental_days(rental_id) > 4
ORDER BY days DESC, rental_id;

-- ============================================================
-- PART 3: Parameter modes
-- ============================================================

-- Exercise 3.1: IN parameters
CREATE OR REPLACE FUNCTION fee_with_discount(p_fee NUMERIC, p_percent NUMERIC)
RETURNS NUMERIC AS $$
BEGIN
    RETURN ROUND(p_fee * (1 - p_percent / 100), 2);
END; $$ LANGUAGE plpgsql;

\echo '>>> 3.1: SELECT fee_with_discount(74.00, 15);'
SELECT fee_with_discount(74.00, 15);

-- Exercise 3.2: OUT parameters
CREATE OR REPLACE FUNCTION member_stats(
    p_member_id INT,
    OUT rental_cnt INT,
    OUT total_fee NUMERIC,
    OUT last_start DATE)
AS $$
BEGIN
    SELECT COUNT(*), COALESCE(SUM(fee), 0), MAX(start_date)
    INTO rental_cnt, total_fee, last_start
    FROM rentals
    WHERE member_id = p_member_id;
END; $$ LANGUAGE plpgsql;

\echo '>>> 3.2: SELECT member_stats(3);'
SELECT member_stats(3);
\echo '>>> 3.2: SELECT * FROM member_stats(3);'
SELECT * FROM member_stats(3);
\echo '>>> 3.2: SELECT * FROM member_stats(6);'
SELECT * FROM member_stats(6);

-- Exercise 3.3: INOUT parameters
CREATE OR REPLACE FUNCTION apply_late_fee(INOUT p_fee NUMERIC) AS $$
BEGIN
    p_fee := p_fee + 5.00;
END; $$ LANGUAGE plpgsql;

\echo '>>> 3.3: apply_late_fee on the fee of rental 1'
SELECT fee AS original_fee, apply_late_fee(fee) AS with_late_fee FROM rentals WHERE rental_id = 1;

-- Exercise 3.4: VARIADIC parameters
CREATE OR REPLACE FUNCTION fee_summary(
    VARIADIC p_fees NUMERIC[],
    OUT total NUMERIC,
    OUT average NUMERIC,
    OUT largest NUMERIC)
AS $$
BEGIN
    SELECT SUM(p_fees[i]), ROUND(AVG(p_fees[i]), 2), MAX(p_fees[i])
    INTO total, average, largest
    FROM generate_subscripts(p_fees, 1) g(i);
END; $$ LANGUAGE plpgsql;

\echo '>>> 3.4: SELECT * FROM fee_summary(13.50, 35.00, 18.50, 31.50);'
SELECT * FROM fee_summary(13.50, 35.00, 18.50, 31.50);
\echo '>>> 3.4: SELECT * FROM fee_summary();   -- no arguments'
SELECT * FROM fee_summary();
\echo '>>> 3.4: SELECT * FROM fee_summary(VARIADIC ARRAY[10, 20]);   -- passing a real array'
SELECT * FROM fee_summary(VARIADIC ARRAY[10, 20]::NUMERIC[]);

-- Exercise 3.5: answers are in the written report.

-- ============================================================
-- PART 4: Default values and overloading
-- ============================================================

-- Exercise 4.1
CREATE OR REPLACE FUNCTION total_fees(p_member_id INT) RETURNS NUMERIC AS $$
DECLARE
    t NUMERIC;
BEGIN
    SELECT COALESCE(SUM(fee), 0) INTO t FROM rentals WHERE member_id = p_member_id;
    RETURN t;
END; $$ LANGUAGE plpgsql;

\echo '>>> 4.1: total_fees(1), total_fees(6)'
SELECT total_fees(1) AS m1, total_fees(6) AS m6;

-- Exercise 4.2: overload with a cut-off date
CREATE OR REPLACE FUNCTION total_fees(p_member_id INT, p_from_date DATE)
RETURNS NUMERIC AS $$
DECLARE
    t NUMERIC;
BEGIN
    SELECT COALESCE(SUM(fee), 0) INTO t
    FROM rentals
    WHERE member_id = p_member_id AND start_date >= p_from_date;
    RETURN t;
END; $$ LANGUAGE plpgsql;

\echo '>>> 4.2: total_fees(1, 2024-01-01) and total_fees(1, 2025-01-01)'
SELECT total_fees(1, DATE '2024-01-01') AS from_2024, total_fees(1, DATE '2025-01-01') AS from_2025;
\echo '>>> 4.2: \df total_fees'
\df total_fees

-- Exercise 4.3: default value -> ambiguity
CREATE OR REPLACE FUNCTION total_fees(p_member_id INT,
                                      p_from_date DATE DEFAULT DATE '2025-01-01')
RETURNS NUMERIC AS $$
DECLARE
    t NUMERIC;
BEGIN
    SELECT COALESCE(SUM(fee), 0) INTO t
    FROM rentals
    WHERE member_id = p_member_id AND start_date >= p_from_date;
    RETURN t;
END; $$ LANGUAGE plpgsql;

\echo '>>> 4.3: SELECT total_fees(1);   -- EXPECTED TO FAIL'
SELECT total_fees(1);

-- Exercise 4.4: resolving the ambiguity
DROP FUNCTION total_fees(INTEGER);
\echo '>>> 4.4: SELECT total_fees(1);   -- after dropping the one-argument version'
SELECT total_fees(1);
\echo '>>> 4.4: \df total_fees'
\df total_fees

-- Exercise 4.5: overload on type
CREATE OR REPLACE FUNCTION total_fees(p_name VARCHAR) RETURNS NUMERIC AS $$
DECLARE
    t NUMERIC;
BEGIN
    SELECT COALESCE(SUM(r.fee), 0) INTO t
    FROM members m
    LEFT JOIN rentals r ON r.member_id = m.member_id
    WHERE m.full_name = p_name;
    RETURN t;
END; $$ LANGUAGE plpgsql;

\echo '>>> 4.5: total_fees(''Aisha Nurlanova'') and total_fees(1)'
SELECT total_fees('Aisha Nurlanova') AS by_name, total_fees(1) AS by_id;
\echo '>>> 4.5: \df total_fees'
\df total_fees

-- ============================================================
-- PART 5: Functions that return a table
-- ============================================================

-- Exercise 5.1
CREATE OR REPLACE FUNCTION find_bikes(p_pattern VARCHAR)
RETURNS TABLE (found_id INT, found_model VARCHAR, found_rate NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT b.bike_id, b.model, b.daily_rate
    FROM bikes b
    WHERE b.model ILIKE p_pattern
    ORDER BY b.bike_id;
END; $$ LANGUAGE plpgsql;

\echo '>>> 5.1: SELECT * FROM find_bikes(''%road%'');'
SELECT * FROM find_bikes('%road%');
\echo '>>> 5.1: SELECT * FROM find_bikes(''%Mini'');'
SELECT * FROM find_bikes('%Mini');
\echo '>>> 5.1: SELECT find_bikes(''%road%'');   -- without FROM'
SELECT find_bikes('%road%');

-- Exercise 5.2
CREATE OR REPLACE FUNCTION member_history(p_member_id INT)
RETURNS TABLE (h_rental_id INT, h_model VARCHAR, h_station VARCHAR, h_days INT, h_fee NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT r.rental_id, b.model, s.station_name, r.end_date - r.start_date, r.fee
    FROM rentals r
    JOIN bikes b ON b.bike_id = r.bike_id
    LEFT JOIN stations s ON s.station_id = b.station_id
    WHERE r.member_id = p_member_id
    ORDER BY r.start_date;
END; $$ LANGUAGE plpgsql;

\echo '>>> 5.2: SELECT * FROM member_history(3);'
SELECT * FROM member_history(3);

-- Exercise 5.3: colliding column names
CREATE OR REPLACE FUNCTION bike_list(p_station_id INT)
RETURNS TABLE (bike_id INT, model VARCHAR) AS $$
BEGIN
    RETURN QUERY SELECT bike_id, model FROM bikes WHERE station_id = p_station_id;
END; $$ LANGUAGE plpgsql;

\echo '>>> 5.3: SELECT * FROM bike_list(10);   -- EXPECTED TO FAIL'
SELECT * FROM bike_list(10);

-- Fix 1: rename the output columns (the return type changes, so DROP first)
DROP FUNCTION bike_list(INT);
CREATE OR REPLACE FUNCTION bike_list(p_station_id INT)
RETURNS TABLE (out_bike_id INT, out_model VARCHAR) AS $$
BEGIN
    RETURN QUERY SELECT bike_id, model FROM bikes WHERE station_id = p_station_id;
END; $$ LANGUAGE plpgsql;

\echo '>>> 5.3 fix 1 (renamed output columns): SELECT * FROM bike_list(10);'
SELECT * FROM bike_list(10);

-- Fix 2: keep the names, qualify the table columns with an alias
DROP FUNCTION bike_list(INT);
CREATE OR REPLACE FUNCTION bike_list(p_station_id INT)
RETURNS TABLE (bike_id INT, model VARCHAR) AS $$
BEGIN
    RETURN QUERY SELECT b.bike_id, b.model FROM bikes b WHERE b.station_id = p_station_id;
END; $$ LANGUAGE plpgsql;

\echo '>>> 5.3 fix 2 (alias b): SELECT * FROM bike_list(10);'
SELECT * FROM bike_list(10);

-- Exercise 5.4: casting the output
-- First the BROKEN version (no casts):
CREATE OR REPLACE FUNCTION station_board(p_city VARCHAR)
RETURNS TABLE (s_name VARCHAR, s_bikes INT, s_free INT) AS $$
BEGIN
    RETURN QUERY
    SELECT s.station_name, COUNT(b.bike_id), s.capacity - COUNT(b.bike_id)
    FROM stations s
    LEFT JOIN bikes b ON b.station_id = s.station_id
    WHERE s.city = p_city
    GROUP BY s.station_id, s.station_name, s.capacity
    ORDER BY s.station_id;
END; $$ LANGUAGE plpgsql;

\echo '>>> 5.4: SELECT * FROM station_board(''Almaty'');   -- EXPECTED TO FAIL (no casts)'
SELECT * FROM station_board('Almaty');

-- Fixed version: explicit casts to INT (same signature, so CREATE OR REPLACE works)
CREATE OR REPLACE FUNCTION station_board(p_city VARCHAR)
RETURNS TABLE (s_name VARCHAR, s_bikes INT, s_free INT) AS $$
BEGIN
    RETURN QUERY
    SELECT s.station_name,
           COUNT(b.bike_id)::INT,
           (s.capacity - COUNT(b.bike_id))::INT
    FROM stations s
    LEFT JOIN bikes b ON b.station_id = s.station_id
    WHERE s.city = p_city
    GROUP BY s.station_id, s.station_name, s.capacity
    ORDER BY s.station_id;
END; $$ LANGUAGE plpgsql;

\echo '>>> 5.4 fixed: station_board(''Almaty'') and station_board(''Astana'')'
SELECT * FROM station_board('Almaty');
SELECT * FROM station_board('Astana');

-- ============================================================
-- PART 6: Blocks, DO and subblocks
-- ============================================================

-- Exercise 6.1: anonymous labelled block
\echo '>>> 6.1: rental_report block'
DO $$
<<rental_report>>
DECLARE
    total_rentals INTEGER := 0;
BEGIN
    SELECT COUNT(*) INTO total_rentals FROM rentals;
    RAISE NOTICE 'The rentals table holds % rows.', total_rentals;
END rental_report $$;

\echo '>>> 6.1: mismatching end label -- EXPECTED TO FAIL'
DO $$
<<rental_report>>
DECLARE
    total_rentals INTEGER := 0;
BEGIN
    SELECT COUNT(*) INTO total_rentals FROM rentals;
    RAISE NOTICE 'The rentals table holds % rows.', total_rentals;
END wrong_label $$;

-- Exercise 6.2: subblock and a hidden variable
\echo '>>> 6.2: shadowed variable'
DO $$
<<rental_report>>
DECLARE
    total_rentals INTEGER := 0;
    fee_total NUMERIC;
BEGIN
    SELECT COUNT(*) INTO total_rentals FROM rentals;
    RAISE NOTICE 'The rentals table holds % rows.', total_rentals;

    SELECT SUM(fee) INTO fee_total FROM rentals;
    RAISE NOTICE '1) outer fee_total before the subblock: %', fee_total;

    DECLARE
        fee_total NUMERIC;   -- hides the outer fee_total
    BEGIN
        SELECT SUM(fee) INTO fee_total FROM rentals WHERE start_date >= DATE '2025-01-01';
        RAISE NOTICE '2) subblock fee_total (since 2025-01-01): %', fee_total;
        RAISE NOTICE '3) outer fee_total through the label: %', rental_report.fee_total;
    END;

    RAISE NOTICE '4) outer fee_total after the subblock: %', fee_total;
END rental_report $$;

-- Exercise 6.3: declarations are local
\echo '>>> 6.3: second subblock reads a variable of the first -- EXPECTED TO FAIL'
DO $$
<<demo>>
BEGIN
    DECLARE
        sub1_total INTEGER;
    BEGIN
        SELECT COUNT(*) INTO sub1_total FROM rentals;
        RAISE NOTICE 'subblock 1 sees sub1_total = %', sub1_total;
    END;

    BEGIN
        RAISE NOTICE 'subblock 2 tries sub1_total = %', sub1_total;
    END;
END demo $$;

\echo '>>> 6.3 fixed: declaration moved up into the outer block'
DO $$
<<demo>>
DECLARE
    shared_total INTEGER;
BEGIN
    BEGIN
        SELECT COUNT(*) INTO shared_total FROM rentals;
        RAISE NOTICE 'subblock 1 sees shared_total = %', shared_total;
    END;

    BEGIN
        RAISE NOTICE 'subblock 2 sees shared_total = %', shared_total;
    END;
END demo $$;

-- Exercise 6.4: from block to function
CREATE OR REPLACE FUNCTION fee_split(
    p_from_date DATE,
    OUT before_total NUMERIC,
    OUT after_total NUMERIC)
AS $$
BEGIN
    SELECT COALESCE(SUM(fee) FILTER (WHERE start_date <  p_from_date), 0),
           COALESCE(SUM(fee) FILTER (WHERE start_date >= p_from_date), 0)
    INTO before_total, after_total
    FROM rentals;
END; $$ LANGUAGE plpgsql;

\echo '>>> 6.4: fee_split(2025-01-01) and a check against the whole table'
SELECT * FROM fee_split(DATE '2025-01-01');
SELECT before_total + after_total AS sum_of_parts,
       (SELECT SUM(fee) FROM rentals) AS whole_table
FROM fee_split(DATE '2025-01-01');

-- ============================================================
-- PART 7: Practical scenarios
-- ============================================================

-- Exercise 7.1: station occupancy (zero capacity -> NULL percentage)
CREATE OR REPLACE FUNCTION station_load(
    p_station_id INT,
    OUT bikes_parked INT,
    OUT capacity_pct NUMERIC)
AS $$
DECLARE
    cap INT;
BEGIN
    SELECT COUNT(*) INTO bikes_parked FROM bikes WHERE station_id = p_station_id;
    SELECT capacity INTO cap FROM stations WHERE station_id = p_station_id;
    capacity_pct := ROUND(100.0 * bikes_parked / NULLIF(cap, 0), 1);
END; $$ LANGUAGE plpgsql;

\echo '>>> 7.1: station_load for every station'
SELECT s.station_id, s.station_name, l.*
FROM stations s, LATERAL station_load(s.station_id) l
ORDER BY s.station_id;

-- Exercise 7.2: top members with a default
CREATE OR REPLACE FUNCTION top_members(p_limit INT DEFAULT 3)
RETURNS TABLE (m_name VARCHAR, rentals_cnt INT, total_spent NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT m.full_name,
           COUNT(r.rental_id)::INT,
           COALESCE(SUM(r.fee), 0)::NUMERIC
    FROM members m
    LEFT JOIN rentals r ON r.member_id = m.member_id
    GROUP BY m.member_id, m.full_name
    ORDER BY COALESCE(SUM(r.fee), 0) DESC, m.member_id
    LIMIT p_limit;
END; $$ LANGUAGE plpgsql;

\echo '>>> 7.2: SELECT * FROM top_members();'
SELECT * FROM top_members();
\echo '>>> 7.2: SELECT * FROM top_members(6);'
SELECT * FROM top_members(6);

-- Exercise 7.3: invoice, open rentals are charged up to CURRENT_DATE
CREATE OR REPLACE FUNCTION rental_invoice(p_rental_id INT)
RETURNS TABLE (inv_member VARCHAR, inv_model VARCHAR, inv_days INT,
               inv_amount NUMERIC, inv_status VARCHAR) AS $$
BEGIN
    RETURN QUERY
    SELECT m.full_name,
           b.model,
           (COALESCE(r.end_date, CURRENT_DATE) - r.start_date)::INT,
           ROUND((COALESCE(r.end_date, CURRENT_DATE) - r.start_date) * b.daily_rate, 2),
           (CASE WHEN r.end_date IS NULL THEN 'OPEN' ELSE 'CLOSED' END)::VARCHAR
    FROM rentals r
    JOIN members m ON m.member_id = r.member_id
    JOIN bikes   b ON b.bike_id   = r.bike_id
    WHERE r.rental_id = p_rental_id;
END; $$ LANGUAGE plpgsql STABLE;

\echo '>>> 7.3: rental_invoice(11) and rental_invoice(19)'
SELECT * FROM rental_invoice(11);
SELECT * FROM rental_invoice(19);
SELECT CURRENT_DATE AS run_date;
\echo '>>> 7.3: stored fee of rental 11 for comparison'
SELECT rental_id, fee FROM rentals WHERE rental_id = 11;

-- Exercise 7.4: city report + overload
CREATE OR REPLACE FUNCTION city_report(p_city VARCHAR)
RETURNS TABLE (member_cnt INT, rental_cnt INT, revenue NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT COUNT(DISTINCT m.member_id)::INT,
           COUNT(r.rental_id)::INT,
           COALESCE(SUM(r.fee), 0)::NUMERIC
    FROM members m
    LEFT JOIN rentals r ON r.member_id = m.member_id
    WHERE m.city = p_city;
END; $$ LANGUAGE plpgsql;

-- date condition in ON  (correct)
CREATE OR REPLACE FUNCTION city_report(p_city VARCHAR, p_from_date DATE)
RETURNS TABLE (member_cnt INT, rental_cnt INT, revenue NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT COUNT(DISTINCT m.member_id)::INT,
           COUNT(r.rental_id)::INT,
           COALESCE(SUM(r.fee), 0)::NUMERIC
    FROM members m
    LEFT JOIN rentals r ON r.member_id = m.member_id
                       AND r.start_date >= p_from_date
    WHERE m.city = p_city;
END; $$ LANGUAGE plpgsql;

-- date condition in WHERE (the experiment, kept under a different name)
CREATE OR REPLACE FUNCTION city_report_where_demo(p_city VARCHAR, p_from_date DATE)
RETURNS TABLE (member_cnt INT, rental_cnt INT, revenue NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT COUNT(DISTINCT m.member_id)::INT,
           COUNT(r.rental_id)::INT,
           COALESCE(SUM(r.fee), 0)::NUMERIC
    FROM members m
    LEFT JOIN rentals r ON r.member_id = m.member_id
    WHERE m.city = p_city AND r.start_date >= p_from_date;
END; $$ LANGUAGE plpgsql;

\echo '>>> 7.4: city_report(''Almaty'')'
SELECT * FROM city_report('Almaty');
\echo '>>> 7.4: city_report(''Almaty'', 2025-01-01)   -- condition in ON'
SELECT * FROM city_report('Almaty', DATE '2025-01-01');
\echo '>>> 7.4: same, condition in WHERE'
SELECT * FROM city_report_where_demo('Almaty', DATE '2025-01-01');
\echo '>>> 7.4: other cities'
SELECT 'Astana' AS city, * FROM city_report('Astana')
UNION ALL SELECT 'Shymkent', * FROM city_report('Shymkent');

-- ============================================================
-- Extra evidence used in the Lab Questions
-- ============================================================
\echo '>>> Q10: CREATE OR REPLACE with different argument types creates a NEW function'
CREATE OR REPLACE FUNCTION rental_days(p_rental_id BIGINT) RETURNS INT AS $$
BEGIN RETURN -1; END; $$ LANGUAGE plpgsql;
\df rental_days
SELECT rental_days(2) AS int_arg, rental_days(2::BIGINT) AS bigint_arg;
DROP FUNCTION rental_days(BIGINT);

\echo '>>> Q10b: CREATE OR REPLACE cannot change the return type'
CREATE OR REPLACE FUNCTION rental_days(p_rental_id INT) RETURNS TEXT AS $$
BEGIN RETURN 'x'; END; $$ LANGUAGE plpgsql;

\echo '>>> Q6: without DEFAULT in the 2-arg version the one-arg call was fine; with it, ambiguous (see 4.3)'
\echo '>>> Q12: the list of everything created'
\df
