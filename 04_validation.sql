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
