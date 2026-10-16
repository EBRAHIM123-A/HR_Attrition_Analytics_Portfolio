-- 04_Attrition_Analysis.sql
-- Answers the "Analytical Questions" from 07_Business_Questions.
-- Real result values (from the current dataset) are noted in comments for reference.

-- Attrition rate by Overtime
-- Expected: Yes ≈ 30.53% (n=416), No ≈ 10.44% (n=1054)
SELECT
    over_time,
    COUNT(*) AS n,
    ROUND(100.0 * SUM(attrition_flag) / COUNT(*), 2) AS attrition_rate_pct
FROM employee_attrition
GROUP BY over_time
ORDER BY attrition_rate_pct DESC;

-- Attrition rate by Department
-- Expected: Sales ≈ 20.63%, HR ≈ 19.05%, R&D ≈ 13.84%
SELECT
    department,
    COUNT(*) AS n,
    ROUND(100.0 * SUM(attrition_flag) / COUNT(*), 2) AS attrition_rate_pct
FROM employee_attrition
GROUP BY department
ORDER BY attrition_rate_pct DESC;

-- Attrition rate by Job Role
-- Expected: highest = Sales Representative ≈ 39.76%, lowest = Research Director ≈ 2.5%
SELECT
    job_role,
    COUNT(*) AS n,
    ROUND(100.0 * SUM(attrition_flag) / COUNT(*), 2) AS attrition_rate_pct
FROM employee_attrition
GROUP BY job_role
ORDER BY attrition_rate_pct DESC;

-- Average YearsAtCompany: leavers vs stayers
-- Expected: Yes ≈ 5.13 yrs, No ≈ 7.37 yrs
SELECT
    attrition,
    ROUND(AVG(years_at_company), 2) AS avg_years_at_company,
    COUNT(*) AS n
FROM employee_attrition
GROUP BY attrition;

-- Attrition rate by tenure band
-- Expected: 0-2 yrs ≈ 29.82%, 10+ yrs ≈ 8.13%
SELECT
    CASE
        WHEN years_at_company <= 2 THEN '0-2 yrs'
        WHEN years_at_company <= 5 THEN '3-5 yrs'
        WHEN years_at_company <= 10 THEN '6-10 yrs'
        ELSE '10+ yrs'
    END AS tenure_band,
    COUNT(*) AS n,
    ROUND(100.0 * SUM(attrition_flag) / COUNT(*), 2) AS attrition_rate_pct
FROM employee_attrition
GROUP BY 1
ORDER BY MIN(years_at_company);

-- Attrition rate by Marital Status
-- Expected: Single ≈ 25.53%, Married ≈ 12.48%, Divorced ≈ 10.09%
SELECT
    marital_status,
    COUNT(*) AS n,
    ROUND(100.0 * SUM(attrition_flag) / COUNT(*), 2) AS attrition_rate_pct
FROM employee_attrition
GROUP BY marital_status
ORDER BY attrition_rate_pct DESC;

-- Attrition rate by Distance From Home band
-- Expected: 0-5km ≈ 13.77%, 21-30km ≈ 22.06%
SELECT
    CASE
        WHEN distance_from_home <= 5 THEN '0-5 km'
        WHEN distance_from_home <= 10 THEN '6-10 km'
        WHEN distance_from_home <= 20 THEN '11-20 km'
        ELSE '21-30 km'
    END AS distance_band,
    COUNT(*) AS n,
    ROUND(100.0 * SUM(attrition_flag) / COUNT(*), 2) AS attrition_rate_pct
FROM employee_attrition
GROUP BY 1
ORDER BY MIN(distance_from_home);
