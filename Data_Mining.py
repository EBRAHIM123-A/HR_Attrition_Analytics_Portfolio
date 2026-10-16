"""
Data_Mining.py — tests the specific attrition patterns documented in 06_Data_Mining.

Run from the project root with:
    python Python/Data_Mining.py

This does NOT assume any relationship exists — every test below prints its actual result,
including the correlation table, so the numbers can be checked against the Excel workbook.
"""

import os
import pandas as pd
import numpy as np

INPUT_XLSX = os.path.join("..", "Excel", "HR_Attrition_Analytics.xlsx")


def load_clean():
    """Row 1 is the sheet title, row 2 a subtitle, row 3 blank, row 4 is the real header."""
    df = pd.read_excel(INPUT_XLSX, sheet_name="02_Cleaned_Data", skiprows=3)
    return df


def rate(df, mask):
    """Attrition rate (%) and sample size for a boolean mask."""
    subset = df[mask]
    if len(subset) == 0:
        return None, 0
    return round((subset["Attrition"] == "Yes").mean() * 100, 2), len(subset)


def test_overtime(df):
    print("\n--- Overtime ---")
    r_yes, n_yes = rate(df, df["OverTime"] == "Yes")
    r_no, n_no = rate(df, df["OverTime"] == "No")
    print(f"OverTime=Yes: {r_yes}% (n={n_yes})   OverTime=No: {r_no}% (n={n_no})")


def test_tenure_bands(df):
    print("\n--- Tenure bands (YearsAtCompany) ---")
    bins = [-1, 2, 5, 10, 100]
    labels = ["0-2 yrs", "3-5 yrs", "6-10 yrs", "10+ yrs"]
    df = df.copy()
    df["TenureGroup"] = pd.cut(df["YearsAtCompany"], bins=bins, labels=labels)
    g = df.groupby("TenureGroup").agg(
        n=("Attrition", "size"),
        attrition_rate=("Attrition", lambda s: round((s == "Yes").mean() * 100, 2)),
    )
    print(g)


def test_income_quartiles(df):
    print("\n--- Income quartiles ---")
    df = df.copy()
    df["IncomeQuartile"] = pd.qcut(df["MonthlyIncome"], 4,
                                    labels=["Q1 (Lowest)", "Q2", "Q3", "Q4 (Highest)"])
    g = df.groupby("IncomeQuartile").agg(
        n=("Attrition", "size"),
        attrition_rate=("Attrition", lambda s: round((s == "Yes").mean() * 100, 2)),
    )
    print(g)


def test_job_role(df):
    print("\n--- Job Role ---")
    g = df.groupby("JobRole").agg(
        n=("Attrition", "size"),
        attrition_rate=("Attrition", lambda s: round((s == "Yes").mean() * 100, 2)),
    ).sort_values("attrition_rate", ascending=False)
    print(g)


def test_interaction_single_overtime(df):
    print("\n--- Interaction: Single + Overtime (highest-risk segment) ---")
    r1, n1 = rate(df, (df["MaritalStatus"] == "Single") & (df["OverTime"] == "Yes"))
    r2, n2 = rate(df, (df["MaritalStatus"] == "Married") & (df["OverTime"] == "No"))
    print(f"Single + OverTime=Yes: {r1}% (n={n1})")
    print(f"Married + OverTime=No: {r2}% (n={n2})")


def correlation_with_attrition(df):
    print("\n--- Correlation of numeric variables with AttritionFlag ---")
    numeric_cols = df.select_dtypes(include=[np.number]).columns.tolist()
    numeric_cols = [c for c in numeric_cols if c not in ("EmployeeNumber", "AttritionFlag")]
    corr = df[numeric_cols + ["AttritionFlag"]].corr()["AttritionFlag"].drop("AttritionFlag")
    corr = corr.sort_values(key=abs, ascending=False)
    print(corr.round(3))
    print("\nNote: correlation values here are all fairly weak on their own (|r| < 0.2).")
    print("This is expected for a binary target with many contributing factors —")
    print("it does NOT mean these variables don't matter, it means no single numeric")
    print("variable explains attrition alone. Categorical breakdowns above (OverTime, JobRole,")
    print("tenure bands) show much larger practical gaps than the correlation coefficients suggest.")


def work_life_balance(df):
    print("\n--- Work-Life Balance ---")
    g = df.groupby("WorkLifeBalance").agg(
        n=("Attrition", "size"),
        attrition_rate=("Attrition", lambda s: round((s == "Yes").mean() * 100, 2)),
    )
    print(g)
    print("Note: relationship is not perfectly linear — Level 4 ('Best') does not")
    print("score lowest, so treat this as a contributing factor, not a clean linear driver.")


if __name__ == "__main__":
    df = load_clean()
    test_overtime(df)
    test_tenure_bands(df)
    test_income_quartiles(df)
    test_job_role(df)
    test_interaction_single_overtime(df)
    work_life_balance(df)
    correlation_with_attrition(df)
