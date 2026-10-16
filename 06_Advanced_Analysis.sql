-- 06_Advanced_Analysis.sql
-- Answers the "Advanced Questions" from 07_Business_Questions.

-- Does the effect of Overtime on attrition change depending on Job Role?
-- (Interaction check — only rows with n >= 15 are meaningful to compare)
SELECT
    job_role,
    over_time,
    COUNT(*) AS n,
    ROUND(100.0 * SUM(attrition_flag) / COUNT(*), 2) AS attrition_rate_pct
FROM employee_attrition
GROUP BY job_role, over_time
HAVING COUNT(*) >= 15
ORDER BY attrition_rate_pct DESC;

-- Income quartile vs attrition rate
-- Expected: Q1 ≈ 29.27%, Q4 ≈ 10.33%
WITH ranked AS (
    SELECT *,
           NTILE(4) OVER (ORDER BY monthly_income) AS income_quartile
    FROM employee_attrition
)
SELECT
    income_quartile,
    COUNT(*) AS n,
    MIN(monthly_income) AS min_income,
    MAX(monthly_income) AS max_income,
    ROUND(100.0 * SUM(attrition_flag) / COUNT(*), 2) AS attrition_rate_pct
FROM ranked
GROUP BY income_quartile
ORDER BY income_quartile;

-- Work-Life Balance vs attrition — is the relationship actually linear?
-- Expected: NOT linear — Level 4 ("Best") does not score lowest.
SELECT
    work_life_balance,
    COUNT(*) AS n,
    ROUND(100.0 * SUM(attrition_flag) / COUNT(*), 2) AS attrition_rate_pct
FROM employee_attrition
GROUP BY work_life_balance
ORDER BY work_life_balance;

-- Rank departments by attrition rate (for a dashboard drill-through / conditional format)
SELECT
    department,
    COUNT(*) AS n,
    ROUND(100.0 * SUM(attrition_flag) / COUNT(*), 2) AS attrition_rate_pct,
    RANK() OVER (ORDER BY 100.0 * SUM(attrition_flag) / COUNT(*) DESC) AS attrition_rank
FROM employee_attrition
GROUP BY department;

-- Single + Overtime vs Married + No-Overtime — the two extremes side by side
-- Expected: 49.62% (n=131) vs 8.42% (n=487)
SELECT
    CASE
        WHEN marital_status = 'Single' AND over_time = 'Yes' THEN 'Single + Overtime'
        WHEN marital_status = 'Married' AND over_time = 'No' THEN 'Married + No Overtime'
        ELSE 'Other'
    END AS segment,
    COUNT(*) AS n,
    ROUND(100.0 * SUM(attrition_flag) / COUNT(*), 2) AS attrition_rate_pct
FROM employee_attrition
WHERE (marital_status = 'Single' AND over_time = 'Yes')
   OR (marital_status = 'Married' AND over_time = 'No')
GROUP BY 1;
