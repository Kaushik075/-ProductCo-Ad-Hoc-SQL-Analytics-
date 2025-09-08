# 🚀 ProductCo Ad Hoc SQL Analytics Project  

## 📌 Overview  
This project simulates **real-world ad hoc analytics** in a **product-based SaaS company**, solving advanced business problems using SQL on a dataset of **2M+ transactions**.  

The focus is on **end-to-end analytics**:  
- Schema design (fact + dimension tables)  
- Ad hoc SQL queries (advanced CTEs, window functions, cohorts, churn detection)  
- Insights + recommendations  

---

## 🏗️ Schema Design  
Star Schema with Fact + Dimension tables:  

- **Dimension Tables**  
  - `dim_users`  
  - `dim_products`  
  - `dim_features`  
  - `dim_regions`  
  - `dim_subscription_plans`  
  - `dim_time`  

- **Fact Tables**  
  - `fact_events` (usage logs)  
  - `fact_payments`  
  - `fact_feedback`  
  - `fact_upgrades`  
  - `fact_cohorts`  

📊 See schema ERD → ![ERD](images/schema.png)  

---

## ❓ Business Problems Solved  

### Product Usage  
- % of new users adopting a feature within 7 days.  
- Weekly retention rates by feature.  
- Average events per DAU.  

### Revenue & Monetization  
- ARPU by region & plan type.  
- Features triggering Free → Paid upgrades.  
- Revenue decomposition (new, expansion, churn recoveries).  

### Retention & Churn  
- Cohort retention at 30, 60, 90 days.  
- Top 10 churn-risk users based on declining usage.  

### Support & Feedback  
- Usage frequency vs ratings correlation.  
- Features with lowest user ratings.  

### Advanced FAANG-Style Insights  
- Detect anomalous usage patterns.  
- Segment users by adoption speed and compare ARPU & churn.  

---
