-- Run ONCE in a fresh database. Original data credited in README.md.
-- Original Northstar Retail dataset from the supplied GrowDataSkills Notion page
BEGIN;
CREATE SCHEMA northstar_retail;
SET search_path TO northstar_retail, public;
CREATE TABLE customers (
    customer_id INTEGER PRIMARY KEY,
    customer_name VARCHAR(60) NOT NULL,
    signup_date DATE NOT NULL,
    acquisition_channel VARCHAR(20) NOT NULL
        CHECK (acquisition_channel IN ('Organic','Paid Search','Referral','Social')),
    city VARCHAR(40) NOT NULL,
    region VARCHAR(10) NOT NULL CHECK (region IN ('North','South','West'))
);

CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customers(customer_id),
    order_date DATE NOT NULL,
    status VARCHAR(15) NOT NULL
        CHECK (status IN ('delivered','cancelled','in_transit')),
    warehouse VARCHAR(15) NOT NULL CHECK (warehouse IN ('North Hub','South Hub')),
    promised_delivery_date DATE,
    delivered_date DATE,
    shipping_charged NUMERIC(10,2) NOT NULL CHECK (shipping_charged >= 0),
    shipping_cost NUMERIC(10,2) NOT NULL CHECK (shipping_cost >= 0),
    CHECK (promised_delivery_date IS NULL OR promised_delivery_date >= order_date),
    CHECK (delivered_date IS NULL OR delivered_date >= order_date),
    CHECK ((status = 'delivered' AND delivered_date IS NOT NULL)
        OR (status <> 'delivered' AND delivered_date IS NULL)),
    CHECK (status <> 'cancelled' OR (shipping_charged = 0 AND shipping_cost = 0))
);

CREATE TABLE order_items (
    order_id INTEGER NOT NULL REFERENCES orders(order_id),
    item_number INTEGER NOT NULL CHECK (item_number > 0),
    product_id INTEGER NOT NULL,
    product_name VARCHAR(60) NOT NULL,
    category VARCHAR(20) NOT NULL
        CHECK (category IN ('Electronics','Home','Fitness','Accessories')),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(10,2) NOT NULL CHECK (unit_price > 0),
    discount_amount NUMERIC(10,2) NOT NULL CHECK (discount_amount >= 0),
    unit_cost NUMERIC(10,2) NOT NULL CHECK (unit_cost >= 0),
    returned_quantity INTEGER NOT NULL CHECK (returned_quantity >= 0),
    refund_amount NUMERIC(10,2) NOT NULL CHECK (refund_amount >= 0),
    PRIMARY KEY (order_id, item_number),
    UNIQUE (order_id, product_id),
    CHECK (discount_amount <= quantity * unit_price),
    CHECK (returned_quantity <= quantity),
    CHECK (refund_amount <= quantity * unit_price - discount_amount),
    CHECK (returned_quantity > 0 OR refund_amount = 0)
);

INSERT INTO customers (customer_id, customer_name, signup_date, acquisition_channel, city, region) VALUES
(1, 'Customer 001', '2024-12-25', 'Organic', 'Delhi', 'North'),
(2, 'Customer 002', '2024-12-15', 'Paid Search', 'Jaipur', 'North'),
(3, 'Customer 003', '2024-12-25', 'Referral', 'Bengaluru', 'South'),
(4, 'Customer 004', '2024-12-23', 'Social', 'Chennai', 'South'),
(5, 'Customer 005', '2024-12-16', 'Organic', 'Mumbai', 'West'),
(6, 'Customer 006', '2025-01-05', 'Paid Search', 'Pune', 'West'),
(7, 'Customer 007', '2024-12-24', 'Referral', 'Delhi', 'North'),
(8, 'Customer 008', '2024-12-27', 'Social', 'Jaipur', 'North'),
(9, 'Customer 009', '2025-01-31', 'Organic', 'Bengaluru', 'South'),
(10, 'Customer 010', '2025-01-30', 'Paid Search', 'Chennai', 'South'),
(11, 'Customer 011', '2025-01-30', 'Referral', 'Mumbai', 'West'),
(12, 'Customer 012', '2025-02-05', 'Social', 'Pune', 'West'),
(13, 'Customer 013', '2025-02-04', 'Organic', 'Delhi', 'North'),
(14, 'Customer 014', '2025-01-29', 'Paid Search', 'Jaipur', 'North'),
(15, 'Customer 015', '2025-02-07', 'Referral', 'Bengaluru', 'South'),
(16, 'Customer 016', '2025-02-20', 'Social', 'Chennai', 'South'),
(17, 'Customer 017', '2025-02-08', 'Organic', 'Mumbai', 'West'),
(18, 'Customer 018', '2025-02-23', 'Paid Search', 'Pune', 'West'),
(19, 'Customer 019', '2025-02-16', 'Referral', 'Delhi', 'North'),
(20, 'Customer 020', '2025-03-30', 'Social', 'Jaipur', 'North'),
(21, 'Customer 021', '2025-03-31', 'Organic', 'Bengaluru', 'South'),
(22, 'Customer 022', '2025-03-17', 'Paid Search', 'Chennai', 'South'),
(23, 'Customer 023', '2025-04-03', 'Referral', 'Mumbai', 'West'),
(24, 'Customer 024', '2025-03-31', 'Social', 'Pune', 'West'),
(25, 'Customer 025', '2025-04-10', 'Organic', 'Delhi', 'North'),
(26, 'Customer 026', '2025-05-02', 'Paid Search', 'Jaipur', 'North'),
(27, 'Customer 027', '2025-05-01', 'Referral', 'Bengaluru', 'South'),
(28, 'Customer 028', '2025-04-17', 'Social', 'Chennai', 'South'),
(29, 'Customer 029', '2025-04-22', 'Organic', 'Mumbai', 'West'),
(30, 'Customer 030', '2025-05-10', 'Paid Search', 'Pune', 'West'),
(31, 'Customer 031', '2025-05-31', 'Referral', 'Delhi', 'North'),
(32, 'Customer 032', '2025-06-01', 'Social', 'Jaipur', 'North'),
(33, 'Customer 033', '2025-05-24', 'Organic', 'Bengaluru', 'South'),
(34, 'Customer 034', '2025-06-12', 'Paid Search', 'Chennai', 'South'),
(35, 'Customer 035', '2025-06-27', 'Referral', 'Mumbai', 'West'),
(36, 'Customer 036', '2025-06-30', 'Social', 'Pune', 'West'),
(37, 'Customer 037', '2025-06-27', 'Organic', 'Delhi', 'North'),
(38, 'Customer 038', '2025-07-29', 'Paid Search', 'Jaipur', 'North'),
(39, 'Customer 039', '2025-07-24', 'Referral', 'Bengaluru', 'South'),
(40, 'Customer 040', '2025-07-12', 'Social', 'Chennai', 'South'),
(41, 'Customer 041', '2025-08-09', 'Organic', 'Mumbai', 'West'),
(42, 'Customer 042', '2025-08-26', 'Paid Search', 'Pune', 'West'),
(43, 'Customer 043', '2025-08-25', 'Referral', 'Delhi', 'North'),
(44, 'Customer 044', '2025-08-14', 'Social', 'Jaipur', 'North'),
(45, 'Customer 045', '2025-09-24', 'Organic', 'Bengaluru', 'South'),
(46, 'Customer 046', '2025-09-12', 'Paid Search', 'Chennai', 'South'),
(47, 'Customer 047', '2025-10-04', 'Referral', 'Mumbai', 'West'),
(48, 'Customer 048', '2025-10-07', 'Social', 'Pune', 'West'),
(49, 'Customer 049', '2025-10-18', 'Organic', 'Delhi', 'North'),
(50, 'Customer 050', '2025-10-23', 'Paid Search', 'Jaipur', 'North'),
(51, 'Customer 051', '2025-11-03', 'Referral', 'Bengaluru', 'South'),
(52, 'Customer 052', '2025-11-22', 'Social', 'Chennai', 'South'),
(53, 'Customer 053', '2025-11-19', 'Organic', 'Mumbai', 'West'),
(54, 'Customer 054', '2025-11-11', 'Paid Search', 'Pune', 'West'),
(55, 'Customer 055', '2025-11-01', 'Referral', 'Delhi', 'North'),
(56, 'Customer 056', '2025-11-02', 'Social', 'Jaipur', 'North'),
(57, 'Customer 057', '2025-11-03', 'Organic', 'Bengaluru', 'South'),
(58, 'Customer 058', '2025-11-04', 'Paid Search', 'Chennai', 'South'),
(59, 'Customer 059', '2025-11-05', 'Referral', 'Mumbai', 'West'),
(60, 'Customer 060', '2025-11-06', 'Social', 'Pune', 'West');

INSERT INTO orders (order_id, customer_id, order_date, status, warehouse, promised_delivery_date, delivered_date, shipping_charged, shipping_cost) VALUES
(1001, 1, '2025-01-01', 'delivered', 'North Hub', '2025-01-06', '2025-01-06', 49, 75),
(1002, 2, '2025-01-01', 'delivered', 'North Hub', '2025-01-06', '2025-01-05', 49, 75),
(1003, 3, '2025-01-02', 'delivered', 'South Hub', '2025-01-07', '2025-01-04', 49, 60),
(1004, 4, '2025-01-02', 'delivered', 'South Hub', '2025-01-07', '2025-01-04', 0, 45),
(1005, 5, '2025-01-03', 'delivered', 'South Hub', '2025-01-10', '2025-01-15', 49, 130),
(1006, 6, '2025-01-10', 'delivered', 'South Hub', '2025-01-17', '2025-01-17', 49, 115),
(1007, 7, '2025-01-12', 'delivered', 'North Hub', '2025-01-17', '2025-01-25', 49, 45),
(1008, 8, '2025-01-13', 'delivered', 'North Hub', '2025-01-18', '2025-01-15', 0, 90),
(1009, 7, '2025-01-15', 'delivered', 'North Hub', '2025-01-20', '2025-01-20', 49, 60),
(1010, 1, '2025-01-20', 'delivered', 'North Hub', '2025-01-25', '2025-01-22', 49, 75),
(1011, 4, '2025-01-21', 'delivered', 'South Hub', '2025-01-26', '2025-01-24', 49, 60),
(1012, 1, '2025-01-22', 'delivered', 'North Hub', '2025-01-27', '2025-01-27', 0, 75),
(1013, 1, '2025-01-24', 'cancelled', 'North Hub', '2025-01-29', NULL, 0, 0),
(1014, 3, '2025-01-24', 'delivered', 'South Hub', '2025-01-29', '2025-02-03', 49, 60),
(1015, 9, '2025-02-01', 'delivered', 'South Hub', '2025-02-06', '2025-02-04', 49, 75),
(1016, 10, '2025-02-04', 'delivered', 'South Hub', '2025-02-09', '2025-02-13', 0, 60),
(1017, 11, '2025-02-04', 'delivered', 'North Hub', '2025-02-11', '2025-02-13', 49, 85),
(1018, 12, '2025-02-09', 'delivered', 'North Hub', '2025-02-16', '2025-02-14', 49, 130),
(1019, 13, '2025-02-11', 'delivered', 'North Hub', '2025-02-16', '2025-02-19', 49, 60),
(1020, 14, '2025-02-14', 'delivered', 'North Hub', '2025-02-19', '2025-02-16', 0, 60),
(1021, 11, '2025-02-14', 'delivered', 'South Hub', '2025-02-21', '2025-02-23', 49, 100),
(1022, 3, '2025-02-14', 'delivered', 'South Hub', '2025-02-19', '2025-02-17', 49, 75),
(1023, 6, '2025-02-16', 'delivered', 'North Hub', '2025-02-23', '2025-02-28', 49, 85),
(1024, 8, '2025-02-16', 'delivered', 'North Hub', '2025-02-21', '2025-02-19', 0, 45),
(1025, 13, '2025-02-17', 'delivered', 'North Hub', '2025-02-22', '2025-02-19', 49, 45),
(1026, 4, '2025-02-19', 'cancelled', 'South Hub', '2025-02-24', NULL, 0, 0),
(1027, 5, '2025-02-20', 'delivered', 'South Hub', '2025-02-27', '2025-02-24', 49, 100),
(1028, 12, '2025-02-23', 'delivered', 'North Hub', '2025-03-02', '2025-02-28', 0, 100),
(1029, 15, '2025-03-01', 'delivered', 'South Hub', '2025-03-06', '2025-03-10', 49, 60),
(1030, 16, '2025-03-01', 'delivered', 'South Hub', '2025-03-06', '2025-03-04', 49, 60),
(1031, 17, '2025-03-03', 'delivered', 'North Hub', '2025-03-10', '2025-03-15', 49, 130),
(1032, 18, '2025-03-04', 'delivered', 'South Hub', '2025-03-11', '2025-03-10', 0, 115),
(1033, 19, '2025-03-06', 'delivered', 'North Hub', '2025-03-11', '2025-03-09', 49, 90),
(1034, 8, '2025-03-07', 'delivered', 'North Hub', NULL, '2025-03-09', 49, 45),
(1035, 13, '2025-03-09', 'delivered', 'North Hub', '2025-03-14', '2025-03-12', 49, 60),
(1036, 4, '2025-03-10', 'delivered', 'South Hub', '2025-03-15', '2025-03-13', 0, 45),
(1037, 7, '2025-03-11', 'delivered', 'North Hub', '2025-03-16', '2025-03-16', 49, 90),
(1038, 17, '2025-03-13', 'delivered', 'North Hub', '2025-03-20', '2025-03-17', 49, 115),
(1039, 19, '2025-03-14', 'delivered', 'North Hub', '2025-03-19', '2025-03-16', 49, 45),
(1040, 13, '2025-03-16', 'delivered', 'North Hub', '2025-03-21', '2025-03-19', 0, 45),
(1041, 17, '2025-03-17', 'cancelled', 'South Hub', '2025-03-24', NULL, 0, 0),
(1042, 14, '2025-03-17', 'delivered', 'North Hub', '2025-03-22', '2025-03-20', 49, 60),
(1043, 6, '2025-03-20', 'delivered', 'South Hub', '2025-03-27', '2025-03-24', 49, 115),
(1044, 2, '2025-03-24', 'cancelled', 'North Hub', '2025-03-29', NULL, 0, 0),
(1045, 20, '2025-04-02', 'delivered', 'North Hub', '2025-04-07', '2025-04-05', 49, 45),
(1046, 21, '2025-04-03', 'delivered', 'South Hub', '2025-04-08', '2025-04-05', 49, 90),
(1047, 22, '2025-04-04', 'delivered', 'South Hub', '2025-04-09', '2025-04-08', 49, 75),
(1048, 23, '2025-04-04', 'delivered', 'North Hub', '2025-04-11', '2025-04-08', 0, 130),
(1049, 24, '2025-04-06', 'delivered', 'South Hub', '2025-04-13', '2025-04-13', 49, 85),
(1050, 7, '2025-04-07', 'delivered', 'North Hub', '2025-04-12', '2025-04-10', 49, 60),
(1051, 9, '2025-04-08', 'delivered', 'South Hub', '2025-04-13', '2025-04-13', 49, 45),
(1052, 10, '2025-04-10', 'delivered', 'South Hub', '2025-04-15', '2025-04-15', 0, 75),
(1053, 5, '2025-04-13', 'delivered', 'North Hub', '2025-04-20', '2025-04-18', 49, 115),
(1054, 5, '2025-04-14', 'delivered', 'South Hub', '2025-04-21', '2025-04-20', 49, 85),
(1055, 5, '2025-04-15', 'delivered', 'North Hub', '2025-04-22', '2025-04-19', 49, 100),
(1056, 16, '2025-04-20', 'delivered', 'South Hub', '2025-04-25', '2025-05-01', 0, 60),
(1057, 2, '2025-04-21', 'delivered', 'North Hub', '2025-04-26', '2025-05-02', 49, 75),
(1058, 10, '2025-04-21', 'delivered', 'South Hub', '2025-04-26', '2025-04-26', 49, 75),
(1059, 2, '2025-04-22', 'delivered', 'North Hub', '2025-04-27', '2025-04-26', 49, 90),
(1060, 5, '2025-04-22', 'delivered', 'North Hub', '2025-04-29', '2025-04-28', 0, 100),
(1061, 25, '2025-05-04', 'delivered', 'North Hub', '2025-05-09', '2025-05-08', 49, 60),
(1062, 26, '2025-05-05', 'delivered', 'North Hub', '2025-05-10', '2025-05-10', 49, 60),
(1063, 27, '2025-05-09', 'delivered', 'South Hub', '2025-05-14', '2025-05-13', 49, 60),
(1064, 28, '2025-05-09', 'delivered', 'South Hub', '2025-05-14', '2025-05-12', 0, 60),
(1065, 29, '2025-05-10', 'delivered', 'South Hub', '2025-05-17', '2025-05-17', 49, 100),
(1066, 25, '2025-05-12', 'delivered', 'North Hub', '2025-05-17', '2025-05-16', 49, 90),
(1067, 17, '2025-05-13', 'cancelled', 'South Hub', '2025-05-20', NULL, 0, 0),
(1068, 1, '2025-05-15', 'delivered', 'North Hub', '2025-05-20', '2025-05-19', 0, 75),
(1069, 13, '2025-05-15', 'delivered', 'North Hub', '2025-05-20', '2025-05-20', 49, 90),
(1070, 10, '2025-05-16', 'delivered', 'South Hub', '2025-05-21', '2025-05-20', 49, 75);

