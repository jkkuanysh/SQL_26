-- =====================================================================
-- Laboratory Work #3: DML Operations
-
-- Student:Zhambyl_Kuanysh   Student ID: 25B031250

-- =====================================================================

-- ---------------------------------------------------------------------
-- PART A: DATABASE AND TABLE SETUP
-- ---------------------------------------------------------------------

-- 1. Create database and tables
DROP DATABASE IF EXISTS advanced_lab;
CREATE DATABASE advanced_lab;
\c advanced_lab

CREATE TABLE employees (
    emp_id      SERIAL PRIMARY KEY,            -- auto increment
    first_name  VARCHAR(50),
    last_name   VARCHAR(50),
    department  VARCHAR(50) DEFAULT 'General', -- default used in Task 10
    salary      INTEGER     DEFAULT 40000,     -- default used in Task 3
    hire_date   DATE,
    status      VARCHAR(20) DEFAULT 'Active'
);

CREATE TABLE departments (
    dept_id     SERIAL PRIMARY KEY,
    dept_name   VARCHAR(50),
    budget      INTEGER,
    manager_id  INTEGER
);

CREATE TABLE projects (
    project_id   SERIAL PRIMARY KEY,
    project_name VARCHAR(100),
    dept_id      INTEGER,
    start_date   DATE,
    end_date     DATE,
    budget       INTEGER
);

-- Sample data used to test the queries below
INSERT INTO departments (dept_name, budget, manager_id) VALUES
    ('IT',      150000, 1),
    ('Sales',    90000, 5),
    ('HR',       60000, 6),
    ('Finance', 120000, 7);

INSERT INTO employees (first_name, last_name, department, salary, hire_date, status) VALUES
    ('Aibek',   'Nurlanov',   'IT',      85000, '2018-03-15', 'Active'),
    ('Dana',    'Seitkali',   'IT',      62000, '2019-07-01', 'Active'),
    ('Arman',   'Zhumabayev', 'IT',      55000, '2021-02-10', 'Active'),
    ('Aliya',   'Bekova',     'Sales',   48000, '2022-05-20', 'Active'),
    ('Nurlan',  'Omarov',     'Sales',   70000, '2017-11-05', 'Active'),
    ('Madina',  'Karimova',   'HR',      45000, '2021-09-12', 'Inactive'),
    ('Yerlan',  'Tokayev',    'Finance', 95000, '2016-01-20', 'Active'),
    ('Saule',   'Akhmetova',  'Finance', 52000, '2023-03-01', 'Terminated'),
    ('Timur',   'Ospanov',    NULL,      35000, '2023-06-15', 'Active'),
    ('Aigerim', 'Sadykova',   'Sales',   39000, '2024-01-10', 'Inactive'),
    ('Bolat',   'Serikov',    'IT',      58000, '2022-08-01', 'Active');

INSERT INTO projects (project_name, dept_id, start_date, end_date, budget) VALUES
    ('Website Redesign', 1, '2022-01-10', '2022-12-31',  70000),
    ('ERP Migration',    1, '2023-02-01', '2024-06-30', 120000),
    ('CRM Rollout',      2, '2023-05-01', '2024-03-31',  60000),
    ('Payroll Audit',    4, '2021-01-01', '2022-06-30',  30000),
    ('Mobile App',       1, '2024-01-15', '2025-01-15',  45000),
    ('Market Research',  2, '2024-02-01', '2024-12-31',  55000);

-- ---------------------------------------------------------------------
-- PART B: ADVANCED INSERT OPERATIONS
-- ---------------------------------------------------------------------

-- 2. INSERT with column specification (only emp_id, first_name, last_name, department)
--    Unlisted columns get their DEFAULT (salary, status) or NULL (hire_date).
INSERT INTO employees (emp_id, first_name, last_name, department)
VALUES (100, 'Erzhan', 'Abenov', 'IT');

-- An explicit emp_id bypasses the sequence, so move the sequence past it
-- to avoid duplicate-key errors on the next auto-generated id.
SELECT setval('employees_emp_id_seq', (SELECT MAX(emp_id) FROM employees));

