-- =====================================================================
-- Laboratory Work #2: Advanced DDL Operations
-- Topic: Database Creation, Table Management & Data Types
-- File:  lab2_advanced_ddl.sql
-- Student: ______________________   Student ID: ______________
-- DBMS:  PostgreSQL (run with psql:  psql -U postgres -f lab2_advanced_ddl.sql)
-- =====================================================================

-- ---------------------------------------------------------------------
-- PART 1: MULTIPLE DATABASE MANAGEMENT
-- ---------------------------------------------------------------------

-- Task 1.1: Database Creation with Parameters

-- 1. university_main: owner = current user, template0, UTF8
--    (CREATE DATABASE does not accept the CURRENT_USER keyword, so the
--     psql variable :"USER" is used - it holds the connected user's name.
--     In pgAdmin replace :"USER" with your role name, e.g. postgres.)
CREATE DATABASE university_main
    OWNER = :"USER"
    TEMPLATE = template0
    ENCODING = 'UTF8';

-- 2. university_archive: connection limit 50, template0
CREATE DATABASE university_archive
    TEMPLATE = template0
    CONNECTION LIMIT = 50;

-- 3. university_test: template database, connection limit 10
CREATE DATABASE university_test
    IS_TEMPLATE = true
    CONNECTION LIMIT = 10;

-- Task 1.2: Tablespace Operations
-- NOTE: the directories must exist on the server and be owned by the
-- postgres OS user before running, e.g.:
--   sudo mkdir -p /data/students /data/courses
--   sudo chown postgres:postgres /data/students /data/courses

-- 1. Tablespace student_data
CREATE TABLESPACE student_data
    LOCATION '/data/students';

-- 2. Tablespace course_data, owner = current user
CREATE TABLESPACE course_data
    OWNER CURRENT_USER
    LOCATION '/data/courses';

-- 3. university_distributed: tablespace student_data, encoding LATIN9
--    (LATIN9 requires template0 and a compatible locale, so 'C' is used)
CREATE DATABASE university_distributed
    TEMPLATE = template0
    TABLESPACE = student_data
    ENCODING = 'LATIN9'
    LC_COLLATE = 'C'
    LC_CTYPE = 'C';

-- ---------------------------------------------------------------------
-- PART 2: COMPLEX TABLE CREATION (inside university_main)
-- ---------------------------------------------------------------------
\c university_main

-- Task 2.1: University Management System

CREATE TABLE students (
    student_id       SERIAL PRIMARY KEY,
    first_name       VARCHAR(50),
    last_name        VARCHAR(50),
    email            VARCHAR(100),
    phone            CHAR(15),
    date_of_birth    DATE,
    enrollment_date  DATE,
    gpa              NUMERIC(3,2),      -- e.g. 3.75
    is_active        BOOLEAN,
    graduation_year  SMALLINT
);

CREATE TABLE professors (
    professor_id     SERIAL PRIMARY KEY,
    first_name       VARCHAR(50),
    last_name        VARCHAR(50),
    email            VARCHAR(100),
    office_number    VARCHAR(20),
    hire_date        DATE,
    salary           NUMERIC(12,2),     -- large decimal, 2 decimal places
    is_tenured       BOOLEAN,
    years_experience INTEGER
);

CREATE TABLE courses (
    course_id        SERIAL PRIMARY KEY,
    course_code      CHAR(8),
    course_title     VARCHAR(100),
    description      TEXT,
    credits          SMALLINT,
    max_enrollment   INTEGER,
    course_fee       NUMERIC(10,2),
    is_online        BOOLEAN,
    created_at       TIMESTAMP WITHOUT TIME ZONE
);

-- Task 2.2: Time-based and Specialized Tables

CREATE TABLE class_schedule (
    schedule_id      SERIAL PRIMARY KEY,
    course_id        INTEGER,
    professor_id     INTEGER,
    classroom        VARCHAR(20),
    class_date       DATE,
    start_time       TIME WITHOUT TIME ZONE,
    end_time         TIME WITHOUT TIME ZONE,
    duration         INTERVAL
);

CREATE TABLE student_records (
    record_id             SERIAL PRIMARY KEY,
    student_id            INTEGER,
    course_id             INTEGER,
    semester              VARCHAR(20),
    year                  INTEGER,
    grade                 CHAR(2),
    attendance_percentage NUMERIC(4,1),   -- e.g. 100.0
    submission_timestamp  TIMESTAMP WITH TIME ZONE,
    last_updated          TIMESTAMP WITH TIME ZONE
);

-- ---------------------------------------------------------------------
-- PART 3: ADVANCED ALTER TABLE OPERATIONS
-- ---------------------------------------------------------------------

-- Task 3.1: Modifying Existing Tables

-- students
ALTER TABLE students ADD COLUMN middle_name VARCHAR(30);
ALTER TABLE students ADD COLUMN student_status VARCHAR(20);
ALTER TABLE students ALTER COLUMN phone TYPE VARCHAR(20);
ALTER TABLE students ALTER COLUMN student_status SET DEFAULT 'ACTIVE';
ALTER TABLE students ALTER COLUMN gpa SET DEFAULT 0.00;

-- professors
ALTER TABLE professors ADD COLUMN department_code CHAR(5);
ALTER TABLE professors ADD COLUMN research_area TEXT;
ALTER TABLE professors ALTER COLUMN years_experience TYPE SMALLINT;
ALTER TABLE professors ALTER COLUMN is_tenured SET DEFAULT false;
ALTER TABLE professors ADD COLUMN last_promotion_date DATE;