INSERT INTO orders (order_id, customer_id, order_date, status, warehouse, promised_delivery_date, delivered_date, shipping_charged, shipping_cost) VALUES
(1071, 1, '2025-05-16', 'delivered', 'North Hub', '2025-05-21', '2025-05-20', 49, 60),
(1072, 17, '2025-05-17', 'delivered', 'North Hub', '2025-05-24', '2025-05-29', 0, 100),
(1073, 20, '2025-05-17', 'delivered', 'North Hub', '2025-05-22', '2025-05-27', 49, 60),
(1074, 7, '2025-05-23', 'delivered', 'North Hub', '2025-05-28', '2025-05-26', 49, 90),
(1075, 13, '2025-05-23', 'delivered', 'North Hub', '2025-05-28', '2025-05-26', 49, 75),
(1076, 2, '2025-05-25', 'cancelled', 'North Hub', '2025-05-30', NULL, 0, 0),
(1077, 8, '2025-05-25', 'delivered', 'North Hub', '2025-05-30', '2025-06-02', 49, 60),
(1078, 30, '2025-06-03', 'delivered', 'South Hub', '2025-06-10', '2025-06-07', 49, 115),
(1079, 31, '2025-06-03', 'delivered', 'North Hub', '2025-06-08', '2025-06-06', 49, 60),
(1080, 32, '2025-06-04', 'delivered', 'North Hub', '2025-06-09', '2025-06-06', 0, 45),
(1081, 33, '2025-06-04', 'delivered', 'South Hub', NULL, '2025-06-09', 49, 90),
(1082, 4, '2025-06-04', 'delivered', 'South Hub', '2025-06-09', '2025-06-07', 49, 45),
(1083, 29, '2025-06-06', 'delivered', 'South Hub', '2025-06-13', '2025-06-17', 49, 100),
(1084, 1, '2025-06-06', 'cancelled', 'North Hub', '2025-06-11', NULL, 0, 0),
(1085, 13, '2025-06-07', 'delivered', 'North Hub', '2025-06-12', '2025-06-12', 49, 45),
(1086, 26, '2025-06-09', 'delivered', 'North Hub', '2025-06-14', '2025-06-11', 49, 90),
(1087, 32, '2025-06-10', 'delivered', 'North Hub', '2025-06-15', '2025-06-14', 49, 60),
(1088, 31, '2025-06-13', 'delivered', 'North Hub', '2025-06-18', '2025-06-16', 0, 75),
(1089, 8, '2025-06-13', 'delivered', 'North Hub', '2025-06-18', '2025-06-15', 49, 90),
(1090, 32, '2025-06-18', 'delivered', 'North Hub', '2025-06-23', '2025-06-22', 49, 45),
(1091, 24, '2025-06-21', 'delivered', 'North Hub', '2025-06-28', '2025-06-25', 49, 100),
(1092, 8, '2025-06-21', 'delivered', 'North Hub', '2025-06-26', '2025-06-23', 0, 75),
(1093, 13, '2025-06-23', 'delivered', 'North Hub', '2025-06-28', '2025-06-28', 49, 45),
(1094, 9, '2025-06-25', 'delivered', 'South Hub', '2025-06-30', '2025-06-28', 49, 75),
(1095, 34, '2025-07-01', 'delivered', 'South Hub', '2025-07-06', '2025-07-04', 49, 75),
(1096, 35, '2025-07-02', 'delivered', 'North Hub', '2025-07-09', '2025-07-10', 0, 85),
(1097, 36, '2025-07-02', 'delivered', 'North Hub', '2025-07-09', '2025-07-17', 49, 85),
(1098, 37, '2025-07-02', 'delivered', 'North Hub', '2025-07-07', '2025-07-07', 49, 75),
(1099, 15, '2025-07-04', 'delivered', 'South Hub', '2025-07-09', '2025-07-09', 49, 60),
(1100, 34, '2025-07-06', 'delivered', 'South Hub', '2025-07-11', '2025-07-08', 0, 75),
(1101, 17, '2025-07-09', 'delivered', 'North Hub', '2025-07-16', '2025-07-13', 49, 130),
(1102, 6, '2025-07-12', 'delivered', 'North Hub', '2025-07-19', '2025-07-16', 49, 100),
(1103, 31, '2025-07-12', 'delivered', 'North Hub', '2025-07-17', '2025-07-17', 49, 60),
(1104, 36, '2025-07-13', 'delivered', 'North Hub', '2025-07-20', '2025-07-18', 0, 115),
(1105, 13, '2025-07-16', 'delivered', 'North Hub', '2025-07-21', '2025-07-18', 49, 90),
(1106, 1, '2025-07-17', 'delivered', 'North Hub', '2025-07-22', '2025-07-29', 49, 60),
(1107, 24, '2025-07-19', 'delivered', 'North Hub', '2025-07-26', '2025-07-24', 49, 130),
(1108, 26, '2025-07-19', 'delivered', 'North Hub', '2025-07-24', '2025-07-24', 0, 75),
(1109, 6, '2025-07-21', 'cancelled', 'North Hub', '2025-07-28', NULL, 0, 0),
(1110, 12, '2025-07-23', 'delivered', 'South Hub', '2025-07-30', '2025-07-27', 49, 100),
(1111, 1, '2025-07-23', 'delivered', 'North Hub', '2025-07-28', '2025-07-27', 49, 60),
(1112, 25, '2025-07-24', 'delivered', 'North Hub', '2025-07-29', '2025-07-27', 0, 90),
(1113, 38, '2025-08-01', 'delivered', 'North Hub', '2025-08-06', '2025-08-05', 49, 75),
(1114, 39, '2025-08-02', 'delivered', 'South Hub', '2025-08-07', '2025-08-14', 49, 45),
(1115, 40, '2025-08-03', 'delivered', 'South Hub', '2025-08-08', '2025-08-15', 49, 45),
(1116, 33, '2025-08-04', 'cancelled', 'South Hub', '2025-08-09', NULL, 0, 0),
(1117, 20, '2025-08-04', 'delivered', 'North Hub', '2025-08-09', '2025-08-07', 49, 90),
(1118, 37, '2025-08-04', 'delivered', 'North Hub', '2025-08-09', '2025-08-13', 49, 45),
(1119, 14, '2025-08-04', 'cancelled', 'North Hub', '2025-08-09', NULL, 0, 0),
(1120, 39, '2025-08-07', 'delivered', 'South Hub', '2025-08-12', '2025-08-09', 0, 60),
(1121, 16, '2025-08-08', 'delivered', 'South Hub', '2025-08-13', '2025-08-11', 49, 45),
(1122, 8, '2025-08-09', 'delivered', 'North Hub', '2025-08-14', '2025-08-13', 49, 45),
(1123, 7, '2025-08-09', 'delivered', 'North Hub', '2025-08-14', '2025-08-12', 49, 60),
(1124, 9, '2025-08-09', 'delivered', 'South Hub', '2025-08-14', '2025-08-13', 0, 75),
(1125, 17, '2025-08-09', 'delivered', 'South Hub', '2025-08-16', '2025-08-13', 49, 115),
(1126, 21, '2025-08-09', 'cancelled', 'South Hub', '2025-08-14', NULL, 0, 0),
(1127, 8, '2025-08-15', 'delivered', 'North Hub', '2025-08-20', '2025-08-23', 49, 75),
(1128, 20, '2025-08-16', 'delivered', 'North Hub', NULL, '2025-08-24', 0, 45),
(1129, 32, '2025-08-17', 'delivered', 'North Hub', '2025-08-22', '2025-08-26', 49, 90),
(1130, 31, '2025-08-24', 'delivered', 'North Hub', '2025-08-29', '2025-09-01', 49, 90),
(1131, 41, '2025-09-01', 'delivered', 'South Hub', '2025-09-08', '2025-09-07', 49, 100),
(1132, 42, '2025-09-02', 'delivered', 'South Hub', '2025-09-09', '2025-09-07', 0, 130),
(1133, 43, '2025-09-02', 'delivered', 'North Hub', '2025-09-07', '2025-09-10', 49, 90),
(1134, 44, '2025-09-03', 'delivered', 'North Hub', '2025-09-08', '2025-09-10', 49, 45),
(1135, 39, '2025-09-03', 'delivered', 'South Hub', '2025-09-08', '2025-09-07', 49, 75),
(1136, 19, '2025-09-04', 'delivered', 'North Hub', '2025-09-09', '2025-09-15', 0, 60),
(1137, 32, '2025-09-05', 'delivered', 'North Hub', '2025-09-10', '2025-09-17', 49, 60),
(1138, 24, '2025-09-06', 'delivered', 'North Hub', '2025-09-13', '2025-09-14', 49, 85),
(1139, 21, '2025-09-07', 'delivered', 'South Hub', '2025-09-12', '2025-09-12', 49, 75),
(1140, 8, '2025-09-07', 'delivered', 'North Hub', '2025-09-12', '2025-09-13', 0, 60);

INSERT INTO orders (order_id, customer_id, order_date, status, warehouse, promised_delivery_date, delivered_date, shipping_charged, shipping_cost) VALUES
(1141, 44, '2025-09-12', 'delivered', 'North Hub', '2025-09-17', '2025-09-20', 49, 90),
(1142, 1, '2025-09-16', 'delivered', 'North Hub', '2025-09-21', '2025-09-21', 49, 45),
(1143, 1, '2025-09-18', 'delivered', 'North Hub', '2025-09-23', '2025-09-21', 49, 90),
(1144, 28, '2025-09-19', 'delivered', 'South Hub', '2025-09-24', '2025-09-22', 0, 45),
(1145, 17, '2025-09-22', 'delivered', 'North Hub', '2025-09-29', '2025-10-01', 49, 100),
(1146, 41, '2025-09-22', 'delivered', 'North Hub', '2025-09-29', '2025-10-03', 49, 85),
(1147, 13, '2025-09-23', 'delivered', 'North Hub', '2025-09-28', '2025-09-27', 49, 45),
(1148, 1, '2025-09-24', 'delivered', 'North Hub', '2025-09-29', '2025-09-30', 0, 90),
(1149, 18, '2025-09-25', 'delivered', 'South Hub', '2025-10-02', '2025-10-02', 49, 100),
(1150, 45, '2025-10-02', 'delivered', 'South Hub', '2025-10-07', '2025-10-04', 49, 45),
(1151, 46, '2025-10-05', 'delivered', 'South Hub', '2025-10-10', '2025-10-16', 49, 60),
(1152, 47, '2025-10-08', 'delivered', 'North Hub', '2025-10-15', '2025-10-18', 0, 85),
(1153, 48, '2025-10-12', 'delivered', 'South Hub', '2025-10-19', '2025-10-17', 49, 130),
(1154, 9, '2025-10-14', 'delivered', 'South Hub', '2025-10-19', '2025-10-18', 49, 75),
(1155, 33, '2025-10-14', 'delivered', 'South Hub', '2025-10-19', '2025-10-17', 49, 60),
(1156, 28, '2025-10-17', 'delivered', 'South Hub', '2025-10-22', '2025-10-19', 0, 45),
(1157, 28, '2025-10-17', 'delivered', 'South Hub', '2025-10-22', '2025-10-20', 49, 90),
(1158, 42, '2025-10-17', 'delivered', 'South Hub', '2025-10-24', '2025-10-25', 49, 100),
(1159, 5, '2025-10-17', 'delivered', 'North Hub', '2025-10-24', '2025-10-31', 49, 85),
(1160, 48, '2025-10-18', 'delivered', 'North Hub', '2025-10-25', '2025-11-02', 0, 130),
(1161, 8, '2025-10-20', 'delivered', 'North Hub', '2025-10-25', '2025-10-26', 49, 90),
(1162, 27, '2025-10-20', 'delivered', 'South Hub', '2025-10-25', '2025-10-29', 49, 45),
(1163, 1, '2025-10-21', 'delivered', 'North Hub', '2025-10-26', '2025-10-28', 49, 90),
(1164, 36, '2025-10-21', 'delivered', 'South Hub', '2025-10-28', '2025-10-28', 0, 85),
(1165, 3, '2025-10-22', 'delivered', 'South Hub', '2025-10-27', '2025-10-26', 49, 45),
(1166, 32, '2025-10-22', 'delivered', 'North Hub', '2025-10-27', '2025-10-29', 49, 90),
(1167, 39, '2025-10-23', 'delivered', 'South Hub', '2025-10-28', '2025-10-26', 49, 90),
(1168, 1, '2025-10-24', 'delivered', 'North Hub', '2025-10-29', '2025-10-27', 0, 90),
(1169, 49, '2025-11-02', 'delivered', 'North Hub', '2025-11-07', '2025-11-13', 49, 90),
(1170, 50, '2025-11-02', 'delivered', 'North Hub', '2025-11-07', '2025-11-15', 49, 75),
(1171, 51, '2025-11-03', 'delivered', 'South Hub', '2025-11-08', '2025-11-06', 49, 75),
(1172, 8, '2025-11-04', 'delivered', 'North Hub', '2025-11-09', '2025-11-08', 0, 45),
(1173, 36, '2025-11-06', 'delivered', 'South Hub', '2025-11-13', '2025-11-11', 49, 85),
(1174, 49, '2025-11-08', 'delivered', 'North Hub', '2025-11-13', '2025-11-10', 49, 45),
(1175, 6, '2025-11-09', 'delivered', 'North Hub', NULL, '2025-11-24', 49, 115),
(1176, 9, '2025-11-10', 'delivered', 'South Hub', '2025-11-15', '2025-11-13', 0, 60),
(1177, 31, '2025-11-10', 'delivered', 'North Hub', '2025-11-15', '2025-11-22', 49, 75),
(1178, 29, '2025-11-11', 'delivered', 'South Hub', '2025-11-18', '2025-11-17', 49, 100),
(1179, 40, '2025-11-11', 'delivered', 'South Hub', '2025-11-16', '2025-11-13', 49, 45),
(1180, 40, '2025-11-12', 'delivered', 'South Hub', '2025-11-17', '2025-11-17', 0, 45),
(1181, 1, '2025-11-12', 'delivered', 'North Hub', '2025-11-17', '2025-11-15', 49, 60),
(1182, 32, '2025-11-14', 'delivered', 'North Hub', '2025-11-19', '2025-11-26', 49, 45),
(1183, 44, '2025-11-15', 'delivered', 'North Hub', '2025-11-20', '2025-11-26', 49, 75),
(1184, 16, '2025-11-18', 'delivered', 'South Hub', '2025-11-23', '2025-11-29', 0, 45),
(1185, 33, '2025-11-18', 'delivered', 'South Hub', '2025-11-23', '2025-11-22', 49, 90),
(1186, 24, '2025-11-19', 'delivered', 'North Hub', '2025-11-26', '2025-11-28', 49, 100),
(1187, 14, '2025-11-20', 'delivered', 'North Hub', '2025-11-25', '2025-11-22', 49, 45),
(1188, 15, '2025-11-22', 'delivered', 'South Hub', '2025-11-27', '2025-11-27', 0, 75),
(1189, 52, '2025-12-01', 'delivered', 'South Hub', '2025-12-06', '2025-12-04', 49, 90),
(1190, 53, '2025-12-02', 'delivered', 'South Hub', '2025-12-09', '2025-12-06', 49, 100),
(1191, 54, '2025-12-02', 'delivered', 'South Hub', '2025-12-09', '2025-12-07', 49, 115),
(1192, 33, '2025-12-03', 'delivered', 'South Hub', '2025-12-08', '2025-12-05', 0, 90),
(1193, 5, '2025-12-07', 'delivered', 'South Hub', '2025-12-14', '2025-12-11', 49, 100),
(1194, 25, '2025-12-10', 'cancelled', 'North Hub', '2025-12-15', NULL, 0, 0),
(1195, 16, '2025-12-10', 'delivered', 'South Hub', '2025-12-15', '2025-12-13', 49, 60),
(1196, 32, '2025-12-13', 'delivered', 'North Hub', '2025-12-18', '2025-12-18', 0, 45),
(1197, 21, '2025-12-14', 'delivered', 'South Hub', '2025-12-19', '2025-12-25', 49, 75),
(1198, 29, '2025-12-15', 'cancelled', 'North Hub', '2025-12-22', NULL, 0, 0),
(1199, 40, '2025-12-15', 'delivered', 'South Hub', '2025-12-20', '2025-12-23', 49, 60),
(1200, 36, '2025-12-18', 'delivered', 'North Hub', '2025-12-25', '2025-12-25', 0, 85),
(1201, 9, '2025-12-18', 'delivered', 'South Hub', '2025-12-23', '2025-12-21', 49, 60),
(1202, 37, '2025-12-19', 'delivered', 'North Hub', '2025-12-24', '2025-12-30', 49, 45),
(1203, 12, '2025-12-20', 'delivered', 'South Hub', '2025-12-27', '2025-12-24', 49, 85),
(1204, 30, '2025-12-20', 'delivered', 'North Hub', '2025-12-27', '2025-12-30', 0, 100),
(1205, 28, '2025-12-20', 'delivered', 'South Hub', '2025-12-25', '2025-12-24', 49, 45),
(1206, 25, '2025-12-21', 'delivered', 'North Hub', '2025-12-26', '2025-12-24', 49, 45),
(1207, 27, '2025-12-21', 'delivered', 'South Hub', '2025-12-26', '2025-12-25', 49, 45),
(1208, 21, '2025-12-23', 'delivered', 'South Hub', '2025-12-28', '2025-12-29', 0, 45),
(1209, 37, '2025-12-24', 'delivered', 'North Hub', '2025-12-29', '2025-12-27', 49, 60),
(1210, 1, '2025-12-25', 'in_transit', 'North Hub', '2025-12-30', NULL, 49, 90);

