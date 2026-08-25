-- =============================================================================
-- MASTER RESET & INITIALIZATION SCRIPT
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. DROP EXISTING TABLES (Reverse Dependency Order)
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS deliveries CASCADE;
DROP TABLE IF EXISTS delivery_partners CASCADE;
DROP TABLE IF EXISTS payments CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS coupons CASCADE;
DROP TABLE IF EXISTS cart_items CASCADE;
DROP TABLE IF EXISTS cart CASCADE;
DROP TABLE IF EXISTS reviews CASCADE;
DROP TABLE IF EXISTS product_variants CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS user_subscriptions CASCADE;
DROP TABLE IF EXISTS addresses CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- -----------------------------------------------------------------------------
-- 2. ENABLE EXTENSIONS
-- -----------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- -----------------------------------------------------------------------------
-- 3. CREATE TABLES (Correct Dependency Order)
-- -----------------------------------------------------------------------------

-- 1. USERS
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(15) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    date_of_birth DATE,
    gender VARCHAR(20) CHECK (gender IN ('MALE', 'FEMALE', 'OTHER', 'PREFER_NOT_TO_SAY')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT chk_email CHECK (email LIKE '%@%.%')
);

-- 2. ADDRESSES
CREATE TABLE addresses (
    address_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    street_address TEXT NOT NULL,
    city VARCHAR(50) NOT NULL,
    state VARCHAR(50) NOT NULL,
    postal_code VARCHAR(20) NOT NULL,
    country VARCHAR(50) DEFAULT 'India',
    is_default BOOLEAN DEFAULT FALSE,
    
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- 3. USER SUBSCRIPTIONS
CREATE TABLE user_subscriptions (
    subscription_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    plan_name VARCHAR(50) NOT NULL,
    status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'EXPIRED', 'CANCELLED')),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- 4. CATEGORIES
CREATE TABLE categories (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT
);

-- 5. PRODUCTS
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    category_id INT NOT NULL,
    title VARCHAR(150) NOT NULL,
    description TEXT,
    base_price NUMERIC(10, 2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_price CHECK (base_price >= 0)
);

-- 6. PRODUCT VARIANTS
CREATE TABLE product_variants (
    variant_id SERIAL PRIMARY KEY,
    product_id INT NOT NULL,
    color VARCHAR(30) NOT NULL,
    size VARCHAR(10) NOT NULL,
    stock_quantity INT DEFAULT 0,
    price_modifier NUMERIC(10, 2) DEFAULT 0.00,
    
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_stock CHECK (stock_quantity >= 0),
    CONSTRAINT unique_product_variant UNIQUE (product_id, color, size)
);

-- 7. REVIEWS
CREATE TABLE reviews (
    review_id SERIAL PRIMARY KEY,
    product_id INT NOT NULL,
    user_id INT NOT NULL,
    rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    review_text TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT unique_user_product_review UNIQUE (user_id, product_id)
);

