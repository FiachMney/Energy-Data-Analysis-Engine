# Energy Data Analysis Engine (MATLAB)

**Automated ETL pipeline and statistical analysis tool for heterogeneous energy time-series.**

## 📌 Overview
This project addresses a critical data engineering problem: processing non-standardized Excel reports (e.g., BP Statistical Review) into a structured database for analysis. It features an automated ETL pipeline, a custom caching system for $O(1)$ data access, and a financial/statistical analysis engine.

**Keywords:** MATLAB, ETL, Time-Series Analysis, Volatility Modeling, Anomaly Detection.

## 🚀 Key Features

### 1. Robust ETL Pipeline
- **Smart Parsing:** Automates the ingestion of unstructured Excel files with shifted headers, merged cells, and mixed formats (Wide vs. Long) .
- **Heuristic Detection:** Algorithms automatically identify units and normalize country names.
- **Performance:** Implements a binary caching system (`.mat` serialization), reducing load times from **45s to 0.3s** .

### 2. Quantitative Analysis Engine
Built-in statistical modules for risk and trend assessment:
- **Volatility:** Rolling window standard deviation to measure market instability ($\sigma_{t}$).
- **Anomaly Detection:** Outlier detection using Median Absolute Deviation (MAD > $3\sigma$) to identify exogenous shocks.
- **Forecasting:** Linear extrapolation and polynomial adjustment for 5-year trend prediction.
- **Calculus:** Discrete derivation (finite differences) to measure reaction speed.

## 🛠️ Architecture
The system is built on a modular 3-layer architecture:
1.  **Backend:** Raw parsing and normalization.
2.  **Storage:** Structured `Map` containers hierarchically indexed by `Year > Sheet > Table`.
3.  **Frontend:** Interactive CLI and visualization engine.

## 💻 How to Run
1.  **Prerequisites:** MATLAB R2020a+ (Statistics Toolbox recommended).
2.  **Setup:**
    - Place your Excel reports (must include year in filename, e.g., `Data_2023.xlsx`) in the data folder.
    - Run `Importation()` to generate the database.
3.  **Usage:**
    - Run `Explorateur()` to launch the interactive menu.
    - Select a commodity (e.g., "Oil Production") and entities.
    - Apply commands: `reg` (regression), `vol` (volatility), `pred` (prediction).

## 📄 Documentation
See [rapport_technique.pdf](docs/Technical_Report.pdf) for the full technical report, mathematical formulas, and error handling protocols.