INSERT INTO order_items (order_id, item_number, product_id, product_name, category, quantity, unit_price, discount_amount, unit_cost, returned_quantity, refund_amount) VALUES
(1001, 1, 8, 'Resistance Bands', 'Fitness', 1, 550, 0, 270, 1, 550.00),
(1001, 2, 14, 'Cushion Set', 'Home', 1, 1100, 0, 610, 0, 0.00),
(1002, 1, 15, 'Foam Roller', 'Fitness', 1, 1000, 100.00, 530, 0, 0.00),
(1003, 1, 17, 'Food Container Set', 'Home', 1, 700, 0, 370, 0, 0.00),
(1003, 2, 2, 'Portable Speaker', 'Electronics', 1, 2400, 0, 1550, 0, 0.00),
(1004, 1, 7, 'Yoga Mat', 'Fitness', 2, 1200, 240.00, 620, 0, 0.00),
(1004, 2, 8, 'Resistance Bands', 'Fitness', 1, 550, 27.50, 270, 0, 0.00),
(1005, 1, 1, 'Wireless Earbuds', 'Electronics', 1, 1800, 180.00, 1150, 0, 0.00),
(1005, 2, 11, 'Cable Organizer', 'Accessories', 1, 250, 0, 100, 0, 0.00),
(1006, 1, 10, 'Laptop Sleeve', 'Accessories', 2, 900, 0, 480, 0, 0.00),
(1006, 2, 1, 'Wireless Earbuds', 'Electronics', 1, 1800, 180.00, 1150, 0, 0.00),
(1007, 1, 4, 'Desk Lamp', 'Home', 1, 1250, 0, 700, 0, 0.00),
(1007, 2, 17, 'Food Container Set', 'Home', 1, 700, 35.00, 370, 1, 665.00),
(1008, 1, 7, 'Yoga Mat', 'Fitness', 1, 1200, 60.00, 620, 0, 0.00),
(1008, 2, 8, 'Resistance Bands', 'Fitness', 1, 550, 0, 270, 0, 0.00),
(1009, 1, 9, 'Training Gloves', 'Fitness', 1, 650, 0, 320, 0, 0.00),
(1009, 2, 10, 'Laptop Sleeve', 'Accessories', 1, 900, 45.00, 480, 0, 0.00),
(1010, 1, 1, 'Wireless Earbuds', 'Electronics', 1, 1800, 0, 1150, 1, 1800.00),
(1010, 2, 11, 'Cable Organizer', 'Accessories', 2, 250, 0, 100, 0, 0.00),
(1011, 1, 10, 'Laptop Sleeve', 'Accessories', 1, 900, 0, 480, 0, 0.00),
(1012, 1, 7, 'Yoga Mat', 'Fitness', 2, 1200, 0, 620, 0, 0.00),
(1012, 2, 8, 'Resistance Bands', 'Fitness', 1, 550, 0, 270, 0, 0.00),
(1013, 1, 8, 'Resistance Bands', 'Fitness', 1, 550, 27.50, 270, 0, 0.00),
(1013, 2, 12, 'Travel Pouch', 'Accessories', 1, 450, 45.00, 220, 0, 0.00),
(1014, 1, 11, 'Cable Organizer', 'Accessories', 1, 250, 0, 100, 0, 0.00),
(1014, 2, 12, 'Travel Pouch', 'Accessories', 2, 450, 45.00, 220, 0, 0.00),
(1015, 1, 1, 'Wireless Earbuds', 'Electronics', 2, 1800, 360.00, 1150, 0, 0.00),
(1015, 2, 11, 'Cable Organizer', 'Accessories', 1, 250, 0, 100, 0, 0.00),
(1016, 1, 12, 'Travel Pouch', 'Accessories', 1, 450, 0, 220, 0, 0.00),
(1017, 1, 16, 'Laptop Stand', 'Accessories', 1, 1500, 75.00, 900, 0, 0.00),
(1017, 2, 12, 'Travel Pouch', 'Accessories', 2, 450, 0, 220, 0, 0.00),
(1018, 1, 12, 'Travel Pouch', 'Accessories', 1, 450, 45.00, 220, 0, 0.00),
(1018, 2, 2, 'Portable Speaker', 'Electronics', 1, 2400, 120.00, 1550, 0, 0.00),
(1019, 1, 13, 'Bluetooth Keyboard', 'Electronics', 1, 2100, 105.00, 1350, 0, 0.00),
(1019, 2, 15, 'Foam Roller', 'Fitness', 1, 1000, 0, 530, 0, 0.00),
(1020, 1, 18, 'Jump Rope', 'Fitness', 1, 400, 20.00, 180, 0, 0.00),
(1021, 1, 14, 'Cushion Set', 'Home', 1, 1100, 0, 610, 0, 0.00),
(1021, 2, 6, 'Insulated Bottle', 'Home', 1, 850, 85.00, 430, 1, 765.00),
(1022, 1, 15, 'Foam Roller', 'Fitness', 2, 1000, 200.00, 530, 0, 0.00),
(1023, 1, 18, 'Jump Rope', 'Fitness', 1, 400, 20.00, 180, 0, 0.00),
(1023, 2, 13, 'Bluetooth Keyboard', 'Electronics', 1, 2100, 0, 1350, 0, 0.00),
(1024, 1, 7, 'Yoga Mat', 'Fitness', 2, 1200, 120.00, 620, 0, 0.00),
(1024, 2, 8, 'Resistance Bands', 'Fitness', 1, 550, 27.50, 270, 0, 0.00),
(1024, 3, 18, 'Jump Rope', 'Fitness', 1, 400, 40.00, 180, 0, 0.00),
(1025, 1, 1, 'Wireless Earbuds', 'Electronics', 1, 1800, 0, 1150, 0, 0.00),
(1025, 2, 11, 'Cable Organizer', 'Accessories', 1, 250, 12.50, 100, 0, 0.00),
(1026, 1, 4, 'Desk Lamp', 'Home', 1, 1250, 62.50, 700, 0, 0.00),
(1027, 1, 14, 'Cushion Set', 'Home', 1, 1100, 0, 610, 0, 0.00),
(1027, 2, 17, 'Food Container Set', 'Home', 1, 700, 0, 370, 0, 0.00),
(1027, 3, 9, 'Training Gloves', 'Fitness', 1, 650, 0, 320, 0, 0.00),
(1028, 1, 7, 'Yoga Mat', 'Fitness', 1, 1200, 120.00, 620, 0, 0.00),
(1028, 2, 8, 'Resistance Bands', 'Fitness', 1, 550, 0, 270, 0, 0.00),
(1029, 1, 8, 'Resistance Bands', 'Fitness', 1, 550, 0, 270, 0, 0.00),
(1029, 2, 2, 'Portable Speaker', 'Electronics', 1, 2400, 240.00, 1550, 0, 0.00),
(1030, 1, 1, 'Wireless Earbuds', 'Electronics', 2, 1800, 360.00, 1150, 0, 0.00),
(1030, 2, 11, 'Cable Organizer', 'Accessories', 1, 250, 25.00, 100, 0, 0.00),
(1031, 1, 16, 'Laptop Stand', 'Accessories', 2, 1500, 600.00, 900, 0, 0.00),
(1031, 2, 17, 'Food Container Set', 'Home', 2, 700, 280.00, 370, 0, 0.00),
(1032, 1, 7, 'Yoga Mat', 'Fitness', 1, 1200, 60.00, 620, 0, 0.00),
(1032, 2, 8, 'Resistance Bands', 'Fitness', 1, 550, 27.50, 270, 0, 0.00),
(1033, 1, 6, 'Insulated Bottle', 'Home', 1, 850, 85.00, 430, 0, 0.00),
(1033, 2, 4, 'Desk Lamp', 'Home', 2, 1250, 125.00, 700, 0, 0.00),
(1034, 1, 12, 'Travel Pouch', 'Accessories', 1, 450, 0, 220, 0, 0.00),
(1035, 1, 1, 'Wireless Earbuds', 'Electronics', 2, 1800, 1080.00, 1150, 2, 2520.00),
(1035, 2, 11, 'Cable Organizer', 'Accessories', 1, 250, 12.50, 100, 0, 0.00),
(1036, 1, 7, 'Yoga Mat', 'Fitness', 1, 1200, 120.00, 620, 0, 0.00),
(1036, 2, 8, 'Resistance Bands', 'Fitness', 1, 550, 27.50, 270, 1, 522.50),
(1037, 1, 11, 'Cable Organizer', 'Accessories', 1, 250, 75.00, 100, 0, 0.00),
(1037, 2, 15, 'Foam Roller', 'Fitness', 2, 1000, 400.00, 530, 0, 0.00),
(1038, 1, 10, 'Laptop Sleeve', 'Accessories', 1, 900, 270.00, 480, 1, 630.00),
(1038, 2, 13, 'Bluetooth Keyboard', 'Electronics', 2, 2100, 420.00, 1350, 0, 0.00),
(1039, 1, 8, 'Resistance Bands', 'Fitness', 1, 550, 55.00, 270, 0, 0.00),
(1039, 2, 13, 'Bluetooth Keyboard', 'Electronics', 1, 2100, 105.00, 1350, 0, 0.00),
(1040, 1, 7, 'Yoga Mat', 'Fitness', 2, 1200, 720.00, 620, 0, 0.00),
(1040, 2, 8, 'Resistance Bands', 'Fitness', 1, 550, 110.00, 270, 1, 440.00),
(1041, 1, 4, 'Desk Lamp', 'Home', 2, 1250, 250.00, 700, 0, 0.00);

INSERT INTO order_items (order_id, item_number, product_id, product_name, category, quantity, unit_price, discount_amount, unit_cost, returned_quantity, refund_amount) VALUES
(1042, 1, 5, 'Storage Basket', 'Home', 1, 600, 60.00, 300, 0, 0.00),
(1042, 2, 18, 'Jump Rope', 'Fitness', 2, 400, 0, 180, 0, 0.00),
(1043, 1, 9, 'Training Gloves', 'Fitness', 1, 650, 195.00, 320, 0, 0.00),
(1043, 2, 3, 'USB-C Charger', 'Electronics', 2, 750, 450.00, 420, 0, 0.00),
(1044, 1, 7, 'Yoga Mat', 'Fitness', 1, 1200, 240.00, 620, 0, 0.00),
(1044, 2, 8, 'Resistance Bands', 'Fitness', 1, 550, 0, 270, 0, 0.00),
(1045, 1, 1, 'Wireless Earbuds', 'Electronics', 1, 1800, 0, 1150, 1, 1800.00),
(1045, 2, 11, 'Cable Organizer', 'Accessories', 1, 250, 25.00, 100, 0, 0.00),
(1046, 1, 5, 'Storage Basket', 'Home', 1, 600, 60.00, 300, 1, 540.00),
(1046, 2, 10, 'Laptop Sleeve', 'Accessories', 1, 900, 0, 480, 0, 0.00),
(1047, 1, 3, 'USB-C Charger', 'Electronics', 2, 750, 0, 420, 0, 0.00),
(1047, 2, 7, 'Yoga Mat', 'Fitness', 1, 1200, 0, 620, 0, 0.00),
(1048, 1, 7, 'Yoga Mat', 'Fitness', 1, 1200, 0, 620, 0, 0.00),
(1048, 2, 8, 'Resistance Bands', 'Fitness', 2, 550, 55.00, 270, 0, 0.00),
(1049, 1, 16, 'Laptop Stand', 'Accessories', 1, 1500, 0, 900, 0, 0.00),
(1050, 1, 4, 'Desk Lamp', 'Home', 1, 1250, 62.50, 700, 1, 1187.50),
(1051, 1, 7, 'Yoga Mat', 'Fitness', 1, 1200, 0, 620, 0, 0.00),
(1051, 2, 11, 'Cable Organizer', 'Accessories', 1, 250, 0, 100, 0, 0.00),
(1051, 3, 3, 'USB-C Charger', 'Electronics', 2, 750, 150.00, 420, 0, 0.00),
(1052, 1, 17, 'Food Container Set', 'Home', 1, 700, 0, 370, 0, 0.00),
(1053, 1, 10, 'Laptop Sleeve', 'Accessories', 1, 900, 45.00, 480, 0, 0.00),
(1054, 1, 17, 'Food Container Set', 'Home', 1, 700, 0, 370, 0, 0.00),
(1054, 2, 9, 'Training Gloves', 'Fitness', 1, 650, 0, 320, 0, 0.00),
(1055, 1, 1, 'Wireless Earbuds', 'Electronics', 1, 1800, 180.00, 1150, 1, 1620.00),
(1055, 2, 11, 'Cable Organizer', 'Accessories', 1, 250, 0, 100, 0, 0.00),
(1056, 1, 4, 'Desk Lamp', 'Home', 1, 1250, 0, 700, 0, 0.00),
(1057, 1, 7, 'Yoga Mat', 'Fitness', 1, 1200, 60.00, 620, 0, 0.00),
(1057, 2, 13, 'Bluetooth Keyboard', 'Electronics', 1, 2100, 105.00, 1350, 0, 0.00),
(1058, 1, 10, 'Laptop Sleeve', 'Accessories', 2, 900, 0, 480, 0, 0.00),
(1058, 2, 12, 'Travel Pouch', 'Accessories', 1, 450, 22.50, 220, 0, 0.00),
(1059, 1, 5, 'Storage Basket', 'Home', 1, 600, 60.00, 300, 0, 0.00),
(1060, 1, 7, 'Yoga Mat', 'Fitness', 1, 1200, 60.00, 620, 0, 0.00),
(1060, 2, 8, 'Resistance Bands', 'Fitness', 2, 550, 110.00, 270, 0, 0.00),
(1061, 1, 7, 'Yoga Mat', 'Fitness', 1, 1200, 120.00, 620, 0, 0.00),
(1061, 2, 15, 'Foam Roller', 'Fitness', 1, 1000, 0, 530, 0, 0.00),
(1062, 1, 10, 'Laptop Sleeve', 'Accessories', 1, 900, 0, 480, 0, 0.00),
(1062, 2, 4, 'Desk Lamp', 'Home', 1, 1250, 62.50, 700, 0, 0.00),
(1063, 1, 14, 'Cushion Set', 'Home', 2, 1100, 0, 610, 0, 0.00),
(1063, 2, 10, 'Laptop Sleeve', 'Accessories', 1, 900, 0, 480, 0, 0.00),
(1064, 1, 6, 'Insulated Bottle', 'Home', 1, 850, 42.50, 430, 0, 0.00),
(1065, 1, 1, 'Wireless Earbuds', 'Electronics', 1, 1800, 0, 1150, 0, 0.00),
(1066, 1, 13, 'Bluetooth Keyboard', 'Electronics', 1, 2100, 0, 1350, 0, 0.00),
(1066, 2, 17, 'Food Container Set', 'Home', 1, 700, 70.00, 370, 0, 0.00),
(1067, 1, 2, 'Portable Speaker', 'Electronics', 2, 2400, 0, 1550, 0, 0.00),
(1068, 1, 7, 'Yoga Mat', 'Fitness', 1, 1200, 60.00, 620, 0, 0.00),
(1068, 2, 8, 'Resistance Bands', 'Fitness', 2, 550, 110.00, 270, 0, 0.00),
(1069, 1, 18, 'Jump Rope', 'Fitness', 2, 400, 40.00, 180, 0, 0.00),
(1069, 2, 11, 'Cable Organizer', 'Accessories', 1, 250, 25.00, 100, 0, 0.00),
(1070, 1, 1, 'Wireless Earbuds', 'Electronics', 1, 1800, 0, 1150, 0, 0.00),
(1070, 2, 11, 'Cable Organizer', 'Accessories', 1, 250, 12.50, 100, 0, 0.00),
(1071, 1, 14, 'Cushion Set', 'Home', 1, 1100, 55.00, 610, 0, 0.00),
(1071, 2, 7, 'Yoga Mat', 'Fitness', 1, 1200, 60.00, 620, 0, 0.00),
(1071, 3, 4, 'Desk Lamp', 'Home', 1, 1250, 125.00, 700, 0, 0.00),
(1072, 1, 7, 'Yoga Mat', 'Fitness', 1, 1200, 60.00, 620, 0, 0.00),
(1072, 2, 8, 'Resistance Bands', 'Fitness', 1, 550, 55.00, 270, 0, 0.00),
(1073, 1, 2, 'Portable Speaker', 'Electronics', 1, 2400, 0, 1550, 0, 0.00),
(1073, 2, 11, 'Cable Organizer', 'Accessories', 1, 250, 25.00, 100, 0, 0.00),
(1074, 1, 17, 'Food Container Set', 'Home', 1, 700, 0, 370, 0, 0.00),
(1075, 1, 1, 'Wireless Earbuds', 'Electronics', 2, 1800, 0, 1150, 2, 3600.00),
(1075, 2, 11, 'Cable Organizer', 'Accessories', 1, 250, 25.00, 100, 0, 0.00),
(1075, 3, 10, 'Laptop Sleeve', 'Accessories', 2, 900, 0, 480, 0, 0.00),
(1076, 1, 7, 'Yoga Mat', 'Fitness', 1, 1200, 120.00, 620, 0, 0.00),
(1076, 2, 8, 'Resistance Bands', 'Fitness', 1, 550, 0, 270, 0, 0.00),
(1077, 1, 13, 'Bluetooth Keyboard', 'Electronics', 1, 2100, 210.00, 1350, 0, 0.00),
(1078, 1, 5, 'Storage Basket', 'Home', 1, 600, 0, 300, 0, 0.00),
(1078, 2, 3, 'USB-C Charger', 'Electronics', 1, 750, 0, 420, 0, 0.00),
(1079, 1, 1, 'Wireless Earbuds', 'Electronics', 1, 1800, 0, 1150, 0, 0.00),
(1079, 2, 9, 'Training Gloves', 'Fitness', 1, 650, 32.50, 320, 0, 0.00),
(1080, 1, 7, 'Yoga Mat', 'Fitness', 1, 1200, 0, 620, 0, 0.00),
(1081, 1, 16, 'Laptop Stand', 'Accessories', 1, 1500, 0, 900, 1, 1500.00),
(1081, 2, 4, 'Desk Lamp', 'Home', 1, 1250, 125.00, 700, 1, 1125.00),
(1082, 1, 5, 'Storage Basket', 'Home', 1, 600, 0, 300, 0, 0.00),
(1082, 2, 8, 'Resistance Bands', 'Fitness', 1, 550, 55.00, 270, 0, 0.00),
(1083, 1, 12, 'Travel Pouch', 'Accessories', 2, 450, 90.00, 220, 0, 0.00),
(1084, 1, 7, 'Yoga Mat', 'Fitness', 1, 1200, 0, 620, 0, 0.00),
(1084, 2, 8, 'Resistance Bands', 'Fitness', 1, 550, 0, 270, 0, 0.00);

