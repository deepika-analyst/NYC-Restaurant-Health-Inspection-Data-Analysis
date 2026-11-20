# 🍽️ NYC Restaurant Health Inspection Data Analysis (2015–2026 | Deep-Dive: 2025)

An end-to-end **Data Engineering, Exploratory SQL Analysis, and Executive Power BI Business Intelligence** project evaluating New York City Department of Health and Mental Hygiene (DOHMH) restaurant inspection data.

To build a robust analytical foundation, **~500,000+ raw inspection records (5 Lakhs)** spanning **2015 through October 2026**—combining an initial **288,000-row** extract and a supplemental **177,000-row** Q4 update—were ingested, deduplicated, standardized, and explored in **MySQL 8.0**. While multi-year longitudinal patterns were analyzed in SQL, the interactive **Power BI Executive Dashboard** isolates **Full-Year 2025** performance across **18,555 unique restaurants** and **25,140 unique inspection events**.

---

## 🎯 Business Problem & Domain Context

In New York City, public health compliance directly impacts consumer safety, dining trust, and restaurant survival. However, raw DOHMH inspection logs present three major analytical challenges for decision-makers:
1. **Inverse Scoring Logic:** Unlike traditional grading systems, NYC health inspections assign **penalty points per violation**—meaning **0 is a perfect score** and higher scores indicate worse sanitary hazards (**Grade A:** `0–13`, **Grade B:** `14–27`, **Grade C:** `28+`).
2. **Row-Level Granularity Bias:** A single restaurant inspection generates *multiple rows*—one for each cited violation—repeating the overall inspection score on every row. Naive `COUNT(*)` or `AVG(SCORE)` queries distort inspection counts and inflate averages toward multi-violation visits.
3. **Technical Jargon Barriers:** Non-technical stakeholders and restaurant operators struggle to interpret raw violation codes (`10F`, `08A`, `02G`) without plain-English operational context.

**Objective:** Build a clean, deduplicated SQL data warehouse and an executive-ready Power BI dashboard that normalizes inspection metrics, uncovers high-risk cuisines and seasonal patterns, and translates technical health codes into actionable insights.

---

## 📊 Dashboard Walkthrough

### 1. Executive Overview — Full-Year 2025 (`Average Score` View)
![NYC Restaurant Health Inspections 2025 Dashboard - Average Score View](images/dashboard_average_score.png)
* **Top KPI Banner:** Highlights full-year 2025 volume (**18,555** restaurants, **25,140** inspections), citywide penalty benchmark (**27.21**), dominant violation severity (**Critical**), and cleanest regional performer (**Staten Island**).
* **Sanitation Score Gauge & Dynamic Grade Card:** Plots the active penalty score against NYC's Grade A target cutoff (`≤ 13`), paired with a dynamically color-coded letter-grade card (`Grade A` Green, `Grade B` Amber, `Grade C` Red) that recalculates on every cross-filter click.
* **Safest & Riskiest Establishments:** Uses `TOPN` DAX logic to dynamically spotlight the cleanest (`Score: 0`) and highest-penalty (`Score: 203`) restaurants within any selected borough, cuisine, or month.

### 2. Dynamic Metric Switching (`Critical Violation %` View)
![NYC Restaurant Health Inspections 2025 Dashboard - Critical Violation % View](images/dashboard_critical_violation.png)
* **Unified Field Parameter Switcher:** Allows stakeholders to toggle seamlessly between **Restaurant Count**, **Total Inspections**, **Average Score**, and **Critical Violation %** across both the Cuisine and Borough charts simultaneously.
* **Dynamic Titles & Subtitles:** Custom DAX measures automatically rewrite chart headers and explanatory subtitles (e.g., reminding users that *"Lower score = cleaner conditions"*) whenever the parameter selection changes.

### 3. Violation Code Drillthrough Guide (Stakeholder Glossary)
![Violation Code Details Drillthrough Page](images/violation_code_details.png)
* **One-Click Drillthrough UX:** Selecting any bar in the *Top 10 Health Code Violations* chart activates a dedicated **View Code Details** button, navigating to a clean reference page powered by a custom DAX `DATATABLE` that translates technical codes into severity levels and plain-English operational summaries.

---

## 🛠️ End-to-End Engineering & Analytics Pipeline

