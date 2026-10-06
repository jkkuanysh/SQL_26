-- ==========================================
-- Laboratory Work 4: SQL Queries, Functions, and Operators
-- Database Schema Setup & Sample Data
-- ==========================================

-- Create tables
CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    department VARCHAR(50),
    salary NUMERIC(10,2),
    hire_date DATE,
    manager_id INTEGER,
    email VARCHAR(100)
);

CREATE TABLE projects (
    project_id SERIAL PRIMARY KEY,
    project_name VARCHAR(100),
    budget NUMERIC(12,2),
    start_date DATE,
    end_date DATE,
    status VARCHAR(20)
);

CREATE TABLE assignments (
    assignment_id SERIAL PRIMARY KEY,
    employee_id INTEGER REFERENCES employees(employee_id),
    project_id INTEGER REFERENCES projects(project_id),
    hours_worked NUMERIC(5,1),
    assignment_date DATE
);

-- Insert sample data
INSERT INTO employees (first_name, last_name, department, salary, hire_date, manager_id, email) VALUES
('John', 'Smith', 'IT', 75000, '2020-01-15', NULL, 'john.smith@company.com'),
('Sarah', 'Johnson', 'IT', 65000, '2020-03-20', 1, 'sarah.j@company.com'),
('Michael', 'Brown', 'Sales', 55000, '2019-06-10', NULL, 'mbrown@company.com'),
('Emily', 'Davis', 'HR', 60000, '2021-02-01', NULL, 'emily.davis@company.com'),
('Robert', 'Wilson', 'IT', 70000, '2020-08-15', 1, NULL),
('Lisa', 'Anderson', 'Sales', 58000, '2021-05-20', 3, 'lisa.a@company.com');

INSERT INTO projects (project_name, budget, start_date, end_date, status) VALUES
('Website Redesign', 150000, '2024-01-01', '2024-06-30', 'Active'),
('CRM Implementation', 200000, '2024-02-15', '2024-12-31', 'Active'),
('Marketing Campaign', 80000, '2024-03-01', '2024-05-31', 'Completed'),
('Database Migration', 120000, '2024-01-10', NULL, 'Active');

INSERT INTO assignments (employee_id, project_id, hours_worked, assignment_date) VALUES
(1, 1, 120.5, '2024-01-15'),
(2, 1, 95.0, '2024-01-20'),
(1, 4, 80.0, '2024-02-01'),
(3, 3, 60.0, '2024-03-05'),
(5, 2, 110.0, '2024-02-20'),
(6, 3, 75.5, '2024-03-10');


-- ==========================================
-- Part 1: Basic SELECT Queries
-- ==========================================

-- Task 1.1: Select all employees, displaying their full name, department, and salary.
SELECT
    first_name || ' ' || last_name AS full_name,
    department,
    salary
FROM employees;

-- Task 1.2: Use SELECT DISTINCT to find all unique departments in the company.
SELECT DISTINCT department
FROM employees;

-- Task 1.3: Select all projects with names, budgets, and a categorized budget status.
SELECT
    project_name,
    budget,
    CASE
        WHEN budget > 150000 THEN 'Large'
        WHEN budget BETWEEN 100000 AND 150000 THEN 'Medium'
        ELSE 'Small'
    END AS budget_category
FROM projects;

-- Task 1.4: Use COALESCE to display employee names and their emails or a fallback string.
SELECT
    first_name || ' ' || last_name AS employee_name,
    COALESCE(email, 'No email provided') AS email
FROM employees;


-- ==========================================
-- Part 2: WHERE Clause and Comparison Operators
-- ==========================================

-- Task 2.1: Find all employees hired after January 1, 2020.
SELECT *
FROM employees
WHERE hire_date > '2020-01-01';

-- Task 2.2: Find all employees whose salary is between 60000 and 70000.
SELECT *
FROM employees
WHERE salary BETWEEN 60000 AND 70000;

-- Task 2.3: Find all employees whose last name starts with 'S' or 'J'.
SELECT *
FROM employees
WHERE last_name LIKE 'S%' OR last_name LIKE 'J%';

-- Task 2.4: Find employees who have a manager and work in the IT department.
SELECT *
FROM employees
WHERE manager_id IS NOT NULL
  AND department = 'IT';


-- ==========================================
-- Part 3: String and Mathematical Functions
-- ==========================================

-- Task 3.1: Uppercase names, last name lengths, and first 3 characters of email.
SELECT
    UPPER(first_name || ' ' || last_name) AS uppercase_name,
    LENGTH(last_name) AS last_name_length,
    SUBSTRING(email FROM 1 FOR 3) AS email_prefix
FROM employees;

-- Task 3.2: Annual salary, rounded monthly salary, and 10% raise amount.
SELECT
    first_name,
    last_name,
    salary AS annual_salary,
    ROUND(salary / 12, 2) AS monthly_salary,
    salary * 0.10 AS raise_amount
