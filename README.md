# CommercePulse-Database-Architecture
# E-Commerce Relational Database & Business Analytics

An end-to-end relational database engineered in PostgreSQL to support a full-scale e-commerce platform. This project models complex business operations—from customer management and inventory cataloging to payment reconciliation and order fulfillment—and translates raw transactional data into actionable operational insights.

---

## Business Objectives

Modern e-commerce platforms generate vast amounts of structured data daily. The primary goal of this project was to:
1. Architect an optimal, normalized relational schema supporting multi-entity operational workflows.
2. Maintain data integrity through explicit key constraints and precise data types.
3. Solve core operational and financial questions by engineering reusable database views for real-time reporting.

---

## Schema Architecture & Data Model

The database comprises **15 interconnected tables** organized into core operational modules:

* **User & Demographics:** `users`
* **Catalog & Inventory:** `categories`, `products`, `product_variants`
* **Order Processing:** `orders`, `order_items`
* **Logistics & Delivery:** `deliveries`, `delivery_partners`
* **Financial Operations:** `payments`, `refunds`, `coupons`
* **Engagement & Support:** `reviews`, `wishlist`, `cart_items`, `addresses`

### Entity Relationship Diagram (ERD)
The full relational layout, foreign key dependencies, and entity associations are detailed in the visual ER diagram included in this repository:
![E-Commerce ER Diagram](./ER_diagram.png)



---

## Strategic Business Queries & Analytical Views

To support executive decision-making and cross-departmental auditing, the following 7 analytical queries were engineered and wrapped into permanent PostgreSQL views (`CREATE VIEW`).

### 1. Customer Life-Stage Demographics (`vw_customer_demographics`)
* **Purpose:** Categorizes the active customer base into five distinct age brackets (Kids, Teenagers, Young Adults, Adults, and Seniors).
* **Business Impact:** Helps marketing teams optimize age-targeted ad spend and tailor product recommendations to dominant demographic tiers.

### 2. Category-Level Product Revenue Ranking (`vw_product_revenue_ranking`)
* **Purpose:** Calculates total revenue per product and uses the `DENSE_RANK()` window function to rank items relative to their product category.
* **Business Impact:** Highlights top-performing SKUs within each category to optimize promotional placement and cross-selling strategies.

### 3. Unpaid & Pending Orders Audit (`vw_unpaid_orders`)
* **Purpose:** Filters transactions where payment status is incomplete or failed, matching user contact details with unpaid order values.
* **Business Impact:** Enables finance and customer support teams to recover pending revenue, identify payment gateway drop-offs, and clear cart bottlenecks.

### 4. Top Customer Lifetime Value (CLV) (`vw_top_3_clv_customers`)
* **Purpose:** Aggregates cumulative order amounts for fulfilled deliveries to identify the top three highest-spending buyers.
* **Business Impact:** Empowers VIP retention initiatives, loyalty reward programs, and personalized outreach for core spenders.

### 5. Low-Stock Inventory Alerts (`vw_low_stock_alerts`)
* **Purpose:** Monitors stock counts across all product variants and flags any item falling below critical threshold limits (< 40 units).
* **Business Impact:** Prevents stockout events, aligns reorder triggers with supply chain vendors, and ensures seamless order fulfillment.

### 6. Monthly Revenue & Order Volume Trends (`vw_monthly_revenue_trends`)
* **Purpose:** Uses `DATE_TRUNC` to aggregate monthly completed order volumes and total net revenue performance over time.
* **Business Impact:** Provides leadership with historical trajectory data to evaluate seasonal sales peaks, forecast future demand, and track month-over-month growth.

### 7. Delivery SLA & Logistics Audit (`vw_delayed_deliveries_audit`)
* **Purpose:** Measures fulfillment timelines by calculating the delta between order creation and final delivery, flagging fulfilled orders taking over 5 days.
* **Business Impact:** Audits third-party courier performance, isolates regional delivery bottlenecks, and improves overall logistics efficiency.

---

## Technical Stack & Methods

* **Database System:** PostgreSQL
* **Management Tool:** pgAdmin 4
* **SQL Capabilities Applied:** DDL/DML, Foreign Key Cascading, Date/Time Arithmetic (`DATE_TRUNC`, `INTERVAL`), Window Functions (`DENSE_RANK`), Multi-Table Joins (`INNER`, `LEFT`), Conditional Aggregations (`CASE WHEN`), and Stored Relational Views.

---