### Phase 1: Locale & Date Standardization (Excel Power Query)
* Raw NYC Open Data CSV exports store dates in US format (`MM/DD/YYYY`), causing type-conversion failures under `DD-MM-YYYY` regional settings.
* Used Power Query's **Using Locale (`English - United States`)** transformation to parse `INSPECTION DATE`, `GRADE DATE`, and `RECORD DATE`, exporting them in ISO **`YYYY-MM-DD`** format for error-free MySQL ingestion.

### Phase 2: Data Cleaning, Incremental Append & Indexing (MySQL 8.0)
* **High-Speed Bulk Ingestion:** Configured `OPT_LOCAL_INFILE=1` and `SET GLOBAL local_infile = 1` to ingest `288K` initial rows (`insp`) and `177K` supplemental rows (`insp2`) via `LOAD DATA LOCAL INFILE`.
* **Window-Function Deduplication:** Added an `AUTO_INCREMENT` `row_id` primary key and purged exact duplicate violation entries using `ROW_NUMBER() OVER(PARTITION BY CAMIS, INSPECTION DATE, VIOLATION CODE, INSPECTION TYPE, ACTION, SCORE ORDER BY row_id)`.
* **Data Hygiene & Standardization:**
  * Converted whitespace and empty strings across 22 columns to `NULL` prior to enforcing strict `INT`, `DATE`, and `VARCHAR` data types.
  * Neutralized corrupted `'1900-01-00'` placeholder dates (used by NYC DOHMH for uninspected new permits) to `NULL`.
  * Standardized 10- and 11-digit phone numbers into `nnn-nnn-nnnn` format and converted invalid `BORO = '0'` values to `NULL`.
  * Consolidated **80+ fragmented cuisine labels** into standardized analytical groups (e.g., grouping *Bangladeshi, Filipino, Indonesian, Pakistani, Southeast Asian* into **Asian Other**, and *Afghan, Egyptian, Ethiopian, Lebanese, Turkish* into **Middle Eastern & African**).
* **Safe Transactional Q4 Append:** When initial analysis revealed missing Q4 2025 records (October–December), a fresh extract was cleaned in `insp2`, schema-aligned by dropping trailing geographic/key columns (`Location`, `row_id`), verified for all 12 months inside a `START TRANSACTION` block, and committed cleanly into `insp`.
* **Query Optimization:** Added targeted indexes on `CUISINE DESCRIPTION`, `INSPECTION DATE`, and `VIOLATION CODE` to accelerate multi-year aggregations.

### Phase 3: Exploratory Data Analysis (MySQL)
* **Gradable vs. Non-Gradable Segmentation:** Separated official scored visits (*Cycle Inspection* and *Pre-permit Operational*) from administrative/non-gradable visits to establish true compliance baselines.
* **Longitudinal Year-over-Year Analysis (`2015–2026`):** Leveraged CTEs (`WITH`) and `LAG()` window functions to track multi-year shifts in average penalty scores and critical violation shares across NYC and within individual boroughs like Manhattan.
* **Share-of-Total & Ranking Queries:** Used `SUM() OVER(PARTITION BY ...)` and `RANK()` to benchmark each borough's share of critical vs. non-critical infractions.

### Phase 4: Semantic Modeling & DAX Engineering (Power BI)
* **Event-Level Deduplication in DAX:** Used `COUNTROWS(SUMMARIZE(insp, [CAMIS], [INSPECTION DATE]))` so multi-violation inspections are counted as **1 unique visit** rather than inflated by row count.
* **Sample-Size Normalization:** Filtered the Cuisine comparison visual to categories with **`200+` inspections** so small niche cuisines with 1–2 troubled establishments do not distort citywide risk rankings.
* **Conditional Formatting & Dynamic Text:** Built `SWITCH(TRUE(), ...)` measures returning exact Hex color codes (`#2E7D32`, `#F9A825`, `#C62828`) to synchronize Gauge arcs, KPI borders, and card backgrounds dynamically.

---

## 🔍 Deep-Dive Analytical Insights

### 1. Citywide Compliance Sits on the Grade B / Grade C Threshold
* Across **18,555 restaurants** and **25,140 unique inspections** in 2025, NYC recorded an average penalty score of **27.21**—just shy of the **Grade C (`28+`)** threshold.
* **Why it matters:** While many individual restaurants earn Grade A (`0–13`) on re-inspection, initial cycle inspections frequently uncover multiple compounding infractions that push the citywide mean into high-risk territory.

### 2. Critical Violations Outnumber General Infractions Across Every Borough
* More than half of all recorded violations across NYC are classified as **Critical** (posing direct food-borne illness risks):
  * **Staten Island:** `55%` Critical share | **Queens & Bronx:** `54%` | **Brooklyn & Manhattan:** `53%`.
