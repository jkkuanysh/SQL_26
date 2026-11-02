-- =====================================================
-- Lab 6: SQL JOINs
-- DBMS: PostgreSQL 16
-- =====================================================

-- drop tables first so the script can be re-run from scratch
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS departments;
DROP TABLE IF EXISTS projects;


-- =====================================================
-- Part 1: Database Setup
-- =====================================================

-- 1.1 tables
CREATE TABLE employees (
    emp_id   INT PRIMARY KEY,
    emp_name VARCHAR(50),
    dept_id  INT,
    salary   DECIMAL(10, 2)
);

CREATE TABLE departments (
    dept_id   INT PRIMARY KEY,
    dept_name VARCHAR(50),
    location  VARCHAR(50)
);

CREATE TABLE projects (
    project_id   INT PRIMARY KEY,
    project_name VARCHAR(50),
    dept_id      INT,
    budget       DECIMAL(10, 2)
);

-- 1.2 sample data
INSERT INTO employees (emp_id, emp_name, dept_id, salary) VALUES
(1, 'John Smith', 101, 50000),
(2, 'Jane Doe', 102, 60000),
(3, 'Mike Johnson', 101, 55000),
(4, 'Sarah Williams', 103, 65000),
(5, 'Tom Brown', NULL, 45000);

INSERT INTO departments (dept_id, dept_name, location) VALUES
(101, 'IT', 'Building A'),
(102, 'HR', 'Building B'),
(103, 'Finance', 'Building C'),
(104, 'Marketing', 'Building D');

INSERT INTO projects (project_id, project_name, dept_id, budget) VALUES
(1, 'Website Redesign', 101, 100000),
(2, 'Employee Training', 102, 50000),
(3, 'Budget Analysis', 103, 75000),
(4, 'Cloud Migration', 101, 150000),
(5, 'AI Research', NULL, 200000);


-- =====================================================
-- Part 2: CROSS JOIN
-- =====================================================

-- 2.1 all combinations of employees and departments
SELECT e.emp_name, d.dept_name
FROM employees e
CROSS JOIN departments d;

-- Answer: 20 rows. N = 5 employees, M = 4 departments, 5 * 4 = 20.
-- Tom Brown is also here, because CROSS JOIN doesn't check any condition,
-- so NULL in dept_id doesn't matter.


-- 2.2 a) same thing with comma notation
SELECT e.emp_name, d.dept_name
FROM employees e, departments d;

-- 2.2 b) INNER JOIN with a condition that is always true
SELECT e.emp_name, d.dept_name
FROM employees e
INNER JOIN departments d ON TRUE;

-- both give the same 20 rows as 2.1


-- 2.3 availability matrix: every employee with every project
-- 5 employees * 5 projects = 25 rows
SELECT e.emp_name, p.project_name
FROM employees e
CROSS JOIN projects p
ORDER BY e.emp_name, p.project_name;


-- =====================================================
-- Part 3: INNER JOIN
-- =====================================================

-- 3.1 employees with their departments (only matched ones)
SELECT e.emp_name, d.dept_name, d.location
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id;

-- Answer: 4 rows. Tom Brown is not included because his dept_id is NULL.
-- NULL = 101 (or any other value) is not TRUE, it's UNKNOWN,
-- so the join condition never matches for him.


-- 3.2 same query with USING
SELECT emp_name, dept_name, location
FROM employees
INNER JOIN departments USING (dept_id);