INSERT INTO order_items (order_id, item_number, product_id, product_name, category, quantity, unit_price, discount_amount, unit_cost, returned_quantity, refund_amount) VALUES
(1085, 1, 1, 'Wireless Earbuds', 'Electronics', 1, 1800, 90.00, 1150, 0, 0.00),
(1085, 2, 11, 'Cable Organizer', 'Accessories', 2, 250, 25.00, 100, 1, 237.50),
(1086, 1, 16, 'Laptop Stand', 'Accessories', 1, 1500, 150.00, 900, 0, 0.00),
(1086, 2, 17, 'Food Container Set', 'Home', 1, 700, 0, 370, 0, 0.00),
(1087, 1, 1, 'Wireless Earbuds', 'Electronics', 2, 1800, 0, 1150, 0, 0.00),
(1087, 2, 13, 'Bluetooth Keyboard', 'Electronics', 1, 2100, 0, 1350, 0, 0.00),
(1087, 3, 3, 'USB-C Charger', 'Electronics', 1, 750, 0, 420, 0, 0.00),
(1088, 1, 7, 'Yoga Mat', 'Fitness', 1, 1200, 120.00, 620, 0, 0.00),
(1088, 2, 8, 'Resistance Bands', 'Fitness', 1, 550, 27.50, 270, 0, 0.00),
(1089, 1, 9, 'Training Gloves', 'Fitness', 1, 650, 32.50, 320, 1, 617.50),
(1089, 2, 17, 'Food Container Set', 'Home', 2, 700, 0, 370, 0, 0.00),
(1090, 1, 13, 'Bluetooth Keyboard', 'Electronics', 1, 2100, 210.00, 1350, 0, 0.00),
(1091, 1, 14, 'Cushion Set', 'Home', 2, 1100, 0, 610, 1, 1100.00),
(1091, 2, 6, 'Insulated Bottle', 'Home', 2, 850, 0, 430, 0, 0.00),
(1092, 1, 7, 'Yoga Mat', 'Fitness', 1, 1200, 60.00, 620, 0, 0.00),
(1092, 2, 8, 'Resistance Bands', 'Fitness', 1, 550, 27.50, 270, 0, 0.00),
(1093, 1, 4, 'Desk Lamp', 'Home', 1, 1250, 0, 700, 0, 0.00),
(1094, 1, 12, 'Travel Pouch', 'Accessories', 1, 450, 0, 220, 0, 0.00),
(1094, 2, 8, 'Resistance Bands', 'Fitness', 1, 550, 55.00, 270, 1, 495.00),
(1095, 1, 1, 'Wireless Earbuds', 'Electronics', 1, 1800, 0, 1150, 0, 0.00),
(1095, 2, 11, 'Cable Organizer', 'Accessories', 1, 250, 75.00, 100, 1, 175.00),
(1096, 1, 7, 'Yoga Mat', 'Fitness', 1, 1200, 60.00, 620, 0, 0.00),
(1096, 2, 8, 'Resistance Bands', 'Fitness', 1, 550, 27.50, 270, 0, 0.00),
(1097, 1, 14, 'Cushion Set', 'Home', 2, 1100, 110.00, 610, 0, 0.00),
(1098, 1, 13, 'Bluetooth Keyboard', 'Electronics', 1, 2100, 420.00, 1350, 0, 0.00),
(1098, 2, 17, 'Food Container Set', 'Home', 1, 700, 35.00, 370, 0, 0.00),
(1099, 1, 10, 'Laptop Sleeve', 'Accessories', 1, 900, 45.00, 480, 0, 0.00),
(1099, 2, 17, 'Food Container Set', 'Home', 1, 700, 140.00, 370, 0, 0.00),
(1100, 1, 7, 'Yoga Mat', 'Fitness', 1, 1200, 60.00, 620, 0, 0.00),
(1100, 2, 8, 'Resistance Bands', 'Fitness', 1, 550, 110.00, 270, 0, 0.00),
(1101, 1, 9, 'Training Gloves', 'Fitness', 1, 650, 130.00, 320, 0, 0.00),
(1101, 2, 7, 'Yoga Mat', 'Fitness', 1, 1200, 120.00, 620, 0, 0.00),
(1102, 1, 7, 'Yoga Mat', 'Fitness', 1, 1200, 0, 620, 0, 0.00),
(1103, 1, 12, 'Travel Pouch', 'Accessories', 1, 450, 22.50, 220, 0, 0.00),
(1104, 1, 7, 'Yoga Mat', 'Fitness', 1, 1200, 360.00, 620, 0, 0.00),
(1104, 2, 8, 'Resistance Bands', 'Fitness', 1, 550, 27.50, 270, 0, 0.00),
(1105, 1, 1, 'Wireless Earbuds', 'Electronics', 2, 1800, 1080.00, 1150, 0, 0.00),
(1105, 2, 11, 'Cable Organizer', 'Accessories', 1, 250, 0, 100, 0, 0.00),
(1106, 1, 3, 'USB-C Charger', 'Electronics', 1, 750, 75.00, 420, 0, 0.00),
(1107, 1, 7, 'Yoga Mat', 'Fitness', 1, 1200, 240.00, 620, 0, 0.00),
(1108, 1, 7, 'Yoga Mat', 'Fitness', 1, 1200, 240.00, 620, 0, 0.00),
(1108, 2, 8, 'Resistance Bands', 'Fitness', 1, 550, 0, 270, 0, 0.00),
(1109, 1, 4, 'Desk Lamp', 'Home', 1, 1250, 0, 700, 0, 0.00),
(1110, 1, 1, 'Wireless Earbuds', 'Electronics', 1, 1800, 180.00, 1150, 0, 0.00),
(1110, 2, 11, 'Cable Organizer', 'Accessories', 1, 250, 50.00, 100, 0, 0.00),
(1111, 1, 17, 'Food Container Set', 'Home', 1, 700, 70.00, 370, 0, 0.00),
(1111, 2, 8, 'Resistance Bands', 'Fitness', 1, 550, 27.50, 270, 0, 0.00),
(1112, 1, 4, 'Desk Lamp', 'Home', 1, 1250, 0, 700, 0, 0.00),
(1113, 1, 2, 'Portable Speaker', 'Electronics', 1, 2400, 120.00, 1550, 0, 0.00),
(1113, 2, 12, 'Travel Pouch', 'Accessories', 1, 450, 45.00, 220, 0, 0.00),
(1114, 1, 17, 'Food Container Set', 'Home', 2, 700, 0, 370, 0, 0.00),
(1114, 2, 11, 'Cable Organizer', 'Accessories', 1, 250, 0, 100, 0, 0.00),
(1115, 1, 1, 'Wireless Earbuds', 'Electronics', 1, 1800, 180.00, 1150, 1, 1620.00),
(1115, 2, 11, 'Cable Organizer', 'Accessories', 1, 250, 0, 100, 0, 0.00),
(1116, 1, 7, 'Yoga Mat', 'Fitness', 1, 1200, 120.00, 620, 0, 0.00),
(1116, 2, 8, 'Resistance Bands', 'Fitness', 1, 550, 0, 270, 0, 0.00),
(1117, 1, 4, 'Desk Lamp', 'Home', 1, 1250, 0, 700, 0, 0.00),
(1117, 2, 3, 'USB-C Charger', 'Electronics', 1, 750, 37.50, 420, 0, 0.00),
(1118, 1, 13, 'Bluetooth Keyboard', 'Electronics', 2, 2100, 0, 1350, 0, 0.00),
(1118, 2, 2, 'Portable Speaker', 'Electronics', 1, 2400, 240.00, 1550, 0, 0.00),
(1119, 1, 8, 'Resistance Bands', 'Fitness', 1, 550, 0, 270, 0, 0.00),
(1119, 2, 12, 'Travel Pouch', 'Accessories', 1, 450, 45.00, 220, 0, 0.00),
(1120, 1, 4, 'Desk Lamp', 'Home', 1, 1250, 125.00, 700, 1, 1125.00),
(1121, 1, 14, 'Cushion Set', 'Home', 1, 1100, 55.00, 610, 0, 0.00),
(1121, 2, 16, 'Laptop Stand', 'Accessories', 1, 1500, 150.00, 900, 0, 0.00),
(1122, 1, 5, 'Storage Basket', 'Home', 1, 600, 0, 300, 0, 0.00),
(1122, 2, 17, 'Food Container Set', 'Home', 1, 700, 35.00, 370, 0, 0.00),
(1123, 1, 3, 'USB-C Charger', 'Electronics', 1, 750, 75.00, 420, 0, 0.00),
(1123, 2, 14, 'Cushion Set', 'Home', 1, 1100, 0, 610, 0, 0.00),
(1124, 1, 7, 'Yoga Mat', 'Fitness', 2, 1200, 120.00, 620, 0, 0.00),
(1124, 2, 8, 'Resistance Bands', 'Fitness', 1, 550, 0, 270, 0, 0.00),
(1125, 1, 8, 'Resistance Bands', 'Fitness', 2, 550, 55.00, 270, 0, 0.00),
(1126, 1, 3, 'USB-C Charger', 'Electronics', 1, 750, 0, 420, 0, 0.00),
(1127, 1, 11, 'Cable Organizer', 'Accessories', 1, 250, 0, 100, 0, 0.00),
(1127, 2, 2, 'Portable Speaker', 'Electronics', 2, 2400, 0, 1550, 0, 0.00),
(1128, 1, 7, 'Yoga Mat', 'Fitness', 1, 1200, 60.00, 620, 0, 0.00);

INSERT INTO order_items (order_id, item_number, product_id, product_name, category, quantity, unit_price, discount_amount, unit_cost, returned_quantity, refund_amount) VALUES
(1128, 2, 8, 'Resistance Bands', 'Fitness', 1, 550, 27.50, 270, 0, 0.00),
(1129, 1, 17, 'Food Container Set', 'Home', 1, 700, 35.00, 370, 0, 0.00),
(1129, 2, 14, 'Cushion Set', 'Home', 1, 1100, 110.00, 610, 0, 0.00),
(1130, 1, 1, 'Wireless Earbuds', 'Electronics', 1, 1800, 0, 1150, 0, 0.00),
(1130, 2, 11, 'Cable Organizer', 'Accessories', 1, 250, 25.00, 100, 1, 225.00),
(1131, 1, 1, 'Wireless Earbuds', 'Electronics', 2, 1800, 0, 1150, 0, 0.00),
(1131, 2, 12, 'Travel Pouch', 'Accessories', 1, 500, 0, 220, 0, 0.00),
(1132, 1, 7, 'Yoga Mat', 'Fitness', 2, 1200, 0, 620, 0, 0.00),
(1132, 2, 8, 'Resistance Bands', 'Fitness', 2, 550, 110.00, 270, 0, 0.00),
(1133, 1, 1, 'Wireless Earbuds', 'Electronics', 1, 1800, 0, 1150, 1, 1800.00),
(1133, 2, 13, 'Bluetooth Keyboard', 'Electronics', 1, 2100, 0, 1350, 0, 0.00),
(1134, 1, 12, 'Travel Pouch', 'Accessories', 1, 500, 0, 220, 0, 0.00),
(1134, 2, 9, 'Training Gloves', 'Fitness', 1, 700, 70.00, 320, 0, 0.00),
(1135, 1, 5, 'Storage Basket', 'Home', 1, 600, 60.00, 300, 0, 0.00),
(1136, 1, 15, 'Foam Roller', 'Fitness', 2, 1050, 0, 530, 0, 0.00),
(1137, 1, 1, 'Wireless Earbuds', 'Electronics', 1, 1800, 90.00, 1150, 0, 0.00),
(1137, 2, 17, 'Food Container Set', 'Home', 1, 700, 0, 370, 0, 0.00),
(1138, 1, 1, 'Wireless Earbuds', 'Electronics', 1, 1800, 90.00, 1150, 1, 1710.00),
(1138, 2, 6, 'Insulated Bottle', 'Home', 1, 900, 90.00, 430, 0, 0.00),
(1139, 1, 8, 'Resistance Bands', 'Fitness', 1, 550, 27.50, 270, 0, 0.00),
(1139, 2, 13, 'Bluetooth Keyboard', 'Electronics', 2, 2100, 420.00, 1350, 0, 0.00),
(1140, 1, 7, 'Yoga Mat', 'Fitness', 1, 1200, 0, 620, 1, 1200.00),
(1140, 2, 8, 'Resistance Bands', 'Fitness', 1, 550, 0, 270, 1, 550.00),
(1141, 1, 2, 'Portable Speaker', 'Electronics', 1, 2400, 240.00, 1550, 0, 0.00),
(1142, 1, 14, 'Cushion Set', 'Home', 1, 1100, 0, 610, 0, 0.00),
(1142, 2, 7, 'Yoga Mat', 'Fitness', 1, 1200, 120.00, 620, 0, 0.00),
(1143, 1, 15, 'Foam Roller', 'Fitness', 1, 1050, 0, 530, 0, 0.00),
(1143, 2, 11, 'Cable Organizer', 'Accessories', 1, 250, 25.00, 100, 0, 0.00),
(1144, 1, 16, 'Laptop Stand', 'Accessories', 2, 1500, 0, 900, 0, 0.00),
(1145, 1, 1, 'Wireless Earbuds', 'Electronics', 2, 1800, 360.00, 1150, 0, 0.00),
(1145, 2, 11, 'Cable Organizer', 'Accessories', 1, 250, 12.50, 100, 0, 0.00),
(1146, 1, 12, 'Travel Pouch', 'Accessories', 1, 500, 0, 220, 0, 0.00),
(1146, 2, 16, 'Laptop Stand', 'Accessories', 1, 1500, 0, 900, 0, 0.00),
(1147, 1, 13, 'Bluetooth Keyboard', 'Electronics', 1, 2100, 0, 1350, 0, 0.00),
(1147, 2, 5, 'Storage Basket', 'Home', 2, 600, 0, 300, 0, 0.00),
(1148, 1, 7, 'Yoga Mat', 'Fitness', 1, 1200, 60.00, 620, 0, 0.00),
(1148, 2, 8, 'Resistance Bands', 'Fitness', 2, 550, 110.00, 270, 0, 0.00),
(1149, 1, 1, 'Wireless Earbuds', 'Electronics', 1, 1800, 90.00, 1150, 0, 0.00),
(1149, 2, 7, 'Yoga Mat', 'Fitness', 1, 1200, 60.00, 620, 0, 0.00),
(1149, 3, 17, 'Food Container Set', 'Home', 1, 700, 35.00, 370, 0, 0.00),
(1150, 1, 10, 'Laptop Sleeve', 'Accessories', 1, 900, 90.00, 480, 0, 0.00),
(1151, 1, 10, 'Laptop Sleeve', 'Accessories', 1, 900, 0, 480, 0, 0.00),
(1151, 2, 16, 'Laptop Stand', 'Accessories', 2, 1500, 150.00, 900, 0, 0.00),
(1152, 1, 7, 'Yoga Mat', 'Fitness', 1, 1200, 0, 620, 0, 0.00),
(1152, 2, 8, 'Resistance Bands', 'Fitness', 1, 550, 0, 270, 0, 0.00),
(1153, 1, 18, 'Jump Rope', 'Fitness', 1, 450, 45.00, 180, 0, 0.00),
(1153, 2, 9, 'Training Gloves', 'Fitness', 1, 700, 35.00, 320, 0, 0.00),
(1154, 1, 3, 'USB-C Charger', 'Electronics', 1, 800, 80.00, 420, 0, 0.00),
(1154, 2, 11, 'Cable Organizer', 'Accessories', 1, 250, 25.00, 100, 0, 0.00),
(1155, 1, 18, 'Jump Rope', 'Fitness', 1, 450, 22.50, 180, 0, 0.00),
(1156, 1, 15, 'Foam Roller', 'Fitness', 2, 1050, 0, 530, 0, 0.00),
(1157, 1, 4, 'Desk Lamp', 'Home', 2, 1250, 0, 700, 0, 0.00),
(1157, 2, 1, 'Wireless Earbuds', 'Electronics', 1, 1800, 180.00, 1150, 1, 1620.00),
(1158, 1, 8, 'Resistance Bands', 'Fitness', 1, 550, 55.00, 270, 1, 495.00),
(1158, 2, 7, 'Yoga Mat', 'Fitness', 1, 1200, 0, 620, 0, 0.00),
(1159, 1, 13, 'Bluetooth Keyboard', 'Electronics', 1, 2100, 105.00, 1350, 0, 0.00),
(1159, 2, 16, 'Laptop Stand', 'Accessories', 2, 1500, 0, 900, 0, 0.00),
(1160, 1, 7, 'Yoga Mat', 'Fitness', 1, 1200, 120.00, 620, 0, 0.00),
(1160, 2, 8, 'Resistance Bands', 'Fitness', 1, 550, 0, 270, 0, 0.00),
(1161, 1, 6, 'Insulated Bottle', 'Home', 1, 900, 45.00, 430, 0, 0.00),
(1161, 2, 8, 'Resistance Bands', 'Fitness', 1, 550, 0, 270, 0, 0.00),
(1161, 3, 2, 'Portable Speaker', 'Electronics', 2, 2400, 0, 1550, 0, 0.00),
(1162, 1, 10, 'Laptop Sleeve', 'Accessories', 1, 900, 0, 480, 0, 0.00),
(1162, 2, 3, 'USB-C Charger', 'Electronics', 1, 800, 0, 420, 0, 0.00),
(1163, 1, 18, 'Jump Rope', 'Fitness', 1, 450, 0, 180, 0, 0.00),
(1163, 2, 1, 'Wireless Earbuds', 'Electronics', 1, 1800, 180.00, 1150, 0, 0.00),
(1164, 1, 3, 'USB-C Charger', 'Electronics', 1, 800, 40.00, 420, 0, 0.00),
(1165, 1, 1, 'Wireless Earbuds', 'Electronics', 1, 1800, 180.00, 1150, 0, 0.00),
(1165, 2, 11, 'Cable Organizer', 'Accessories', 1, 250, 0, 100, 0, 0.00),
(1166, 1, 13, 'Bluetooth Keyboard', 'Electronics', 1, 2100, 0, 1350, 0, 0.00),
(1166, 2, 4, 'Desk Lamp', 'Home', 2, 1250, 0, 700, 0, 0.00),
(1167, 1, 8, 'Resistance Bands', 'Fitness', 2, 550, 110.00, 270, 0, 0.00),
(1167, 2, 7, 'Yoga Mat', 'Fitness', 1, 1200, 60.00, 620, 0, 0.00),
(1168, 1, 7, 'Yoga Mat', 'Fitness', 1, 1200, 0, 620, 0, 0.00),
(1168, 2, 8, 'Resistance Bands', 'Fitness', 1, 550, 27.50, 270, 0, 0.00),
(1169, 1, 12, 'Travel Pouch', 'Accessories', 1, 500, 150.00, 220, 0, 0.00);