-- 8. CART
CREATE TABLE cart (
    cart_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- 9. CART ITEMS
CREATE TABLE cart_items (
    cart_item_id SERIAL PRIMARY KEY,
    cart_id INT NOT NULL,
    variant_id INT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    added_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (cart_id) REFERENCES cart(cart_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (variant_id) REFERENCES product_variants(variant_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_cart_qty CHECK (quantity > 0),
    CONSTRAINT unique_cart_variant UNIQUE (cart_id, variant_id)
);

-- 10. COUPONS
CREATE TABLE coupons (
    coupon_id SERIAL PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    discount_percentage NUMERIC(5, 2) CHECK (discount_percentage BETWEEN 0 AND 100),
    max_discount_amount NUMERIC(10, 2),
    valid_until TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE
);

-- 11. ORDERS
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    address_id INT NOT NULL,
    coupon_id INT,
    order_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    total_amount NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    discount_amount NUMERIC(10, 2) DEFAULT 0.00,
    shipping_type VARCHAR(20) DEFAULT 'STANDARD' CHECK (shipping_type IN ('STANDARD', 'EXPRESS', 'SAME_DAY')),
    status VARCHAR(20) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'PROCESSING', 'SHIPPED', 'DELIVERED', 'CANCELLED')),
    
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (address_id) REFERENCES addresses(address_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (coupon_id) REFERENCES coupons(coupon_id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT chk_total CHECK (total_amount >= 0)
);

-- 12. ORDER ITEMS
CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id INT NOT NULL,
    variant_id INT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    unit_price NUMERIC(10, 2) NOT NULL,
    
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (variant_id) REFERENCES product_variants(variant_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_order_item_qty CHECK (quantity > 0)
);

-- 13. PAYMENTS
CREATE TABLE payments (
    payment_id SERIAL PRIMARY KEY,
    order_id INT NOT NULL UNIQUE,
    payment_method VARCHAR(20) NOT NULL CHECK (payment_method IN ('UPI', 'CREDIT_CARD', 'DEBIT_CARD', 'NET_BANKING', 'COD')),
    payment_status VARCHAR(20) DEFAULT 'PENDING' CHECK (payment_status IN ('PENDING', 'COMPLETED', 'FAILED', 'REFUNDED')),
    transaction_id VARCHAR(100) UNIQUE,
    payment_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- 14. DELIVERY PARTNERS
CREATE TABLE delivery_partners (
    partner_id SERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    phone_number VARCHAR(15) NOT NULL UNIQUE,
    vehicle_number VARCHAR(20),
    current_status VARCHAR(20) DEFAULT 'AVAILABLE' CHECK (current_status IN ('AVAILABLE', 'ON_DELIVERY', 'OFF_DUTY')),
    rating NUMERIC(3, 2) DEFAULT 5.00 CHECK (rating BETWEEN 1.00 AND 5.00)
);

-- 15. DELIVERIES
CREATE TABLE deliveries (
    delivery_id SERIAL PRIMARY KEY,
    order_id INT NOT NULL UNIQUE,
    partner_id INT NOT NULL,
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    delivered_at TIMESTAMP WITH TIME ZONE,
    delivery_otp VARCHAR(6),
    delivery_status VARCHAR(25) DEFAULT 'ASSIGNED' CHECK (delivery_status IN ('ASSIGNED', 'OUT_FOR_DELIVERY', 'DELIVERED', 'ATTEMPTED_FAILED', 'RETURNED')),
    
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (partner_id) REFERENCES delivery_partners(partner_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- -----------------------------------------------------------------------------
-- 4. INDEXES FOR PERFORMANCE
-- -----------------------------------------------------------------------------
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_addresses_user ON addresses(user_id);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_variants_product ON product_variants(product_id);
CREATE INDEX idx_reviews_product ON reviews(product_id);
CREATE INDEX idx_cart_user ON cart(user_id);
CREATE INDEX idx_cart_items_cart ON cart_items(cart_id);
CREATE INDEX idx_orders_user ON orders(user_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_deliveries_order ON deliveries(order_id);
CREATE INDEX idx_deliveries_partner ON deliveries(partner_id);

-- =============================================================================
-- Insert order respects Foreign Key constraints
-- =============================================================================

-- 1. USERS
INSERT INTO users (first_name, last_name, email, phone, password_hash, date_of_birth, gender) VALUES
('Aarav', 'Sharma', 'aarav.sharma@email.com', '+919876543210', 'hash_pass_1', '1995-04-12', 'MALE'),
('Priya', 'Verma', 'priya.verma@email.com', '+919876543211', 'hash_pass_2', '2001-08-25', 'FEMALE'),
('Rohan', 'Mehta', 'rohan.mehta@email.com', '+919876543212', 'hash_pass_3', '1988-11-03', 'MALE'),
('Ananya', 'Deshmukh', 'ananya.d@email.com', '+919876543213', 'hash_pass_4', '2003-01-15', 'FEMALE');

-- 2. ADDRESSES
INSERT INTO addresses (user_id, street_address, city, state, postal_code, country, is_default) VALUES
(1, '12 MG Road', 'Nagpur', 'Maharashtra', '440001', 'India', TRUE),
(2, '45 Park Street', 'Pune', 'Maharashtra', '411001', 'India', TRUE),
(3, '88 Civil Lines', 'Jaipur', 'Rajasthan', '302001', 'India', TRUE),
(4, '102 FC Road', 'Pune', 'Maharashtra', '411004', 'India', TRUE);

-- 3. USER SUBSCRIPTIONS
INSERT INTO user_subscriptions (user_id, plan_name, status, start_date, end_date) VALUES
(1, 'VIP_PRIME', 'ACTIVE', '2026-01-01', '2027-01-01'),
(3, 'GOLD_MEMBER', 'ACTIVE', '2026-03-15', '2026-09-15');

-- 4. CATEGORIES
INSERT INTO categories (category_name, description) VALUES
('Footwear', 'Running shoes, sneakers, and casual footwear'),
('Apparel', 'Men and Women casual clothing'),
('Electronics', 'Gadgets and accessories');

-- 5. PRODUCTS
INSERT INTO products (category_id, title, description, base_price) VALUES
(1, 'Air Max Pro', 'High-performance running shoes', 4999.00),
(2, 'Classic Cotton T-Shirt', '100% breathable cotton t-shirt', 799.00),
(3, 'Wireless Earbuds', 'Noise canceling Bluetooth earbuds', 2499.00);

-- 6. PRODUCT VARIANTS
INSERT INTO product_variants (product_id, color, size, stock_quantity, price_modifier) VALUES
(1, 'Red', '9', 50, 0.00),
(1, 'Black', '10', 30, 200.00),
(2, 'White', 'M', 100, 0.00),
(2, 'Blue', 'L', 80, 0.00),
(3, 'Black', 'OneSize', 40, 0.00);

-- 7. REVIEWS
INSERT INTO reviews (product_id, user_id, rating, review_text) VALUES
(1, 1, 5, 'Super comfortable running shoes!'),
(2, 2, 4, 'Great material, fits perfectly.'),
(3, 3, 5, 'Battery backup is amazing.');

-- 8. CART
INSERT INTO cart (user_id) VALUES
(1), (2), (3), (4);

-- 9. CART ITEMS
INSERT INTO cart_items (cart_id, variant_id, quantity) VALUES
(2, 3, 2),
(4, 5, 1);

-- 10. COUPONS
INSERT INTO coupons (code, discount_percentage, max_discount_amount, valid_until, is_active) VALUES
('WELCOME10', 10.00, 500.00, '2026-12-31 23:59:59', TRUE),
('SUMMER20', 20.00, 1000.00, '2026-09-30 23:59:59', TRUE);

-- 11. ORDERS
INSERT INTO orders (user_id, address_id, coupon_id, total_amount, discount_amount, shipping_type, status) VALUES
(1, 1, 1, 4699.10, 499.90, 'EXPRESS', 'DELIVERED'),
(2, 2, NULL, 799.00, 0.00, 'STANDARD', 'PROCESSING'),
(3, 3, 2, 2199.20, 499.80, 'SAME_DAY', 'DELIVERED');

-- 12. ORDER ITEMS
INSERT INTO order_items (order_id, variant_id, quantity, unit_price) VALUES
(1, 1, 1, 4999.00),
(2, 3, 1, 799.00),
(3, 5, 1, 2499.00);

-- 13. PAYMENTS
INSERT INTO payments (order_id, payment_method, payment_status, transaction_id) VALUES
(1, 'UPI', 'COMPLETED', 'TXN_99887766551'),
(2, 'CREDIT_CARD', 'PENDING', 'TXN_99887766552'),
(3, 'NET_BANKING', 'COMPLETED', 'TXN_99887766553');

-- 14. DELIVERY PARTNERS
INSERT INTO delivery_partners (full_name, phone_number, vehicle_number, current_status, rating) VALUES
('Suresh Kumar', '+919123456780', 'MH-31-AB-1234', 'AVAILABLE', 4.90),
('Ramesh Patel', '+919123456781', 'MH-12-CD-5678', 'ON_DELIVERY', 4.75);

-- 15. DELIVERIES
INSERT INTO deliveries (order_id, partner_id, delivery_otp, delivery_status, delivered_at) VALUES
(1, 1, '4589', 'DELIVERED', CURRENT_TIMESTAMP - INTERVAL '2 days'),
(3, 2, '1234', 'OUT_FOR_DELIVERY', NULL);

-- =============================================================================
-- TASK 1: Customer Demographics Analysis (5-Tier Life Stages)
-- =============================================================================
-- BUSINESS QUESTION:
-- How are our registered users distributed across different life stages?
-- Segment all users into five distinct age brackets (Kids, Teenagers, 
-- Young Adults, Adults, and Seniors) and calculate the total number 
-- of users in each segment to identify our core demographic target.
-- =============================================================================

CREATE OR REPLACE VIEW vw_customer_demographics AS
SELECT 
    CASE 
        WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, date_of_birth)) < 13 THEN 'Kids'
        WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, date_of_birth)) BETWEEN 13 AND 17 THEN 'Teenagers'
        WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, date_of_birth)) BETWEEN 18 AND 25 THEN 'Young Adults'
        WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, date_of_birth)) BETWEEN 26 AND 59 THEN 'Adults'
        ELSE 'Seniors'
    END AS age_group,
    COUNT(*) AS total_users
