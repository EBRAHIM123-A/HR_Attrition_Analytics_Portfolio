-- 01_Create_Table.sql
-- Schema matches 02_Cleaned_Data exactly (33 columns, 1,470 rows expected after load).
-- Written for PostgreSQL syntax; adjust types (e.g. VARCHAR(n)) if loading into SQL Server/MySQL.

CREATE TABLE employee_attrition (
    employee_number             INTEGER PRIMARY KEY,
    age                         INTEGER NOT NULL,
    attrition                   VARCHAR(3) NOT NULL,          -- 'Yes' / 'No'
    attrition_flag              SMALLINT NOT NULL,            -- 1 = Yes, 0 = No
    business_travel             VARCHAR(20) NOT NULL,
    daily_rate                  INTEGER NOT NULL,
    department                  VARCHAR(30) NOT NULL,
    distance_from_home          INTEGER NOT NULL,
    education                   SMALLINT NOT NULL,            -- 1-5
    education_field              VARCHAR(30) NOT NULL,
    environment_satisfaction    SMALLINT NOT NULL,            -- 1-4
    gender                      VARCHAR(10) NOT NULL,
    hourly_rate                 INTEGER NOT NULL,
    job_involvement             SMALLINT NOT NULL,            -- 1-4
    job_level                   SMALLINT NOT NULL,            -- 1-5
    job_role                    VARCHAR(30) NOT NULL,
    job_satisfaction            SMALLINT NOT NULL,            -- 1-4
    marital_status               VARCHAR(15) NOT NULL,
    monthly_income               INTEGER NOT NULL,
    monthly_rate                 INTEGER NOT NULL,
    num_companies_worked          SMALLINT NOT NULL,
    over_time                    VARCHAR(3) NOT NULL,          -- 'Yes' / 'No'
    percent_salary_hike           SMALLINT NOT NULL,
    performance_rating            SMALLINT NOT NULL,           -- 3-4
    relationship_satisfaction     SMALLINT NOT NULL,           -- 1-4
    stock_option_level            SMALLINT NOT NULL,           -- 0-3
    total_working_years           INTEGER NOT NULL,
    training_times_last_year      SMALLINT NOT NULL,
    work_life_balance             SMALLINT NOT NULL,           -- 1-4
    years_at_company               INTEGER NOT NULL,
    years_in_current_role           INTEGER NOT NULL,
    years_since_last_promotion      INTEGER NOT NULL,
    years_with_curr_manager          INTEGER NOT NULL
);

-- Helpful indexes for the queries in this folder
CREATE INDEX idx_attrition ON employee_attrition (attrition);
CREATE INDEX idx_department ON employee_attrition (department);
CREATE INDEX idx_job_role ON employee_attrition (job_role);
CREATE INDEX idx_overtime ON employee_attrition (over_time);

-- Note: EmployeeCount, Over18, StandardHours are intentionally NOT columns here.
-- They were constant across all 1,470 raw rows (see 04_Cleaning_Log) and carry no
-- analytical value, so they were dropped before this table was designed.