INSERT INTO order_items (order_id, item_number, product_id, product_name, category, quantity, unit_price, discount_amount, unit_cost, returned_quantity, refund_amount) VALUES
(1170, 1, 1, 'Wireless Earbuds', 'Electronics', 1, 1800, 0, 1150, 0, 0.00),
(1170, 2, 11, 'Cable Organizer', 'Accessories', 1, 250, 0, 100, 0, 0.00),
(1171, 1, 8, 'Resistance Bands', 'Fitness', 1, 550, 55.00, 270, 0, 0.00),
(1171, 2, 5, 'Storage Basket', 'Home', 1, 600, 60.00, 300, 1, 540.00),
(1172, 1, 7, 'Yoga Mat', 'Fitness', 1, 1200, 60.00, 620, 1, 1140.00),
(1172, 2, 8, 'Resistance Bands', 'Fitness', 1, 550, 55.00, 270, 0, 0.00),
(1173, 1, 10, 'Laptop Sleeve', 'Accessories', 1, 900, 45.00, 480, 0, 0.00),
(1174, 1, 18, 'Jump Rope', 'Fitness', 2, 450, 90.00, 180, 0, 0.00),
(1174, 2, 12, 'Travel Pouch', 'Accessories', 1, 500, 25.00, 220, 0, 0.00),
(1174, 3, 11, 'Cable Organizer', 'Accessories', 1, 250, 0, 100, 0, 0.00),
(1175, 1, 1, 'Wireless Earbuds', 'Electronics', 1, 1800, 0, 1150, 0, 0.00),
(1175, 2, 11, 'Cable Organizer', 'Accessories', 1, 250, 75.00, 100, 0, 0.00),
(1176, 1, 7, 'Yoga Mat', 'Fitness', 1, 1200, 120.00, 620, 0, 0.00),
(1176, 2, 8, 'Resistance Bands', 'Fitness', 1, 550, 165.00, 270, 0, 0.00),
(1177, 1, 13, 'Bluetooth Keyboard', 'Electronics', 2, 2100, 420.00, 1350, 0, 0.00),
(1177, 2, 6, 'Insulated Bottle', 'Home', 1, 900, 180.00, 430, 0, 0.00),
(1177, 3, 3, 'USB-C Charger', 'Electronics', 2, 800, 80.00, 420, 0, 0.00),
(1178, 1, 15, 'Foam Roller', 'Fitness', 1, 1050, 315.00, 530, 0, 0.00),
(1178, 2, 6, 'Insulated Bottle', 'Home', 1, 900, 90.00, 430, 0, 0.00),
(1179, 1, 3, 'USB-C Charger', 'Electronics', 1, 800, 160.00, 420, 1, 640.00),
(1180, 1, 7, 'Yoga Mat', 'Fitness', 1, 1200, 120.00, 620, 0, 0.00),
(1180, 2, 8, 'Resistance Bands', 'Fitness', 2, 550, 0, 270, 0, 0.00),
(1181, 1, 17, 'Food Container Set', 'Home', 1, 700, 0, 370, 0, 0.00),
(1182, 1, 1, 'Wireless Earbuds', 'Electronics', 1, 1800, 540.00, 1150, 0, 0.00),
(1182, 2, 10, 'Laptop Sleeve', 'Accessories', 1, 900, 0, 480, 0, 0.00),
(1183, 1, 4, 'Desk Lamp', 'Home', 1, 1250, 375.00, 700, 0, 0.00),
(1183, 2, 16, 'Laptop Stand', 'Accessories', 2, 1500, 600.00, 900, 1, 1200.00),
(1184, 1, 7, 'Yoga Mat', 'Fitness', 1, 1200, 120.00, 620, 0, 0.00),
(1184, 2, 8, 'Resistance Bands', 'Fitness', 1, 550, 0, 270, 0, 0.00),
(1185, 1, 17, 'Food Container Set', 'Home', 1, 700, 70.00, 370, 0, 0.00),
(1186, 1, 9, 'Training Gloves', 'Fitness', 2, 700, 420.00, 320, 0, 0.00),
(1186, 2, 11, 'Cable Organizer', 'Accessories', 1, 250, 12.50, 100, 0, 0.00),
(1187, 1, 3, 'USB-C Charger', 'Electronics', 1, 800, 80.00, 420, 0, 0.00),
(1188, 1, 7, 'Yoga Mat', 'Fitness', 1, 1200, 0, 620, 0, 0.00),
(1188, 2, 8, 'Resistance Bands', 'Fitness', 2, 550, 0, 270, 0, 0.00),
(1189, 1, 10, 'Laptop Sleeve', 'Accessories', 1, 900, 0, 480, 0, 0.00),
(1189, 2, 2, 'Portable Speaker', 'Electronics', 1, 2400, 240.00, 1550, 0, 0.00),
(1190, 1, 1, 'Wireless Earbuds', 'Electronics', 1, 1800, 180.00, 1150, 0, 0.00),
(1190, 2, 11, 'Cable Organizer', 'Accessories', 1, 250, 12.50, 100, 1, 237.50),
(1191, 1, 11, 'Cable Organizer', 'Accessories', 1, 250, 25.00, 100, 0, 0.00),
(1191, 2, 8, 'Resistance Bands', 'Fitness', 1, 550, 165.00, 270, 0, 0.00),
(1192, 1, 7, 'Yoga Mat', 'Fitness', 1, 1200, 360.00, 620, 0, 0.00),
(1192, 2, 8, 'Resistance Bands', 'Fitness', 1, 550, 0, 270, 0, 0.00),
(1193, 1, 12, 'Travel Pouch', 'Accessories', 1, 500, 0, 220, 0, 0.00),
(1194, 1, 14, 'Cushion Set', 'Home', 1, 1100, 110.00, 610, 0, 0.00),
(1194, 2, 6, 'Insulated Bottle', 'Home', 1, 900, 0, 430, 0, 0.00),
(1195, 1, 1, 'Wireless Earbuds', 'Electronics', 1, 1800, 360.00, 1150, 1, 1440.00),
(1195, 2, 11, 'Cable Organizer', 'Accessories', 1, 250, 50.00, 100, 0, 0.00),
(1196, 1, 7, 'Yoga Mat', 'Fitness', 1, 1200, 360.00, 620, 0, 0.00),
(1196, 2, 8, 'Resistance Bands', 'Fitness', 1, 550, 165.00, 270, 0, 0.00),
(1197, 1, 17, 'Food Container Set', 'Home', 1, 700, 70.00, 370, 0, 0.00),
(1197, 2, 10, 'Laptop Sleeve', 'Accessories', 1, 900, 45.00, 480, 0, 0.00),
(1198, 1, 6, 'Insulated Bottle', 'Home', 2, 900, 180.00, 430, 0, 0.00),
(1198, 2, 8, 'Resistance Bands', 'Fitness', 2, 550, 220.00, 270, 0, 0.00),
(1199, 1, 12, 'Travel Pouch', 'Accessories', 1, 500, 25.00, 220, 1, 475.00),
(1199, 2, 7, 'Yoga Mat', 'Fitness', 1, 1200, 0, 620, 0, 0.00),
(1200, 1, 7, 'Yoga Mat', 'Fitness', 1, 1200, 0, 620, 0, 0.00),
(1200, 2, 8, 'Resistance Bands', 'Fitness', 2, 550, 55.00, 270, 0, 0.00),
(1201, 1, 7, 'Yoga Mat', 'Fitness', 1, 1200, 360.00, 620, 0, 0.00),
(1201, 2, 17, 'Food Container Set', 'Home', 1, 700, 35.00, 370, 0, 0.00),
(1202, 1, 11, 'Cable Organizer', 'Accessories', 1, 250, 0, 100, 0, 0.00),
(1202, 2, 7, 'Yoga Mat', 'Fitness', 2, 1200, 120.00, 620, 0, 0.00),
(1203, 1, 13, 'Bluetooth Keyboard', 'Electronics', 1, 2100, 630.00, 1350, 1, 1470.00),
(1203, 2, 9, 'Training Gloves', 'Fitness', 1, 700, 140.00, 320, 1, 560.00),
(1204, 1, 7, 'Yoga Mat', 'Fitness', 1, 1200, 360.00, 620, 0, 0.00),
(1204, 2, 8, 'Resistance Bands', 'Fitness', 1, 550, 55.00, 270, 0, 0.00),
(1205, 1, 1, 'Wireless Earbuds', 'Electronics', 1, 1800, 180.00, 1150, 0, 0.00),
(1205, 2, 11, 'Cable Organizer', 'Accessories', 2, 250, 150.00, 100, 0, 0.00),
(1206, 1, 12, 'Travel Pouch', 'Accessories', 1, 500, 150.00, 220, 0, 0.00),
(1206, 2, 6, 'Insulated Bottle', 'Home', 1, 900, 90.00, 430, 0, 0.00),
(1207, 1, 15, 'Foam Roller', 'Fitness', 1, 1050, 210.00, 530, 1, 840.00),
(1207, 2, 17, 'Food Container Set', 'Home', 1, 700, 210.00, 370, 0, 0.00),
(1208, 1, 10, 'Laptop Sleeve', 'Accessories', 1, 900, 180.00, 480, 0, 0.00),
(1209, 1, 13, 'Bluetooth Keyboard', 'Electronics', 2, 2100, 1260.00, 1350, 0, 0.00),
(1209, 2, 10, 'Laptop Sleeve', 'Accessories', 1, 900, 45.00, 480, 0, 0.00),
(1210, 1, 10, 'Laptop Sleeve', 'Accessories', 1, 900, 0, 480, 0, 0.00);

COMMIT;


-- Shared reporting layer. Run after 01_setup.sql in the same database.
SET search_path TO northstar_retail, public;
BEGIN;
CREATE OR REPLACE VIEW months AS
SELECT d::date AS month FROM generate_series(DATE '2025-01-01',DATE '2025-12-01',INTERVAL '1 month') d;
CREATE OR REPLACE VIEW line_values AS
SELECT i.*, quantity*unit_price AS gross, quantity*unit_price-discount_amount AS paid,
 quantity*unit_price-discount_amount-refund_amount AS net, quantity*unit_cost AS cost
FROM order_items i;
CREATE OR REPLACE VIEW order_values AS
SELECT o.*,c.acquisition_channel AS channel,c.region,
 date_trunc('month',order_date)::date AS month,
 CASE WHEN order_date<DATE '2025-07-01' THEN 'H1' ELSE 'H2' END AS half,
 l.gross,l.discounts,l.refunds,l.paid,l.net,l.cost,l.units,l.returned_units,
 l.net+shipping_charged AS revenue,
 l.net-l.cost+shipping_charged-shipping_cost AS contribution
FROM orders o JOIN customers c USING(customer_id)
JOIN (SELECT order_id,sum(gross) gross,sum(discount_amount) discounts,sum(refund_amount) refunds,
 sum(paid) paid,sum(net) net,sum(cost) cost,sum(quantity) units,sum(returned_quantity) returned_units
 FROM line_values GROUP BY order_id) l USING(order_id);
CREATE OR REPLACE VIEW sales AS SELECT * FROM order_values WHERE status='delivered';
CREATE OR REPLACE VIEW allocated_lines AS
SELECT l.*,s.customer_id,s.channel,s.region,s.warehouse,s.order_date,s.month,s.half,s.delivered_date,
 l.paid/NULLIF(s.paid,0)*s.shipping_charged AS allocated_charge,
 l.paid/NULLIF(s.paid,0)*s.shipping_cost AS allocated_shipping_cost,
 l.net+l.paid/NULLIF(s.paid,0)*s.shipping_charged AS revenue,
 l.net-l.cost+l.paid/NULLIF(s.paid,0)*(s.shipping_charged-s.shipping_cost) AS contribution
FROM line_values l JOIN sales s USING(order_id);
CREATE OR REPLACE VIEW sequenced_sales AS
SELECT s.*, row_number() OVER(PARTITION BY customer_id ORDER BY order_date,order_id) AS purchase_number,
 CASE WHEN row_number() OVER(PARTITION BY customer_id ORDER BY order_date,order_id)=1 THEN 'first_time' ELSE 'returning' END AS purchase_type
FROM sales s;
CREATE OR REPLACE VIEW customer_history AS
SELECT customer_id,min(channel) channel,min(region) region,
 min(order_date) first_date,max(order_date) last_date,
 max(order_id) FILTER(WHERE purchase_number=1) first_order_id,
 max(order_date) FILTER(WHERE purchase_number=2) second_date,
 count(*) orders,sum(paid) paid,sum(revenue) revenue,sum(contribution) contribution
FROM sequenced_sales GROUP BY customer_id;
CREATE OR REPLACE VIEW customer_90 AS
SELECT h.customer_id,h.channel,h.region,h.first_date,h.first_order_id,h.second_date,
 count(*) window_orders,sum(s.paid) window_paid,sum(s.contribution) window_contribution
FROM customer_history h JOIN sales s ON s.customer_id=h.customer_id
 AND s.order_date BETWEEN h.first_date AND h.first_date+90
WHERE h.first_date+90<DATE '2026-01-01'
GROUP BY h.customer_id,h.channel,h.region,h.first_date,h.first_order_id,h.second_date;
CREATE OR REPLACE VIEW monthly AS
SELECT m.month,count(o.order_id) placed_orders,
 count(*) FILTER(WHERE status='delivered') delivered_orders,
 count(*) FILTER(WHERE status='cancelled') cancelled_orders,
 count(*) FILTER(WHERE status='in_transit') in_transit_orders,
 count(DISTINCT customer_id) FILTER(WHERE status='delivered') purchasing_customers,
 coalesce(sum(paid) FILTER(WHERE status='delivered'),0) paid,
 coalesce(sum(net) FILTER(WHERE status='delivered'),0) net,
 coalesce(sum(refunds) FILTER(WHERE status='delivered'),0) refunds,
 coalesce(sum(shipping_charged) FILTER(WHERE status='delivered'),0) charged,
 coalesce(sum(shipping_cost) FILTER(WHERE status='delivered'),0) shipping_cost,
 coalesce(sum(revenue) FILTER(WHERE status='delivered'),0) revenue,
 coalesce(sum(contribution) FILTER(WHERE status='delivered'),0) contribution,
 count(*) FILTER(WHERE status='delivered' AND promised_delivery_date IS NOT NULL) eligible,
 count(*) FILTER(WHERE status='delivered' AND delivered_date>promised_delivery_date) late
FROM months m LEFT JOIN order_values o USING(month) GROUP BY m.month;
COMMIT;


-- All 30 PostgreSQL solutions. Dependencies: 01_setup.sql, 02_reporting_views.sql.
-- Views retain raw arithmetic internally; round only displayed outputs.
SET search_path TO northstar_retail, public;
BEGIN;

-- Q01: Monthly business health
CREATE OR REPLACE VIEW q01 AS
SELECT month purchase_month,placed_orders,delivered_orders,cancelled_orders,in_transit_orders,purchasing_customers,
paid paid_merchandise_value,round(paid/NULLIF(delivered_orders,0),2) aov,net net_merchandise_value,
charged shipping_charged,shipping_cost,contribution,round(100*contribution/NULLIF(revenue,0),2) margin_pct,
round(100.0*cancelled_orders/NULLIF(placed_orders,0),2) cancellation_rate_pct FROM monthly ORDER BY month;

-- Q02: Order loss diagnosis
CREATE OR REPLACE VIEW q02 AS
WITH a AS (SELECT *,CASE WHEN contribution<0 THEN row_number() OVER(PARTITION BY contribution<0 ORDER BY contribution,order_id) END loss_rank FROM sales)
SELECT order_id,gross gross_merchandise_value,discounts,refunds,cost product_cost,shipping_charged,shipping_cost,
 revenue net_revenue,contribution,round(100*contribution/NULLIF(revenue,0),2) margin_pct,contribution<0 loss_flag,
 CASE WHEN greatest(refunds,discounts,greatest(shipping_cost-shipping_charged,0))=0 THEN 'base_cost'
 WHEN refunds>=discounts AND refunds>=greatest(shipping_cost-shipping_charged,0) THEN 'refund'
 WHEN discounts>=greatest(shipping_cost-shipping_charged,0) THEN 'discount' ELSE 'shipping' END diagnosis_label,loss_rank