FROM users
GROUP BY age_group
ORDER BY total_users DESC;

-- =============================================================================
-- TASK 2: Revenue by Product Category
-- =============================================================================
-- BUSINESS QUESTION:
-- Which product categories generate the highest total sales revenue?
-- =============================================================================

CREATE OR REPLACE VIEW vw_product_revenue_ranking AS
SELECT 
    c.category_name,
    p.title AS product_name,
    SUM(oi.quantity) AS total_units_sold,
    SUM(oi.quantity * oi.unit_price) AS total_revenue,
    DENSE_RANK() OVER (
        PARTITION BY c.category_name 
        ORDER BY SUM(oi.quantity * oi.unit_price) DESC
    ) AS product_rank_in_category
FROM categories c
JOIN products p ON c.category_id = p.category_id
JOIN product_variants pv ON p.product_id = pv.product_id
JOIN order_items oi ON pv.variant_id = oi.variant_id
GROUP BY c.category_name, p.title
ORDER BY c.category_name ASC, total_revenue DESC;

-- =============================================================================
-- TASK 3: Unpaid or Pending Orders Audit
-- =============================================================================
-- BUSINESS QUESTION:
-- Which orders have NOT been paid for yet?
-- Fetch the customer's full name, email, order ID, total order amount, 
-- and payment status for all orders where payment_status IS NOT 'COMPLETED'.
-- =============================================================================