-- 3. INSERT with DEFAULT values for salary and status
INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('Gulnara', 'Ismailova', 'Sales', DEFAULT, '2022-11-01', DEFAULT);

-- 4. INSERT multiple rows in a single statement (3 departments)
INSERT INTO departments (dept_name, budget, manager_id) VALUES
    ('Marketing', 80000, NULL),
    ('Research',  70000, NULL),
    ('Legal',     50000, NULL);

-- 5. INSERT with expressions: hire_date = current date, salary = 50000 * 1.1
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Askar', 'Mukanov', 'IT', 50000 * 1.1, CURRENT_DATE);   -- salary = 55000

-- 6. INSERT from SELECT: temporary table with IT employees
CREATE TEMPORARY TABLE temp_employees (LIKE employees);

INSERT INTO temp_employees
SELECT * FROM employees
WHERE department = 'IT';

SELECT * FROM temp_employees ORDER BY emp_id;

-- ---------------------------------------------------------------------
-- PART C: COMPLEX UPDATE OPERATIONS
-- ---------------------------------------------------------------------

-- 7. UPDATE with arithmetic expression: +10% to all salaries
UPDATE employees
SET salary = salary * 1.10;

-- 8. UPDATE with WHERE and multiple conditions
UPDATE employees
SET status = 'Senior'
WHERE salary > 60000
  AND hire_date < '2020-01-01';

-- 9. UPDATE using CASE expression
--    This overwrites every department name. It is run inside a
--    transaction and rolled back so that the later tasks (which need
--    'IT' and 'Sales') still have meaningful data. Remove BEGIN/ROLLBACK
--    to make the change permanent.
BEGIN;
UPDATE employees
SET department = CASE
                     WHEN salary > 80000                 THEN 'Management'
                     WHEN salary BETWEEN 50000 AND 80000 THEN 'Senior'
                     ELSE 'Junior'
                 END
RETURNING emp_id, first_name, salary, department;
ROLLBACK;

-- 10. UPDATE with DEFAULT: department back to its default ('General')
--     for inactive employees
UPDATE employees
SET department = DEFAULT
WHERE status = 'Inactive';

-- 11. UPDATE with subquery: department budget = average salary of the
--     department's employees + 20%. Employees store the department name,
--     so the match is on dept_name. EXISTS skips departments with no
--     employees (otherwise their budget would become NULL).
UPDATE departments d
SET budget = (SELECT AVG(e.salary) * 1.20
              FROM employees e
              WHERE e.department = d.dept_name)
WHERE EXISTS (SELECT 1 FROM employees e WHERE e.department = d.dept_name);

-- 12. UPDATE multiple columns in one statement
UPDATE employees
SET salary = salary * 1.15,
    status = 'Promoted'
WHERE department = 'Sales';

-- ---------------------------------------------------------------------
-- PART D: ADVANCED DELETE OPERATIONS
-- ---------------------------------------------------------------------

-- 13. DELETE with simple WHERE
DELETE FROM employees
WHERE status = 'Terminated';

-- 14. DELETE with complex WHERE
DELETE FROM employees
WHERE salary < 40000
  AND hire_date > '2023-01-01'
  AND department IS NULL;

-- 15. DELETE with subquery: departments that no employee belongs to.
--     NOTE: the task text compares dept_id with employees.department, but
--     dept_id is INTEGER and department is a VARCHAR name, so PostgreSQL
--     would raise a type error. The correct comparison is on dept_name.
--     "department IS NOT NULL" matters: NOT IN with a NULL in the list
--     returns no rows at all.
DELETE FROM departments
WHERE dept_name NOT IN (SELECT DISTINCT department
                        FROM employees
                        WHERE department IS NOT NULL)
RETURNING *;

-- 16. DELETE with RETURNING: projects that ended before 2023
DELETE FROM projects
WHERE end_date < '2023-01-01'
RETURNING *;

-- ---------------------------------------------------------------------
-- PART E: OPERATIONS WITH NULL VALUES
-- ---------------------------------------------------------------------

-- 17. INSERT with NULL salary and NULL department
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Kairat', 'Bekmukhambetov', NULL, NULL, '2024-04-01');

