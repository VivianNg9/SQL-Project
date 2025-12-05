<h1 align="center">Data Warehouse & Analytics SQL Project</h1>
---

This project showcases a complete end-to-end **Data Warehouse and Analytics** solution by using Microsoft SQL Server. It follows modern data engineering best practices — from ingesting raw data to delivering business-ready insights through analytical data models.
---

## 🏗️ Data Architecture

This solution uses the **Medallion Layer Architecture**, structured into **Bronze → Silver → Gold** layers.

| Layer | Purpose | Description |
|-------|---------|-------------|
| **🟫 Bronze (Raw Layer)** | Landing Zone | Stores raw CSV data directly from source systems (ERP & CRM). Used for lineage, auditing, and reprocessing. |
| **⚪ Silver (Clean Layer)** | Standardised Data | Cleans, validates, and harmonises raw data. Applies schema alignment, deduplication, datatype corrections, and business rules. |
| **🟡 Gold (Analytics Layer)** | Business Models | Contains analytics-optimised tables (Star Schema). Fact tables aggregate business events, while dimension tables provide descriptive context. |

---

## 🎯 Project Objectives

### **Data Engineering**
- Ingest datasets from **ERP** and **CRM** source systems.
- Clean and standardize raw data to resolve data quality issues.
- Integrate data into a unified analytical model.
- Build **fact** and **dimension** tables designed for performance.
  
---

## 📂 Repository Structure

- **[datasets/](guide://action?prefill=Tell%20me%20more%20about%3A%20%60datasets%2F%60)**: Contains raw ERP and CRM data inputs.
- **[docs/](guide://action?prefill=Tell%20me%20more%20about%3A%20%60docs%2F%60)**: Visuals and documentation for architecture, ETL, and naming standards.
- **[scripts/](guide://action?prefill=Tell%20me%20more%20about%3A%20%60scripts%2F%60)**: Organized ETL logic across Bronze → Silver → Gold layers.
- **[tests/](guide://action?prefill=Tell%20me%20more%20about%3A%20%60tests%2F%60)**: Ensures data quality and transformation accuracy.
- **[README.md](guide://action?prefill=Tell%20me%20more%20about%3A%20%60README.md%60)**: Entry point for understanding and using the project.
- **[requirements.txt](guide://action?prefill=Tell%20me%20more%20about%3A%20%60requirements.txt%60)**: Lists required libraries and dependencies.