* **Regional Nuance:** **Staten Island** achieved the **lowest (cleanest) overall average score** in 2025 despite having a `55%` critical share—indicating that when Staten Island restaurants are cited, they tend to have *fewer total violations per visit* compared to **Queens** (which recorded the highest average penalty score at `29`).

### 3. High-Risk Cuisines Share Specific Operational Challenges
* Among major cuisines (`200+` inspections), **Indian**, **Asian Other**, **Chinese**, and **Korean** restaurants recorded the highest average penalty scores and critical violation rates (`56%–58%`).
* **Operational Insight:** Complex multi-ingredient prep, bulk batch cooking, and strict hot/cold temperature holding requirements in these kitchens create higher exposure to temperature-control (`02G`, `02B`) and cross-contamination (`06C`, `06D`) citations.

### 4. Summer Surge & Q4 Enforcement Stabilization
* Monthly tracking across all 12 months of 2025 revealed a distinct seasonal pattern:
  * **Spring–Summer Escalation:** Inspection volume climbed from ~1,500/month in Q1 to a peak of **~2,500 inspections/month in July and August**, accompanied by rising average penalty scores (`29–30`). Warmer ambient temperatures accelerate bacterial growth and pest activity.
 
  * **Improvement:** From **October through December**, both inspection volume (~1,500/month) and average penalty scores dropped noticeably (`~24–26`), reflecting post-summer compliance corrections and re-inspection cycles.

### 5. Facility Maintenance & Pest Entry Drive Top Violation Volume
* **Top General Citations:** **`10F`** (*Unclean non-food surfaces* — **12.7K** citations) and **`08A`** (*Pest/vermin entry conditions* — **7.5K** citations) were the single most common infractions across NYC.
* **Top Critical Health Hazards:** **`06C`** (*Unprotected food/equipment* — **6.1K**), **`02G`** (*Cold food held above 41°F* — **5.9K**), and **`06D`** (*Unsanitized food-contact surfaces* — **5.5K**) led critical citations—showing that basic sanitation, refrigeration calibration, and pest-proofing account for the vast majority of preventable penalty points.

---

## 💡 Actionable Recommendations

1. **Targeted Multilingual Kitchen Training:** Deploy DOHMH consultative workshops focused on cold/hot holding calibration (`02G`/`02B`) and utensil sanitization (`06D`) tailored to high-volume independent operators in **Queens** and top-scoring cuisine segments.
2. **Pre-Summer Preventive Audits (April–May):** Increase proactive pest-proofing (`08A`) and refrigeration checks ahead of the June–August summer temperature spike to prevent Q3 score surges.
3. **Facility Maintenance Checklists:** Restaurant operators can eliminate their two highest-frequency citations (`10F` and `08A`) by implementing weekly deep-cleaning schedules for non-food surfaces and sealing structural wall/door gaps before cycle inspections.

---

## 📁 Repository Structure

    ├── data_cleaning/
    │   ├── 01_bulk_import_and_cleaning.sql      # Deduplication, null handling, cuisine standardization, indexing
    │   └── 02_q4_incremental_append.sql         # Schema alignment & transactional Q4 2025 append
    ├── exploratory_analysis/
    │   └── 03_nyc_inspections_eda.sql           # Multi-year (2015–2026) CTE & window-function EDA queries
    ├── powerbi/
    │   └── NYC_Restaurant_Inspection_Dashboard.pbix
    ├── images/
    │   ├── dashboard_average_score.png
    │   ├── dashboard_critical_violation.png
    │   └── violation_code_details.png
    └── README.md

---

## 🚀 How to Reproduce

1. **Acquire Source Data:** Download the *DOHMH New York City Restaurant Inspection Results* CSV from [NYC Open Data](https://cityofnewyork.us).
2. **Standardize Dates:** Open in Excel Power Query, apply `Using Locale -> Date -> English (United States)` to all date columns, and format as `YYYY-MM-DD`.
3. **Load & Clean in MySQL:** Execute `01_bulk_import_and_cleaning.sql` and `02_q4_incremental_append.sql` in MySQL 8.0+ to generate the cleaned, indexed `insp` table.
4. **Launch Dashboard:** Open `NYC_Restaurant_Inspection_Dashboard.pbix` in Power BI Desktop, update the MySQL connection under **Transform Data -> Data source settings**, and click **Refresh**.

