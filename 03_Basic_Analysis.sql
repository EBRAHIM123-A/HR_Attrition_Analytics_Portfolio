-- 03_Basic_Analysis.sql
-- Answers the "Basic Questions" from 07_Business_Questions.

-- Total employees
SELECT COUNT(*) AS total_employees FROM employee_attrition;

-- Attrition counts (Yes vs No)
SELECT attrition, COUNT(*) AS employee_count
FROM employee_attrition
GROUP BY attrition;

-- Overall attrition rate
SELECT
    ROUND(100.0 * SUM(attrition_flag) / COUNT(*), 2) AS attrition_rate_pct
FROM employee_attrition;

-- Headcount by department
SELECT department, COUNT(*) AS headcount
FROM employee_attrition
GROUP BY department
ORDER BY headcount DESC;

-- Average monthly income (company-wide)
SELECT ROUND(AVG(monthly_income), 2) AS avg_monthly_income
FROM employee_attrition;

-- Average age (company-wide)
SELECT ROUND(AVG(age), 1) AS avg_age
FROM employee_attrition;

-- Headcount by job role
SELECT job_role, COUNT(*) AS headcount
FROM employee_attrition
GROUP BY job_role
ORDER BY headcount DESC;
