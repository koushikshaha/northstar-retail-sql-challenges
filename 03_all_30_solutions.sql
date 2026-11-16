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
