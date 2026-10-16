-- 05_Business_Questions.sql
-- Answers the "Business Questions" from 07_Business_Questions — framed for HR management decisions.

-- Which departments need immediate attention (rate AND volume)?
-- Volume matters as much as rate: a low-rate department with a huge headcount can still
-- lose more people in absolute terms than a high-rate department with a small headcount.
SELECT
    department,
    COUNT(*) AS headcount,
    SUM(attrition_flag) AS employees_lost,
    ROUND(100.0 * SUM(attrition_flag) / COUNT(*), 2) AS attrition_rate_pct
FROM employee_attrition
GROUP BY department
ORDER BY employees_lost DESC;

-- Are new employees (< 2 years) leaving at a higher rate?
-- Expected: yes, 0-2 yrs ≈ 29.82% vs company average 16.12%
SELECT
    CASE WHEN years_at_company <= 2 THEN 'New (0-2 yrs)' ELSE 'Established (3+ yrs)' END AS tenure_group,
    COUNT(*) AS n,
    ROUND(100.0 * SUM(attrition_flag) / COUNT(*), 2) AS attrition_rate_pct
FROM employee_attrition
GROUP BY 1;

-- Does low job satisfaction correlate with higher attrition?
-- Expected: Level 1 ≈ 22.84% vs Level 4 ≈ 11.33%
SELECT
    job_satisfaction,
    COUNT(*) AS n,
    ROUND(100.0 * SUM(attrition_flag) / COUNT(*), 2) AS attrition_rate_pct
FROM employee_attrition
GROUP BY job_satisfaction
ORDER BY job_satisfaction;

-- Is sustained overtime a real retention risk, or is it noise?
-- Expected: Yes ≈ 30.53% vs No ≈ 10.44% — a ~3x gap, not noise.
SELECT
    over_time,
    COUNT(*) AS n,
    SUM(attrition_flag) AS employees_lost,
    ROUND(100.0 * SUM(attrition_flag) / COUNT(*), 2) AS attrition_rate_pct
FROM employee_attrition
GROUP BY over_time;

-- What is the single highest-risk segment HR should target first with a retention pilot?
-- Expected: Single + OverTime=Yes ≈ 49.62% (n=131)
SELECT
    marital_status,
    over_time,
    COUNT(*) AS n,
    ROUND(100.0 * SUM(attrition_flag) / COUNT(*), 2) AS attrition_rate_pct
FROM employee_attrition
WHERE marital_status = 'Single' AND over_time = 'Yes'
GROUP BY marital_status, over_time;
