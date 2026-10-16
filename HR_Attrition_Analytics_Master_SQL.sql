/*
================================================================================
HR ATTRITION ANALYTICS — SQL ANALYSIS & POWER BI
================================================================================
Purpose:
    End-to-end SQL Server project for HR Attrition Analysis.

Workflow:
    01. Database / staging setup
    02. Data quality checks
    03. Cleaning and analytical table
    04. Business Questions
    05. Advanced SQL analysis
    06. Power BI-ready views

Source:
    Cleaned_Data.csv from the HR Attrition Analytics Portfolio.

Important:
    - The staging table is treated as the imported source layer.
    - The analytical table is rebuilt from staging; the staging data is not
      modified by the cleaning process.
    - The CSV used in this project contains 1,470 rows and 33 columns,
      including AttritionFlag.
    - Run this script in SQL Server Management Studio (SSMS), not in Power BI.
      Power BI connects to the resulting SQL Server database/views.
================================================================================
*/

--------------------------------------------------------------------------------
-- 00. DATABASE
--------------------------------------------------------------------------------
IF DB_ID(N'HR_Analytics') IS NULL
BEGIN
    CREATE DATABASE HR_Analytics;
END;
GO

USE HR_Analytics;
GO

--------------------------------------------------------------------------------
-- 01. STAGING TABLE
-- Import the CSV into this table first.
--------------------------------------------------------------------------------
IF OBJECT_ID(N'dbo.stg_HR_Attrition', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.stg_HR_Attrition
    (
        EmployeeNumber              INT NULL,
        Age                         INT NULL,
        Attrition                   VARCHAR(10) NULL,
        BusinessTravel              VARCHAR(30) NULL,
        DailyRate                   INT NULL,
        Department                  VARCHAR(100) NULL,
        DistanceFromHome            INT NULL,
        Education                   INT NULL,
        EducationField              VARCHAR(50) NULL,
        EnvironmentSatisfaction     INT NULL,
        Gender                      VARCHAR(20) NULL,
        HourlyRate                  INT NULL,
        JobInvolvement              INT NULL,
        JobLevel                    INT NULL,
        JobRole                     VARCHAR(100) NULL,
        JobSatisfaction             INT NULL,
        MaritalStatus               VARCHAR(30) NULL,
        MonthlyIncome               INT NULL,
        MonthlyRate                 INT NULL,
        NumCompaniesWorked         INT NULL,
        OverTime                    VARCHAR(10) NULL,
        PercentSalaryHike           INT NULL,
        PerformanceRating           INT NULL,
        RelationshipSatisfaction    INT NULL,
        StockOptionLevel            INT NULL,
        TotalWorkingYears           INT NULL,
        TrainingTimesLastYear       INT NULL,
        WorkLifeBalance             INT NULL,
        YearsAtCompany              INT NULL,
        YearsInCurrentRole          INT NULL,
        YearsSinceLastPromotion     INT NULL,
        YearsWithCurrManager        INT NULL,
        AttritionFlag               INT NULL
    );
END;
GO

/*
OPTIONAL CSV LOAD
-----------------
Change the path to the exact local path of your Cleaned_Data.csv.

The SQL Server service account must be able to read the file.

Example:
BULK INSERT dbo.stg_HR_Attrition
FROM 'C:\YourPath\Cleaned_Data.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    TABLOCK
);
GO

If you already imported the CSV into stg_HR_Attrition through SSMS,
skip the BULK INSERT block.
*/

--------------------------------------------------------------------------------
-- 02. DATA PROFILING
--------------------------------------------------------------------------------

-- Q0. How many records are in the dataset?
SELECT COUNT(*) AS Total_Rows
FROM dbo.stg_HR_Attrition;
GO

-- Q0.1 What columns and data types are available?
SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'stg_HR_Attrition'
ORDER BY ORDINAL_POSITION;
GO

-- Q0.2 Is EmployeeNumber unique?
SELECT
    EmployeeNumber,
    COUNT(*) AS DuplicateCount
FROM dbo.stg_HR_Attrition
GROUP BY EmployeeNumber
HAVING COUNT(*) > 1;
GO

--------------------------------------------------------------------------------
-- 03. DATA QUALITY / CLEANING CHECKS
--------------------------------------------------------------------------------

-- Q1. Are there missing values in key fields?
SELECT
    SUM(CASE WHEN EmployeeNumber IS NULL THEN 1 ELSE 0 END) AS Null_EmployeeNumber,
    SUM(CASE WHEN Age IS NULL THEN 1 ELSE 0 END) AS Null_Age,
    SUM(CASE WHEN Attrition IS NULL THEN 1 ELSE 0 END) AS Null_Attrition,
    SUM(CASE WHEN Department IS NULL THEN 1 ELSE 0 END) AS Null_Department,
    SUM(CASE WHEN JobRole IS NULL THEN 1 ELSE 0 END) AS Null_JobRole,
    SUM(CASE WHEN MonthlyIncome IS NULL THEN 1 ELSE 0 END) AS Null_MonthlyIncome,
    SUM(CASE WHEN OverTime IS NULL THEN 1 ELSE 0 END) AS Null_OverTime
FROM dbo.stg_HR_Attrition;
GO

-- Q2. Are Attrition values valid?
SELECT DISTINCT Attrition
FROM dbo.stg_HR_Attrition
WHERE Attrition NOT IN ('Yes', 'No')
   OR Attrition IS NULL;
GO

-- Q3. Are OverTime values valid?
SELECT DISTINCT OverTime
FROM dbo.stg_HR_Attrition
WHERE OverTime NOT IN ('Yes', 'No')
   OR OverTime IS NULL;
GO

-- Q4. Are there impossible age values?
SELECT *
FROM dbo.stg_HR_Attrition
WHERE Age < 18 OR Age > 100;
GO

-- Q5. Are there invalid non-negative measures?
SELECT *
FROM dbo.stg_HR_Attrition
WHERE MonthlyIncome < 0
   OR DistanceFromHome < 0
   OR TotalWorkingYears < 0
   OR YearsAtCompany < 0
   OR YearsInCurrentRole < 0
   OR YearsSinceLastPromotion < 0
   OR YearsWithCurrManager < 0
   OR NumCompaniesWorked < 0;
GO

-- Q6. Zero-variance fields from the original source dataset.
-- These fields are intentionally absent from the imported cleaned CSV and
-- therefore are not part of the analytical table.
-- EmployeeCount = 1 for every row, Over18 = 'Y' for every row,
-- StandardHours = 80 for every row.
-- Removing constant fields avoids carrying columns with no analytical value.

 /*
Cleaning decision:
    EmployeeCount, Over18 and StandardHours are constant fields in the
    original HR Attrition dataset. They do not add analytical information,
    so they are not carried into the analytical table.

    String fields are normalized with LTRIM/RTRIM.
    AttritionFlag is recalculated from Attrition so the target variable
    is derived from the business label rather than trusted blindly.
*/

--------------------------------------------------------------------------------
-- 04. CLEAN / ANALYTICAL TABLE
--------------------------------------------------------------------------------
IF OBJECT_ID(N'dbo.Employee_Attrition', N'U') IS NOT NULL
    DROP TABLE dbo.Employee_Attrition;
GO

SELECT
    EmployeeNumber,
    Age,
    LTRIM(RTRIM(Attrition)) AS Attrition,
    LTRIM(RTRIM(BusinessTravel)) AS BusinessTravel,
    DailyRate,
    LTRIM(RTRIM(Department)) AS Department,
    DistanceFromHome,
    Education,
    LTRIM(RTRIM(EducationField)) AS EducationField,
    EnvironmentSatisfaction,
    LTRIM(RTRIM(Gender)) AS Gender,
    HourlyRate,
    JobInvolvement,
    JobLevel,
    LTRIM(RTRIM(JobRole)) AS JobRole,
    JobSatisfaction,
    LTRIM(RTRIM(MaritalStatus)) AS MaritalStatus,
    MonthlyIncome,
    MonthlyRate,
    NumCompaniesWorked,
    LTRIM(RTRIM(OverTime)) AS OverTime,
    PercentSalaryHike,
    PerformanceRating,
    RelationshipSatisfaction,
    StockOptionLevel,
    TotalWorkingYears,
    TrainingTimesLastYear,
    WorkLifeBalance,
    YearsAtCompany,
    YearsInCurrentRole,
    YearsSinceLastPromotion,
    YearsWithCurrManager,
    CAST(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END AS TINYINT) AS AttritionFlag
INTO dbo.Employee_Attrition
FROM dbo.stg_HR_Attrition
WHERE EmployeeNumber IS NOT NULL;
GO

ALTER TABLE dbo.Employee_Attrition
ADD CONSTRAINT PK_Employee_Attrition PRIMARY KEY (EmployeeNumber);
GO

--------------------------------------------------------------------------------
-- 05. FINAL DATA QUALITY CHECKS
--------------------------------------------------------------------------------

-- Row count
SELECT COUNT(*) AS Clean_Row_Count
FROM dbo.Employee_Attrition;
GO

-- Duplicate employee IDs
SELECT EmployeeNumber, COUNT(*) AS DuplicateCount
FROM dbo.Employee_Attrition
GROUP BY EmployeeNumber
HAVING COUNT(*) > 1;
GO

-- Target validation
SELECT Attrition, AttritionFlag, COUNT(*) AS EmployeeCount
FROM dbo.Employee_Attrition
GROUP BY Attrition, AttritionFlag
ORDER BY Attrition;
GO

--------------------------------------------------------------------------------
-- 06. BASIC QUESTIONS
--------------------------------------------------------------------------------

-- Q1. كم عدد الموظفين الكلي في الشركة؟
SELECT COUNT(*) AS Total_Employees
FROM dbo.Employee_Attrition;
GO
-- Answer: 1,470 employees.

-- Q2. كم عدد الموظفين الذين تركوا العمل مقابل الذين بقوا؟
SELECT
    Attrition,
    COUNT(*) AS EmployeeCount
FROM dbo.Employee_Attrition
GROUP BY Attrition
ORDER BY Attrition;
GO
-- Answer: 237 left; 1,233 stayed.

-- Q3. ما هو إجمالي Attrition Rate؟
SELECT
    COUNT(*) AS TotalEmployees,
    SUM(AttritionFlag) AS EmployeesLeft,
    CAST(AVG(AttritionFlag * 1.0) * 100 AS DECIMAL(5,2)) AS AttritionRatePct
FROM dbo.Employee_Attrition;
GO
-- Answer: 16.12%.

-- Q4. كم عدد الموظفين في كل Department؟
SELECT
    Department,
    COUNT(*) AS EmployeeCount
FROM dbo.Employee_Attrition
GROUP BY Department
ORDER BY EmployeeCount DESC;
GO
-- Answer:
-- Research & Development = 961
-- Sales = 446
-- Human Resources = 63

-- Q5. ما متوسط الدخل الشهري لكل الموظفين؟
SELECT
    CAST(AVG(MonthlyIncome * 1.0) AS DECIMAL(10,2)) AS AvgMonthlyIncome
FROM dbo.Employee_Attrition;
GO
-- Answer: 6,502.93.

-- Q6. ما متوسط عمر الموظفين؟
SELECT
    CAST(AVG(Age * 1.0) AS DECIMAL(10,2)) AS AverageAge
FROM dbo.Employee_Attrition;
GO
-- Answer: 36.92 years.

--------------------------------------------------------------------------------
-- 07. ANALYTICAL QUESTIONS
--------------------------------------------------------------------------------

-- Q7. هل يختلف معدل ترك العمل بين الموظفين الذين يعملون Overtime وغيرهم؟
SELECT
    OverTime,
    COUNT(*) AS EmployeeCount,
    SUM(AttritionFlag) AS EmployeesLeft,
    CAST(AVG(AttritionFlag * 1.0) * 100 AS DECIMAL(5,2)) AS AttritionRatePct
FROM dbo.Employee_Attrition
GROUP BY OverTime
ORDER BY AttritionRatePct DESC;
GO
-- Answer: Overtime Yes = 30.53%; No = 10.44%.

-- Q8. هل هناك علاقة بين الدخل الشهري ومعدل ترك العمل؟
-- NTILE(4) creates four employee groups with approximately equal row counts.
WITH IncomeGroups AS
(
    SELECT
        *,
        NTILE(4) OVER (ORDER BY MonthlyIncome) AS IncomeQuartile
    FROM dbo.Employee_Attrition
)
SELECT
    IncomeQuartile,
    COUNT(*) AS EmployeeCount,
    SUM(AttritionFlag) AS EmployeesLeft,
    CAST(AVG(AttritionFlag * 1.0) * 100 AS DECIMAL(5,2)) AS AttritionRatePct
FROM IncomeGroups
GROUP BY IncomeQuartile
ORDER BY IncomeQuartile;
GO
-- Answer: Q1 = 29.27%, Q2 = 14.21%, Q3 = 10.63%, Q4 = 10.33%.
-- Interpretation: lower-income employees show higher observed attrition.

-- Q9. هل تختلف مدة البقاء في الشركة (YearsAtCompany) بين من ترك العمل ومن بقي؟
SELECT
    Attrition,
    COUNT(*) AS EmployeeCount,
    CAST(AVG(YearsAtCompany * 1.0) AS DECIMAL(10,2)) AS AvgYearsAtCompany
FROM dbo.Employee_Attrition
GROUP BY Attrition;
GO
-- Answer: Stayers = 7.37 years; Leavers = 5.13 years.

-- Q10. هل هناك JobRole معين يرتبط بمعدل ترك عمل أعلى من البقية؟
SELECT
    JobRole,
    COUNT(*) AS EmployeeCount,
    SUM(AttritionFlag) AS EmployeesLeft,
    CAST(AVG(AttritionFlag * 1.0) * 100 AS DECIMAL(5,2)) AS AttritionRatePct
FROM dbo.Employee_Attrition
GROUP BY JobRole
ORDER BY AttritionRatePct DESC;
GO
-- Answer: Sales Representative has the highest rate at 39.76%.

-- Q11. هل تؤثر DistanceFromHome على قرار ترك العمل؟
SELECT
    CASE
        WHEN DistanceFromHome <= 5 THEN '0-5'
        WHEN DistanceFromHome <= 10 THEN '6-10'
        WHEN DistanceFromHome <= 20 THEN '11-20'
        ELSE '21+'
    END AS DistanceBand,
    COUNT(*) AS EmployeeCount,
    CAST(AVG(AttritionFlag * 1.0) * 100 AS DECIMAL(5,2)) AS AttritionRatePct
FROM dbo.Employee_Attrition
GROUP BY
    CASE
        WHEN DistanceFromHome <= 5 THEN '0-5'
        WHEN DistanceFromHome <= 10 THEN '6-10'
        WHEN DistanceFromHome <= 20 THEN '11-20'
        ELSE '21+'
    END
ORDER BY AttritionRatePct DESC;
GO
-- Answer: the 21+ mile/km band has the highest observed attrition in this
-- segmentation. This is association, not proof of causation.

-- Q12. هل هناك فرق في معدل ترك العمل حسب MaritalStatus؟
SELECT
    MaritalStatus,
    COUNT(*) AS EmployeeCount,
    SUM(AttritionFlag) AS EmployeesLeft,
    CAST(AVG(AttritionFlag * 1.0) * 100 AS DECIMAL(5,2)) AS AttritionRatePct
FROM dbo.Employee_Attrition
GROUP BY MaritalStatus
ORDER BY AttritionRatePct DESC;
GO
-- Answer: Single = 25.53%; Married = 12.48%; Divorced = 10.09%.

--------------------------------------------------------------------------------
-- 08. BUSINESS QUESTIONS
--------------------------------------------------------------------------------

-- Q13. ما الأقسام الأكثر تأثراً بترك الموظفين، وهل تحتاج تدخلاً فورياً؟
SELECT
    Department,
    COUNT(*) AS Headcount,
    SUM(AttritionFlag) AS EmployeesLeft,
    CAST(AVG(AttritionFlag * 1.0) * 100 AS DECIMAL(5,2)) AS AttritionRatePct
FROM dbo.Employee_Attrition
GROUP BY Department
ORDER BY AttritionRatePct DESC;
GO
-- Answer:
-- Sales = 20.63%
-- Human Resources = 19.05%
-- Research & Development = 13.84%
-- Sales also has 92 leavers, so it is a priority for investigation.

-- Q14. هل الموظفون الجدد أقل من سنتين هم الأكثر عرضة لترك العمل؟
SELECT
    CASE
        WHEN YearsAtCompany <= 1 THEN 'New Hire (0-1 yr)'
        ELSE 'Tenured (2+ yr)'
    END AS TenureGroup,
    COUNT(*) AS EmployeeCount,
    SUM(AttritionFlag) AS EmployeesLeft,
    CAST(AVG(AttritionFlag * 1.0) * 100 AS DECIMAL(5,2)) AS AttritionRatePct
FROM dbo.Employee_Attrition
GROUP BY
    CASE
        WHEN YearsAtCompany <= 1 THEN 'New Hire (0-1 yr)'
        ELSE 'Tenured (2+ yr)'
    END
ORDER BY AttritionRatePct DESC;
GO
-- Answer: New Hire (0-1 yr) = 34.88%.

-- Q15. هل هناك علاقة بين انخفاض JobSatisfaction ومعدل ترك العمل؟
SELECT
    JobSatisfaction,
    COUNT(*) AS EmployeeCount,
    SUM(AttritionFlag) AS EmployeesLeft,
    CAST(AVG(AttritionFlag * 1.0) * 100 AS DECIMAL(5,2)) AS AttritionRatePct
FROM dbo.Employee_Attrition
GROUP BY JobSatisfaction
ORDER BY JobSatisfaction;
GO
-- Answer:
-- Score 1 = 22.84%
-- Score 2 = 16.43%
-- Score 3 = 16.52%
-- Score 4 = 11.33%

-- Q16. هل العمل الإضافي المستمر يشكل خطراً حقيقياً على الاحتفاظ بالموظفين؟
SELECT
    OverTime,
    COUNT(*) AS Employees,
    SUM(AttritionFlag) AS Leavers,
    CAST(AVG(AttritionFlag * 1.0) * 100 AS DECIMAL(5,2)) AS AttritionRatePct
FROM dbo.Employee_Attrition
GROUP BY OverTime
ORDER BY AttritionRatePct DESC;
GO
-- Answer: Yes = 30.53% vs No = 10.44%.

-- Q17. ما هي المجموعة (Segment) الأكثر عرضة لترك العمل؟
SELECT
    CASE
        WHEN YearsAtCompany <= 1 THEN 'New Hire (0-1 yr)'
        ELSE 'Tenured (2+ yr)'
    END AS TenureGroup,
    OverTime,
    COUNT(*) AS EmployeeCount,
    SUM(AttritionFlag) AS EmployeesLeft,
    CAST(AVG(AttritionFlag * 1.0) * 100 AS DECIMAL(5,2)) AS AttritionRatePct
FROM dbo.Employee_Attrition
GROUP BY
    CASE
        WHEN YearsAtCompany <= 1 THEN 'New Hire (0-1 yr)'
        ELSE 'Tenured (2+ yr)'
    END,
    OverTime
ORDER BY AttritionRatePct DESC;
GO
-- Answer: New Hire + Overtime is the highest-risk combination in this view:
-- 55.07% observed attrition.

--------------------------------------------------------------------------------
-- 09. ADVANCED QUESTIONS
--------------------------------------------------------------------------------

-- Q18. ما أقوى 5 متغيرات رقمية ارتباطاً بترك العمل (Correlation)؟
-- Pearson correlation is calculated against the binary AttritionFlag.
-- EmployeeNumber is excluded because it is an identifier, not an analytical
-- variable. AttritionFlag itself is excluded from the candidate list.
WITH NumericValues AS
(
    SELECT
        e.EmployeeNumber,
        e.AttritionFlag,
        v.VariableName,
        v.VariableValue
    FROM dbo.Employee_Attrition e
    CROSS APPLY
    (
        VALUES
            ('Age', CAST(e.Age AS FLOAT)),
            ('DailyRate', CAST(e.DailyRate AS FLOAT)),
            ('DistanceFromHome', CAST(e.DistanceFromHome AS FLOAT)),
            ('Education', CAST(e.Education AS FLOAT)),
            ('EnvironmentSatisfaction', CAST(e.EnvironmentSatisfaction AS FLOAT)),
            ('HourlyRate', CAST(e.HourlyRate AS FLOAT)),
            ('JobInvolvement', CAST(e.JobInvolvement AS FLOAT)),
            ('JobLevel', CAST(e.JobLevel AS FLOAT)),
            ('JobSatisfaction', CAST(e.JobSatisfaction AS FLOAT)),
            ('MonthlyIncome', CAST(e.MonthlyIncome AS FLOAT)),
            ('MonthlyRate', CAST(e.MonthlyRate AS FLOAT)),
            ('NumCompaniesWorked', CAST(e.NumCompaniesWorked AS FLOAT)),
            ('PercentSalaryHike', CAST(e.PercentSalaryHike AS FLOAT)),
            ('PerformanceRating', CAST(e.PerformanceRating AS FLOAT)),
            ('RelationshipSatisfaction', CAST(e.RelationshipSatisfaction AS FLOAT)),
            ('StockOptionLevel', CAST(e.StockOptionLevel AS FLOAT)),
            ('TotalWorkingYears', CAST(e.TotalWorkingYears AS FLOAT)),
            ('TrainingTimesLastYear', CAST(e.TrainingTimesLastYear AS FLOAT)),
            ('WorkLifeBalance', CAST(e.WorkLifeBalance AS FLOAT)),
            ('YearsAtCompany', CAST(e.YearsAtCompany AS FLOAT)),
            ('YearsInCurrentRole', CAST(e.YearsInCurrentRole AS FLOAT)),
            ('YearsSinceLastPromotion', CAST(e.YearsSinceLastPromotion AS FLOAT)),
            ('YearsWithCurrManager', CAST(e.YearsWithCurrManager AS FLOAT))
    ) v(VariableName, VariableValue)
),
CorrelationStats AS
(
    SELECT
        VariableName,
        COUNT(*) AS N,
        SUM(VariableValue) AS SumX,
        SUM(CAST(AttritionFlag AS FLOAT)) AS SumY,
        SUM(VariableValue * VariableValue) AS SumX2,
        SUM(CAST(AttritionFlag AS FLOAT) * AttritionFlag) AS SumY2,
        SUM(VariableValue * CAST(AttritionFlag AS FLOAT)) AS SumXY
    FROM NumericValues
    GROUP BY VariableName
)
SELECT TOP 5
    VariableName,
    CAST(
        (
            N * SumXY - SumX * SumY
        )
        /
        NULLIF(
            SQRT(
                (N * SumX2 - SumX * SumX)
                *
                (N * SumY2 - SumY * SumY)
            ),
            0
        )
        AS DECIMAL(6,3)
    ) AS PearsonCorrelation
FROM CorrelationStats
ORDER BY ABS(
    (
        N * SumXY - SumX * SumY
    )
    /
    NULLIF(
        SQRT(
            (N * SumX2 - SumX * SumX)
            *
            (N * SumY2 - SumY * SumY)
        ),
        0
    )
) DESC;
GO
-- Expected top 5 on this dataset:
-- TotalWorkingYears   ≈ -0.171
-- JobLevel             ≈ -0.169
-- YearsInCurrentRole   ≈ -0.161
-- MonthlyIncome        ≈ -0.160
-- Age                  ≈ -0.159

-- Q19. هل يتغير أثر Overtime على ترك العمل حسب JobRole؟
SELECT
    JobRole,
    OverTime,
    COUNT(*) AS EmployeeCount,
    SUM(AttritionFlag) AS EmployeesLeft,
    CAST(AVG(AttritionFlag * 1.0) * 100 AS DECIMAL(5,2)) AS AttritionRatePct
FROM dbo.Employee_Attrition
GROUP BY JobRole, OverTime
ORDER BY JobRole, OverTime;
GO
-- Examples:
-- Sales Representative: No = 28.81%, Yes = 66.67%
-- Laboratory Technician: No = 15.74%, Yes = 50.00%

-- Q20. هل التفاعل بين الحالة الاجتماعية والعمل الإضافي (Single + Overtime)
--     يرفع معدل ترك العمل بشكل ملحوظ؟
SELECT
    CASE
        WHEN MaritalStatus = 'Single' AND OverTime = 'Yes'
            THEN 'Single + Overtime'
        ELSE 'Other'
    END AS Segment,
    COUNT(*) AS EmployeeCount,
    SUM(AttritionFlag) AS EmployeesLeft,
    CAST(AVG(AttritionFlag * 1.0) * 100 AS DECIMAL(5,2)) AS AttritionRatePct
FROM dbo.Employee_Attrition
GROUP BY
    CASE
        WHEN MaritalStatus = 'Single' AND OverTime = 'Yes'
            THEN 'Single + Overtime'
        ELSE 'Other'
    END
ORDER BY AttritionRatePct DESC;
GO
-- Answer: Single + Overtime = 49.62%; Other = 12.85%.
-- This is a strong descriptive difference. It is not, by itself, a
-- statistical-significance test.

-- Q21. هل هناك فرق في معدل ترك العمل بين أرباع الدخل الشهري الأربعة؟
WITH IncomeQuartiles AS
(
    SELECT
        *,
        NTILE(4) OVER (ORDER BY MonthlyIncome) AS IncomeQuartile
    FROM dbo.Employee_Attrition
)
SELECT
    IncomeQuartile,
    COUNT(*) AS EmployeeCount,
    SUM(AttritionFlag) AS EmployeesLeft,
    CAST(AVG(AttritionFlag * 1.0) * 100 AS DECIMAL(5,2)) AS AttritionRatePct
FROM IncomeQuartiles
GROUP BY IncomeQuartile
ORDER BY IncomeQuartile;
GO
-- Answer: Q1 = 29.27%, Q2 = 14.21%, Q3 = 10.63%, Q4 = 10.33%.
-- SQL here shows the observed difference; a formal significance test would
-- require an additional statistical procedure.

-- Q22. هل WorkLifeBalance له علاقة خطية مع ترك العمل أم لا؟
SELECT
    WorkLifeBalance,
    COUNT(*) AS EmployeeCount,
    SUM(AttritionFlag) AS EmployeesLeft,
    CAST(AVG(AttritionFlag * 1.0) * 100 AS DECIMAL(5,2)) AS AttritionRatePct
FROM dbo.Employee_Attrition
GROUP BY WorkLifeBalance
ORDER BY WorkLifeBalance;
GO
-- Answer:
-- 1 = 31.25%, 2 = 16.86%, 3 = 14.22%, 4 = 17.65%.
-- The pattern is not monotonic, so a simple linear relationship is not
-- evident from this descriptive analysis.

--------------------------------------------------------------------------------
-- 10. ADDITIONAL PORTFOLIO QUESTIONS
--------------------------------------------------------------------------------

-- Q23. What are the top 5 JobRoles by number of leavers?
SELECT TOP 5
    JobRole,
    COUNT(*) AS EmployeesLeft
FROM dbo.Employee_Attrition
WHERE Attrition = 'Yes'
GROUP BY JobRole
ORDER BY EmployeesLeft DESC;
GO

-- Q24. What percentage of each department works overtime?
SELECT
    Department,
    COUNT(*) AS EmployeeCount,
    SUM(CASE WHEN OverTime = 'Yes' THEN 1 ELSE 0 END) AS OvertimeEmployees,
    CAST(
        SUM(CASE WHEN OverTime = 'Yes' THEN 1 ELSE 0 END) * 100.0
        / COUNT(*)
        AS DECIMAL(5,2)
    ) AS OvertimeRatePct
FROM dbo.Employee_Attrition
GROUP BY Department
ORDER BY OvertimeRatePct DESC;
GO

-- Q25. Which Department + JobRole combinations have the highest attrition?
-- Minimum group size reduces misleading results from tiny segments.
SELECT TOP 10
    Department,
    JobRole,
    COUNT(*) AS EmployeeCount,
    SUM(AttritionFlag) AS EmployeesLeft,
    CAST(AVG(AttritionFlag * 1.0) * 100 AS DECIMAL(5,2)) AS AttritionRatePct
FROM dbo.Employee_Attrition
GROUP BY Department, JobRole
HAVING COUNT(*) >= 10
ORDER BY AttritionRatePct DESC;
GO

-- Q26. Rank JobRoles by attrition risk.
SELECT
    JobRole,
    COUNT(*) AS EmployeeCount,
    CAST(AVG(AttritionFlag * 1.0) * 100 AS DECIMAL(5,2)) AS AttritionRatePct,
    RANK() OVER
    (
        ORDER BY AVG(AttritionFlag * 1.0) DESC
    ) AS RiskRank
FROM dbo.Employee_Attrition
GROUP BY JobRole
ORDER BY RiskRank;
GO

-- Q27. Compare each JobRole with the average attrition across JobRoles.
WITH RoleMetrics AS
(
    SELECT
        JobRole,
        AVG(AttritionFlag * 1.0) AS AttritionRate
    FROM dbo.Employee_Attrition
    GROUP BY JobRole
)
SELECT
    JobRole,
    CAST(AttritionRate * 100 AS DECIMAL(5,2)) AS RoleAttritionRatePct,
    CAST(AVG(AttritionRate) OVER () * 100 AS DECIMAL(5,2))
        AS AverageRoleAttritionPct,
    CAST(
        (AttritionRate - AVG(AttritionRate) OVER ()) * 100
        AS DECIMAL(5,2)
    ) AS DifferenceFromAveragePctPoints
FROM RoleMetrics
ORDER BY AttritionRate DESC;
GO

-- Q28. Build a simple employee-level risk factor score.
SELECT
    EmployeeNumber,
    Department,
    JobRole,
    Attrition,
    OverTime,
    YearsAtCompany,
    MonthlyIncome,
    JobSatisfaction,
    WorkLifeBalance,
    (
        CASE WHEN OverTime = 'Yes' THEN 1 ELSE 0 END
        + CASE WHEN YearsAtCompany <= 1 THEN 1 ELSE 0 END
        + CASE WHEN JobSatisfaction <= 2 THEN 1 ELSE 0 END
        + CASE WHEN WorkLifeBalance <= 2 THEN 1 ELSE 0 END
    ) AS RiskFactorCount,
    CASE
        WHEN
            (
                CASE WHEN OverTime = 'Yes' THEN 1 ELSE 0 END
                + CASE WHEN YearsAtCompany <= 1 THEN 1 ELSE 0 END
                + CASE WHEN JobSatisfaction <= 2 THEN 1 ELSE 0 END
                + CASE WHEN WorkLifeBalance <= 2 THEN 1 ELSE 0 END
            ) >= 3
            THEN 'High Risk'
        WHEN
            (
                CASE WHEN OverTime = 'Yes' THEN 1 ELSE 0 END
                + CASE WHEN YearsAtCompany <= 1 THEN 1 ELSE 0 END
                + CASE WHEN JobSatisfaction <= 2 THEN 1 ELSE 0 END
                + CASE WHEN WorkLifeBalance <= 2 THEN 1 ELSE 0 END
            ) = 2
            THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS RiskLevel
FROM dbo.Employee_Attrition;
GO

--------------------------------------------------------------------------------
-- 11. POWER BI-READY VIEWS
--------------------------------------------------------------------------------
/*
Power BI recommendation:
    Use dbo.vw_PBI_Employee_Attrition as the main detailed source.
    The other views are summary tables for simple visuals/KPIs if desired.

    Connect Power BI to:
        Server: .\SQLEXPRESS
        Database: HR_Analytics
*/

CREATE OR ALTER VIEW dbo.vw_PBI_Employee_Attrition
AS
SELECT
    EmployeeNumber,
    Age,
    Attrition,
    AttritionFlag,
    BusinessTravel,
    DailyRate,
    Department,
    DistanceFromHome,
    Education,
    EducationField,
    EnvironmentSatisfaction,
    Gender,
    HourlyRate,
    JobInvolvement,
    JobLevel,
    JobRole,
    JobSatisfaction,
    MaritalStatus,
    MonthlyIncome,
    MonthlyRate,
    NumCompaniesWorked,
    OverTime,
    PercentSalaryHike,
    PerformanceRating,
    RelationshipSatisfaction,
    StockOptionLevel,
    TotalWorkingYears,
    TrainingTimesLastYear,
    WorkLifeBalance,
    YearsAtCompany,
    YearsInCurrentRole,
    YearsSinceLastPromotion,
    YearsWithCurrManager,

    CASE
        WHEN Age BETWEEN 18 AND 25 THEN '18-25'
        WHEN Age BETWEEN 26 AND 35 THEN '26-35'
        WHEN Age BETWEEN 36 AND 45 THEN '36-45'
        WHEN Age BETWEEN 46 AND 55 THEN '46-55'
        ELSE '56+'
    END AS AgeBand,

    CASE
        WHEN YearsAtCompany <= 1 THEN '0-1 yr'
        WHEN YearsAtCompany BETWEEN 2 AND 5 THEN '2-5 yr'
        WHEN YearsAtCompany BETWEEN 6 AND 10 THEN '6-10 yr'
        ELSE '10+ yr'
    END AS TenureBand,

    CASE
        WHEN DistanceFromHome <= 5 THEN '0-5'
        WHEN DistanceFromHome <= 10 THEN '6-10'
        WHEN DistanceFromHome <= 20 THEN '11-20'
        ELSE '21+'
    END AS DistanceBand,

    CASE
        WHEN MonthlyIncome <= 3000 THEN 'Low Income'
        WHEN MonthlyIncome <= 6000 THEN 'Mid-Low Income'
        WHEN MonthlyIncome <= 10000 THEN 'Mid-High Income'
        ELSE 'High Income'
    END AS IncomeBand,

    (
        CASE WHEN OverTime = 'Yes' THEN 1 ELSE 0 END
        + CASE WHEN YearsAtCompany <= 1 THEN 1 ELSE 0 END
        + CASE WHEN JobSatisfaction <= 2 THEN 1 ELSE 0 END
        + CASE WHEN WorkLifeBalance <= 2 THEN 1 ELSE 0 END
    ) AS RiskFactorCount,

    CASE
        WHEN
            (
                CASE WHEN OverTime = 'Yes' THEN 1 ELSE 0 END
                + CASE WHEN YearsAtCompany <= 1 THEN 1 ELSE 0 END
                + CASE WHEN JobSatisfaction <= 2 THEN 1 ELSE 0 END
                + CASE WHEN WorkLifeBalance <= 2 THEN 1 ELSE 0 END
            ) >= 3
            THEN 'High Risk'
        WHEN
            (
                CASE WHEN OverTime = 'Yes' THEN 1 ELSE 0 END
                + CASE WHEN YearsAtCompany <= 1 THEN 1 ELSE 0 END
                + CASE WHEN JobSatisfaction <= 2 THEN 1 ELSE 0 END
                + CASE WHEN WorkLifeBalance <= 2 THEN 1 ELSE 0 END
            ) = 2
            THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS RiskLevel

FROM dbo.Employee_Attrition;
GO

CREATE OR ALTER VIEW dbo.vw_PBI_KPI
AS
SELECT
    COUNT(*) AS TotalEmployees,
    SUM(AttritionFlag) AS EmployeesLeft,
    COUNT(*) - SUM(AttritionFlag) AS EmployeesStayed,
    CAST(AVG(AttritionFlag * 1.0) * 100 AS DECIMAL(5,2)) AS AttritionRatePct,
    CAST(AVG(Age * 1.0) AS DECIMAL(10,2)) AS AverageAge,
    CAST(AVG(MonthlyIncome * 1.0) AS DECIMAL(10,2)) AS AverageMonthlyIncome,
    CAST(AVG(YearsAtCompany * 1.0) AS DECIMAL(10,2)) AS AverageYearsAtCompany
FROM dbo.Employee_Attrition;
GO

CREATE OR ALTER VIEW dbo.vw_PBI_Department
AS
SELECT
    Department,
    COUNT(*) AS Headcount,
    SUM(AttritionFlag) AS EmployeesLeft,
    COUNT(*) - SUM(AttritionFlag) AS EmployeesStayed,
    CAST(AVG(AttritionFlag * 1.0) * 100 AS DECIMAL(5,2)) AS AttritionRatePct,
    CAST(AVG(MonthlyIncome * 1.0) AS DECIMAL(10,2)) AS AvgMonthlyIncome,
    CAST(AVG(JobSatisfaction * 1.0) AS DECIMAL(5,2)) AS AvgJobSatisfaction
FROM dbo.Employee_Attrition
GROUP BY Department;
GO

CREATE OR ALTER VIEW dbo.vw_PBI_JobRole
AS
SELECT
    JobRole,
    Department,
    COUNT(*) AS Headcount,
    SUM(AttritionFlag) AS EmployeesLeft,
    CAST(AVG(AttritionFlag * 1.0) * 100 AS DECIMAL(5,2)) AS AttritionRatePct,
    CAST(AVG(MonthlyIncome * 1.0) AS DECIMAL(10,2)) AS AvgMonthlyIncome
FROM dbo.Employee_Attrition
GROUP BY JobRole, Department;
GO

CREATE OR ALTER VIEW dbo.vw_PBI_Overtime
AS
SELECT
    OverTime,
    COUNT(*) AS Headcount,
    SUM(AttritionFlag) AS EmployeesLeft,
    CAST(AVG(AttritionFlag * 1.0) * 100 AS DECIMAL(5,2)) AS AttritionRatePct
FROM dbo.Employee_Attrition
GROUP BY OverTime;
GO

CREATE OR ALTER VIEW dbo.vw_PBI_Tenure
AS
SELECT
    CASE
        WHEN YearsAtCompany <= 1 THEN '0-1 yr'
        WHEN YearsAtCompany BETWEEN 2 AND 5 THEN '2-5 yr'
        WHEN YearsAtCompany BETWEEN 6 AND 10 THEN '6-10 yr'
        ELSE '10+ yr'
    END AS TenureBand,
    COUNT(*) AS Headcount,
    SUM(AttritionFlag) AS EmployeesLeft,
    CAST(AVG(AttritionFlag * 1.0) * 100 AS DECIMAL(5,2)) AS AttritionRatePct
FROM dbo.Employee_Attrition
GROUP BY
    CASE
        WHEN YearsAtCompany <= 1 THEN '0-1 yr'
        WHEN YearsAtCompany BETWEEN 2 AND 5 THEN '2-5 yr'
        WHEN YearsAtCompany BETWEEN 6 AND 10 THEN '6-10 yr'
        ELSE '10+ yr'
    END;
GO

CREATE OR ALTER VIEW dbo.vw_PBI_Satisfaction
AS
SELECT
    JobSatisfaction,
    WorkLifeBalance,
    COUNT(*) AS Headcount,
    SUM(AttritionFlag) AS EmployeesLeft,
    CAST(AVG(AttritionFlag * 1.0) * 100 AS DECIMAL(5,2)) AS AttritionRatePct
FROM dbo.Employee_Attrition
GROUP BY JobSatisfaction, WorkLifeBalance;
GO

--------------------------------------------------------------------------------
-- 12. FINAL OBJECT CHECK
--------------------------------------------------------------------------------
SELECT
    TABLE_SCHEMA,
    TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME IN ('stg_HR_Attrition', 'Employee_Attrition')
ORDER BY TABLE_NAME;
GO

SELECT
    TABLE_SCHEMA,
    TABLE_NAME
FROM INFORMATION_SCHEMA.VIEWS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME LIKE 'vw_PBI_%'
ORDER BY TABLE_NAME;
GO
   