FROM a ORDER BY order_id;
CREATE OR REPLACE VIEW q02_worst_losses AS
SELECT * FROM q02 WHERE loss_flag ORDER BY loss_rank LIMIT 10;

-- Q03: Monthly sales bridge
CREATE OR REPLACE VIEW q03 AS
WITH a AS(SELECT *,paid/NULLIF(delivered_orders,0) aov FROM monthly),b AS(SELECT *,lag(paid) OVER w prior_sales,lag(delivered_orders) OVER w prior_n,lag(aov) OVER w prior_a FROM a WINDOW w AS(ORDER BY month))
SELECT month,delivered_orders,round(aov,2) aov,paid paid_merchandise_value,prior_n prior_orders,round(prior_a,2) prior_aov,prior_sales,paid-prior_sales sales_change,
round((delivered_orders-prior_n)*prior_a,2) volume_effect,round(delivered_orders*(aov-prior_a),2) basket_effect,
round(100*(paid-prior_sales)/NULLIF(prior_sales,0),2) growth_pct FROM b ORDER BY month;

-- Q04: Category growth contribution
CREATE OR REPLACE VIEW q04 AS
WITH a AS(SELECT category,coalesce(sum(paid) FILTER(WHERE half='H1'),0) h1,coalesce(sum(paid) FILTER(WHERE half='H2'),0) h2 FROM allocated_lines GROUP BY category),
b AS(SELECT *,sum(h1) OVER() t1,sum(h2) OVER() t2 FROM a)
SELECT category,h1 h1_sales,h2 h2_sales,h2-h1 absolute_change,round(100*(h2-h1)/NULLIF(h1,0),2) growth_pct,
round(100*h1/NULLIF(t1,0),2) h1_share_pct,round(100*h2/NULLIF(t2,0),2) h2_share_pct,
round(100*(h2/NULLIF(t2,0)-h1/NULLIF(t1,0)),2) share_change_pp,round(100*(h2-h1)/NULLIF(t2-t1,0),2) contribution_to_company_change_pct,
row_number() OVER(ORDER BY h2-h1 DESC,category) rank FROM b ORDER BY rank;

-- Q05: Rolling margin deterioration
CREATE OR REPLACE VIEW q05 AS
WITH a AS(SELECT *,CASE WHEN month>=DATE '2025-03-01' THEN sum(revenue) OVER w END r,CASE WHEN month>=DATE '2025-03-01' THEN sum(contribution) OVER w END c FROM monthly WINDOW w AS(ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)),
b AS(SELECT *,100*c/NULLIF(r,0) margin FROM a),d AS(SELECT *,margin-lag(margin) OVER(ORDER BY month) change FROM b),
e AS(SELECT *,coalesce(change<=-5,false) flag FROM d),f AS(SELECT *,sum((NOT flag)::int) OVER(ORDER BY month) grp FROM e)
SELECT month,revenue net_revenue,contribution,r rolling_3m_revenue,c rolling_3m_contribution,round(margin,2) rolling_margin_pct,round(change,2) change_pp,flag deterioration_flag,
CASE WHEN flag THEN count(*) FILTER(WHERE flag) OVER(PARTITION BY grp ORDER BY month) ELSE 0 END streak_length FROM f ORDER BY month;

-- Q06: Positive product concentration
CREATE OR REPLACE VIEW q06 AS
WITH a AS(SELECT product_id,min(product_name) product_name,sum(contribution) contribution FROM allocated_lines GROUP BY product_id HAVING sum(contribution)>0),
b AS(SELECT *,row_number() OVER w rank,sum(contribution) OVER w running,sum(contribution) OVER() pool FROM a WINDOW w AS(ORDER BY contribution DESC,product_id))
SELECT product_id,product_name,round(contribution,2) contribution,rank,round(100*contribution/pool,2) share_pct,round(100*running/pool,2) cumulative_share_pct,running-contribution<.8*pool in_80pct_group FROM b ORDER BY rank;
CREATE OR REPLACE VIEW q06_non_positive AS
SELECT count(*) products,round(coalesce(sum(c),0),2) combined_contribution FROM(SELECT product_id,sum(contribution)c FROM allocated_lines GROUP BY product_id HAVING sum(contribution)<=0)a;

-- Q07: First-time versus returning
CREATE OR REPLACE VIEW q07 AS
SELECT m.month purchase_month,t.purchase_type,count(s.order_id) orders,count(DISTINCT s.customer_id) customers,
coalesce(sum(s.paid),0) paid_merchandise_value,coalesce(sum(s.contribution),0) contribution,
round(100*coalesce(sum(s.paid),0)/NULLIF(m.paid,0),2) monthly_sales_share_pct
FROM monthly m CROSS JOIN(VALUES('first_time'),('returning'))t(purchase_type)
LEFT JOIN sequenced_sales s ON s.month=m.month AND s.purchase_type=t.purchase_type GROUP BY m.month,t.purchase_type,m.paid ORDER BY 1,2;

-- Q08: Observable cohort retention
CREATE OR REPLACE VIEW q08 AS
WITH h AS(SELECT *,date_trunc('month',first_date)::date cohort FROM customer_history),
a AS(SELECT cohort,count(*) size FROM h GROUP BY cohort),b AS(SELECT a.*,n month_index,(cohort+n*INTERVAL '1 month')::date activity_month FROM a CROSS JOIN generate_series(0,5)n),
c AS(SELECT b.*,activity_month+INTERVAL '1 month'<=DATE '2026-01-01' observable,count(DISTINCT s.customer_id) active FROM b JOIN h USING(cohort)
LEFT JOIN sales s ON s.customer_id=h.customer_id AND s.month=b.activity_month GROUP BY b.cohort,b.size,b.month_index,b.activity_month)
SELECT cohort cohort_month,size cohort_size,month_index,activity_month,observable observable_flag,CASE WHEN observable THEN active END active_customers,
CASE WHEN observable THEN round(100.0*active/size,2) END retention_pct FROM c ORDER BY cohort,month_index;

-- Q09: First-to-second purchase conversion
CREATE OR REPLACE VIEW q09 AS
WITH a AS(SELECT *,date_trunc('month',first_date)::date cohort,second_date-first_date gap FROM customer_history),b AS(
SELECT cohort,count(*) cohort_size,count(*) FILTER(WHERE first_date+30<DATE '2026-01-01') eligible_30,count(*) FILTER(WHERE first_date+60<DATE '2026-01-01') eligible_60,count(*) FILTER(WHERE first_date+90<DATE '2026-01-01') eligible_90,
count(*) FILTER(WHERE first_date+30<DATE '2026-01-01' AND gap BETWEEN 0 AND 30) converters_30,
count(*) FILTER(WHERE first_date+60<DATE '2026-01-01' AND gap BETWEEN 0 AND 60) converters_60,
count(*) FILTER(WHERE first_date+90<DATE '2026-01-01' AND gap BETWEEN 0 AND 90) converters_90,
percentile_cont(.5) WITHIN GROUP(ORDER BY gap) FILTER(WHERE first_date+90<DATE '2026-01-01' AND gap BETWEEN 0 AND 90) median_days_to_second_within_90 FROM a GROUP BY cohort)
SELECT *,round(100.0*converters_30/NULLIF(eligible_30,0),2) conversion_30_pct,round(100.0*converters_60/NULLIF(eligible_60,0),2) conversion_60_pct,round(100.0*converters_90/NULLIF(eligible_90,0),2) conversion_90_pct FROM b ORDER BY cohort;

-- Q10: Channel 90-day value
CREATE OR REPLACE VIEW q10 AS
SELECT c.channel,count(h.customer_id) eligible_customers,round(avg(window_paid),2) avg_90d_paid_value,round(avg(window_contribution),2) avg_90d_contribution,
round((percentile_cont(.5) WITHIN GROUP(ORDER BY window_contribution))::numeric,2) median_90d_contribution,round(avg(window_orders),2) avg_90d_orders,
round(100.0*count(*) FILTER(WHERE window_orders>=2)/NULLIF(count(h.customer_id),0),2) repeat_customer_pct,
CASE WHEN count(h.customer_id)<5 THEN 'insufficient_sample' ELSE 'sufficient_sample' END sample_flag
FROM(SELECT DISTINCT acquisition_channel channel FROM customers)c LEFT JOIN customer_90 h USING(channel) GROUP BY c.channel ORDER BY c.channel;

-- Q11: First-purchase entry category
CREATE OR REPLACE VIEW q11 AS
WITH a AS(SELECT h.customer_id,l.category,sum(l.paid) paid,row_number() OVER(PARTITION BY h.customer_id ORDER BY sum(l.paid) DESC,l.category) rn FROM customer_90 h JOIN line_values l ON l.order_id=h.first_order_id GROUP BY h.customer_id,l.category)
SELECT a.category entry_category,count(*) eligible_customers,round(avg(s.paid),2) first_order_aov,round(avg(h.window_contribution),2) avg_90d_contribution,
round(100.0*count(*) FILTER(WHERE window_orders>=2)/count(*),2) second_purchase_90d_pct,
CASE WHEN count(*)<5 THEN 'insufficient_sample' ELSE 'sufficient_sample' END sample_flag FROM a JOIN customer_90 h USING(customer_id) JOIN sales s ON s.order_id=h.first_order_id WHERE rn=1 GROUP BY a.category ORDER BY a.category;

-- Q12: Win-back audience
CREATE OR REPLACE VIEW q12 AS
WITH latest AS(SELECT DISTINCT ON(customer_id) customer_id,status FROM orders ORDER BY customer_id,order_date DESC,order_id DESC),a AS(
SELECT h.customer_id,channel,orders qualifying_orders,last_date last_purchase_date,DATE '2026-01-01'-last_date recency_days,contribution lifetime_contribution,l.status latest_order_status,
row_number() OVER(ORDER BY contribution DESC,DATE '2026-01-01'-last_date DESC,h.customer_id) priority_rank
FROM customer_history h JOIN latest l USING(customer_id) WHERE orders>=2 AND contribution>0 AND DATE '2026-01-01'-last_date>=60 AND l.status<>'in_transit') SELECT * FROM a WHERE priority_rank<=10 ORDER BY priority_rank;

-- Q13: Mature discount-band economics
CREATE OR REPLACE VIEW q13 AS
WITH a AS(SELECT *,CASE WHEN discounts=0 THEN 'none' WHEN discounts/gross<.1 THEN 'low' WHEN discounts/gross<.2 THEN 'medium' ELSE 'high' END band FROM sales WHERE delivered_date<=DATE '2025-12-01')
SELECT b.band,count(a.order_id) orders,round(sum(paid)/NULLIF(count(a.order_id),0),2) aov,coalesce(sum(revenue),0) net_revenue,coalesce(sum(contribution),0) contribution,
round(100*sum(contribution)/NULLIF(sum(revenue),0),2) margin_pct,coalesce(sum(units),0) purchased_units,coalesce(sum(returned_units),0) returned_units,
round(100.0*sum(returned_units)/NULLIF(sum(units),0),2) unit_return_pct,round(100.0*count(*) FILTER(WHERE returned_units>0)/NULLIF(count(a.order_id),0),2) order_return_pct,
CASE WHEN count(a.order_id)<5 THEN 'insufficient_sample' ELSE 'sufficient_sample' END sample_flag
FROM(VALUES('none',1),('low',2),('medium',3),('high',4))b(band,seq) LEFT JOIN a USING(band) GROUP BY b.band,b.seq ORDER BY b.seq;

-- Q14: Category growth versus margin
CREATE OR REPLACE VIEW q14 AS
WITH a AS(SELECT category,sum(paid) FILTER(WHERE half='H1') p1,sum(paid) FILTER(WHERE half='H2') p2,
sum(revenue) FILTER(WHERE half='H1') r1,sum(revenue) FILTER(WHERE half='H2') r2,sum(contribution) FILTER(WHERE half='H1') c1,sum(contribution) FILTER(WHERE half='H2') c2 FROM allocated_lines GROUP BY category),
b AS(SELECT *,100*c1/NULLIF(r1,0) m1,100*c2/NULLIF(r2,0) m2 FROM a)
SELECT category,p1 h1_paid_value,p2 h2_paid_value,round(r1,2) h1_net_revenue,round(r2,2) h2_net_revenue,round(c1,2) h1_contribution,round(c2,2) h2_contribution,round(m1,2) h1_margin_pct,round(m2,2) h2_margin_pct,
round(100*(p2-p1)/NULLIF(p1,0),2) paid_value_growth_pct,round(m2-m1,2) margin_change_pp,CASE WHEN m1 IS NOT NULL AND m2 IS NOT NULL THEN p2>p1 AND m2-m1<=-5 END review_flag FROM b ORDER BY category;

-- Q15: Mechanical no-discount scenario
CREATE OR REPLACE VIEW q15 AS
SELECT category,sum(discount_amount) actual_discounts,round(sum(discount_amount*returned_quantity/quantity),2) discounts_on_returned_units,
sum(net) actual_net_merchandise_value,sum((quantity-returned_quantity)*unit_price) no_discount_net_merchandise_value,
round(sum(contribution),2) actual_contribution,round(sum((quantity-returned_quantity)*unit_price-cost+allocated_charge-allocated_shipping_cost),2) no_discount_contribution,
round(sum((quantity-returned_quantity)*unit_price-net),2) mechanical_contribution_lift FROM allocated_lines GROUP BY category ORDER BY category;

-- Q16: Mature product returns
CREATE OR REPLACE VIEW q16 AS
WITH products AS(SELECT DISTINCT product_id,product_name FROM allocated_lines),a AS(
SELECT p.product_id,p.product_name,count(DISTINCT l.order_id) eligible_orders,coalesce(sum(quantity),0) purchased_units,coalesce(sum(returned_quantity),0) returned_units,
count(DISTINCT l.order_id) FILTER(WHERE returned_quantity>0) orders_with_return,coalesce(sum(refund_amount),0) refunds FROM products p LEFT JOIN allocated_lines l ON l.product_id=p.product_id AND l.delivered_date<=DATE '2025-12-01' GROUP BY p.product_id,p.product_name),
b AS(SELECT *,100.0*returned_units/NULLIF(purchased_units,0) rate FROM a)
SELECT product_id,product_name,eligible_orders,purchased_units,returned_units,round(rate,2) unit_return_pct,orders_with_return,round(100.0*orders_with_return/NULLIF(eligible_orders,0),2) order_return_pct,refunds,
CASE WHEN purchased_units<8 THEN 'insufficient_sample' ELSE 'sufficient_sample' END sample_flag,
CASE WHEN purchased_units>=8 THEN row_number() OVER(PARTITION BY purchased_units>=8 ORDER BY rate DESC,refunds DESC,product_id) END quality_rank FROM b ORDER BY quality_rank NULLS LAST,product_id;
CREATE OR REPLACE VIEW q16_immature_exclusion AS
SELECT count(*) excluded_orders,sum(units) purchased_units,sum(returned_units) returned_units,sum(refunds) refunds FROM sales WHERE delivered_date>DATE '2025-12-01';

-- Q17: Regional contribution bridge
CREATE OR REPLACE VIEW q17 AS
SELECT region,sum(gross) gross_value,sum(discounts) discounts,sum(refunds) refunds,sum(cost) product_cost,sum(shipping_charged) shipping_charged,sum(shipping_cost) shipping_cost,sum(revenue) net_revenue,sum(contribution) contribution,
round(100*sum(contribution)/NULLIF(sum(revenue),0),2) margin_pct,round(100*sum(discounts)/NULLIF(sum(gross),0),2) discount_pct_of_gross,round(100*sum(refunds)/NULLIF(sum(gross),0),2) refund_pct_of_gross,
round(100*sum(cost)/NULLIF(sum(gross),0),2) product_cost_pct_of_gross,round(100*sum(shipping_cost)/NULLIF(sum(gross),0),2) shipping_cost_pct_of_gross,
sum(shipping_charged-shipping_cost) shipping_net,row_number() OVER(ORDER BY sum(contribution)/NULLIF(sum(revenue),0),region) rank FROM sales GROUP BY region ORDER BY rank;

-- Q18: Category-mix standardized regions
CREATE OR REPLACE VIEW q18 AS
WITH w AS(SELECT category,sum(revenue)/sum(sum(revenue)) OVER() weight FROM allocated_lines GROUP BY category),rc AS(SELECT region,category,sum(revenue) revenue,sum(contribution) contribution FROM allocated_lines GROUP BY region,category),
a AS(SELECT r.region,100*sum(rc.contribution)/NULLIF(sum(rc.revenue),0) actual,
CASE WHEN count(*) FILTER(WHERE w.weight>0 AND (rc.revenue IS NULL OR rc.revenue=0))=0 THEN sum(100*w.weight*rc.contribution/NULLIF(rc.revenue,0)) END standardized,
string_agg(w.category,', ' ORDER BY w.category) FILTER(WHERE w.weight>0 AND (rc.revenue IS NULL OR rc.revenue=0)) missing_categories
FROM(SELECT DISTINCT region FROM customers)r CROSS JOIN w LEFT JOIN rc ON rc.region=r.region AND rc.category=w.category GROUP BY r.region)
SELECT region,round(actual,2) actual_margin_pct,round(standardized,2) standardized_margin_pct,round(actual-standardized,2) actual_minus_standardized_pp,missing_categories,
CASE WHEN standardized IS NOT NULL THEN row_number() OVER(ORDER BY standardized DESC NULLS LAST,region) END standardized_rank FROM a ORDER BY standardized_rank NULLS LAST,region;
CREATE OR REPLACE VIEW q18_common_weights AS
SELECT category,round(sum(revenue),2) net_revenue,round(100*sum(revenue)/sum(sum(revenue)) OVER(),2) weight_pct FROM allocated_lines GROUP BY category ORDER BY category;

