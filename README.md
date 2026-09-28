# CommercePulse — E-Commerce SQL & Database Analytics

A PostgreSQL project that models the core data of an e-commerce business and uses SQL to answer practical business questions.

The project was built to practice **relational database design, SQL querying, data integrity, and business analysis** using a realistic e-commerce scenario.

---

## 📌 Project Overview

CommercePulse represents the data behind an online shopping platform.

The database stores information about:

* Customers
* Customer addresses
* Subscriptions
* Product categories
* Products and product variants
* Shopping carts
* Customer reviews
* Coupons
* Orders and order items
* Payments
* Delivery partners
* Deliveries

After creating the database and populating it with sample data, I used PostgreSQL to create **7 analytical views** that answer common business questions related to customers, sales, inventory, payments, and delivery performance.

The main goal of this project was not just to create tables, but to understand how business data is connected and how SQL can be used to turn that data into useful information.

---

## 🎯 Project Objectives

The project focuses on four main objectives:

1. Build a structured relational database for an e-commerce business.
2. Connect related business entities using primary keys and foreign keys.
3. Maintain data quality using constraints and appropriate data types.
4. Use SQL to answer practical business questions through reusable analytical views.

---

## 🏗️ Database Structure

The database contains **15 interconnected tables**.

### 👤 Customer Management

| Table                | Purpose                                                                          |
| -------------------- | -------------------------------------------------------------------------------- |
| `users`              | Stores customer information such as name, email, phone, date of birth and gender |
| `addresses`          | Stores customer addresses                                                        |
| `user_subscriptions` | Stores customer subscription information                                         |

### 🛍️ Product & Catalog Management

| Table              | Purpose                                                                 |
| ------------------ | ----------------------------------------------------------------------- |
| `categories`       | Stores product categories                                               |
| `products`         | Stores the main product information                                     |
| `product_variants` | Stores product options such as color, size, stock and price differences |

### 🛒 Customer Activity

| Table        | Purpose                                          |
| ------------ | ------------------------------------------------ |
| `cart`       | Stores a customer's active shopping cart         |
| `cart_items` | Stores products added to the cart                |
| `reviews`    | Stores customer ratings and reviews for products |

### 🎟️ Orders & Payments

| Table         | Purpose                                             |
| ------------- | --------------------------------------------------- |
| `coupons`     | Stores discount coupon information                  |
| `orders`      | Stores order-level information                      |
| `order_items` | Stores the individual products included in an order |
| `payments`    | Stores payment information for orders               |

### 🚚 Delivery

| Table               | Purpose                             |
| ------------------- | ----------------------------------- |
| `delivery_partners` | Stores delivery partner information |
| `deliveries`        | Stores order delivery information   |

---

## 🔗 How the Main Tables Connect

The database follows the flow of a typical online purchase:

```text
User
  ↓
Order
  ↓
Order Items
  ↓
Product Variant
  ↓
Product
  ↓
Category
```

Other important relationships include:

```text
User → Addresses

User → Cart → Cart Items → Product Variants

User → Reviews → Products

Order → Payment

Order → Delivery → Delivery Partner

Order → Coupon
```

This structure allows information from different parts of the business to be combined when performing analysis.

For example, I can connect an order to a customer, then connect that order to its products and calculate product-level revenue.

---

## 🧩 Why Products and Product Variants Are Separate

A product can have multiple versions.

For example:

```text
Air Max Pro
│
├── Black / Size 9
├── Black / Size 10
├── Red / Size 9
└── Red / Size 10
```

The `products` table stores the main product information, while `product_variants` stores the specific options and stock levels.

This makes it possible to track inventory at the variant level.

---

## 🧾 Why Orders and Order Items Are Separate

An order can contain multiple products.

For example:

```text
Order #101
│
├── Air Max Pro × 1
├── Classic T-Shirt × 2
└── Wireless Earbuds × 1
```

Therefore:

* `orders` stores information about the overall order.
* `order_items` stores the individual products inside that order.

The `unit_price` is also stored in `order_items` so that the price paid for an item remains available even if the product's current price changes later.

---

## 🔐 Data Integrity

I used PostgreSQL constraints to reduce invalid or inconsistent data.

### Primary Keys

Each table has a primary key to uniquely identify its records.