-- 18. UPDATE NULL handling (use IS NULL, never "= NULL")
UPDATE employees
SET department = 'Unassigned'
WHERE department IS NULL;

-- 19. DELETE with NULL conditions
DELETE FROM employees
WHERE salary IS NULL
   OR department IS NULL
RETURNING emp_id, first_name, last_name;

-- ---------------------------------------------------------------------
-- PART F: RETURNING CLAUSE OPERATIONS
-- ---------------------------------------------------------------------

-- 20. INSERT with RETURNING: generated id and full name
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Zhanna', 'Utepova', 'IT', 60000, '2023-09-01')
RETURNING emp_id, first_name || ' ' || last_name AS full_name;

-- 21. UPDATE with RETURNING: old and new salary for IT (+5000)
--     RETURNING shows the row after the update, so the old salary is
--     computed back as (salary - 5000).
UPDATE employees
SET salary = salary + 5000
WHERE department = 'IT'
RETURNING emp_id, salary - 5000 AS old_salary, salary AS new_salary;

-- 22. DELETE with RETURNING all columns: hired before 2020
DELETE FROM employees
WHERE hire_date < '2020-01-01'
RETURNING *;

-- ---------------------------------------------------------------------
-- PART G: ADVANCED DML PATTERNS
-- ---------------------------------------------------------------------

-- 23. Conditional INSERT (only if same first + last name does not exist)
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
SELECT 'Ruslan', 'Kassymov', 'Sales', 52000, '2023-02-15'
WHERE NOT EXISTS (SELECT 1 FROM employees
                  WHERE first_name = 'Ruslan' AND last_name = 'Kassymov');
-- Running the same statement again inserts 0 rows (duplicate prevented):
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
SELECT 'Ruslan', 'Kassymov', 'Sales', 52000, '2023-02-15'
WHERE NOT EXISTS (SELECT 1 FROM employees
                  WHERE first_name = 'Ruslan' AND last_name = 'Kassymov');

-- 24. UPDATE with "join" logic via a correlated subquery:
--     department budget > 100000 -> +10%, otherwise +5%
UPDATE employees e
SET salary = CASE
                 WHEN (SELECT d.budget FROM departments d
                       WHERE d.dept_name = e.department) > 100000
                 THEN salary * 1.10
                 ELSE salary * 1.05
             END;

-- 25. Bulk operations: 5 employees in one INSERT, then +10% in one UPDATE
INSERT INTO employees (first_name, last_name, department, salary, hire_date) VALUES
    ('Daniyar', 'Alimov',    'IT', 45000, '2024-02-01'),
    ('Kamila',  'Zhakupova', 'IT', 47000, '2024-02-01'),
    ('Marat',   'Tulegenov', 'IT', 49000, '2024-02-01'),
    ('Assel',   'Nurmagam',  'IT', 51000, '2024-02-01'),
    ('Olzhas',  'Baimukhan', 'IT', 53000, '2024-02-01');

UPDATE employees
SET salary = salary * 1.10
WHERE last_name IN ('Alimov', 'Zhakupova', 'Tulegenov', 'Nurmagam', 'Baimukhan');

-- 26. Data migration: move inactive employees to an archive table.
--     Done in one transaction so rows are never lost or duplicated.
CREATE TABLE employee_archive (LIKE employees INCLUDING DEFAULTS);

BEGIN;
INSERT INTO employee_archive
SELECT * FROM employees
WHERE status = 'Inactive';

DELETE FROM employees
WHERE status = 'Inactive';
COMMIT;

SELECT * FROM employee_archive;

-- 27. Complex business logic: extend end_date by 30 days for projects
--     with budget > 50000 whose department has more than 3 employees.
UPDATE projects p
SET end_date = end_date + INTERVAL '30 days'
WHERE p.budget > 50000
  AND (SELECT COUNT(*)
       FROM employees e
       JOIN departments d ON d.dept_name = e.department
       WHERE d.dept_id = p.dept_id) > 3
RETURNING *;

-- Final state check
SELECT * FROM employees   ORDER BY emp_id;
SELECT * FROM departments ORDER BY dept_id;
SELECT * FROM projects    ORDER BY project_id;

-- =====================================================================
-- END OF LAB 3
-- =====================================================================
