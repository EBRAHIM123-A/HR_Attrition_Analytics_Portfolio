"""
EDA.py — Exploratory Data Analysis on the IBM HR Attrition dataset.

Run from the project root with:
    python Python/EDA.py

Expects the raw CSV at ../Excel/ (exported once from 01_Raw_Data) OR reads directly from
HR_Attrition_Analytics.xlsx sheet "01_Raw_Data" if the CSV isn't present.
Outputs: prints a data inspection summary to the console and saves 4 charts to ./output_charts/.
"""

import os
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

INPUT_XLSX = os.path.join("..", "Excel", "HR_Attrition_Analytics.xlsx")
OUTPUT_DIR = "output_charts"


def load_data():
    """Load the raw data from the workbook's 01_Raw_Data sheet.
    Row 1 is the sheet title, row 2 a subtitle, row 3 blank, row 4 is the real header — skip the first 3 rows."""
    df = pd.read_excel(INPUT_XLSX, sheet_name="01_Raw_Data", skiprows=3)
    return df


def inspect(df):
    print("=" * 60)
    print("DATA INSPECTION")
    print("=" * 60)
    print(f"Shape: {df.shape[0]} rows x {df.shape[1]} columns")
    print(f"\nColumn dtypes:\n{df.dtypes}")

    print("\nMissing values per column:")
    missing = df.isnull().sum()
    print(missing[missing > 0] if missing.sum() > 0 else "  None found.")

    print(f"\nDuplicate rows: {df.duplicated().sum()}")
    if "EmployeeNumber" in df.columns:
        print(f"Duplicate EmployeeNumber values: {df['EmployeeNumber'].duplicated().sum()}")

    print("\nDescriptive statistics (numeric columns):")
    print(df.describe().T[["mean", "std", "min", "50%", "max"]].round(2))

    const_cols = [c for c in df.columns if df[c].nunique() == 1]
    print(f"\nConstant (zero-variance) columns: {const_cols}")


def attrition_overview(df):
    print("\n" + "=" * 60)
    print("ATTRITION OVERVIEW")
    print("=" * 60)
    counts = df["Attrition"].value_counts()
    rate = (df["Attrition"] == "Yes").mean() * 100
    print(f"Attrition counts:\n{counts}")
    print(f"Overall attrition rate: {rate:.2f}%")
    return rate


def group_analysis(df, group_col, min_n=10):
    """Attrition rate broken down by a categorical column."""
    g = df.groupby(group_col).agg(
        n=("Attrition", "size"),
        attrition_rate=("Attrition", lambda s: round((s == "Yes").mean() * 100, 2)),
    ).sort_values("attrition_rate", ascending=False)
    return g[g["n"] >= min_n]


def make_charts(df):
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    # 1. Attrition by Department
    fig, ax = plt.subplots(figsize=(7, 4))
    dept = group_analysis(df, "Department")
    ax.bar(dept.index, dept["attrition_rate"], color="#2E7D6B")
    ax.set_title("Attrition Rate by Department")
    ax.set_ylabel("Attrition Rate (%)")
    plt.xticks(rotation=15)
    plt.tight_layout()
    fig.savefig(os.path.join(OUTPUT_DIR, "attrition_by_department.png"), dpi=120)
    plt.close(fig)

    # 2. Attrition by Overtime
    fig, ax = plt.subplots(figsize=(5, 4))
    ot = group_analysis(df, "OverTime")
    ax.bar(ot.index, ot["attrition_rate"], color=["#B0563E", "#2E7D6B"])
    ax.set_title("Attrition Rate: Overtime vs No Overtime")
    ax.set_ylabel("Attrition Rate (%)")
    plt.tight_layout()
    fig.savefig(os.path.join(OUTPUT_DIR, "attrition_by_overtime.png"), dpi=120)
    plt.close(fig)

    # 3. Income distribution by Attrition
    fig, ax = plt.subplots(figsize=(6, 4))
    for label, color in [("Yes", "#B0563E"), ("No", "#2E7D6B")]:
        subset = df[df["Attrition"] == label]["MonthlyIncome"]
        ax.hist(subset, bins=30, alpha=0.6, label=f"Attrition={label}", color=color)
    ax.set_title("Monthly Income Distribution by Attrition")
    ax.set_xlabel("Monthly Income")
    ax.legend()
    plt.tight_layout()
    fig.savefig(os.path.join(OUTPUT_DIR, "income_distribution.png"), dpi=120)
    plt.close(fig)

    # 4. Attrition by Job Role
    fig, ax = plt.subplots(figsize=(8, 4))
    role = group_analysis(df, "JobRole")
    ax.barh(role.index, role["attrition_rate"], color="#1F3B4D")
    ax.set_title("Attrition Rate by Job Role")
    ax.set_xlabel("Attrition Rate (%)")
    plt.tight_layout()
    fig.savefig(os.path.join(OUTPUT_DIR, "attrition_by_jobrole.png"), dpi=120)
    plt.close(fig)

    print(f"\n4 charts saved to ./{OUTPUT_DIR}/")


if __name__ == "__main__":
    df = load_data()
    inspect(df)
    attrition_overview(df)

    print("\n" + "=" * 60)
    print("ATTRITION RATE BY DEPARTMENT")
    print("=" * 60)
    print(group_analysis(df, "Department"))

    print("\n" + "=" * 60)
    print("ATTRITION RATE BY JOB ROLE")
    print("=" * 60)
    print(group_analysis(df, "JobRole"))

    print("\n" + "=" * 60)
    print("ATTRITION RATE BY OVERTIME")
    print("=" * 60)
    print(group_analysis(df, "OverTime"))

    make_charts(df)