Example:

```sql
user_id SERIAL PRIMARY KEY
```

### Foreign Keys

Foreign keys connect related tables.

For example:

```text
orders.user_id
        ↓
users.user_id
```

This allows order information to be connected back to the customer who placed the order.

### UNIQUE Constraints

Used where duplicate values should not normally exist.

Examples include:

* Customer email
* Customer phone
* Category name
* Product variant combination
* Coupon code
* Transaction ID

### CHECK Constraints

Used to control acceptable values.

Examples:

```text
Product price ≥ 0
Stock quantity ≥ 0
Order quantity > 0
Rating between 1 and 5
Discount percentage between 0 and 100
```

### NOT NULL

Used for fields where a value is required for the record to make sense.

---

# 📊 Business Questions & Analytical Views

After creating the database, I created **7 PostgreSQL views** to answer practical business questions.

---

## 1. Customer Demographics

### View

```text
vw_customer_demographics
```

### Business Question

> How are registered users distributed across different age groups?

### What it does

The query calculates age from the customer's date of birth and groups customers into:

* Kids
* Teenagers
* Young Adults
* Adults
* Seniors

### SQL Concepts Used

* `CASE`
* `AGE()`
* `EXTRACT()`
* `GROUP BY`
* `COUNT()`

### Why it matters

This can help understand the demographic composition of the customer base.

---

## 2. Product Revenue Ranking

### View

```text
vw_product_revenue_ranking
```

### Business Question

> Which products generate the most revenue within each category?

### What it does

The query calculates:

* Total units sold
* Total revenue
* Product rank within its category

The ranking is performed using:

```sql
DENSE_RANK()
```

### SQL Concepts Used

* Multiple `JOIN`s
* `SUM()`
* `GROUP BY`
* `DENSE_RANK()`
* `PARTITION BY`

### Why it matters

This can help identify products that perform strongly within their respective categories.

---

## 3. Unpaid Orders Audit

### View

```text
vw_unpaid_orders
```

### Business Question

> Which orders do not have a completed payment?

### What it does

The query connects:

```text
Users → Orders → Payments
```

and identifies orders where the payment status is not `COMPLETED`.

### SQL Concepts Used

* `JOIN`
* `WHERE`
* Filtering
* Combining customer and transaction information

### Why it matters

This can help identify orders that may require payment follow-up.

---

## 4. Top 3 Customers by Delivered-Order Spend

### View

```text
vw_top_3_clv_customers
```

### Business Question

> Which customers have spent the most on delivered orders?

### What it does

The query:

* Considers delivered orders
* Calculates total money spent by each customer
* Counts their delivered orders
* Returns the top 3 customers

### SQL Concepts Used

* `JOIN`
* `SUM()`
* `COUNT()`
* `GROUP BY`
* `ORDER BY`
* `LIMIT`

### Why it matters

This helps identify customers who have generated high delivered-order value.

> **Note:** In this project, this view represents top customers by delivered-order spend. It is not intended to be a complete customer lifetime value model with retention, margin, acquisition cost, or future value.

---

## 5. Low-Stock Inventory Alerts

### View

```text
vw_low_stock_alerts
```

### Business Question

> Which product variants have critically low stock?

### Rule Used

```text
stock quantity < 40
```

### Output Includes

* Product name
* Color
* Size
* Remaining stock

### SQL Concepts Used

* `JOIN`
* `WHERE`
* Filtering

### Why it matters

This can help identify products that may require inventory replenishment.

---

## 6. Monthly Revenue & Order Trends

### View

```text
vw_monthly_revenue_trends
```

### Business Question

> How does completed-order revenue change over time?

### What it does

The query considers delivered orders and groups them by month.

It calculates:

* Completed order count
* Monthly revenue

The month is created using:

```sql
DATE_TRUNC('month', order_date)
```

### SQL Concepts Used

* `DATE_TRUNC()`
* `COUNT()`
* `SUM()`
* `GROUP BY`
* Date-based analysis

### Why it matters

This provides a simple view of monthly sales performance.

---

## 7. Delivery Performance Audit

### View

```text
vw_delayed_deliveries_audit
```

### Business Question

> Which delivered orders took more than 5 days to reach the customer?

### What it does

The query compares:

