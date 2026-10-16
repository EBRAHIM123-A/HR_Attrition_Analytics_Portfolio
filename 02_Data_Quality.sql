-- 02_Data_Quality.sql
-- Mirrors the checks in 05_Data_Quality (Excel). Run after loading employee_attrition.
-- Expected results (on the real dataset) are noted in comments — if your results differ,
-- your load has an issue, since the source data itself has none of these problems.

-- Row count (expected: 1470)
SELECT COUNT(*) AS row_count FROM employee_attrition;

-- Duplicate rows on the full row (expected: 0)
SELECT COUNT(*) AS duplicate_full_rows
FROM (
    SELECT *, COUNT(*) OVER (PARTITION BY employee_number) AS cnt
    FROM employee_attrition
) t
WHERE cnt > 1;

-- Duplicate primary key (expected: 0 rows returned)
SELECT employee_number, COUNT(*) AS occurrences
FROM employee_attrition
GROUP BY employee_number
HAVING COUNT(*) > 1;

-- Missing values check across key columns (expected: 0 for all)
SELECT
    SUM(CASE WHEN age IS NULL THEN 1 ELSE 0 END)            AS null_age,
    SUM(CASE WHEN monthly_income IS NULL THEN 1 ELSE 0 END) AS null_income,
    SUM(CASE WHEN department IS NULL THEN 1 ELSE 0 END)     AS null_department,
    SUM(CASE WHEN job_role IS NULL THEN 1 ELSE 0 END)       AS null_job_role,
    SUM(CASE WHEN attrition IS NULL THEN 1 ELSE 0 END)      AS null_attrition
FROM employee_attrition;

-- Range checks — impossible/invalid values (expected: 0 rows for each)
SELECT * FROM employee_attrition WHERE age < 18 OR age > 65;
SELECT * FROM employee_attrition WHERE monthly_income <= 0;
SELECT * FROM employee_attrition WHERE years_at_company < 0;
SELECT * FROM employee_attrition WHERE job_satisfaction NOT BETWEEN 1 AND 4;
SELECT * FROM employee_attrition WHERE work_life_balance NOT BETWEEN 1 AND 4;
SELECT * FROM employee_attrition WHERE attrition NOT IN ('Yes', 'No');
SELECT * FROM employee_attrition WHERE over_time NOT IN ('Yes', 'No');

-- Category consistency check — lists every distinct value so inconsistent spelling/casing would show up
SELECT DISTINCT department FROM employee_attrition ORDER BY 1;
SELECT DISTINCT job_role FROM employee_attrition ORDER BY 1;
SELECT DISTINCT marital_status FROM employee_attrition ORDER BY 1;
SELECT DISTINCT business_travel FROM employee_attrition ORDER BY 1;

-- attrition_flag consistency vs attrition text (expected: 0 mismatches)
SELECT COUNT(*) AS flag_mismatches
FROM employee_attrition
WHERE (attrition = 'Yes' AND attrition_flag <> 1)
   OR (attrition = 'No'  AND attrition_flag <> 0);
