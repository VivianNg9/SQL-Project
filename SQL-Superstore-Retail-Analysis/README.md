# Superstore Retail SQL Analysis – Pricing, Profitability & Customer Value

## Overview

This project uses **advanced SQL in PostgreSQL** to perform a deep-dive analytics study on a classic **Superstore retail dataset** (9,994 order lines; **$2.30M** in revenue; **$286K** in profit; **793 customers; 5,009 orders**).

By joining **customers, employees, products and orders** and layering **CTEs, window functions and statistical functions (`corr`)**, the analysis moves past “top 10 products” and answers questions a real business would care about:

- Which **segments and regions** drive **profitable** growth, not just sales volume?
- Where are discounts **creating value** vs **destroying margin**?
- Which **categories and subcategories** should we **grow, fix or exit**?
- Which **customers and salespeople** are building **high-quality, sustainable revenue** – and which ones are actually **unprofitable**?

All queries are written in **T-SQL style but executed in PostgreSQL**, making this a strong, portfolio-ready example of **SQL used as an analytics and decision-making tool**, not just a data extraction tool.

---

## Headline Business Insights

### 1️⃣ Segment & Region – not all revenue is created equal

- **Total performance**  
  - Revenue: **$2.30M**  
  - Profit: **$286K**  
  - Overall margin: **12.5%**

- **Customer segments (by sales & margin)**  
  - **Consumer**  
    - ≈ **$1.16M** sales (**~50.6%** of revenue)  
    - Profit ≈ **$134.1K**, margin ≈ **11.5%**
  - **Corporate**  
    - ≈ **$706K** sales (**~30.7%** of revenue)  
    - Profit ≈ **$92.0K**, margin ≈ **13.0%**
  - **Home Office**  
    - ≈ **$430K** sales (**~18.7%** of revenue)  
    - Profit ≈ **$60.3K**, margin ≈ **14.0%**

**Insight:**  
**Home Office** is the **smallest segment** by revenue but has the **highest margin**.  
**Consumer** fuels top-line growth, but **Home Office & Corporate** are more profitable per dollar.

> 📌 Strategy: Use Consumer for **scale**, and focus targeted account development, loyalty, and higher-value offers on **Home Office and Corporate** where the business earns more per dollar.

---

### 2️⃣ Portfolio Reality – Furniture vs Office Supplies & Tech

- **Category performance**

  | Category          | Sales      | Profit     | Margin  |
  |-------------------|-----------:|-----------:|--------:|
  | **Furniture**     | $742K      | **$18.5K** | **2.5%** |
  | Office Supplies   | $719K      | $122.5K    | 17.0%   |
  | Technology        | $836K      | $145.5K    | 17.4%   |

- Furniture looks big on the P&L, but with only **2.5% margin**, it’s almost a **break-even category**.  
- Within Furniture, **Tables and Bookcases** are particularly problematic:
  - **Tables**: ≈ **$207K** sales, **–$17.7K** profit → **–8.6% margin**
  - **Bookcases**: ≈ **$115K** sales, **–$3.5K** profit → **–3.0% margin**

By contrast, several Office Supplies subcategories are **margin engines**:

- **Paper**:  
  - ≈ **$78.5K** sales, ≈ **$34.1K** profit → **43.4% margin**  
- **Labels, Envelopes, Copiers**: margins in the **30–40%+** range.

**Insight:**  
The company is **subsidising low-margin Furniture** with **high-margin Office Supplies & Technology**.  

> 📌 Strategy:  
> - **Fix or shrink** structural loss-makers (e.g. Tables, Bookcases) via **repricing, cost optimisation or assortment rationalisation**.  
> - Double down on **Office Supplies & Technology**, especially **Paper / Labels / Copiers**, as **profit anchors** and cross-sell drivers.

---

### 3️⃣ Discounts – where profitability silently dies

Using SQL CTEs and banding on `DISCOUNT`, we see a very sharp pattern:

| Discount band | Sales      | Profit       | Margin   | Share of Sales |
|---------------|-----------:|------------:|--------:|---------------:|
| **0%**        | $1.09M     | $321.0K      | **29.5%** | 47.4%          |
| **0–20%**     | $846.5K    | $100.8K      | 11.9%   | 36.9%          |
| **20–40%**    | $234.1K    | **–$35.8K**  | **–15.3%** | 10.2%       |
| **40–60%**    | $71.0K     | **–$28.9K**  | **–40.7%** | 3.1%        |
| **60%+**      | $57.6K     | **–$70.6K**  | **–122.6%** | 2.5%       |