-- Q19: Delivery reliability
CREATE OR REPLACE VIEW q19 AS
SELECT warehouse,region,count(*) delivered_orders,count(*) FILTER(WHERE promised_delivery_date IS NULL) missing_promises,count(promised_delivery_date) eligible_orders,
count(*) FILTER(WHERE delivered_date>promised_delivery_date) late_orders,round(100.0*count(*) FILTER(WHERE delivered_date>promised_delivery_date)/NULLIF(count(promised_delivery_date),0),2) late_pct,
round(100.0*count(*) FILTER(WHERE delivered_date<=promised_delivery_date)/NULLIF(count(promised_delivery_date),0),2) on_time_pct,
round(avg(delivered_date-promised_delivery_date) FILTER(WHERE delivered_date>promised_delivery_date),2) avg_days_late,
round((percentile_cont(.9) WITHIN GROUP(ORDER BY delivered_date-promised_delivery_date) FILTER(WHERE delivered_date>promised_delivery_date))::numeric,2) p90_days_late,
CASE WHEN count(promised_delivery_date)<5 THEN 'insufficient_sample' ELSE 'sufficient_sample' END sample_flag FROM sales GROUP BY warehouse,region ORDER BY warehouse,region;

-- Q20: Warehouse deterioration streak
CREATE OR REPLACE VIEW q20 AS
WITH a AS(SELECT m.month,w.warehouse,count(s.promised_delivery_date) eligible_orders,count(*) FILTER(WHERE s.delivered_date>s.promised_delivery_date) late_orders
FROM months m CROSS JOIN(SELECT DISTINCT warehouse FROM orders)w LEFT JOIN sales s ON s.month=m.month AND s.warehouse=w.warehouse GROUP BY m.month,w.warehouse),
b AS(SELECT *,CASE WHEN month>=DATE '2025-04-01' THEN sum(eligible_orders) OVER w END be,CASE WHEN month>=DATE '2025-04-01' THEN sum(late_orders) OVER w END bl,100.0*late_orders/NULLIF(eligible_orders,0) rate FROM a WINDOW w AS(PARTITION BY warehouse ORDER BY month ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING)),
c AS(SELECT *,100.0*bl/NULLIF(be,0) baseline FROM b),d AS(SELECT *,coalesce(eligible_orders>=5 AND be>=15 AND rate-baseline>=15,false) flag FROM c),e AS(SELECT *,sum((NOT flag)::int) OVER(PARTITION BY warehouse ORDER BY month) grp FROM d)
SELECT warehouse,month,eligible_orders,late_orders,round(rate,2) late_pct,be baseline_eligible_orders,round(baseline,2) baseline_late_pct,round(rate-baseline,2) excess_pp,flag warning_flag,
CASE WHEN flag THEN count(*) FILTER(WHERE flag) OVER(PARTITION BY warehouse,grp ORDER BY month) ELSE 0 END streak_length FROM e ORDER BY warehouse,month;

-- Q21: First delivery and repeat purchasing
CREATE OR REPLACE VIEW q21 AS
WITH a AS(SELECT h.*,CASE WHEN s.delivered_date>s.promised_delivery_date THEN 'late' ELSE 'on_time' END experience,second_date-first_date gap FROM customer_90 h JOIN sales s ON s.order_id=h.first_order_id WHERE s.promised_delivery_date IS NOT NULL)
SELECT c.channel,e.experience,count(a.customer_id) eligible_customers,count(*) FILTER(WHERE gap BETWEEN 0 AND 90) converters_90d,
round(100.0*count(*) FILTER(WHERE gap BETWEEN 0 AND 90)/NULLIF(count(a.customer_id),0),2) conversion_pct,
percentile_cont(.5) WITHIN GROUP(ORDER BY gap) FILTER(WHERE gap BETWEEN 0 AND 90) median_second_purchase_gap,
CASE WHEN count(a.customer_id)<5 THEN 'insufficient_sample' ELSE 'sufficient_sample' END sample_flag
FROM(SELECT DISTINCT acquisition_channel channel FROM customers)c CROSS JOIN(VALUES('late'),('on_time'))e(experience) LEFT JOIN a ON a.channel=c.channel AND a.experience=e.experience GROUP BY c.channel,e.experience ORDER BY 1,2;
CREATE OR REPLACE VIEW q21_missing_first_promises AS
SELECT count(*) excluded_mature_customers FROM customer_90 h JOIN sales s ON s.order_id=h.first_order_id WHERE s.promised_delivery_date IS NULL;

-- Q22: Shipping subsidy exposure
CREATE OR REPLACE VIEW q22 AS
WITH a AS(SELECT r.region,q.quarter,count(s.order_id) orders,coalesce(sum(shipping_charged),0) charged,coalesce(sum(shipping_cost),0) cost,count(*) FILTER(WHERE shipping_cost>shipping_charged) subsidized
FROM(SELECT DISTINCT region FROM customers)r CROSS JOIN generate_series(1,4)q(quarter) LEFT JOIN sales s ON s.region=r.region AND extract(quarter FROM s.order_date)=q.quarter GROUP BY r.region,q.quarter)
SELECT region,quarter,orders,charged,cost,cost-charged subsidy,round((cost-charged)/NULLIF(orders,0),2) subsidy_per_order,round(100*charged/NULLIF(cost,0),2) recovery_pct,
round(100.0*subsidized/NULLIF(orders,0),2) subsidized_order_pct,row_number() OVER(ORDER BY cost-charged DESC,region,quarter) exposure_rank FROM a ORDER BY exposure_rank;
CREATE OR REPLACE VIEW q22_annual_regions AS
SELECT region,sum(orders) orders,sum(charged) charged,sum(cost) cost,sum(subsidy) subsidy,round(sum(subsidy)/NULLIF(sum(orders),0),2) subsidy_per_order,round(100*sum(charged)/NULLIF(sum(cost),0),2) recovery_pct,bool_and(subsidy>0) positive_all_four_quarters FROM q22 GROUP BY region ORDER BY subsidy DESC,region;

-- Q23: Conservative delivery promises
CREATE OR REPLACE VIEW q23 AS
SELECT warehouse,region,count(*) eligible_orders,round(avg(promised_delivery_date-order_date),2) avg_promised_days,round(avg(delivered_date-order_date),2) avg_actual_days,
round(avg(promised_delivery_date-delivered_date),2) avg_signed_buffer_days,percentile_cont(.5) WITHIN GROUP(ORDER BY promised_delivery_date-delivered_date) median_buffer_days,
round(100.0*count(*) FILTER(WHERE promised_delivery_date-delivered_date>=3)/count(*),2) early_3plus_pct,round(100.0*count(*) FILTER(WHERE delivered_date>promised_delivery_date)/count(*),2) late_pct,
count(*)>=10 AND 1.0*count(*) FILTER(WHERE promised_delivery_date-delivered_date>=3)/count(*)>=.5 AND 1.0*count(*) FILTER(WHERE delivered_date>promised_delivery_date)/count(*)<=.1 review_candidate
FROM sales WHERE promised_delivery_date IS NOT NULL GROUP BY warehouse,region ORDER BY warehouse,region;

-- Q24: Cancellation exposure
CREATE OR REPLACE VIEW q24 AS
WITH a AS(SELECT region,half,count(*) placed_orders,count(*) FILTER(WHERE status='cancelled') cancelled_orders,100.0*count(*) FILTER(WHERE status='cancelled')/count(*) rate,
coalesce(sum(paid) FILTER(WHERE status='cancelled'),0) cancelled_quoted_value,sum(paid) placed_quoted_value FROM order_values GROUP BY region,half)
SELECT region,half,placed_orders,cancelled_orders,round(rate,2) cancellation_pct,cancelled_quoted_value,placed_quoted_value,round(100*cancelled_quoted_value/NULLIF(placed_quoted_value,0),2) cancelled_value_share_pct,
round(rate-lag(rate) OVER(PARTITION BY region ORDER BY half),2) change_vs_h1_pp,CASE WHEN placed_orders<10 THEN 'insufficient_sample' ELSE 'sufficient_sample' END sample_flag FROM a ORDER BY region,half;

-- Q25: Cross-sell product pairs
CREATE OR REPLACE VIEW q25 AS
WITH baskets AS(SELECT DISTINCT order_id,product_id FROM allocated_lines),single AS(SELECT product_id,count(*) n FROM baskets GROUP BY product_id),pairs AS(SELECT a.product_id a,b.product_id b,count(*) n FROM baskets a JOIN baskets b ON a.order_id=b.order_id AND a.product_id<b.product_id GROUP BY a.product_id,b.product_id HAVING count(*)>=3),
x AS(SELECT p.*,sa.n na,sb.n nb,(SELECT count(*) FROM sales) total,1.0*p.n*(SELECT count(*) FROM sales)/(sa.n*sb.n) lift FROM pairs p JOIN single sa ON sa.product_id=p.a JOIN single sb ON sb.product_id=p.b),
r AS(SELECT *,row_number() OVER(ORDER BY lift DESC,n DESC,a,b) rank FROM x)
SELECT a product_a,b product_b,na orders_a,nb orders_b,n shared_orders,round(100.0*n/total,2) support_pct,round(100.0*n/na,2) confidence_a_to_b_pct,round(100.0*n/nb,2) confidence_b_to_a_pct,round(lift,4) lift,rank FROM r WHERE rank<=10 ORDER BY rank;

-- Q26: Customer value concentration
CREATE OR REPLACE VIEW q26 AS
WITH a AS(SELECT *,row_number() OVER(ORDER BY paid DESC,customer_id) rn,ceil(.2*count(*) OVER()) cutoff FROM customer_history),b AS(SELECT *,CASE WHEN rn<=cutoff THEN 'top_20pct' ELSE 'remaining' END group_name FROM a),
c AS(SELECT group_name,max(cutoff) selected_cutoff_count,count(*) customers,sum(orders) orders,sum(paid) paid_value,sum(revenue) net_revenue,sum(contribution) contribution FROM b GROUP BY group_name)
SELECT *,round(100*contribution/NULLIF(net_revenue,0),2) margin_pct,round(100*paid_value/NULLIF(sum(paid_value) OVER(),0),2) sales_share_pct,round(100*contribution/NULLIF(sum(contribution) OVER(),0),2) contribution_share_pct FROM c ORDER BY group_name;

-- Q27: Monthly exception monitor
CREATE OR REPLACE VIEW q27 AS
WITH b AS(SELECT *,avg(paid) OVER w baseline_sales,sum(paid) OVER w bp,sum(refunds) OVER w br,sum(eligible) OVER w be,sum(late) OVER w bl FROM monthly WINDOW w AS(ORDER BY month ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING)),
a AS(SELECT month,'paid_sales'::text metric_name,paid current_value,baseline_sales baseline_value,delivered_orders eligible_count,NULL::numeric baseline_count,baseline_sales>0 evaluable,paid<.8*baseline_sales hit FROM b WHERE month>=DATE '2025-04-01'
UNION ALL SELECT month,'refund_ratio_pct',100*refunds/NULLIF(paid,0),100*br/NULLIF(bp,0),delivered_orders,NULL,paid>0 AND bp>0,100*refunds/NULLIF(paid,0)-100*br/NULLIF(bp,0)>=5 FROM b WHERE month>=DATE '2025-04-01'
UNION ALL SELECT month,'late_rate_pct',100.0*late/NULLIF(eligible,0),100*bl/NULLIF(be,0),eligible,be,eligible>=5 AND be>=15,100.0*late/NULLIF(eligible,0)-100*bl/NULLIF(be,0)>=15 FROM b WHERE month>=DATE '2025-04-01')
SELECT month,metric_name,round(current_value,2) current_value,round(baseline_value,2) baseline_value,round(current_value-baseline_value,2) comparison_difference,eligible_count,baseline_count,
CASE WHEN evaluable THEN 'evaluated' ELSE 'not_evaluable' END evaluation_status,CASE WHEN evaluable THEN hit END alert_flag FROM a ORDER BY month,metric_name;

-- Q28: Regional growth and repeat mix
CREATE OR REPLACE VIEW q28 AS
WITH a AS(SELECT r.region,h.half,t.purchase_type,count(s.order_id) orders,count(DISTINCT s.customer_id) customers,coalesce(sum(s.paid),0) paid_merchandise_value,coalesce(sum(s.contribution),0) contribution
FROM(SELECT DISTINCT region FROM customers)r CROSS JOIN(VALUES('H1'),('H2'))h(half) CROSS JOIN(VALUES('first_time'),('returning'))t(purchase_type)
LEFT JOIN sequenced_sales s ON s.region=r.region AND s.half=h.half AND s.purchase_type=t.purchase_type GROUP BY r.region,h.half,t.purchase_type)
SELECT *,round(100.0*sum(orders) FILTER(WHERE purchase_type='returning') OVER w/NULLIF(sum(orders) OVER w,0),2) returning_order_share_pct,
round(100*sum(paid_merchandise_value) FILTER(WHERE purchase_type='returning') OVER w/NULLIF(sum(paid_merchandise_value) OVER w,0),2) returning_sales_share_pct FROM a WINDOW w AS(PARTITION BY region,half) ORDER BY region,half,purchase_type;
CREATE OR REPLACE VIEW q28_region_comparison AS
WITH a AS(SELECT region,half,sum(paid) sales,100*sum(paid) FILTER(WHERE purchase_type='returning')/NULLIF(sum(paid),0) share FROM sequenced_sales GROUP BY region,half) SELECT a.region,a.sales h1_sales,b.sales h2_sales,b.sales-a.sales absolute_sales_change,round(100*(b.sales-a.sales)/NULLIF(a.sales,0),2) sales_growth_pct,round(a.share,2) h1_returning_sales_share_pct,round(b.share,2) h2_returning_sales_share_pct,round(b.share-a.share,2) returning_share_change_pp FROM a JOIN a b ON b.region=a.region AND b.half='H2' WHERE a.half='H1' ORDER BY a.region;

-- Q29: Service recovery review queue
CREATE OR REPLACE VIEW q29 AS
WITH a AS(SELECT customer_id,count(*) affected_orders_q4,max(delivered_date-promised_delivery_date) max_late_days FROM sales WHERE order_date>=DATE '2025-10-01' AND order_date<DATE '2026-01-01' AND delivered_date-promised_delivery_date>3 GROUP BY customer_id),
b AS(SELECT a.*,h.orders annual_orders,h.contribution annual_contribution,CASE WHEN affected_orders_q4>=2 THEN 3 ELSE 0 END repeat_issue_points,CASE WHEN max_late_days>=7 THEN 2 ELSE 0 END severity_points,CASE WHEN h.contribution>0 THEN 2 ELSE 0 END value_points,CASE WHEN h.orders>=3 THEN 1 ELSE 0 END frequency_points FROM a JOIN customer_history h USING(customer_id)),
c AS(SELECT *,repeat_issue_points+severity_points+value_points+frequency_points total_score FROM b),d AS(SELECT *,row_number() OVER(ORDER BY total_score DESC,annual_contribution DESC,customer_id) priority_rank FROM c)
SELECT * FROM d WHERE priority_rank<=10 ORDER BY priority_rank;

-- Q30: Leadership action register
CREATE OR REPLACE VIEW q30 AS
WITH a AS(SELECT 'category_refunds'::text candidate_type,category entity_name,count(DISTINCT order_id) FILTER(WHERE refund_amount>0) affected_orders,sum(refund_amount) exposure_inr,'Product Quality / Category Manager'::text suggested_owner FROM allocated_lines GROUP BY category
UNION ALL SELECT 'warehouse_shipping_shortfall',warehouse,count(*) FILTER(WHERE shipping_cost>shipping_charged),sum(greatest(shipping_cost-shipping_charged,0)),'Logistics Finance' FROM sales GROUP BY warehouse
UNION ALL SELECT 'region_loss_orders',region,count(*) FILTER(WHERE contribution<0),-sum(contribution) FILTER(WHERE contribution<0),'Regional Commercial / Finance' FROM sales GROUP BY region),
b AS(SELECT *,row_number() OVER(ORDER BY exposure_inr DESC,candidate_type,entity_name) rank FROM a WHERE exposure_inr>0)
SELECT rank,candidate_type,entity_name,affected_orders,round(exposure_inr,2) exposure_inr,round(100*exposure_inr/NULLIF((SELECT sum(revenue) FROM sales),0),2) exposure_pct_of_company_net_revenue,suggested_owner FROM b WHERE rank<=5 ORDER BY rank;
CREATE OR REPLACE VIEW q30_source_trace AS
SELECT 'category_refunds' candidate_type,category entity_name,order_id,item_number,refund_amount exposure_inr FROM allocated_lines WHERE refund_amount>0 UNION ALL SELECT 'warehouse_shipping_shortfall',warehouse,order_id,NULL,greatest(shipping_cost-shipping_charged,0) FROM sales WHERE shipping_cost>shipping_charged UNION ALL SELECT 'region_loss_orders',region,order_id,NULL,-contribution FROM sales WHERE contribution<0 ORDER BY 1,2,3,4;
COMMIT;

-- Result sets (select a statement in pgAdmin to view one answer at a time).

-- Q01: Monthly business health
SELECT * FROM q01;

-- Q02: Order loss diagnosis
SELECT * FROM q02;
SELECT * FROM q02_worst_losses;

-- Q03: Monthly sales bridge
SELECT * FROM q03;

-- Q04: Category growth contribution
SELECT * FROM q04;

-- Q05: Rolling margin deterioration
SELECT * FROM q05;

-- Q06: Positive product concentration
SELECT * FROM q06;
SELECT * FROM q06_non_positive;

-- Q07: First-time versus returning
SELECT * FROM q07;

-- Q08: Observable cohort retention
SELECT * FROM q08;

