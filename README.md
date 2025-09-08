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
# Schema Setup 

<img width="1624" height="2552" alt="Image" src="https://github.com/user-attachments/assets/fa23793c-8e80-4bab-8fa3-e1f58fe03600" />
<img width="1860" height="2752" alt="Image" src="https://github.com/user-attachments/assets/ca055491-e9b9-4c35-8178-5d64aa0bd823" />
<img width="1792" height="1990" alt="Image" src="https://github.com/user-attachments/assets/591d5b84-46ca-4043-af0c-df0fc3b28e1b" />

---
# Queries

<img width="2048" height="2262" alt="Image" src="https://github.com/user-attachments/assets/f1ad6ee2-dd16-46c2-976e-c42eda2b9f64" />
<img width="2048" height="3546" alt="Image" src="https://github.com/user-attachments/assets/76fd9252-2300-40da-a203-5cd40e915f14" />