**Key takeaways:**

- At **0% discount**, the business runs at **~29.5% margin** – very healthy.  
- At **20–40% discount**, it starts **losing money**, with a margin of **–15.3%**.  
- At **40–60% and 60%+**, it’s not just thin; it’s **deeply negative** – effectively **paying customers** to take stock away.

Zooming into **Furniture subcategories**:

- **Tables** (correlation between discount & profit ≈ **–0.67**):  
  - 0% discount → **+18.5% margin**  
  - 20–40% discount → **–27.7% margin**  
  - 40–60% discount → **–58.0% margin**

- **Bookcases** (corr ≈ **–0.61**):  
  - 0% discount → **+19.0% margin**  
  - 60%+ discount → **–158.4% margin**  

**Insight:**  
Discounts **above 20% are structurally unprofitable**, and **Furniture is extremely discount-sensitive**.

> 📌 Strategy:  
> - Introduce **subcategory-specific discount caps** (e.g. strict limits on Tables, Bookcases, Machines).  
> - Reserve **40%+ discounts** only for **true end-of-life / clearance** events with clear business justification.  
> - Use **high-margin items** (Paper, Labels, Copiers) as discount-friendly components in bundles instead.

---

### 4️⃣ Customer Behaviour – loyalty quietly powers the business

Using window functions and CTEs over orders and customers, we segment by **order count (loyalty)**:

| Tier             | Customers | Sales      | Profit     | Margin | Sales Share |
|------------------|----------:|-----------:|-----------:|-------:|-----------:|
| **Frequent (5+)** | 598       | $2.02M     | $260.2K    | 12.9%  | **87.9%**  |
| Occasional (2–4) | 183       | $273.6K    | $25.4K     | 9.3%   | 11.9%      |
| One-time         | 12        | $5.2K      | $0.77K     | 14.9%  | 0.2%       |

**Key points:**

- Nearly **88% of revenue** comes from customers with **5+ orders**.  
- One-time buyers are tiny in number and revenue – good to have, but not strategic.  
- RFM (Recency–Frequency–Monetary) analysis shows a **“High RFM” group (~20% of customers)** contributing **~35–40% of revenue at the strongest margins**.

**Insight:**  
This is a **relationship-driven business**: **repeat customers and high-RFM cohorts** are the real engine of growth and profitability.

> 📌 Strategy:  
> - Build **tiered loyalty / account programs** focused on **Frequent and High-RFM customers**.  
> - Design **targeted upsell, cross-sell and retention** campaigns rather than only chasing new acquisition.  
> - Track **“high-revenue but loss-making customers”** as a specific risk segment and review their pricing / discount structure.

---

### 5️⃣ Operations & Regional Nuances – where execution erodes value

SQL window functions over shipping lead times and regional joins show:

- **Shipping modes overall**

  - **Standard Class**:  
    - ≈ **$1.36M** sales, **12.1% margin**, median lead ≈ **5 days**  
  - **First Class & Same Day**:  
    - Still profitable, with margins around **12–14%** overall  

- **Region + Same Day**  
  - East / West: Same Day is **profitable**, with strong margins.  
  - **South + Same Day**:  
    - Sales ≈ **$28.9K**, **–$1.26K** profit → **–4.35% margin**

**Insight:**  
Fast shipping is not inherently bad for margin – **except** in the **South**, where Same Day becomes **loss-making**.

> 📌 Strategy:  
> - **Re-price or limit Same-Day** in the South (higher fees or restricted zones).  
> - Keep leveraging Same-Day / First Class in stronger regions as a **value-added service**, not a margin killer.

---

## Summary

- Shows **end-to-end use of SQL**: from building an **analytics-ready view** to advanced techniques like:
  - CTEs to structure business logic (discount bands, RFM, cohorts)
  - **Window functions** (`RANK`, `NTILE`, `LAG`, running totals)
  - **Correlation analysis** (`corr`) for **discount–profit sensitivity**
- Demonstrates how SQL can **directly support decisions** in:
  - **Pricing & discount policy**
  - **Product & assortment strategy**
  - **Customer segmentation and CLV-style thinking**
  - **Salesforce performance and incentive design**
  - **Regional and operational optimisation**