CREATE OR REPLACE VIEW vw_unpaid_orders AS
SELECT 
    CONCAT(u.first_name, ' ', u.last_name) AS full_name,
    u.email,
    o.order_id,
    o.total_amount,
    pay.payment_status,
    pay.payment_method
FROM users u
JOIN orders o ON u.user_id = o.user_id
JOIN payments pay ON o.order_id = pay.order_id
WHERE pay.payment_status != 'COMPLETED'
ORDER BY o.total_amount DESC;

-- =============================================================================
-- TASK 4: High-Value Customer Identification (Top 3 CLV)
-- =============================================================================
-- BUSINESS QUESTION:
-- Who are our top 3 most valuable customers based on total money spent on 
-- successful ('DELIVERED') orders?
-- Requirements: Display full name, email, total money spent, and total 
-- count of delivered orders. Order by highest spent and limit to top 3.
-- =============================================================================

CREATE OR REPLACE VIEW vw_top_3_clv_customers AS
SELECT 
    CONCAT(u.first_name, ' ', u.last_name) AS full_name,
    u.email,
    SUM(o.total_amount) AS total_money_spent,
    COUNT(o.order_id) AS total_delivered_orders
FROM users u
JOIN orders o ON u.user_id = o.user_id
WHERE o.status = 'DELIVERED'
GROUP BY u.user_id, u.first_name, u.last_name, u.email
ORDER BY total_money_spent DESC
LIMIT 3;

-- =============================================================================
-- TASK 5: Low-Stock Inventory Alert
-- =============================================================================
-- BUSINESS QUESTION:
-- Which product items are running critically low in our inventory?
-- List all product titles, their color, size, and remaining stock quantity 
-- for any variant that has fewer than 40 items left in stock.
-- =============================================================================

CREATE OR REPLACE VIEW vw_low_stock_alerts AS
SELECT 
    p.title AS product_name,
    pv.color,
    pv.size,
    pv.stock_quantity
FROM products p
JOIN product_variants pv ON p.product_id = pv.product_id
WHERE pv.stock_quantity < 40
ORDER BY pv.stock_quantity ASC;

-- =============================================================================
-- TASK 6: Monthly Revenue & Order Volume Trend
-- =============================================================================
-- BUSINESS QUESTION:
-- How is our business performing month over month in terms of completed orders 
-- and total revenue generated?
-- =============================================================================

CREATE OR REPLACE VIEW vw_monthly_revenue_trends AS
SELECT 
    DATE_TRUNC('month', order_date) AS order_month,
    COUNT(order_id) AS total_completed_orders,
    SUM(total_amount) AS total_monthly_revenue
FROM orders
WHERE status = 'DELIVERED'
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY order_month ASC;

-- =============================================================================
-- TASK 7: Delivery Time Performance Audit
-- =============================================================================
-- BUSINESS QUESTION:
-- Which delivered orders took longer than 5 days to reach the customer?
-- Display order ID, order date, delivery date, customer full name, and 
-- delivery duration in days.
-- =============================================================================

CREATE OR REPLACE VIEW vw_delayed_deliveries_audit AS
SELECT 
    o.order_id,
    CONCAT(u.first_name, ' ', u.last_name) AS full_name,
    o.order_date,
    d.delivered_at,
    (d.delivered_at::date - o.order_date::date) AS delivery_duration_days
FROM users u
JOIN orders o ON u.user_id = o.user_id
JOIN deliveries d ON o.order_id = d.order_id
WHERE d.delivery_status = 'DELIVERED'
AND (d.delivered_at::date - o.order_date::date) >5
ORDER BY delivery_duration_days DESC;

-- View 1: Customer Demographics Breakdown
SELECT * FROM vw_customer_demographics;

-- View 2: Product Revenue & Category Rankings
SELECT * FROM vw_product_revenue_ranking;

-- View 3: Unpaid & Pending Orders Audit
SELECT * FROM vw_unpaid_orders;

-- View 4: Top 3 High-Value Customers (CLV)
SELECT * FROM vw_top_3_clv_customers;

-- View 5: Low-Stock Inventory Alerts
SELECT * FROM vw_low_stock_alerts;

-- View 6: Monthly Revenue & Order Volume Trends
SELECT * FROM vw_monthly_revenue_trends;

-- View 7: Delayed Deliveries Audit (>5 Days)
SELECT * FROM vw_delayed_deliveries_audit;

