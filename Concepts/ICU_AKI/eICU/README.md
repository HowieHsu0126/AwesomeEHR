# eICU-CRD v2.0

## Overview

This repository contains a collection of PostgreSQL scripts designed for the analysis and early detection of Acute Kidney Injury (AKI) using clinical data from databases like MIMIC-IV and eICU-CRD 2.0. The scripts utilize a combination of creatinine measurements, urine output data, and patient treatment records to identify and categorize instances of AKI, with a specific focus on ICU-acquired AKI.

## Files Description

- **cr_7d.sql**: Calculates peak creatinine levels within a 7-day window post-ICU admission.
- **cr_48h.sql**: Identifies peak creatinine levels within the first 48 hours of ICU admission.
- **cr_baseline.sql**: Establishes baseline creatinine levels for patients by identifying ***the most stable creatinine value within the 3 months prior to ICU admission***.
  - A "stable value" is defined as the creatinine measurement closest to the average of all measurements within this period, reflecting a period of relative stability in kidney function. This stable baseline is crucial for accurately assessing subsequent changes in kidney function and identifying ICU-acquired AKI.
- **patient_weight.sql**: Creates a table for patient weights, crucial for calculations in other scripts.
- **aki_cr.sql**: Defines the view for AKI detection based on creatinine ratios within 48 hours and 7 days.
- **aki_rrt.sql**: Identifies patients who have received renal replacement therapies prior to ICU admission, indicating chronic AKI conditions or previous AKI treatments.
- **aki_uo.sql**: Determines AKI status based on urine output criteria as per KDIGO guidelines, calculating per-hour urine volume against patient weight.
- **aki_final.sql**: Compiles the final AKI status by combining creatinine and urine output diagnostics with considerations for Renal Replacement Therapy (RRT). It specifically identifies ICU-acquired AKI, ensuring each patient's `patientunitstayid` is unique.
- **main.sql**: Acts as the primary script importing other SQL files and orchestrating the workflow. It ensures the sequential execution of scripts to maintain the logical flow of data analysis.

## Usage

The SQL scripts are designed to be run in a sequential manner:

1. **Set up the environment**: Ensure that your database environment is compatible with the scripts, typically PostgreSQL or a similar system.
   
2. **Run the scripts**: Start with `main.sql`, which will guide the order of execution. Ensure that all dependent views and tables are created before running scripts that rely on them.

3. **Data Analysis**: After running the scripts, use the resulting data to analyze AKI incidence, progression, and potential treatment paths. Focus particularly on ICU-acquired AKI instances for targeted intervention and management.

## Dependencies

- A database containing MIMIC-IV or eICU-CRD 2.0 data.
- PostgreSQL environment capable of executing complex queries and view creation.
- Adequate knowledge of clinical criteria for AKI diagnosis and progression, especially in the context of ICU care.