-- Q09: First-to-second purchase conversion
SELECT * FROM q09;

-- Q10: Channel 90-day value
SELECT * FROM q10;

-- Q11: First-purchase entry category
SELECT * FROM q11;

-- Q12: Win-back audience
SELECT * FROM q12;

-- Q13: Mature discount-band economics
SELECT * FROM q13;

-- Q14: Category growth versus margin
SELECT * FROM q14;

-- Q15: Mechanical no-discount scenario
SELECT * FROM q15;

-- Q16: Mature product returns
SELECT * FROM q16;
SELECT * FROM q16_immature_exclusion;

-- Q17: Regional contribution bridge
SELECT * FROM q17;

-- Q18: Category-mix standardized regions
SELECT * FROM q18;
SELECT * FROM q18_common_weights;

-- Q19: Delivery reliability
SELECT * FROM q19;

-- Q20: Warehouse deterioration streak
SELECT * FROM q20;

-- Q21: First delivery and repeat purchasing
SELECT * FROM q21;
SELECT * FROM q21_missing_first_promises;

-- Q22: Shipping subsidy exposure
SELECT * FROM q22;
SELECT * FROM q22_annual_regions;

-- Q23: Conservative delivery promises
SELECT * FROM q23;

-- Q24: Cancellation exposure
SELECT * FROM q24;

-- Q25: Cross-sell product pairs
SELECT * FROM q25;

-- Q26: Customer value concentration
SELECT * FROM q26;

-- Q27: Monthly exception monitor
SELECT * FROM q27;

-- Q28: Regional growth and repeat mix
SELECT * FROM q28;
SELECT * FROM q28_region_comparison;

-- Q29: Service recovery review queue
SELECT * FROM q29;

-- Q30: Leadership action register
SELECT * FROM q30;
SELECT * FROM q30_source_trace;


-- Independent control checks. All checks should return passed=true.
SET search_path TO northstar_retail, public;
CREATE OR REPLACE VIEW validation_results AS
WITH checks AS (
SELECT 'SETUP' question,'650 rows, expected statuses and coverage' check_name,
 (SELECT count(*) FROM customers)=60 AND (SELECT count(*) FROM orders)=210 AND (SELECT count(*) FROM order_items)=380
 AND (SELECT count(*) FROM orders WHERE status='delivered')=196 AND (SELECT count(*) FROM orders WHERE status='cancelled')=13
 AND (SELECT count(*) FROM orders WHERE status='in_transit')=1
 AND (SELECT min(order_date) FROM orders)=DATE '2025-01-01' AND (SELECT max(order_date) FROM orders)=DATE '2025-12-25'
 AND (SELECT count(DISTINCT date_trunc('month',order_date)) FROM orders)=12 AS passed
UNION ALL SELECT 'SETUP','No orphan/missing lines, signup errors or non-delivered returns',
 NOT EXISTS(SELECT 1 FROM orders o WHERE NOT EXISTS(SELECT 1 FROM order_items i WHERE i.order_id=o.order_id))
 AND (SELECT count(*) FROM customers c WHERE NOT EXISTS(SELECT 1 FROM orders o WHERE o.customer_id=c.customer_id))=6
 AND NOT EXISTS(SELECT 1 FROM orders o JOIN customers c USING(customer_id) WHERE signup_date>order_date)
 AND NOT EXISTS(SELECT 1 FROM order_items i JOIN orders o USING(order_id) WHERE status<>'delivered' AND (returned_quantity>0 OR refund_amount>0))
UNION ALL SELECT 'Q01','Status counts and independently computed annual contribution',
 NOT EXISTS(SELECT 1 FROM q01 WHERE placed_orders<>delivered_orders+cancelled_orders+in_transit_orders)
 AND (SELECT sum(contribution) FROM q01)=
 (SELECT sum(i.quantity*i.unit_price-i.discount_amount-i.refund_amount-i.quantity*i.unit_cost) FROM order_items i JOIN orders o USING(order_id) WHERE o.status='delivered')
 +(SELECT sum(shipping_charged-shipping_cost) FROM orders WHERE status='delivered')
UNION ALL SELECT 'Q02','Each delivered order reconciles; 10 worst losses correctly ordered',
 (SELECT count(*) FROM q02)=196 AND NOT EXISTS(SELECT 1 FROM q02 WHERE net_revenue-product_cost-shipping_cost<>contribution)
 AND NOT EXISTS(SELECT 1 FROM q02 WHERE loss_flag<>(contribution<0) OR (NOT loss_flag AND loss_rank IS NOT NULL))
 AND (SELECT count(*) FROM q02_worst_losses)=least(10,(SELECT count(*) FROM sales WHERE contribution<0))
UNION ALL SELECT 'Q03','Unrounded volume plus basket bridge reconciles',
 NOT EXISTS(WITH a AS(SELECT *,paid/NULLIF(delivered_orders,0) av FROM monthly),b AS(SELECT *,lag(paid) OVER w p,lag(delivered_orders) OVER w n,lag(av) OVER w a FROM a WINDOW w AS(ORDER BY month))
 SELECT 1 FROM b WHERE month>DATE '2025-01-01' AND abs((delivered_orders-n)*a+delivered_orders*(av-a)-(paid-p))>.00000001)
UNION ALL SELECT 'Q04','Category half-year totals and changes reconcile',
 (SELECT sum(h1_sales) FROM q04)=(SELECT sum(paid) FROM sales WHERE half='H1') AND (SELECT sum(h2_sales) FROM q04)=(SELECT sum(paid) FROM sales WHERE half='H2')
 AND (SELECT sum(absolute_change) FROM q04)=(SELECT sum(paid) FILTER(WHERE half='H2')-sum(paid) FILTER(WHERE half='H1') FROM sales)
UNION ALL SELECT 'Q05','March window is precisely Jan-Mar; early windows unavailable',
 (SELECT rolling_3m_revenue FROM q05 WHERE month=DATE '2025-03-01')=(SELECT sum(revenue) FROM sales WHERE order_date>=DATE '2025-01-01' AND order_date<DATE '2025-04-01')
 AND (SELECT rolling_3m_contribution FROM q05 WHERE month=DATE '2025-03-01')=(SELECT sum(contribution) FROM sales WHERE order_date<DATE '2025-04-01')
 AND NOT EXISTS(SELECT 1 FROM q05 WHERE month<DATE '2025-03-01' AND rolling_margin_pct IS NOT NULL)
UNION ALL SELECT 'Q06','All allocated contributions reconcile and 80% prefix is minimal',
 abs((SELECT sum(contribution) FROM allocated_lines)-(SELECT sum(contribution) FROM sales))<.000001
 AND (SELECT max(cumulative_share_pct) FROM q06 WHERE in_80pct_group)>=80
 AND (SELECT max(cumulative_share_pct) FROM q06 WHERE rank<(SELECT max(rank) FROM q06 WHERE in_80pct_group))<80
UNION ALL SELECT 'Q07','Two segments per month reconcile orders and sales',
 (SELECT count(*) FROM q07)=24 AND NOT EXISTS(SELECT m.month FROM monthly m JOIN q07 q ON q.purchase_month=m.month GROUP BY m.month,m.delivered_orders,m.paid HAVING sum(q.orders)<>m.delivered_orders OR sum(q.paid_merchandise_value)<>m.paid)
UNION ALL SELECT 'Q08','Cohort bounds, month zero and unobserved cells',
 NOT EXISTS(SELECT 1 FROM q08 WHERE active_customers>cohort_size OR (month_index=0 AND active_customers<>cohort_size) OR (NOT observable_flag AND (active_customers IS NOT NULL OR retention_pct IS NOT NULL)))
 AND (SELECT count(*) FROM q08)=6*(SELECT count(DISTINCT date_trunc('month',first_date)) FROM customer_history)
UNION ALL SELECT 'Q09','Converters bounded and strict 90-day eligibility',
 NOT EXISTS(SELECT 1 FROM q09 WHERE converters_30>eligible_30 OR converters_60>eligible_60 OR converters_90>eligible_90)
 AND (SELECT sum(eligible_90) FROM q09)=(SELECT count(*) FROM customer_history WHERE first_date+90<DATE '2026-01-01')
 AND DATE '2025-10-02'+90=DATE '2025-12-31' AND DATE '2025-10-03'+90=DATE '2026-01-01'
UNION ALL SELECT 'Q10','Windows include first order and exclude day 91',
 NOT EXISTS(SELECT 1 FROM customer_90 h WHERE window_orders<>(SELECT count(*) FROM sales s WHERE s.customer_id=h.customer_id AND s.order_date>=h.first_date AND s.order_date<h.first_date+91) OR NOT EXISTS(SELECT 1 FROM sales s WHERE s.order_id=h.first_order_id AND s.order_date=h.first_date))
 AND (SELECT sum(eligible_customers) FROM q10)=(SELECT count(*) FROM customer_90)
UNION ALL SELECT 'Q11','Entry-category assignment has one customer per eligible cohort member',
 (SELECT sum(eligible_customers) FROM q11)=(SELECT count(*) FROM customer_90)
UNION ALL SELECT 'Q12','All audience conditions and capacity hold',
 NOT EXISTS(SELECT 1 FROM q12 WHERE qualifying_orders<2 OR lifetime_contribution<=0 OR recency_days<60 OR latest_order_status='in_transit') AND (SELECT count(*) FROM q12)<=10
UNION ALL SELECT 'Q13','Mature population partition and returned-unit bounds',
 (SELECT sum(orders) FROM q13)=(SELECT count(*) FROM sales WHERE delivered_date<=DATE '2025-12-01')
 AND NOT EXISTS(SELECT 1 FROM q13 WHERE returned_units>purchased_units) AND (SELECT count(*) FROM q13)=4
UNION ALL SELECT 'Q14','Category allocations reconcile in each half without rounding',
 NOT EXISTS(SELECT half FROM allocated_lines GROUP BY half HAVING abs(sum(contribution)-(SELECT sum(s.contribution) FROM sales s WHERE s.half=allocated_lines.half))>.000001)
UNION ALL SELECT 'Q15','Line scenario lift equals retained-unit discount',
 NOT EXISTS(SELECT 1 FROM allocated_lines WHERE abs(((quantity-returned_quantity)*unit_price-net)-discount_amount*(quantity-returned_quantity)/quantity)>.005)
 AND abs((SELECT sum(mechanical_contribution_lift) FROM q15)-(SELECT sum(discount_amount*(quantity-returned_quantity)/quantity) FROM allocated_lines))<.02
UNION ALL SELECT 'Q16','Units versus lines and mature/immature partition',
 100.0*1/2=50 AND EXISTS(SELECT 1 FROM allocated_lines WHERE quantity=2 AND returned_quantity=1)
 AND NOT EXISTS(SELECT 1 FROM q16 WHERE returned_units>purchased_units OR (purchased_units<8 AND quality_rank IS NOT NULL))
 AND (SELECT sum(purchased_units) FROM q16)+(SELECT purchased_units FROM q16_immature_exclusion)=(SELECT sum(units) FROM sales)
UNION ALL SELECT 'Q17','Regional bridge exactly reconciles',
 NOT EXISTS(SELECT 1 FROM q17 WHERE gross_value-discounts-refunds-product_cost+shipping_charged-shipping_cost<>contribution)
UNION ALL SELECT 'Q18','Common weights total one and regional contributions reconcile',
 abs((SELECT sum(weight) FROM(SELECT sum(revenue)/(SELECT sum(revenue) FROM allocated_lines) weight FROM allocated_lines GROUP BY category)a)-1)<.000001
 AND abs((SELECT sum(contribution) FROM allocated_lines)-(SELECT sum(contribution) FROM sales))<.000001
UNION ALL SELECT 'Q19','Eligible late/on-time partition and missing promises',
 NOT EXISTS(SELECT 1 FROM q19 WHERE delivered_orders<>missing_promises+eligible_orders)
 AND (SELECT sum(eligible_orders-late_orders) FROM q19)=(SELECT count(*) FROM sales WHERE delivered_date<=promised_delivery_date)
UNION ALL SELECT 'Q20','April baseline uses Jan-Mar pooled eligible counts',
 NOT EXISTS(SELECT 1 FROM q20 q WHERE month=DATE '2025-04-01' AND baseline_eligible_orders<>(SELECT count(promised_delivery_date) FROM sales s WHERE s.warehouse=q.warehouse AND order_date>=DATE '2025-01-01' AND order_date<DATE '2025-04-01'))
 AND NOT EXISTS(SELECT 1 FROM q20 WHERE month<DATE '2025-04-01' AND warning_flag)
UNION ALL SELECT 'Q21','Mature first-promise inclusion/exclusion partitions customers',
 (SELECT sum(eligible_customers) FROM q21)+(SELECT excluded_mature_customers FROM q21_missing_first_promises)=(SELECT count(*) FROM customer_90)
 AND NOT EXISTS(SELECT 1 FROM q21 WHERE converters_90d>eligible_customers)
UNION ALL SELECT 'Q22','Four quarters reconcile to order shipping totals',
 (SELECT count(*) FROM q22)=12 AND (SELECT sum(charged) FROM q22)=(SELECT sum(shipping_charged) FROM sales)
 AND (SELECT sum(cost) FROM q22)=(SELECT sum(shipping_cost) FROM sales)
 AND (SELECT sum(subsidy) FROM q22_annual_regions)=(SELECT sum(shipping_cost-shipping_charged) FROM sales)
UNION ALL SELECT 'Q23','Signed buffer directions and complete promise population',
 NOT EXISTS(SELECT 1 FROM sales WHERE promised_delivery_date IS NOT NULL AND ((delivered_date>promised_delivery_date)<>(promised_delivery_date-delivered_date<0)))
 AND (SELECT sum(eligible_orders) FROM q23)=(SELECT count(promised_delivery_date) FROM sales)
UNION ALL SELECT 'Q24','Cancellations reconcile to 13 without altering delivered population',
 (SELECT sum(cancelled_orders) FROM q24)=13 AND (SELECT sum(placed_orders) FROM q24)=210 AND (SELECT count(*) FROM sales)=196
UNION ALL SELECT 'Q25','Unordered unique pairs and independently counted shared baskets',
 NOT EXISTS(SELECT 1 FROM q25 WHERE product_a>=product_b OR shared_orders<3 OR shared_orders<>(SELECT count(*) FROM sales s WHERE EXISTS(SELECT 1 FROM order_items i WHERE i.order_id=s.order_id AND i.product_id=q25.product_a) AND EXISTS(SELECT 1 FROM order_items i WHERE i.order_id=s.order_id AND i.product_id=q25.product_b)))
 AND (SELECT count(*) FROM q25)=(SELECT count(DISTINCT(product_a,product_b)) FROM q25)
UNION ALL SELECT 'Q26','Purchaser groups and monetary totals reconcile',
 (SELECT sum(customers) FROM q26)=(SELECT count(*) FROM customer_history) AND (SELECT customers FROM q26 WHERE group_name='top_20pct')=ceil(.2*(SELECT count(*) FROM customer_history))
 AND (SELECT sum(contribution) FROM q26)=(SELECT sum(contribution) FROM sales) AND (SELECT sum(paid_value) FROM q26)=(SELECT sum(paid) FROM sales)
UNION ALL SELECT 'Q27','All 27 observations; April baselines exclude current month',
 (SELECT count(*) FROM q27)=27 AND (SELECT baseline_value FROM q27 WHERE month=DATE '2025-04-01' AND metric_name='paid_sales')=(SELECT round(avg(paid),2) FROM monthly WHERE month<DATE '2025-04-01')
 AND (SELECT baseline_value FROM q27 WHERE month=DATE '2025-04-01' AND metric_name='refund_ratio_pct')=(SELECT round(100*sum(refunds)/sum(paid),2) FROM sales WHERE order_date<DATE '2025-04-01')
UNION ALL SELECT 'Q28','Annual type totals reconcile to monthly segmentation',
 NOT EXISTS(SELECT purchase_type FROM q28 GROUP BY purchase_type HAVING sum(paid_merchandise_value)<>(SELECT sum(q.paid_merchandise_value) FROM q07 q WHERE q.purchase_type=q28.purchase_type) OR sum(orders)<>(SELECT sum(q.orders) FROM q07 q WHERE q.purchase_type=q28.purchase_type))
UNION ALL SELECT 'Q29','Scores recalculate and all queued customers have Q4 delay',
 NOT EXISTS(SELECT 1 FROM q29 WHERE total_score<>(CASE WHEN affected_orders_q4>=2 THEN 3 ELSE 0 END+CASE WHEN max_late_days>=7 THEN 2 ELSE 0 END+CASE WHEN annual_contribution>0 THEN 2 ELSE 0 END+CASE WHEN annual_orders>=3 THEN 1 ELSE 0 END) OR NOT EXISTS(SELECT 1 FROM sales s WHERE s.customer_id=q29.customer_id AND order_date>=DATE '2025-10-01' AND order_date<DATE '2026-01-01' AND delivered_date-promised_delivery_date>3))
UNION ALL SELECT 'Q30','Action exposures and affected orders trace to source records',
 NOT EXISTS(SELECT 1 FROM q30 q WHERE exposure_inr<>(SELECT round(sum(exposure_inr),2) FROM q30_source_trace t WHERE t.candidate_type=q.candidate_type AND t.entity_name=q.entity_name) OR affected_orders<>(SELECT count(DISTINCT order_id) FROM q30_source_trace t WHERE t.candidate_type=q.candidate_type AND t.entity_name=q.entity_name))
)
SELECT * FROM checks ORDER BY question,check_name;
SELECT * FROM validation_results;
DO $$ BEGIN IF EXISTS(SELECT 1 FROM validation_results WHERE passed IS DISTINCT FROM true) THEN RAISE EXCEPTION 'Validation failed: inspect validation_results'; END IF; END $$;
