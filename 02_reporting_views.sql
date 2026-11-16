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