-- courses
ALTER TABLE courses ADD COLUMN prerequisite_course_id INTEGER;
ALTER TABLE courses ADD COLUMN difficulty_level SMALLINT;
ALTER TABLE courses ALTER COLUMN course_code TYPE VARCHAR(10);
ALTER TABLE courses ALTER COLUMN credits SET DEFAULT 3;
ALTER TABLE courses ADD COLUMN lab_required BOOLEAN DEFAULT false;

-- Task 3.2: Column Management Operations

-- class_schedule
ALTER TABLE class_schedule ADD COLUMN room_capacity INTEGER;
ALTER TABLE class_schedule DROP COLUMN duration;
ALTER TABLE class_schedule ADD COLUMN session_type VARCHAR(15);
ALTER TABLE class_schedule ALTER COLUMN classroom TYPE VARCHAR(30);
ALTER TABLE class_schedule ADD COLUMN equipment_needed TEXT;

-- student_records
ALTER TABLE student_records ADD COLUMN extra_credit_points NUMERIC(4,1);
ALTER TABLE student_records ALTER COLUMN grade TYPE VARCHAR(5);
ALTER TABLE student_records ALTER COLUMN extra_credit_points SET DEFAULT 0.0;
ALTER TABLE student_records ADD COLUMN final_exam_date DATE;
ALTER TABLE student_records DROP COLUMN last_updated;

-- ---------------------------------------------------------------------
-- PART 4: TABLE RELATIONSHIPS AND MANAGEMENT
-- ---------------------------------------------------------------------

-- Task 4.1: Additional Supporting Tables

CREATE TABLE departments (
    department_id    SERIAL PRIMARY KEY,
    department_name  VARCHAR(100),
    department_code  CHAR(5),
    building         VARCHAR(50),
    phone            VARCHAR(15),
    budget           NUMERIC(15,2),
    established_year INTEGER
);

CREATE TABLE library_books (
    book_id               SERIAL PRIMARY KEY,
    isbn                  CHAR(13),
    title                 VARCHAR(200),
    author                VARCHAR(100),
    publisher             VARCHAR(100),
    publication_date      DATE,
    price                 NUMERIC(10,2),
    is_available          BOOLEAN,
    acquisition_timestamp TIMESTAMP WITHOUT TIME ZONE
);

CREATE TABLE student_book_loans (
    loan_id      SERIAL PRIMARY KEY,
    student_id   INTEGER,
    book_id      INTEGER,
    loan_date    DATE,
    due_date     DATE,
    return_date  DATE,
    fine_amount  NUMERIC(10,2),
    loan_status  VARCHAR(20)
);

-- Task 4.2: Table Modifications for Integration

-- 1. Foreign key columns (columns only, no constraints yet)
ALTER TABLE professors ADD COLUMN department_id INTEGER;
ALTER TABLE students   ADD COLUMN advisor_id    INTEGER;
ALTER TABLE courses    ADD COLUMN department_id INTEGER;

-- 2. Lookup tables
CREATE TABLE grade_scale (
    grade_id        SERIAL PRIMARY KEY,
    letter_grade    CHAR(2),
    min_percentage  NUMERIC(4,1),
    max_percentage  NUMERIC(4,1),
    gpa_points      NUMERIC(3,2)
);

CREATE TABLE semester_calendar (
    semester_id           SERIAL PRIMARY KEY,
    semester_name         VARCHAR(20),
    academic_year         INTEGER,
    start_date            DATE,
    end_date              DATE,
    registration_deadline TIMESTAMP WITH TIME ZONE,
    is_current            BOOLEAN
);

-- ---------------------------------------------------------------------
-- PART 5: TABLE DELETION AND CLEANUP
-- ---------------------------------------------------------------------

-- Task 5.1: Conditional Table Operations

-- 1. Drop tables only if they exist
DROP TABLE IF EXISTS student_book_loans;
DROP TABLE IF EXISTS library_books;
DROP TABLE IF EXISTS grade_scale;

-- 2. Recreate grade_scale with an additional column "description"
CREATE TABLE grade_scale (
    grade_id        SERIAL PRIMARY KEY,
    letter_grade    CHAR(2),
    min_percentage  NUMERIC(4,1),
    max_percentage  NUMERIC(4,1),
    gpa_points      NUMERIC(3,2),
    description     TEXT
);

-- 3. Drop semester_calendar with CASCADE and recreate it
DROP TABLE IF EXISTS semester_calendar CASCADE;

CREATE TABLE semester_calendar (
    semester_id           SERIAL PRIMARY KEY,
    semester_name         VARCHAR(20),
    academic_year         INTEGER,
    start_date            DATE,
    end_date              DATE,
    registration_deadline TIMESTAMP WITH TIME ZONE,
    is_current            BOOLEAN
);

-- Task 5.2: Database Cleanup
-- Switch away from university_main: a database cannot be used as a
-- template (or dropped) while someone is connected to it.
\c postgres

-- university_test was created as a template; PostgreSQL refuses to drop
-- a template database, so unmark it first.
ALTER DATABASE university_test IS_TEMPLATE = false;
DROP DATABASE IF EXISTS university_test;
DROP DATABASE IF EXISTS university_distributed;

CREATE DATABASE university_backup
    TEMPLATE = university_main;

-- =====================================================================
-- END OF LAB 2
-- =====================================================================