```text
Order Date
        ↓
Delivery Date
```

and calculates the delivery duration.

Orders taking more than 5 days are flagged for review.

### SQL Concepts Used

* Date arithmetic
* `JOIN`
* Filtering
* Calculated fields

### Why it matters

This can help identify potentially delayed deliveries and support basic delivery-performance analysis.

---

# 🛠️ Technical Skills Demonstrated

### Database

* PostgreSQL
* pgAdmin 4

### SQL

* `CREATE TABLE`
* `INSERT`
* Primary Keys
* Foreign Keys
* `UNIQUE`
* `CHECK`
* `NOT NULL`
* `JOIN`
* `LEFT JOIN`
* `GROUP BY`
* `ORDER BY`
* `WHERE`
* `CASE WHEN`
* Aggregate functions
* Date functions
* `DATE_TRUNC()`
* `AGE()`
* `EXTRACT()`
* Window functions
* `DENSE_RANK()`
* SQL Views
* Indexes

---

# 📁 Repository Contents

```text
CommercePulse-Database-Architecture/
│
├── E-Commerce db.sql
│   └── Database creation, sample data and analytical views
│
├── ER diagram.png
│   └── Visual representation of the database relationships
│
├── ER Diagram.pdf
│   └── PDF version of the ER diagram
│
└── README.md
    └── Project documentation
```

---

# ▶️ How to Run the Project

### 1. Install PostgreSQL

Install PostgreSQL and open the database using **pgAdmin 4** or another PostgreSQL client.

### 2. Create a Database

Create a new PostgreSQL database.

For example:

```sql
CREATE DATABASE commercepulse;
```

### 3. Open the SQL File

Open:

```text
E-Commerce db.sql
```

in the PostgreSQL query editor.

### 4. Run the Script

The SQL script:

1. Removes existing project tables if required
2. Enables the required PostgreSQL extension
3. Creates the tables
4. Adds constraints
5. Creates indexes
6. Inserts sample data
7. Creates the analytical views

### 5. Explore the Views

After running the script, the analytical views can be queried like tables.

Example:

```sql
SELECT *
FROM vw_monthly_revenue_trends;
```

---

# 📈 What I Learned From This Project

This project helped me understand that SQL is not only about writing individual queries.

I learned how to:

* Think about how business entities are connected
* Structure data into related tables
* Use keys to maintain relationships
* Apply constraints to improve data quality
* Work with multiple related tables
* Translate business questions into SQL
* Use aggregation to create business metrics
* Use window functions for ranking
* Work with dates and time-based analysis
* Create reusable SQL views
* Think about data from both a database and business perspective

---

# ⚠️ Project Scope

CommercePulse is a **portfolio project focused on SQL, relational data and business analysis**.

The database intentionally models the core e-commerce workflow without trying to reproduce every feature of a production-scale e-commerce platform.

Some real-world processes, such as multiple payment attempts, complex shipment splitting and advanced inventory history, could be modeled in greater depth in a larger system.

The purpose of this project is to demonstrate practical PostgreSQL and SQL skills that are relevant to data analysis.

---

# 🚀 Possible Future Improvements

If this project is expanded in the future, possible additions could include:

* More realistic payment history
* Detailed refund tracking
* Shipment-level order splitting
* Inventory movement history
* More advanced customer analysis
* Product/category performance analysis
* Additional sales and customer retention metrics
* Power BI reporting using the PostgreSQL database

These are intentionally outside the current project scope.

---

# 🎯 Project Takeaway

CommercePulse demonstrates how a relational PostgreSQL database can be used as a foundation for business analysis.

The project follows a simple flow:

```text
Business Data
      ↓
Relational Database
      ↓
SQL Queries
      ↓
Business Metrics
      ↓
Analytical Views
      ↓
Business Insights
```

The main objective was to build a database that is **structured, understandable and useful for analysis**, while demonstrating practical SQL skills through realistic business questions.

---

## 👤 Author

**Maheen Sheikh**

Aspiring Data Analyst | SQL | PostgreSQL | Excel | Power BI | Python

GitHub: [Maheen-Sheikh2005](https://github.com/Maheen-Sheikh2005)

---

⭐ If you find this project useful, feel free to explore the SQL script and ER diagram.