-- Answer: with USING the join column dept_id appears only ONCE in the result
-- (it's merged into one column). With ON there are two separate columns,
-- e.dept_id and d.dept_id. You can see it with SELECT *:
--   ... JOIN ... ON    -> emp_id, emp_name, dept_id, salary, dept_id, dept_name, location (7 columns)
--   ... JOIN ... USING -> dept_id, emp_id, emp_name, salary, dept_name, location         (6 columns)
-- Also with USING we can write just dept_id without a table prefix.
-- In our query we select the same 3 columns, so the visible result is identical.


-- 3.3 NATURAL INNER JOIN
SELECT emp_name, dept_name, location
FROM employees
NATURAL INNER JOIN departments;

-- the only column with the same name in both tables is dept_id,
-- so it works exactly like USING (dept_id) -> same 4 rows


-- 3.4 employee + department + project (all three tables)
SELECT e.emp_name, d.dept_name, p.project_name
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
INNER JOIN projects p    ON d.dept_id = p.dept_id;

-- 6 rows: IT has 2 employees and 2 projects -> 2 * 2 = 4 rows,
-- HR 1 row, Finance 1 row. Tom (no dept), Marketing (no employees/projects)
-- and AI Research (no dept) are not in the result.


-- =====================================================
-- Part 4: LEFT JOIN
-- =====================================================

-- 4.1 all employees, even without a department
SELECT e.emp_name, e.dept_id AS emp_dept, d.dept_id AS dept_dept, d.dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id;

-- Answer: 5 rows. Tom Brown is shown, but emp_dept, dept_dept and dept_name
-- are all NULL for him (no matching row in departments, so the right side is filled with NULLs).


-- 4.2 same with USING
SELECT emp_name, dept_id, dept_name
FROM employees
LEFT JOIN departments USING (dept_id);

-- here there is only one dept_id column. Tom still has NULL in dept_id and dept_name.


-- 4.3 employees that are NOT in any department
SELECT e.emp_name, e.dept_id
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE d.dept_id IS NULL;

-- result: Tom Brown
-- (checking d.dept_id IS NULL is safe because dept_id is the primary key
--  of departments, so it can be NULL only when there was no match)


-- 4.4 number of employees in every department, including empty ones
SELECT d.dept_name, COUNT(e.emp_id) AS employee_count
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
ORDER BY employee_count DESC;

-- IT = 2, HR = 1, Finance = 1, Marketing = 0
-- important: COUNT(e.emp_id), not COUNT(*).
-- COUNT(*) would give 1 for Marketing, because the row with NULLs is still a row.


-- =====================================================
-- Part 5: RIGHT JOIN
-- =====================================================

-- 5.1 all departments with their employees
SELECT e.emp_name, d.dept_name
FROM employees e
RIGHT JOIN departments d ON e.dept_id = d.dept_id;

-- 5 rows: Marketing is shown with emp_name = NULL.
-- Tom Brown is not shown, because now the right table (departments) is the "main" one.


-- 5.2 same result with LEFT JOIN (just swap the tables)
SELECT e.emp_name, d.dept_name
FROM departments d
LEFT JOIN employees e ON e.dept_id = d.dept_id;


-- 5.3 departments without employees
SELECT d.dept_name, d.location
FROM employees e
RIGHT JOIN departments d ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL;

-- result: Marketing, Building D


-- =====================================================
-- Part 6: FULL JOIN
-- =====================================================

-- 6.1 all employees and all departments
SELECT e.emp_name, e.dept_id AS emp_dept, d.dept_id AS dept_dept, d.dept_name
FROM employees e
FULL JOIN departments d ON e.dept_id = d.dept_id;

-- Answer: 6 rows (4 matched + 1 + 1).
-- NULL on the LEFT side (employee columns): Marketing - no employees there.
-- NULL on the RIGHT side (department columns): Tom Brown - he has no department.


-- 6.2 all departments and all projects
SELECT d.dept_name, p.project_name, p.budget
FROM departments d
FULL JOIN projects p ON d.dept_id = p.dept_id;

-- 6 rows: IT twice (Website Redesign, Cloud Migration), HR, Finance,
-- Marketing with NULL project, and AI Research with NULL department.


-- 6.3 orphaned records from both sides
SELECT
    CASE
        WHEN e.emp_id IS NULL THEN 'Department without employees'
        WHEN d.dept_id IS NULL THEN 'Employee without department'
        ELSE 'Matched'
    END AS record_status,
    e.emp_name,
    d.dept_name
FROM employees e
FULL JOIN departments d ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL OR d.dept_id IS NULL;

-- result: Tom Brown (employee without department) and Marketing (department without employees).
-- 'Matched' never shows up here because of the WHERE filter.


-- =====================================================
-- Part 7: ON vs WHERE
-- =====================================================

-- 7.1 filter in ON (LEFT JOIN)
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id AND d.location = 'Building A';

-- 5 rows: all employees. Only John Smith and Mike Johnson get dept_name = 'IT',
-- everyone else has dept_name = NULL.


-- 7.2 filter in WHERE (LEFT JOIN)
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE d.location = 'Building A';

-- 2 rows: only John Smith and Mike Johnson.

-- Comparison:
-- In Query 1 the location check is part of the join condition. It only decides
-- WHICH department row gets matched to an employee. If nothing matches, LEFT JOIN
-- still keeps the employee and puts NULLs in the department columns.
-- So all 5 employees stay in the result.
-- In Query 2 the join is done first (all 5 employees), and then WHERE filters the
-- finished rows. For employees from Building B/C and for Tom, d.location is
-- 'Building B', 'Building C' or NULL, so the condition is not TRUE and these rows
-- are removed. Basically the LEFT JOIN turns into an INNER JOIN here.


-- 7.3 the same with INNER JOIN
-- filter in ON
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id AND d.location = 'Building A';

-- filter in WHERE
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
WHERE d.location = 'Building A';

-- Answer: no difference, both return the same 2 rows (John Smith, Mike Johnson).
-- INNER JOIN only keeps rows where the condition is TRUE and doesn't add any
-- NULL rows for unmatched records. So it doesn't matter if the condition is
-- checked during the join or after it - the rows that fail it are dropped anyway.


-- =====================================================
-- Part 8: Complex JOIN scenarios
-- =====================================================

-- 8.1 all departments + their employees (if any) + their projects (if any)
SELECT
    d.dept_name,
    e.emp_name,
    e.salary,
    p.project_name,
    p.budget
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
LEFT JOIN projects p  ON d.dept_id = p.dept_id
ORDER BY d.dept_name, e.emp_name;

-- 7 rows. Note: IT has 2 employees and 2 projects, so we get 2 * 2 = 4 rows for IT
-- (every employee is repeated with every project). Because of this you can't just
-- SUM(salary) or SUM(budget) on this result - the values would be counted twice.
-- Marketing is shown once with NULL employee and NULL project.


-- 8.2 self join: employees and their managers
ALTER TABLE employees ADD COLUMN manager_id INT;

UPDATE employees SET manager_id = 3    WHERE emp_id = 1;
UPDATE employees SET manager_id = 3    WHERE emp_id = 2;
UPDATE employees SET manager_id = NULL WHERE emp_id = 3;
UPDATE employees SET manager_id = 3    WHERE emp_id = 4;
UPDATE employees SET manager_id = 3    WHERE emp_id = 5;

SELECT
    e.emp_name AS employee,
    m.emp_name AS manager
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.emp_id;

-- Mike Johnson is the manager of everyone else. He doesn't have a manager himself,
-- so his manager column is NULL. LEFT JOIN is used so that Mike is not lost
-- (with INNER JOIN he would disappear from the result).


-- 8.3 departments where average salary > 50000
-- version with JOIN + GROUP BY + HAVING
SELECT d.dept_name, AVG(e.salary) AS avg_salary
FROM departments d
INNER JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
HAVING AVG(e.salary) > 50000;

-- version with a subquery (as in the exercise title):
-- first calculate averages in a subquery, then join it with departments
SELECT d.dept_name, s.avg_salary
FROM departments d
INNER JOIN (
    SELECT dept_id, AVG(salary) AS avg_salary
    FROM employees
    WHERE dept_id IS NOT NULL
    GROUP BY dept_id
) s ON d.dept_id = s.dept_id
WHERE s.avg_salary > 50000;

-- both return IT (52500), HR (60000), Finance (65000).
-- Marketing is not there because it has no employees, so there is no average.


-- =====================================================
-- Lab Questions
-- =====================================================

-- 1. What is the difference between INNER JOIN and LEFT JOIN?
--    INNER JOIN returns only rows that have a match in both tables.
--    LEFT JOIN returns all rows from the left table; if there is no match,
--    the columns from the right table are NULL.
--    Example: Tom Brown is in the LEFT JOIN result (4.1) but not in the INNER JOIN result (3.1).

-- 2. When would you use CROSS JOIN in a practical scenario?
--    When you really need all combinations: e.g. an availability matrix
--    (employees x projects like in 2.3), a schedule (all employees x all days),
--    all sizes x all colors of a product, or to generate a full grid for a report
--    and then LEFT JOIN real data onto it to see the gaps.

-- 3. Why does ON vs WHERE matter for outer joins but not for inner joins?
--    In an outer join the ON condition only controls matching - unmatched rows
--    from the preserved table are still kept (with NULLs). WHERE runs after the
--    join and removes rows, including those NULL-filled ones.
--    In an inner join unmatched rows are never kept, so a condition in ON or
--    in WHERE removes exactly the same rows -> same result.

-- 4. COUNT(*) from table1 CROSS JOIN table2 (5 rows and 10 rows)?
--    5 * 10 = 50.

-- 5. How does NATURAL JOIN determine which columns to join on?
--    It automatically uses ALL columns that have the same name in both tables
--    and compares them with equality (like USING with all common column names).
--    If there are no common columns, it works like a CROSS JOIN.

-- 6. Risks of NATURAL JOIN:
--    - the join depends only on column names, not on meaning. Columns like
--      "name", "id", "created_at" can match by accident and give wrong/empty results;
--    - if someone later adds a column with the same name to one of the tables
--      (ALTER TABLE), the query silently changes its behaviour without any error;
--    - if there are no common columns, it silently becomes a CROSS JOIN;
--    - it's harder to read, because the join condition isn't written anywhere.
--    So it's better to use ON or USING with explicit columns.

-- 7. Convert to RIGHT JOIN:  SELECT * FROM A LEFT JOIN B ON A.id = B.id
--    SELECT * FROM B RIGHT JOIN A ON A.id = B.id;
--    The rows are the same; only the column order with SELECT * is different
--    (B's columns come first). To get identical output, list the columns:
--    SELECT A.*, B.* FROM B RIGHT JOIN A ON A.id = B.id;

-- 8. When should you use FULL OUTER JOIN?
--    When you need all rows from both tables and want to see what doesn't match
--    on either side. For example: comparing/reconciling two lists (data sync,
--    checking two systems), or finding orphaned records on both sides at once
--    like in 6.3.


-- =====================================================
-- Additional Challenges (optional)
-- =====================================================

-- 1. FULL OUTER JOIN without FULL JOIN
--    LEFT JOIN gives all employees (matched + unmatched),
--    then we add only the departments that had no employees.
--    UNION ALL + WHERE e.emp_id IS NULL is used instead of plain UNION,
--    because UNION removes duplicates and could also remove real duplicate rows.
SELECT e.emp_name, d.dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
UNION ALL
SELECT e.emp_name, d.dept_name
FROM employees e
RIGHT JOIN departments d ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL;

-- gives the same 6 rows as 6.1


-- 2. employees who work in departments with more than one project
SELECT e.emp_name, d.dept_name
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
WHERE e.dept_id IN (
    SELECT dept_id
    FROM projects
    WHERE dept_id IS NOT NULL
    GROUP BY dept_id
    HAVING COUNT(*) > 1
);

-- result: John Smith and Mike Johnson (IT has 2 projects)


-- 3. full org structure (employee -> manager -> manager's manager -> ...)
--    with a recursive CTE, so it works for any number of levels
WITH RECURSIVE org AS (
    -- top level: people without a manager
    SELECT emp_id,
           emp_name,
           manager_id,
           1 AS level,
           emp_name::TEXT AS chain
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    -- next level: people whose manager is already in org
    SELECT e.emp_id,
           e.emp_name,
           e.manager_id,
           o.level + 1,
           e.emp_name || ' -> ' || o.chain
    FROM employees e
    INNER JOIN org o ON e.manager_id = o.emp_id
)
SELECT level, emp_name, chain
FROM org
ORDER BY level, emp_name;

-- same idea with plain self joins (fixed depth, 3 levels):
SELECT e.emp_name  AS employee,
       m1.emp_name AS manager,
       m2.emp_name AS managers_manager
FROM employees e
LEFT JOIN employees m1 ON e.manager_id  = m1.emp_id
LEFT JOIN employees m2 ON m1.manager_id = m2.emp_id;


-- 4. all pairs of employees from the same department
--    e1.emp_id < e2.emp_id removes pairs with yourself and mirrored duplicates
--    (John-Mike and Mike-John would otherwise be 2 rows)
SELECT e1.emp_name AS employee_1,
       e2.emp_name AS employee_2,
       d.dept_name
FROM employees e1
INNER JOIN employees e2  ON e1.dept_id = e2.dept_id
                        AND e1.emp_id  < e2.emp_id
INNER JOIN departments d ON d.dept_id = e1.dept_id;

-- result: John Smith - Mike Johnson (IT). Tom is never paired because NULL = NULL is not TRUE.