FROM employees;

-- Task 3.3: Use the format() function to create a formatted string for each project.
SELECT
    format('Project: %s - Budget: $%s - Status: %s', project_name, budget, status) AS project_report
FROM projects;

-- Task 3.4: Calculate years of service for each employee.
SELECT
    first_name,
    last_name,
    hire_date,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, hire_date)) AS years_with_company
FROM employees;


-- ==========================================
-- Part 4: Aggregate Functions and GROUP BY
-- ==========================================

-- Task 4.1: Calculate the average salary for each department.
SELECT
    department,
    AVG(salary) AS avg_salary
FROM employees
GROUP BY department;

-- Task 4.2: Find total hours worked on each project, including project name.
SELECT
    p.project_name,
    SUM(a.hours_worked) AS total_hours
FROM projects p
LEFT JOIN assignments a ON p.project_id = a.project_id
GROUP BY p.project_id, p.project_name;

-- Task 4.3: Count number of employees in each department (departments with > 1 employee).
SELECT
    department,
    COUNT(*) AS employee_count
FROM employees
GROUP BY department
HAVING COUNT(*) > 1;

-- Task 4.4: Maximum salary, minimum salary, and total payroll.
SELECT
    MAX(salary) AS max_salary,
    MIN(salary) AS min_salary,
    SUM(salary) AS total_payroll
FROM employees;


-- ==========================================
-- Part 5: Set Operations
-- ==========================================

-- Task 5.1: Combine employees with salary > 65000 and those hired after 2020-01-01 using UNION.
SELECT employee_id, first_name || ' ' || last_name AS full_name, salary
FROM employees
WHERE salary > 65000
UNION
SELECT employee_id, first_name || ' ' || last_name AS full_name, salary
FROM employees
WHERE hire_date > '2020-01-01';

-- Task 5.2: Use INTERSECT to find employees in IT with a salary > 65000.
SELECT employee_id, first_name, last_name, department, salary
FROM employees
WHERE department = 'IT'
INTERSECT
SELECT employee_id, first_name, last_name, department, salary
FROM employees
WHERE salary > 65000;

-- Task 5.3: Use EXCEPT to find employees who are NOT assigned to any project.
SELECT employee_id, first_name, last_name
FROM employees
EXCEPT
SELECT e.employee_id, e.first_name, e.last_name
FROM employees e
JOIN assignments a ON e.employee_id = a.employee_id;


-- ==========================================
-- Part 6: Subqueries
-- ==========================================

-- Task 6.1: Use EXISTS to find employees with at least one project assignment.
SELECT *
FROM employees e
WHERE EXISTS (
    SELECT 1
    FROM assignments a
    WHERE a.employee_id = e.employee_id
);

-- Task 6.2: Use IN with a subquery to find employees working on 'Active' projects.
SELECT *
FROM employees
WHERE employee_id IN (
    SELECT a.employee_id
    FROM assignments a
    JOIN projects p ON a.project_id = p.project_id
    WHERE p.status = 'Active'
);

-- Task 6.3: Use ANY to find employees whose salary is greater than ANY employee in Sales.
SELECT *
FROM employees
WHERE salary > ANY (
    SELECT salary
    FROM employees
    WHERE department = 'Sales'
);


-- ==========================================
-- Part 7: Complex Queries
-- ==========================================

-- Task 7.1: Employee name, department, average hours worked, and department salary rank.
SELECT
    e.first_name || ' ' || last_name AS employee_name,
    e.department,
    COALESCE(AVG(a.hours_worked), 0) AS avg_hours_worked,
    (SELECT COUNT(*)
     FROM employees e2
     WHERE e2.department = e.department AND e2.salary >= e.salary) AS salary_rank
FROM employees e
LEFT JOIN assignments a ON e.employee_id = a.employee_id
GROUP BY e.employee_id, e.first_name, e.last_name, e.department, e.salary;

-- Task 7.2: Projects where total hours worked > 150 hours.
SELECT
    p.project_name,
    SUM(a.hours_worked) AS total_hours,
    COUNT(DISTINCT a.employee_id) AS employees_assigned_count
FROM projects p
JOIN assignments a ON p.project_id = a.project_id
GROUP BY p.project_id, p.project_name
HAVING SUM(a.hours_worked) > 150;

-- Task 7.3: Department report with total employees, average salary, highest paid employee, and GREATEST/LEAST usage.
SELECT
    department,
    COUNT(*) AS total_employees,
    ROUND(AVG(salary), 2) AS average_salary,
    (SELECT first_name || ' ' || last_name
     FROM employees e2
     WHERE e2.department = employees.department
     ORDER BY salary DESC LIMIT 1) AS highest_paid_employee,
    GREATEST(MAX(salary), 100000.00) AS comparison_max_benchmark,
    LEAST(MIN(salary), 50000.00) AS comparison_min_benchmark
FROM employees
GROUP BY department;