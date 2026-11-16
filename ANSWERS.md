# Northstar Retail — 30 solved challenges

Executed against PostgreSQL 18.4 with the supplied 650-row synthetic dataset. Purchase period: 2025; exclusive observation cutoff: 2026-01-01. Currency: INR. All 32 validation checks passed.

Each section includes the complete query, a result preview, a link to the complete CSV, interpretation, and its validation check. The shared views in `02_reporting_views.sql` are required; every query is also saved as `northstar_retail.q01` through `q30`. CSVs contain the complete results, including rows not displayed in the preview.

## Q01. Monthly business health

December has the lowest monthly contribution margin, 18.67%, despite 22 placed orders; only 19 were delivered. August has the highest cancellation rate, 16.67% (3 of 18). These are distinct margin and fulfillment issues, and placed-order volume alone does not establish better commercial performance.

### Query

```sql
SET search_path TO northstar_retail, public;
SELECT month purchase_month,placed_orders,delivered_orders,cancelled_orders,in_transit_orders,purchasing_customers,
paid paid_merchandise_value,round(paid/NULLIF(delivered_orders,0),2) aov,net net_merchandise_value,
charged shipping_charged,shipping_cost,contribution,round(100*contribution/NULLIF(revenue,0),2) margin_pct,
round(100.0*cancelled_orders/NULLIF(placed_orders,0),2) cancellation_rate_pct FROM monthly ORDER BY month;
```

### Result

[Complete result: 12 rows](results/q01.csv). Preview:

| purchase_month | placed_orders | delivered_orders | cancelled_orders | in_transit_orders | purchasing_customers | paid_merchandise_value | aov | net_merchandise_value | shipping_charged | shipping_cost | contribution | margin_pct | cancellation_rate_pct |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 2025-01-01 | 14 | 13 | 1 | 0 | 8 | 25987.5 | 1999.04 | 22972.5 | 490 | 965 | 7657.5 | 32.64 | 7.14 |
| 2025-02-01 | 14 | 13 | 1 | 0 | 10 | 27750 | 2134.62 | 26985 | 441 | 1020 | 9856 | 35.94 | 7.14 |
| 2025-03-01 | 16 | 14 | 2 | 0 | 11 | 32947.5 | 2353.39 | 28835 | 539 | 1075 | 6019 | 20.49 | 12.5 |
| 2025-04-01 | 16 | 16 | 0 | 0 | 11 | 27955 | 1747.19 | 22807.5 | 588 | 1305 | 6180.5 | 26.42 | 0 |
| 2025-05-01 | 17 | 15 | 2 | 0 | 12 | 33542.5 | 2236.17 | 29942.5 | 588 | 1115 | 9665.5 | 31.66 | 11.76 |
| 2025-06-01 | 17 | 16 | 1 | 0 | 11 | 33450 | 2090.63 | 28375 | 637 | 1155 | 8287 | 28.56 | 5.88 |

### Validation

Passed. The check and its independent arithmetic are in [04_validation.sql](04_validation.sql); view the saved [validation results](results/validation.csv).

```sql
SELECT * FROM northstar_retail.validation_results WHERE question='Q01';
```

## Q02. Order loss diagnosis

Order 1035 is the worst loss at INR 2,173.50 below zero, with INR 2,520 of refunds. A high checkout value is not necessarily a valuable order: order 1075 has INR 5,650 gross value but loses INR 1,361. The labels identify the largest recorded deduction, not a proven operational cause.

### Query

```sql
SET search_path TO northstar_retail, public;
WITH a AS (SELECT *,CASE WHEN contribution<0 THEN row_number() OVER(PARTITION BY contribution<0 ORDER BY contribution,order_id) END loss_rank FROM sales)
SELECT order_id,gross gross_merchandise_value,discounts,refunds,cost product_cost,shipping_charged,shipping_cost,
 revenue net_revenue,contribution,round(100*contribution/NULLIF(revenue,0),2) margin_pct,contribution<0 loss_flag,
 CASE WHEN greatest(refunds,discounts,greatest(shipping_cost-shipping_charged,0))=0 THEN 'base_cost'
 WHEN refunds>=discounts AND refunds>=greatest(shipping_cost-shipping_charged,0) THEN 'refund'
 WHEN discounts>=greatest(shipping_cost-shipping_charged,0) THEN 'discount' ELSE 'shipping' END diagnosis_label,loss_rank
FROM a ORDER BY order_id;
```

### Result

[Complete result: 196 rows](results/q02.csv). Preview:

| order_id | gross_merchandise_value | discounts | refunds | product_cost | shipping_charged | shipping_cost | net_revenue | contribution | margin_pct | loss_flag | diagnosis_label | loss_rank |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1001 | 1650 | 0 | 550 | 880 | 49 | 75 | 1149 | 194 | 16.88 | false | refund | NULL |
| 1002 | 1000 | 100 | 0 | 530 | 49 | 75 | 949 | 344 | 36.25 | false | discount | NULL |
| 1003 | 3100 | 0 | 0 | 1920 | 49 | 60 | 3149 | 1169 | 37.12 | false | shipping | NULL |
| 1004 | 2950 | 267.5 | 0 | 1510 | 0 | 45 | 2682.5 | 1127.5 | 42.03 | false | discount | NULL |
| 1005 | 2050 | 180 | 0 | 1250 | 49 | 130 | 1919 | 539 | 28.09 | false | discount | NULL |
| 1006 | 3600 | 180 | 0 | 2110 | 49 | 115 | 3469 | 1244 | 35.86 | false | discount | NULL |

**worst losses:** [Complete CSV](results/q02_worst_losses.csv)

```sql
SELECT * FROM q02 WHERE loss_flag ORDER BY loss_rank LIMIT 10;
```

| order_id | gross_merchandise_value | discounts | refunds | product_cost | shipping_charged | shipping_cost | net_revenue | contribution | margin_pct | loss_flag | diagnosis_label | loss_rank |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1035 | 3850 | 1092.5 | 2520 | 2400 | 49 | 60 | 286.5 | -2173.5 | -758.64 | true | refund | 1 |
| 1203 | 2800 | 770 | 2030 | 1670 | 49 | 85 | 49 | -1706 | -3481.63 | true | refund | 2 |
| 1081 | 2750 | 125 | 2625 | 1600 | 49 | 90 | 49 | -1641 | -3348.98 | true | refund | 3 |
| 1075 | 5650 | 25 | 3600 | 3360 | 49 | 75 | 2074 | -1361 | -65.62 | true | refund | 4 |
| 1195 | 2050 | 410 | 1440 | 1250 | 49 | 60 | 249 | -1061 | -426.1 | true | refund | 5 |

### Validation

Passed. The check and its independent arithmetic are in [04_validation.sql](04_validation.sql); view the saved [validation results](results/validation.csv).

```sql
SELECT * FROM northstar_retail.validation_results WHERE question='Q02';
```

## Q03. Monthly sales bridge

September sales rose INR 13,825: INR 9,428 came from the order-volume effect and INR 4,397 from the basket effect. In November, the positive INR 2,334.21 volume effect was overwhelmed by the negative INR 12,766.71 basket effect, leaving sales down INR 10,432.50. Components use unrounded AOV internally, so displayed cents can differ by one paisa when independently rounded.

### Query

```sql
SET search_path TO northstar_retail, public;
WITH a AS(SELECT *,paid/NULLIF(delivered_orders,0) aov FROM monthly),b AS(SELECT *,lag(paid) OVER w prior_sales,lag(delivered_orders) OVER w prior_n,lag(aov) OVER w prior_a FROM a WINDOW w AS(ORDER BY month))
SELECT month,delivered_orders,round(aov,2) aov,paid paid_merchandise_value,prior_n prior_orders,round(prior_a,2) prior_aov,prior_sales,paid-prior_sales sales_change,
round((delivered_orders-prior_n)*prior_a,2) volume_effect,round(delivered_orders*(aov-prior_a),2) basket_effect,
round(100*(paid-prior_sales)/NULLIF(prior_sales,0),2) growth_pct FROM b ORDER BY month;
```

### Result

[Complete result: 12 rows](results/q03.csv). Preview:

| month | delivered_orders | aov | paid_merchandise_value | prior_orders | prior_aov | prior_sales | sales_change | volume_effect | basket_effect | growth_pct |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 2025-01-01 | 13 | 1999.04 | 25987.5 | NULL | NULL | NULL | NULL | NULL | NULL | NULL |
| 2025-02-01 | 13 | 2134.62 | 27750 | 13 | 1999.04 | 25987.5 | 1762.5 | 0 | 1762.5 | 6.78 |
| 2025-03-01 | 14 | 2353.39 | 32947.5 | 13 | 2134.62 | 27750 | 5197.5 | 2134.62 | 3062.88 | 18.73 |
| 2025-04-01 | 16 | 1747.19 | 27955 | 14 | 2353.39 | 32947.5 | -4992.5 | 4706.79 | -9699.29 | -15.15 |
| 2025-05-01 | 15 | 2236.17 | 33542.5 | 16 | 1747.19 | 27955 | 5587.5 | -1747.19 | 7334.69 | 19.99 |
| 2025-06-01 | 16 | 2090.63 | 33450 | 15 | 2236.17 | 33542.5 | -92.5 | 2236.17 | -2328.67 | -0.28 |

### Validation

Passed. The check and its independent arithmetic are in [04_validation.sql](04_validation.sql); view the saved [validation results](results/validation.csv).

```sql
SELECT * FROM northstar_retail.validation_results WHERE question='Q03';
```

## Q04. Category growth contribution

Electronics supplied the largest absolute H2 growth, INR 21,202.50, or 54.33% of company growth. Fitness grew faster in percentage terms, 33.67% versus Electronics at 31.15%. Home declined INR 2,592.50 and therefore contributes a valid negative 6.64% to the signed company change.

### Query

```sql
SET search_path TO northstar_retail, public;
WITH a AS(SELECT category,coalesce(sum(paid) FILTER(WHERE half='H1'),0) h1,coalesce(sum(paid) FILTER(WHERE half='H2'),0) h2 FROM allocated_lines GROUP BY category),
b AS(SELECT *,sum(h1) OVER() t1,sum(h2) OVER() t2 FROM a)
SELECT category,h1 h1_sales,h2 h2_sales,h2-h1 absolute_change,round(100*(h2-h1)/NULLIF(h1,0),2) growth_pct,
round(100*h1/NULLIF(t1,0),2) h1_share_pct,round(100*h2/NULLIF(t2,0),2) h2_share_pct,
round(100*(h2/NULLIF(t2,0)-h1/NULLIF(t1,0)),2) share_change_pp,round(100*(h2-h1)/NULLIF(t2-t1,0),2) contribution_to_company_change_pct,
row_number() OVER(ORDER BY h2-h1 DESC,category) rank FROM b ORDER BY rank;
```

### Result

[Complete result: 4 rows](results/q04.csv). Preview:

| category | h1_sales | h2_sales | absolute_change | growth_pct | h1_share_pct | h2_share_pct | share_change_pp | contribution_to_company_change_pct | rank |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Electronics | 68055 | 89257.5 | 21202.5 | 31.15 | 37.47 | 40.45 | 2.98 | 54.33 | 1 |
| Fitness | 50710 | 67782.5 | 17072.5 | 33.67 | 27.92 | 30.72 | 2.8 | 43.74 | 2 |
| Accessories | 28500 | 31845 | 3345 | 11.74 | 15.69 | 14.43 | -1.26 | 8.57 | 3 |
| Home | 34367.5 | 31775 | -2592.5 | -7.54 | 18.92 | 14.4 | -4.52 | -6.64 | 4 |

### Validation

Passed. The check and its independent arithmetic are in [04_validation.sql](04_validation.sql); view the saved [validation results](results/validation.csv).

```sql
SELECT * FROM northstar_retail.validation_results WHERE question='Q04';
```

## Q05. Rolling margin deterioration

No month meets the five-percentage-point rolling deterioration threshold. December's three-month margin is 29.08%, down 2.87 points, so its low standalone margin does not create a rolling alert. Weighting by revenue gives larger months more influence; an average of monthly percentages would incorrectly weight all months equally.

### Query

```sql
SET search_path TO northstar_retail, public;
WITH a AS(SELECT *,CASE WHEN month>=DATE '2025-03-01' THEN sum(revenue) OVER w END r,CASE WHEN month>=DATE '2025-03-01' THEN sum(contribution) OVER w END c FROM monthly WINDOW w AS(ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)),
b AS(SELECT *,100*c/NULLIF(r,0) margin FROM a),d AS(SELECT *,margin-lag(margin) OVER(ORDER BY month) change FROM b),
e AS(SELECT *,coalesce(change<=-5,false) flag FROM d),f AS(SELECT *,sum((NOT flag)::int) OVER(ORDER BY month) grp FROM e)
SELECT month,revenue net_revenue,contribution,r rolling_3m_revenue,c rolling_3m_contribution,round(margin,2) rolling_margin_pct,round(change,2) change_pp,flag deterioration_flag,
CASE WHEN flag THEN count(*) FILTER(WHERE flag) OVER(PARTITION BY grp ORDER BY month) ELSE 0 END streak_length FROM f ORDER BY month;
```

### Result

[Complete result: 12 rows](results/q05.csv). Preview:

| month | net_revenue | contribution | rolling_3m_revenue | rolling_3m_contribution | rolling_margin_pct | change_pp | deterioration_flag | streak_length |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 2025-01-01 | 23462.5 | 7657.5 | NULL | NULL | NULL | NULL | false | 0 |
| 2025-02-01 | 27426 | 9856 | NULL | NULL | NULL | NULL | false | 0 |
| 2025-03-01 | 29374 | 6019 | 80262.5 | 23532.5 | 29.32 | NULL | false | 0 |
| 2025-04-01 | 23395.5 | 6180.5 | 80195.5 | 22055.5 | 27.5 | -1.82 | false | 0 |
| 2025-05-01 | 30530.5 | 9665.5 | 83300 | 21865 | 26.25 | -1.25 | false | 0 |
| 2025-06-01 | 29012 | 8287 | 82938 | 24133 | 29.1 | 2.85 | false | 0 |

### Validation

Passed. The check and its independent arithmetic are in [04_validation.sql](04_validation.sql); view the saved [validation results](results/validation.csv).

```sql
SELECT * FROM northstar_retail.validation_results WHERE question='Q05';
```

## Q06. Positive product concentration

Eleven of the 18 positive-contribution products are needed to reach 80%; that prefix supplies 83.77%. Yoga Mat alone contributes INR 23,448.97, or 21.40% of the positive pool. There are no zero/negative annual product totals, so the positive pool equals company contribution here even though individual orders lose contribution.

### Query

```sql
SET search_path TO northstar_retail, public;
WITH a AS(SELECT product_id,min(product_name) product_name,sum(contribution) contribution FROM allocated_lines GROUP BY product_id HAVING sum(contribution)>0),
b AS(SELECT *,row_number() OVER w rank,sum(contribution) OVER w running,sum(contribution) OVER() pool FROM a WINDOW w AS(ORDER BY contribution DESC,product_id))
SELECT product_id,product_name,round(contribution,2) contribution,rank,round(100*contribution/pool,2) share_pct,round(100*running/pool,2) cumulative_share_pct,running-contribution<.8*pool in_80pct_group FROM b ORDER BY rank;
```

### Result

[Complete result: 18 rows](results/q06.csv). Preview:

| product_id | product_name | contribution | rank | share_pct | cumulative_share_pct | in_80pct_group |
| --- | --- | --- | --- | --- | --- | --- |
| 7 | Yoga Mat | 23448.97 | 1 | 21.4 | 21.4 | true |
| 13 | Bluetooth Keyboard | 11827.79 | 2 | 10.8 | 32.2 | true |
| 8 | Resistance Bands | 9852.42 | 3 | 8.99 | 41.19 | true |
| 2 | Portable Speaker | 8756.79 | 4 | 7.99 | 49.19 | true |
| 10 | Laptop Sleeve | 7917.69 | 5 | 7.23 | 56.41 | true |
| 17 | Food Container Set | 6459 | 6 | 5.9 | 62.31 | true |

**non positive:** [Complete CSV](results/q06_non_positive.csv)

```sql
SELECT count(*) products,round(coalesce(sum(c),0),2) combined_contribution FROM(SELECT product_id,sum(contribution)c FROM allocated_lines GROUP BY product_id HAVING sum(contribution)<=0)a;
```

| products | combined_contribution |
| --- | --- |
| 0 | 0 |

### Validation

Passed. The check and its independent arithmetic are in [04_validation.sql](04_validation.sql); view the saved [validation results](results/validation.csv).

```sql
SELECT * FROM northstar_retail.validation_results WHERE question='Q06';
```

## Q07. First-time versus returning

Returning purchases rise from 33.71% of January paid sales to 82.76% of December paid sales. In December they generate INR 3,694 of the INR 5,176 contribution, about 71.37%, below their sales share. Customers may appear in both monthly segments because classification is by order, not a permanent customer label.

### Query

```sql
SET search_path TO northstar_retail, public;
SELECT m.month purchase_month,t.purchase_type,count(s.order_id) orders,count(DISTINCT s.customer_id) customers,
coalesce(sum(s.paid),0) paid_merchandise_value,coalesce(sum(s.contribution),0) contribution,
round(100*coalesce(sum(s.paid),0)/NULLIF(m.paid,0),2) monthly_sales_share_pct
FROM monthly m CROSS JOIN(VALUES('first_time'),('returning'))t(purchase_type)
LEFT JOIN sequenced_sales s ON s.month=m.month AND s.purchase_type=t.purchase_type GROUP BY m.month,t.purchase_type,m.paid ORDER BY 1,2;
```

### Result

[Complete result: 24 rows](results/q07.csv). Preview:

| purchase_month | purchase_type | orders | customers | paid_merchandise_value | contribution | monthly_sales_share_pct |
| --- | --- | --- | --- | --- | --- | --- |
| 2025-01-01 | first_time | 8 | 8 | 17227.5 | 5511.5 | 66.29 |
| 2025-01-01 | returning | 5 | 4 | 8760 | 2146 | 33.71 |
| 2025-02-01 | first_time | 6 | 6 | 12325 | 4261 | 44.41 |
| 2025-02-01 | returning | 7 | 7 | 15425 | 5595 | 55.59 |
| 2025-03-01 | first_time | 5 | 5 | 14497.5 | 4758.5 | 44 |
| 2025-03-01 | returning | 9 | 8 | 18450 | 1260.5 | 56 |

### Validation

Passed. The check and its independent arithmetic are in [04_validation.sql](04_validation.sql); view the saved [validation results](results/validation.csv).

```sql
SELECT * FROM northstar_retail.validation_results WHERE question='Q07';
```

## Q08. Observable cohort retention

At the shared month-1 horizon, January retains 4 of 8 customers (50%) and February retains 2 of 6 (33.33%). These small cohorts support descriptive comparisons, not confident claims about structural improvement. A blank future cell is unobserved; an observed zero means the entire activity month passed without a qualifying purchase.

### Query

```sql
SET search_path TO northstar_retail, public;
WITH h AS(SELECT *,date_trunc('month',first_date)::date cohort FROM customer_history),
a AS(SELECT cohort,count(*) size FROM h GROUP BY cohort),b AS(SELECT a.*,n month_index,(cohort+n*INTERVAL '1 month')::date activity_month FROM a CROSS JOIN generate_series(0,5)n),
c AS(SELECT b.*,activity_month+INTERVAL '1 month'<=DATE '2026-01-01' observable,count(DISTINCT s.customer_id) active FROM b JOIN h USING(cohort)
LEFT JOIN sales s ON s.customer_id=h.customer_id AND s.month=b.activity_month GROUP BY b.cohort,b.size,b.month_index,b.activity_month)
SELECT cohort cohort_month,size cohort_size,month_index,activity_month,observable observable_flag,CASE WHEN observable THEN active END active_customers,
CASE WHEN observable THEN round(100.0*active/size,2) END retention_pct FROM c ORDER BY cohort,month_index;
```

### Result

[Complete result: 72 rows](results/q08.csv). Preview:

| cohort_month | cohort_size | month_index | activity_month | observable_flag | active_customers | retention_pct |
| --- | --- | --- | --- | --- | --- | --- |
| 2025-01-01 | 8 | 0 | 2025-01-01 | true | 8 | 100 |
| 2025-01-01 | 8 | 1 | 2025-02-01 | true | 4 | 50 |
| 2025-01-01 | 8 | 2 | 2025-03-01 | true | 4 | 50 |
| 2025-01-01 | 8 | 3 | 2025-04-01 | true | 3 | 37.5 |
| 2025-01-01 | 8 | 4 | 2025-05-01 | true | 3 | 37.5 |
| 2025-01-01 | 8 | 5 | 2025-06-01 | true | 2 | 25 |

### Validation

Passed. The check and its independent arithmetic are in [04_validation.sql](04_validation.sql); view the saved [validation results](results/validation.csv).

```sql
SELECT * FROM northstar_retail.validation_results WHERE question='Q08';
```

## Q09. First-to-second purchase conversion

January's 90-day second-purchase conversion is 7 of 8 (87.50%); February's is 6 of 6 (100%). October has four customers but only one with a fully observed 90-day horizon, while November and December have none eligible at that horizon. Raw converter counts would mix different exposure windows and cohort sizes.

### Query

```sql
SET search_path TO northstar_retail, public;
WITH a AS(SELECT *,date_trunc('month',first_date)::date cohort,second_date-first_date gap FROM customer_history),b AS(
SELECT cohort,count(*) cohort_size,count(*) FILTER(WHERE first_date+30<DATE '2026-01-01') eligible_30,count(*) FILTER(WHERE first_date+60<DATE '2026-01-01') eligible_60,count(*) FILTER(WHERE first_date+90<DATE '2026-01-01') eligible_90,
count(*) FILTER(WHERE first_date+30<DATE '2026-01-01' AND gap BETWEEN 0 AND 30) converters_30,
count(*) FILTER(WHERE first_date+60<DATE '2026-01-01' AND gap BETWEEN 0 AND 60) converters_60,
count(*) FILTER(WHERE first_date+90<DATE '2026-01-01' AND gap BETWEEN 0 AND 90) converters_90,
percentile_cont(.5) WITHIN GROUP(ORDER BY gap) FILTER(WHERE first_date+90<DATE '2026-01-01' AND gap BETWEEN 0 AND 90) median_days_to_second_within_90 FROM a GROUP BY cohort)
SELECT *,round(100.0*converters_30/NULLIF(eligible_30,0),2) conversion_30_pct,round(100.0*converters_60/NULLIF(eligible_60,0),2) conversion_60_pct,round(100.0*converters_90/NULLIF(eligible_90,0),2) conversion_90_pct FROM b ORDER BY cohort;
```

### Result

[Complete result: 12 rows](results/q09.csv). Preview:

| cohort | cohort_size | eligible_30 | eligible_60 | eligible_90 | converters_30 | converters_60 | converters_90 | median_days_to_second_within_90 | conversion_30_pct | conversion_60_pct | conversion_90_pct |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 2025-01-01 | 8 | 8 | 8 | 8 | 4 | 7 | 7 | 22 | 50 | 87.5 | 87.5 |
| 2025-02-01 | 6 | 6 | 6 | 6 | 3 | 4 | 6 | 22.5 | 50 | 66.67 | 100 |
| 2025-03-01 | 5 | 5 | 5 | 5 | 2 | 3 | 3 | 10 | 40 | 60 | 60 |
| 2025-04-01 | 5 | 5 | 5 | 5 | 0 | 1 | 2 | 60.5 | 0 | 20 | 40 |
| 2025-05-01 | 5 | 5 | 5 | 5 | 2 | 3 | 3 | 27 | 40 | 60 | 60 |
| 2025-06-01 | 4 | 4 | 4 | 4 | 2 | 2 | 2 | 8 | 50 | 50 | 50 |

### Validation

Passed. The check and its independent arithmetic are in [04_validation.sql](04_validation.sql); view the saved [validation results](results/validation.csv).

```sql
SELECT * FROM northstar_retail.validation_results WHERE question='Q09';
```

## Q10. Channel 90-day value

Social has the highest mean 90-day contribution, INR 1,232.18 across 11 eligible customers, and an 81.82% repeat rate. Organic has the highest average paid value, INR 5,444.58, but a lower mean contribution of INR 1,139.83. Advertising spend, acquisition costs, customer mix, and a controlled test are needed before interpreting these differences as marketing ROI or shifting budget.

### Query

```sql
SET search_path TO northstar_retail, public;
SELECT c.channel,count(h.customer_id) eligible_customers,round(avg(window_paid),2) avg_90d_paid_value,round(avg(window_contribution),2) avg_90d_contribution,
round((percentile_cont(.5) WITHIN GROUP(ORDER BY window_contribution))::numeric,2) median_90d_contribution,round(avg(window_orders),2) avg_90d_orders,
round(100.0*count(*) FILTER(WHERE window_orders>=2)/NULLIF(count(h.customer_id),0),2) repeat_customer_pct,
CASE WHEN count(h.customer_id)<5 THEN 'insufficient_sample' ELSE 'sufficient_sample' END sample_flag
FROM(SELECT DISTINCT acquisition_channel channel FROM customers)c LEFT JOIN customer_90 h USING(channel) GROUP BY c.channel ORDER BY c.channel;
```

### Result

[Complete result: 4 rows](results/q10.csv). Preview:

| channel | eligible_customers | avg_90d_paid_value | avg_90d_contribution | median_90d_contribution | avg_90d_orders | repeat_customer_pct | sample_flag |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Organic | 12 | 5444.58 | 1139.83 | 1278 | 2.17 | 75 | sufficient_sample |
| Paid Search | 11 | 3280.68 | 1219.95 | 1139 | 1.82 | 54.55 | sufficient_sample |
| Referral | 11 | 4340.23 | 1202.27 | 958 | 2.18 | 54.55 | sufficient_sample |
| Social | 11 | 4859.77 | 1232.18 | 1233 | 2.27 | 81.82 | sufficient_sample |

### Validation

Passed. The check and its independent arithmetic are in [04_validation.sql](04_validation.sql); view the saved [validation results](results/validation.csv).

```sql
SELECT * FROM northstar_retail.validation_results WHERE question='Q10';
```

## Q11. First-purchase entry category

Electronics entry customers have the largest first-order AOV, INR 2,637.92, but Fitness entry customers have the highest mean 90-day contribution, INR 1,489.73. Home has the highest second-purchase rate, 75% among eight eligible customers. These measures describe different aspects of customer value, and category assignment is an association rather than a causal effect.

### Query

```sql
SET search_path TO northstar_retail, public;
WITH a AS(SELECT h.customer_id,l.category,sum(l.paid) paid,row_number() OVER(PARTITION BY h.customer_id ORDER BY sum(l.paid) DESC,l.category) rn FROM customer_90 h JOIN line_values l ON l.order_id=h.first_order_id GROUP BY h.customer_id,l.category)
SELECT a.category entry_category,count(*) eligible_customers,round(avg(s.paid),2) first_order_aov,round(avg(h.window_contribution),2) avg_90d_contribution,
round(100.0*count(*) FILTER(WHERE window_orders>=2)/count(*),2) second_purchase_90d_pct,
CASE WHEN count(*)<5 THEN 'insufficient_sample' ELSE 'sufficient_sample' END sample_flag FROM a JOIN customer_90 h USING(customer_id) JOIN sales s ON s.order_id=h.first_order_id WHERE rn=1 GROUP BY a.category ORDER BY a.category;
```

### Result

[Complete result: 4 rows](results/q11.csv). Preview:

| entry_category | eligible_customers | first_order_aov | avg_90d_contribution | second_purchase_90d_pct | sample_flag |
| --- | --- | --- | --- | --- | --- |
| Accessories | 8 | 2011.25 | 865.56 | 62.5 | sufficient_sample |
| Electronics | 18 | 2637.92 | 1151.25 | 66.67 | sufficient_sample |
| Fitness | 11 | 1729.32 | 1489.73 | 63.64 | sufficient_sample |
| Home | 8 | 2055 | 1230.31 | 75 | sufficient_sample |

### Validation

Passed. The check and its independent arithmetic are in [04_validation.sql](04_validation.sql); view the saved [validation results](results/validation.csv).

```sql
SELECT * FROM northstar_retail.validation_results WHERE question='Q11';
```

## Q12. Win-back audience

The queue contains ten customers, led by customer 17 with INR 4,122.50 lifetime contribution and 101 days of recency. The rules prioritize previously profitable repeat purchasers who have become inactive while excluding a latest in-transit order. This is an eligibility policy over the observed year, not a prediction of campaign response or consent to contact.

### Query

```sql
SET search_path TO northstar_retail, public;
WITH latest AS(SELECT DISTINCT ON(customer_id) customer_id,status FROM orders ORDER BY customer_id,order_date DESC,order_id DESC),a AS(
SELECT h.customer_id,channel,orders qualifying_orders,last_date last_purchase_date,DATE '2026-01-01'-last_date recency_days,contribution lifetime_contribution,l.status latest_order_status,
row_number() OVER(ORDER BY contribution DESC,DATE '2026-01-01'-last_date DESC,h.customer_id) priority_rank
FROM customer_history h JOIN latest l USING(customer_id) WHERE orders>=2 AND contribution>0 AND DATE '2026-01-01'-last_date>=60 AND l.status<>'in_transit') SELECT * FROM a WHERE priority_rank<=10 ORDER BY priority_rank;
```

### Result

[Complete result: 10 rows](results/q12.csv). Preview:

| customer_id | channel | qualifying_orders | last_purchase_date | recency_days | lifetime_contribution | latest_order_status | priority_rank |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 17 | Organic | 6 | 2025-09-22 | 101 | 4122.5 | delivered | 1 |
| 19 | Referral | 3 | 2025-09-04 | 119 | 3123 | delivered | 2 |
| 3 | Referral | 4 | 2025-10-22 | 71 | 3061 | delivered | 3 |
| 41 | Organic | 2 | 2025-09-22 | 101 | 2373 | delivered | 4 |
| 4 | Social | 4 | 2025-06-04 | 211 | 2210.5 | delivered | 5 |
| 10 | Paid Search | 4 | 2025-05-16 | 230 | 2208 | delivered | 6 |

### Validation

Passed. The check and its independent arithmetic are in [04_validation.sql](04_validation.sql); view the saved [validation results](results/validation.csv).

```sql
SELECT * FROM northstar_retail.validation_results WHERE question='Q12';
```

## Q13. Mature discount-band economics

High-discount mature orders have 6.28% contribution margin and a 14.71% unit return rate across 14 orders and 34 units. No-discount mature orders have 35.50% margin and a 7.50% unit return rate across 39 orders and 80 units. Product selection, customers, and timing can differ between groups, so this does not show that discounts caused returns.

### Query

```sql
SET search_path TO northstar_retail, public;
WITH a AS(SELECT *,CASE WHEN discounts=0 THEN 'none' WHEN discounts/gross<.1 THEN 'low' WHEN discounts/gross<.2 THEN 'medium' ELSE 'high' END band FROM sales WHERE delivered_date<=DATE '2025-12-01')
SELECT b.band,count(a.order_id) orders,round(sum(paid)/NULLIF(count(a.order_id),0),2) aov,coalesce(sum(revenue),0) net_revenue,coalesce(sum(contribution),0) contribution,
round(100*sum(contribution)/NULLIF(sum(revenue),0),2) margin_pct,coalesce(sum(units),0) purchased_units,coalesce(sum(returned_units),0) returned_units,
round(100.0*sum(returned_units)/NULLIF(sum(units),0),2) unit_return_pct,round(100.0*count(*) FILTER(WHERE returned_units>0)/NULLIF(count(a.order_id),0),2) order_return_pct,
CASE WHEN count(a.order_id)<5 THEN 'insufficient_sample' ELSE 'sufficient_sample' END sample_flag
FROM(VALUES('none',1),('low',2),('medium',3),('high',4))b(band,seq) LEFT JOIN a USING(band) GROUP BY b.band,b.seq ORDER BY b.seq;
```

### Result

[Complete result: 4 rows](results/q13.csv). Preview:

| band | orders | aov | net_revenue | contribution | margin_pct | purchased_units | returned_units | unit_return_pct | order_return_pct | sample_flag |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| none | 39 | 2205.13 | 80323 | 28518 | 35.5 | 80 | 6 | 7.5 | 12.82 | sufficient_sample |
| low | 100 | 2177.53 | 199718.5 | 63503.5 | 31.8 | 231 | 21 | 9.09 | 19 | sufficient_sample |
| medium | 24 | 1688.33 | 39254 | 10994 | 28.01 | 42 | 3 | 7.14 | 12.5 | sufficient_sample |
| high | 14 | 1854.11 | 21745.5 | 1365.5 | 6.28 | 34 | 5 | 14.71 | 28.57 | sufficient_sample |

### Validation

Passed. The check and its independent arithmetic are in [04_validation.sql](04_validation.sql); view the saved [validation results](results/validation.csv).

```sql
SELECT * FROM northstar_retail.validation_results WHERE question='Q13';
```

## Q14. Category growth versus margin

No category satisfies both growth and a margin decline of at least five percentage points. Fitness sales rise 33.67%, but its margin decline is only 2.42 points; Electronics grows while its margin improves. Further review can separate price, discounts, refunds, product costs, and shipping, without changing the specified threshold to manufacture a flag.

### Query

```sql
SET search_path TO northstar_retail, public;
WITH a AS(SELECT category,sum(paid) FILTER(WHERE half='H1') p1,sum(paid) FILTER(WHERE half='H2') p2,
sum(revenue) FILTER(WHERE half='H1') r1,sum(revenue) FILTER(WHERE half='H2') r2,sum(contribution) FILTER(WHERE half='H1') c1,sum(contribution) FILTER(WHERE half='H2') c2 FROM allocated_lines GROUP BY category),
b AS(SELECT *,100*c1/NULLIF(r1,0) m1,100*c2/NULLIF(r2,0) m2 FROM a)
SELECT category,p1 h1_paid_value,p2 h2_paid_value,round(r1,2) h1_net_revenue,round(r2,2) h2_net_revenue,round(c1,2) h1_contribution,round(c2,2) h2_contribution,round(m1,2) h1_margin_pct,round(m2,2) h2_margin_pct,
round(100*(p2-p1)/NULLIF(p1,0),2) paid_value_growth_pct,round(m2-m1,2) margin_change_pp,CASE WHEN m1 IS NOT NULL AND m2 IS NOT NULL THEN p2>p1 AND m2-m1<=-5 END review_flag FROM b ORDER BY category;
```

### Result

[Complete result: 4 rows](results/q14.csv). Preview:

| category | h1_paid_value | h2_paid_value | h1_net_revenue | h2_net_revenue | h1_contribution | h2_contribution | h1_margin_pct | h2_margin_pct | paid_value_growth_pct | margin_change_pp | review_flag |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Accessories | 28500 | 31845 | 26879.93 | 30314.9 | 9713.84 | 10998.56 | 36.14 | 36.28 | 11.74 | 0.14 | false |
| Electronics | 68055 | 89257.5 | 57929.79 | 80518.62 | 10007.37 | 16102.6 | 17.27 | 20 | 31.15 | 2.72 | false |
| Fitness | 50710 | 67782.5 | 48628.49 | 63834.55 | 18891.73 | 23252.6 | 38.85 | 36.43 | 33.67 | -2.42 | false |
| Home | 34367.5 | 31775 | 29762.29 | 30898.43 | 9052.57 | 11537.73 | 30.42 | 37.34 | -7.54 | 6.92 | false |

### Validation

Passed. The check and its independent arithmetic are in [04_validation.sql](04_validation.sql); view the saved [validation results](results/validation.csv).

```sql
SELECT * FROM northstar_retail.validation_results WHERE question='Q14';
```

## Q15. Mechanical no-discount scenario

The fixed-demand no-discount scenario adds INR 26,185 of contribution, with the largest category lift in Electronics at INR 10,277.50. It excludes INR 4,822.50 of discounts attributable to returned units from the lift. Quantities and return behavior are held fixed, so this arithmetic scenario cannot forecast the profit effect of removing promotions.

### Query

```sql
SET search_path TO northstar_retail, public;
SELECT category,sum(discount_amount) actual_discounts,round(sum(discount_amount*returned_quantity/quantity),2) discounts_on_returned_units,
sum(net) actual_net_merchandise_value,sum((quantity-returned_quantity)*unit_price) no_discount_net_merchandise_value,
round(sum(contribution),2) actual_contribution,round(sum((quantity-returned_quantity)*unit_price-cost+allocated_charge-allocated_shipping_cost),2) no_discount_contribution,
round(sum((quantity-returned_quantity)*unit_price-net),2) mechanical_contribution_lift FROM allocated_lines GROUP BY category ORDER BY category;
```

### Result

[Complete result: 4 rows](results/q15.csv). Preview:

| category | actual_discounts | discounts_on_returned_units | actual_net_merchandise_value | no_discount_net_merchandise_value | actual_contribution | no_discount_contribution | mechanical_contribution_lift |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Accessories | 3955 | 720 | 55665 | 58900 | 20712.41 | 23947.41 | 3235 |
| Electronics | 13137.5 | 2860 | 135672.5 | 145950 | 26109.97 | 36387.47 | 10277.5 |
| Fitness | 10457.5 | 690 | 111082.5 | 120850 | 42144.33 | 51911.83 | 9767.5 |
| Home | 3457.5 | 552.5 | 59095 | 62000 | 20590.3 | 23495.3 | 2905 |

### Validation

Passed. The check and its independent arithmetic are in [04_validation.sql](04_validation.sql); view the saved [validation results](results/validation.csv).

```sql
SELECT * FROM northstar_retail.validation_results WHERE question='Q15';
```

## Q16. Mature product returns

Wireless Earbuds ranks first with 11 returned units out of 40 mature purchased units (27.50%) and INR 18,090 of refunds across 32 eligible orders. Its material refund amount supports a quality investigation, while the denominator remains small. Nineteen immature orders, representing 40 units and INR 5,022.50 of recorded refunds, are shown separately rather than treated as equally observed.

### Query

```sql
SET search_path TO northstar_retail, public;
WITH products AS(SELECT DISTINCT product_id,product_name FROM allocated_lines),a AS(
SELECT p.product_id,p.product_name,count(DISTINCT l.order_id) eligible_orders,coalesce(sum(quantity),0) purchased_units,coalesce(sum(returned_quantity),0) returned_units,
count(DISTINCT l.order_id) FILTER(WHERE returned_quantity>0) orders_with_return,coalesce(sum(refund_amount),0) refunds FROM products p LEFT JOIN allocated_lines l ON l.product_id=p.product_id AND l.delivered_date<=DATE '2025-12-01' GROUP BY p.product_id,p.product_name),
b AS(SELECT *,100.0*returned_units/NULLIF(purchased_units,0) rate FROM a)
SELECT product_id,product_name,eligible_orders,purchased_units,returned_units,round(rate,2) unit_return_pct,orders_with_return,round(100.0*orders_with_return/NULLIF(eligible_orders,0),2) order_return_pct,refunds,
CASE WHEN purchased_units<8 THEN 'insufficient_sample' ELSE 'sufficient_sample' END sample_flag,
CASE WHEN purchased_units>=8 THEN row_number() OVER(PARTITION BY purchased_units>=8 ORDER BY rate DESC,refunds DESC,product_id) END quality_rank FROM b ORDER BY quality_rank NULLS LAST,product_id;
```

### Result

[Complete result: 18 rows](results/q16.csv). Preview:

| product_id | product_name | eligible_orders | purchased_units | returned_units | unit_return_pct | orders_with_return | order_return_pct | refunds | sample_flag | quality_rank |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Wireless Earbuds | 32 | 40 | 11 | 27.5 | 9 | 28.13 | 18090 | sufficient_sample | 1 |
| 5 | Storage Basket | 9 | 10 | 2 | 20 | 2 | 22.22 | 1080 | sufficient_sample | 2 |
| 4 | Desk Lamp | 14 | 17 | 3 | 17.65 | 3 | 21.43 | 3437.5 | sufficient_sample | 3 |
| 16 | Laptop Stand | 11 | 16 | 2 | 12.5 | 2 | 18.18 | 2700 | sufficient_sample | 4 |
| 8 | Resistance Bands | 43 | 52 | 6 | 11.54 | 6 | 13.95 | 3052.5 | sufficient_sample | 5 |
| 6 | Insulated Bottle | 8 | 9 | 1 | 11.11 | 1 | 12.5 | 765 | sufficient_sample | 6 |

**immature exclusion:** [Complete CSV](results/q16_immature_exclusion.csv)

```sql
SELECT count(*) excluded_orders,sum(units) purchased_units,sum(returned_units) returned_units,sum(refunds) refunds FROM sales WHERE delivered_date>DATE '2025-12-01';
```

| excluded_orders | purchased_units | returned_units | refunds |
| --- | --- | --- | --- |
| 19 | 40 | 6 | 5022.5 |

### Validation

Passed. The check and its independent arithmetic are in [04_validation.sql](04_validation.sql); view the saved [validation results](results/validation.csv).

```sql
SELECT * FROM northstar_retail.validation_results WHERE question='Q16';
```

## Q17. Regional contribution bridge

North has the lowest actual contribution margin, 29.39%, and INR 19,532.50 in recorded refunds. West has the largest shipping subsidy, INR 3,550, and shipping cost equal to 4.79% of gross merchandise value. These accounting components point to different commercial and fulfillment investigations, not a single established cause.

### Query

```sql
SET search_path TO northstar_retail, public;
SELECT region,sum(gross) gross_value,sum(discounts) discounts,sum(refunds) refunds,sum(cost) product_cost,sum(shipping_charged) shipping_charged,sum(shipping_cost) shipping_cost,sum(revenue) net_revenue,sum(contribution) contribution,
round(100*sum(contribution)/NULLIF(sum(revenue),0),2) margin_pct,round(100*sum(discounts)/NULLIF(sum(gross),0),2) discount_pct_of_gross,round(100*sum(refunds)/NULLIF(sum(gross),0),2) refund_pct_of_gross,
round(100*sum(cost)/NULLIF(sum(gross),0),2) product_cost_pct_of_gross,round(100*sum(shipping_cost)/NULLIF(sum(gross),0),2) shipping_cost_pct_of_gross,
sum(shipping_charged-shipping_cost) shipping_net,row_number() OVER(ORDER BY sum(contribution)/NULLIF(sum(revenue),0),region) rank FROM sales GROUP BY region ORDER BY rank;
```

### Result

[Complete result: 3 rows](results/q17.csv). Preview:

| region | gross_value | discounts | refunds | product_cost | shipping_charged | shipping_cost | net_revenue | contribution | margin_pct | discount_pct_of_gross | refund_pct_of_gross | product_cost_pct_of_gross | shipping_cost_pct_of_gross | shipping_net | rank |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| North | 202050 | 14060 | 19532.5 | 115590 | 3283 | 5670 | 171740.5 | 50480.5 | 29.39 | 6.96 | 9.67 | 57.21 | 2.81 | -2387 | 1 |
| West | 115050 | 8970 | 8587.5 | 64160 | 1960 | 5510 | 99452.5 | 29782.5 | 29.95 | 7.8 | 7.46 | 55.77 | 4.79 | -3550 | 2 |
| South | 116200 | 7977.5 | 12657.5 | 64620 | 2009 | 3660 | 97574 | 29294 | 30.02 | 6.87 | 10.89 | 55.61 | 3.15 | -1651 | 3 |

### Validation

Passed. The check and its independent arithmetic are in [04_validation.sql](04_validation.sql); view the saved [validation results](results/validation.csv).

```sql
SELECT * FROM northstar_retail.validation_results WHERE question='Q17';
```

## Q18. Category-mix standardized regions

The actual margin ranking is South, West, North, but the standardized ranking is North (30.64%), West (28.81%), South (28.39%). All regions have usable revenue in every weighted category, so no standardized result is missing. Common category weights adjust only for category mix, not within-category product, customer, discount, or delivery differences.

### Query

```sql
SET search_path TO northstar_retail, public;
WITH w AS(SELECT category,sum(revenue)/sum(sum(revenue)) OVER() weight FROM allocated_lines GROUP BY category),rc AS(SELECT region,category,sum(revenue) revenue,sum(contribution) contribution FROM allocated_lines GROUP BY region,category),
a AS(SELECT r.region,100*sum(rc.contribution)/NULLIF(sum(rc.revenue),0) actual,
CASE WHEN count(*) FILTER(WHERE w.weight>0 AND (rc.revenue IS NULL OR rc.revenue=0))=0 THEN sum(100*w.weight*rc.contribution/NULLIF(rc.revenue,0)) END standardized,
string_agg(w.category,', ' ORDER BY w.category) FILTER(WHERE w.weight>0 AND (rc.revenue IS NULL OR rc.revenue=0)) missing_categories
FROM(SELECT DISTINCT region FROM customers)r CROSS JOIN w LEFT JOIN rc ON rc.region=r.region AND rc.category=w.category GROUP BY r.region)
SELECT region,round(actual,2) actual_margin_pct,round(standardized,2) standardized_margin_pct,round(actual-standardized,2) actual_minus_standardized_pp,missing_categories,
CASE WHEN standardized IS NOT NULL THEN row_number() OVER(ORDER BY standardized DESC NULLS LAST,region) END standardized_rank FROM a ORDER BY standardized_rank NULLS LAST,region;
```

### Result

[Complete result: 3 rows](results/q18.csv). Preview:

| region | actual_margin_pct | standardized_margin_pct | actual_minus_standardized_pp | missing_categories | standardized_rank |
| --- | --- | --- | --- | --- | --- |
| North | 29.39 | 30.64 | -1.25 | NULL | 1 |
| West | 29.95 | 28.81 | 1.14 | NULL | 2 |
| South | 30.02 | 28.39 | 1.63 | NULL | 3 |

**common weights:** [Complete CSV](results/q18_common_weights.csv)

```sql
SELECT category,round(sum(revenue),2) net_revenue,round(100*sum(revenue)/sum(sum(revenue)) OVER(),2) weight_pct FROM allocated_lines GROUP BY category ORDER BY category;
```

| category | net_revenue | weight_pct |
| --- | --- | --- |
| Accessories | 57194.83 | 15.51 |
| Electronics | 138448.41 | 37.54 |
| Fitness | 112463.04 | 30.5 |
| Home | 60660.72 | 16.45 |

### Validation

Passed. The check and its independent arithmetic are in [04_validation.sql](04_validation.sql); view the saved [validation results](results/validation.csv).

```sql
SELECT * FROM northstar_retail.validation_results WHERE question='Q18';
```

## Q19. Delivery reliability

North Hub to West has the highest late frequency: 14 of 27 eligible deliveries, or 51.85%. Its late orders average 4 days late, with a continuous 90th percentile of 7.7 days; one additional delivered order has no promise. This combination warrants review, while a missing promise must remain visible outside the rate denominator.

### Query

```sql
SET search_path TO northstar_retail, public;
SELECT warehouse,region,count(*) delivered_orders,count(*) FILTER(WHERE promised_delivery_date IS NULL) missing_promises,count(promised_delivery_date) eligible_orders,
count(*) FILTER(WHERE delivered_date>promised_delivery_date) late_orders,round(100.0*count(*) FILTER(WHERE delivered_date>promised_delivery_date)/NULLIF(count(promised_delivery_date),0),2) late_pct,
round(100.0*count(*) FILTER(WHERE delivered_date<=promised_delivery_date)/NULLIF(count(promised_delivery_date),0),2) on_time_pct,
round(avg(delivered_date-promised_delivery_date) FILTER(WHERE delivered_date>promised_delivery_date),2) avg_days_late,
round((percentile_cont(.9) WITHIN GROUP(ORDER BY delivered_date-promised_delivery_date) FILTER(WHERE delivered_date>promised_delivery_date))::numeric,2) p90_days_late,
CASE WHEN count(promised_delivery_date)<5 THEN 'insufficient_sample' ELSE 'sufficient_sample' END sample_flag FROM sales GROUP BY warehouse,region ORDER BY warehouse,region;
```

### Result

[Complete result: 4 rows](results/q19.csv). Preview:

| warehouse | region | delivered_orders | missing_promises | eligible_orders | late_orders | late_pct | on_time_pct | avg_days_late | p90_days_late | sample_flag |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| North Hub | North | 85 | 2 | 83 | 26 | 31.33 | 68.67 | 4.38 | 7 | sufficient_sample |
| North Hub | West | 28 | 1 | 27 | 14 | 51.85 | 48.15 | 4 | 7.7 | sufficient_sample |
| South Hub | South | 58 | 1 | 57 | 12 | 21.05 | 78.95 | 4.92 | 6.9 | sufficient_sample |
| South Hub | West | 25 | 0 | 25 | 4 | 16 | 84 | 3 | 4.7 | sufficient_sample |

### Validation

Passed. The check and its independent arithmetic are in [04_validation.sql](04_validation.sql); view the saved [validation results](results/validation.csv).

```sql
SELECT * FROM northstar_retail.validation_results WHERE question='Q19';
```

## Q20. Warehouse deterioration streak

North Hub triggers consecutive warnings in August, September, and October, with streak lengths one, two, and three. October has 6 late orders among 7 eligible orders (85.71%) versus a 50% pooled three-month baseline from 34 eligible orders. The repeated warnings indicate sustained deterioration under the training rule, although the monthly denominators are small.

### Query

```sql
SET search_path TO northstar_retail, public;
WITH a AS(SELECT m.month,w.warehouse,count(s.promised_delivery_date) eligible_orders,count(*) FILTER(WHERE s.delivered_date>s.promised_delivery_date) late_orders
FROM months m CROSS JOIN(SELECT DISTINCT warehouse FROM orders)w LEFT JOIN sales s ON s.month=m.month AND s.warehouse=w.warehouse GROUP BY m.month,w.warehouse),
b AS(SELECT *,CASE WHEN month>=DATE '2025-04-01' THEN sum(eligible_orders) OVER w END be,CASE WHEN month>=DATE '2025-04-01' THEN sum(late_orders) OVER w END bl,100.0*late_orders/NULLIF(eligible_orders,0) rate FROM a WINDOW w AS(PARTITION BY warehouse ORDER BY month ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING)),
c AS(SELECT *,100.0*bl/NULLIF(be,0) baseline FROM b),d AS(SELECT *,coalesce(eligible_orders>=5 AND be>=15 AND rate-baseline>=15,false) flag FROM c),e AS(SELECT *,sum((NOT flag)::int) OVER(PARTITION BY warehouse ORDER BY month) grp FROM d)
SELECT warehouse,month,eligible_orders,late_orders,round(rate,2) late_pct,be baseline_eligible_orders,round(baseline,2) baseline_late_pct,round(rate-baseline,2) excess_pp,flag warning_flag,
CASE WHEN flag THEN count(*) FILTER(WHERE flag) OVER(PARTITION BY warehouse,grp ORDER BY month) ELSE 0 END streak_length FROM e ORDER BY warehouse,month;
```

### Result

[Complete result: 24 rows](results/q20.csv). Preview:

| warehouse | month | eligible_orders | late_orders | late_pct | baseline_eligible_orders | baseline_late_pct | excess_pp | warning_flag | streak_length |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| North Hub | 2025-01-01 | 7 | 1 | 14.29 | NULL | NULL | NULL | false | 0 |
| North Hub | 2025-02-01 | 8 | 3 | 37.5 | NULL | NULL | NULL | false | 0 |
| North Hub | 2025-03-01 | 8 | 1 | 12.5 | NULL | NULL | NULL | false | 0 |
| North Hub | 2025-04-01 | 8 | 1 | 12.5 | 23 | 21.74 | -9.24 | false | 0 |
| North Hub | 2025-05-01 | 11 | 3 | 27.27 | 24 | 20.83 | 6.44 | false | 0 |
| North Hub | 2025-06-01 | 11 | 0 | 0 | 27 | 18.52 | -18.52 | false | 0 |

### Validation

Passed. The check and its independent arithmetic are in [04_validation.sql](04_validation.sql); view the saved [validation results](results/validation.csv).

```sql
SELECT * FROM northstar_retail.validation_results WHERE question='Q20';
```

## Q21. First delivery and repeat purchasing

Within Referral, first-late customers convert at 50% (3 of 6), compared with 60% (3 of 5) for on-time customers. Organic, Paid Search, and Social late groups have fewer than five customers, and one mature customer is excluded for a missing first-order promise. Channel mix and purchases made before first delivery prevent a causal interpretation of this retrospective association.

### Query

```sql
SET search_path TO northstar_retail, public;
WITH a AS(SELECT h.*,CASE WHEN s.delivered_date>s.promised_delivery_date THEN 'late' ELSE 'on_time' END experience,second_date-first_date gap FROM customer_90 h JOIN sales s ON s.order_id=h.first_order_id WHERE s.promised_delivery_date IS NOT NULL)
SELECT c.channel,e.experience,count(a.customer_id) eligible_customers,count(*) FILTER(WHERE gap BETWEEN 0 AND 90) converters_90d,
round(100.0*count(*) FILTER(WHERE gap BETWEEN 0 AND 90)/NULLIF(count(a.customer_id),0),2) conversion_pct,
percentile_cont(.5) WITHIN GROUP(ORDER BY gap) FILTER(WHERE gap BETWEEN 0 AND 90) median_second_purchase_gap,
CASE WHEN count(a.customer_id)<5 THEN 'insufficient_sample' ELSE 'sufficient_sample' END sample_flag
FROM(SELECT DISTINCT acquisition_channel channel FROM customers)c CROSS JOIN(VALUES('late'),('on_time'))e(experience) LEFT JOIN a ON a.channel=c.channel AND a.experience=e.experience GROUP BY c.channel,e.experience ORDER BY 1,2;
```

### Result

[Complete result: 8 rows](results/q21.csv). Preview:

| channel | experience | eligible_customers | converters_90d | conversion_pct | median_second_purchase_gap | sample_flag |
| --- | --- | --- | --- | --- | --- | --- |
| Organic | late | 3 | 3 | 100 | 10 | insufficient_sample |
| Organic | on_time | 8 | 6 | 75 | 24 | sufficient_sample |
| Paid Search | late | 1 | 1 | 100 | 65 | insufficient_sample |
| Paid Search | on_time | 10 | 5 | 50 | 35 | sufficient_sample |
| Referral | late | 6 | 3 | 50 | 5 | sufficient_sample |
| Referral | on_time | 5 | 3 | 60 | 10 | sufficient_sample |

**missing first promises:** [Complete CSV](results/q21_missing_first_promises.csv)

```sql
SELECT count(*) excluded_mature_customers FROM customer_90 h JOIN sales s ON s.order_id=h.first_order_id WHERE s.promised_delivery_date IS NULL;
```

| excluded_mature_customers |
| --- |
| 1 |

### Validation

Passed. The check and its independent arithmetic are in [04_validation.sql](04_validation.sql); view the saved [validation results](results/validation.csv).

```sql
SELECT * FROM northstar_retail.validation_results WHERE question='Q21';
```

## Q22. Shipping subsidy exposure

West has both the largest annual shipping subsidy, INR 3,550, and the highest subsidy per delivered order, INR 66.98. It recovers 35.57% of shipping cost through charges, and all three regions show positive subsidies in all four quarters. Total exposure and per-order economics should both inform a shipping-pricing or carrier review.

### Query

```sql
SET search_path TO northstar_retail, public;
WITH a AS(SELECT r.region,q.quarter,count(s.order_id) orders,coalesce(sum(shipping_charged),0) charged,coalesce(sum(shipping_cost),0) cost,count(*) FILTER(WHERE shipping_cost>shipping_charged) subsidized
FROM(SELECT DISTINCT region FROM customers)r CROSS JOIN generate_series(1,4)q(quarter) LEFT JOIN sales s ON s.region=r.region AND extract(quarter FROM s.order_date)=q.quarter GROUP BY r.region,q.quarter)
SELECT region,quarter,orders,charged,cost,cost-charged subsidy,round((cost-charged)/NULLIF(orders,0),2) subsidy_per_order,round(100*charged/NULLIF(cost,0),2) recovery_pct,
round(100.0*subsidized/NULLIF(orders,0),2) subsidized_order_pct,row_number() OVER(ORDER BY cost-charged DESC,region,quarter) exposure_rank FROM a ORDER BY exposure_rank;
```

### Result

[Complete result: 12 rows](results/q22.csv). Preview:

| region | quarter | orders | charged | cost | subsidy | subsidy_per_order | recovery_pct | subsidized_order_pct | exposure_rank |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| West | 4 | 16 | 539 | 1600 | 1061 | 66.31 | 33.69 | 100 | 1 |
| West | 3 | 14 | 539 | 1460 | 921 | 65.79 | 36.92 | 100 | 2 |
| West | 1 | 12 | 490 | 1320 | 830 | 69.17 | 37.12 | 100 | 3 |
| North | 3 | 26 | 980 | 1800 | 820 | 31.54 | 54.44 | 80.77 | 4 |
| West | 2 | 11 | 392 | 1130 | 738 | 67.09 | 34.69 | 100 | 5 |
| South | 4 | 25 | 882 | 1560 | 678 | 27.12 | 56.54 | 76 | 6 |

**annual regions:** [Complete CSV](results/q22_annual_regions.csv)

```sql
SELECT region,sum(orders) orders,sum(charged) charged,sum(cost) cost,sum(subsidy) subsidy,round(sum(subsidy)/NULLIF(sum(orders),0),2) subsidy_per_order,round(100*sum(charged)/NULLIF(sum(cost),0),2) recovery_pct,bool_and(subsidy>0) positive_all_four_quarters FROM q22 GROUP BY region ORDER BY subsidy DESC,region;
```

| region | orders | charged | cost | subsidy | subsidy_per_order | recovery_pct | positive_all_four_quarters |
| --- | --- | --- | --- | --- | --- | --- | --- |
| West | 53 | 1960 | 5510 | 3550 | 66.98 | 35.57 | true |
| North | 85 | 3283 | 5670 | 2387 | 28.08 | 57.9 | true |
| South | 58 | 2009 | 3660 | 1651 | 28.47 | 54.89 | true |

### Validation

Passed. The check and its independent arithmetic are in [04_validation.sql](04_validation.sql); view the saved [validation results](results/validation.csv).

```sql
SELECT * FROM northstar_retail.validation_results WHERE question='Q22';
```

## Q23. Conservative delivery promises

No warehouse-region group meets the conservative-promise review rule. South Hub to West has the largest early-three-days share at 32%, below the required 50%, and its late rate is 16%, above the 10% ceiling. Shortening every promise would therefore be unsupported by this rule and could worsen reliability.

### Query

```sql
SET search_path TO northstar_retail, public;
SELECT warehouse,region,count(*) eligible_orders,round(avg(promised_delivery_date-order_date),2) avg_promised_days,round(avg(delivered_date-order_date),2) avg_actual_days,
round(avg(promised_delivery_date-delivered_date),2) avg_signed_buffer_days,percentile_cont(.5) WITHIN GROUP(ORDER BY promised_delivery_date-delivered_date) median_buffer_days,
round(100.0*count(*) FILTER(WHERE promised_delivery_date-delivered_date>=3)/count(*),2) early_3plus_pct,round(100.0*count(*) FILTER(WHERE delivered_date>promised_delivery_date)/count(*),2) late_pct,
count(*)>=10 AND 1.0*count(*) FILTER(WHERE promised_delivery_date-delivered_date>=3)/count(*)>=.5 AND 1.0*count(*) FILTER(WHERE delivered_date>promised_delivery_date)/count(*)<=.1 review_candidate
FROM sales WHERE promised_delivery_date IS NOT NULL GROUP BY warehouse,region ORDER BY warehouse,region;
```

### Result

[Complete result: 4 rows](results/q23.csv). Preview:

| warehouse | region | eligible_orders | avg_promised_days | avg_actual_days | avg_signed_buffer_days | median_buffer_days | early_3plus_pct | late_pct | review_candidate |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| North Hub | North | 83 | 5 | 5.33 | -0.33 | 1 | 14.46 | 31.33 | false |
| North Hub | West | 27 | 7 | 8 | -1 | -1 | 22.22 | 51.85 | false |
| South Hub | South | 57 | 5 | 4.72 | 0.28 | 1 | 15.79 | 21.05 | false |
| South Hub | West | 25 | 7 | 6.04 | 0.96 | 1 | 32 | 16 | false |

### Validation

Passed. The check and its independent arithmetic are in [04_validation.sql](04_validation.sql); view the saved [validation results](results/validation.csv).

```sql
SELECT * FROM northstar_retail.validation_results WHERE question='Q23';
```

## Q24. Cancellation exposure

North's cancellation rate falls from 8.70% in H1 to 4.35% in H2, while South rises from 4.35% to 5.26%. West's H1 cancelled quoted value is INR 7,050, or 12.52% of placed quoted value. These are unfulfilled checkout exposures, not recorded cash losses or amounts to add to delivered revenue.

### Query

```sql
SET search_path TO northstar_retail, public;
WITH a AS(SELECT region,half,count(*) placed_orders,count(*) FILTER(WHERE status='cancelled') cancelled_orders,100.0*count(*) FILTER(WHERE status='cancelled')/count(*) rate,
coalesce(sum(paid) FILTER(WHERE status='cancelled'),0) cancelled_quoted_value,sum(paid) placed_quoted_value FROM order_values GROUP BY region,half)
SELECT region,half,placed_orders,cancelled_orders,round(rate,2) cancellation_pct,cancelled_quoted_value,placed_quoted_value,round(100*cancelled_quoted_value/NULLIF(placed_quoted_value,0),2) cancelled_value_share_pct,
round(rate-lag(rate) OVER(PARTITION BY region ORDER BY half),2) change_vs_h1_pp,CASE WHEN placed_orders<10 THEN 'insufficient_sample' ELSE 'sufficient_sample' END sample_flag FROM a ORDER BY region,half;
```

### Result

[Complete result: 6 rows](results/q24.csv). Preview:

| region | half | placed_orders | cancelled_orders | cancellation_pct | cancelled_quoted_value | placed_quoted_value | cancelled_value_share_pct | change_vs_h1_pp | sample_flag |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| North | H1 | 46 | 4 | 8.7 | 5817.5 | 95150 | 6.11 | NULL | sufficient_sample |
| North | H2 | 46 | 2 | 4.35 | 2845 | 102402.5 | 2.78 | -4.35 | sufficient_sample |
| South | H1 | 23 | 1 | 4.35 | 1187.5 | 44220 | 2.69 | NULL | sufficient_sample |
| South | H2 | 38 | 2 | 5.26 | 2380 | 67570 | 3.52 | 0.92 | sufficient_sample |
| West | H1 | 25 | 2 | 8 | 7050 | 56317.5 | 12.52 | NULL | sufficient_sample |
| West | H2 | 32 | 2 | 6.25 | 3750 | 60562.5 | 6.19 | -1.75 | sufficient_sample |

### Validation

Passed. The check and its independent arithmetic are in [04_validation.sql](04_validation.sql); view the saved [validation results](results/validation.csv).

```sql
SELECT * FROM northstar_retail.validation_results WHERE question='Q24';
```

## Q25. Cross-sell product pairs

Yoga Mat and Resistance Bands (products 7 and 8) are a plausible bundle candidate: 37 shared orders, 18.88% support, and lift 2.9624. The highest-lift pair is products 1 and 11, at 3.5778 across 23 orders. Only four pairs pass the three-order threshold; a bundle experiment must still assess incremental demand, margin, and whether the observed association reflects existing merchandising.

### Query

```sql
SET search_path TO northstar_retail, public;
WITH baskets AS(SELECT DISTINCT order_id,product_id FROM allocated_lines),single AS(SELECT product_id,count(*) n FROM baskets GROUP BY product_id),pairs AS(SELECT a.product_id a,b.product_id b,count(*) n FROM baskets a JOIN baskets b ON a.order_id=b.order_id AND a.product_id<b.product_id GROUP BY a.product_id,b.product_id HAVING count(*)>=3),
x AS(SELECT p.*,sa.n na,sb.n nb,(SELECT count(*) FROM sales) total,1.0*p.n*(SELECT count(*) FROM sales)/(sa.n*sb.n) lift FROM pairs p JOIN single sa ON sa.product_id=p.a JOIN single sb ON sb.product_id=p.b),
r AS(SELECT *,row_number() OVER(ORDER BY lift DESC,n DESC,a,b) rank FROM x)
SELECT a product_a,b product_b,na orders_a,nb orders_b,n shared_orders,round(100.0*n/total,2) support_pct,round(100.0*n/na,2) confidence_a_to_b_pct,round(100.0*n/nb,2) confidence_b_to_a_pct,round(lift,4) lift,rank FROM r WHERE rank<=10 ORDER BY rank;
```

### Result

[Complete result: 4 rows](results/q25.csv). Preview:

| product_a | product_b | orders_a | orders_b | shared_orders | support_pct | confidence_a_to_b_pct | confidence_b_to_a_pct | lift | rank |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | 11 | 35 | 36 | 23 | 11.73 | 65.71 | 63.89 | 3.5778 | 1 |
| 7 | 8 | 51 | 48 | 37 | 18.88 | 72.55 | 77.08 | 2.9624 | 2 |
| 9 | 17 | 11 | 23 | 3 | 1.53 | 27.27 | 13.04 | 2.3241 | 3 |
| 1 | 10 | 35 | 20 | 3 | 1.53 | 8.57 | 15 | 0.84 | 4 |

### Validation

Passed. The check and its independent arithmetic are in [04_validation.sql](04_validation.sql); view the saved [validation results](results/validation.csv).

```sql
SELECT * FROM northstar_retail.validation_results WHERE question='Q25';
```

## Q26. Customer value concentration

The top group contains exactly 11 of 54 purchasing customers. It generates 48.33% of paid sales and 48.82% of contribution, so dependence on top spenders is slightly stronger by contribution. Registered non-purchasers do not enter the denominator, and the ranking is based on paid sales rather than hindsight profitability.

### Query

```sql
SET search_path TO northstar_retail, public;
WITH a AS(SELECT *,row_number() OVER(ORDER BY paid DESC,customer_id) rn,ceil(.2*count(*) OVER()) cutoff FROM customer_history),b AS(SELECT *,CASE WHEN rn<=cutoff THEN 'top_20pct' ELSE 'remaining' END group_name FROM a),
c AS(SELECT group_name,max(cutoff) selected_cutoff_count,count(*) customers,sum(orders) orders,sum(paid) paid_value,sum(revenue) net_revenue,sum(contribution) contribution FROM b GROUP BY group_name)
SELECT *,round(100*contribution/NULLIF(net_revenue,0),2) margin_pct,round(100*paid_value/NULLIF(sum(paid_value) OVER(),0),2) sales_share_pct,round(100*contribution/NULLIF(sum(contribution) OVER(),0),2) contribution_share_pct FROM c ORDER BY group_name;
```

### Result

[Complete result: 2 rows](results/q26.csv). Preview:

| group_name | selected_cutoff_count | customers | orders | paid_value | net_revenue | contribution | margin_pct | sales_share_pct | contribution_share_pct |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| remaining | 11 | 43 | 114 | 207867.5 | 188549 | 56074 | 29.74 | 51.67 | 51.18 |
| top_20pct | 11 | 11 | 82 | 194425 | 180218 | 53483 | 29.68 | 48.33 | 48.82 |

### Validation

Passed. The check and its independent arithmetic are in [04_validation.sql](04_validation.sql); view the saved [validation results](results/validation.csv).

```sql
SELECT * FROM northstar_retail.validation_results WHERE question='Q26';
```

## Q27. Monthly exception monitor

The monitor returns six alerts, including late-rate alerts in August and September, sales alerts in November and December, and refund-ratio alerts in April and December. September's late rate is 52.63% across 19 eligible orders versus a 21.74% pooled baseline across 46. Final statuses and refunds are attributed back to purchase month, so these are retrospective review signals rather than claims about what was knowable in real time.

### Query

```sql
SET search_path TO northstar_retail, public;
WITH b AS(SELECT *,avg(paid) OVER w baseline_sales,sum(paid) OVER w bp,sum(refunds) OVER w br,sum(eligible) OVER w be,sum(late) OVER w bl FROM monthly WINDOW w AS(ORDER BY month ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING)),
a AS(SELECT month,'paid_sales'::text metric_name,paid current_value,baseline_sales baseline_value,delivered_orders eligible_count,NULL::numeric baseline_count,baseline_sales>0 evaluable,paid<.8*baseline_sales hit FROM b WHERE month>=DATE '2025-04-01'
UNION ALL SELECT month,'refund_ratio_pct',100*refunds/NULLIF(paid,0),100*br/NULLIF(bp,0),delivered_orders,NULL,paid>0 AND bp>0,100*refunds/NULLIF(paid,0)-100*br/NULLIF(bp,0)>=5 FROM b WHERE month>=DATE '2025-04-01'
UNION ALL SELECT month,'late_rate_pct',100.0*late/NULLIF(eligible,0),100*bl/NULLIF(be,0),eligible,be,eligible>=5 AND be>=15,100.0*late/NULLIF(eligible,0)-100*bl/NULLIF(be,0)>=15 FROM b WHERE month>=DATE '2025-04-01')
SELECT month,metric_name,round(current_value,2) current_value,round(baseline_value,2) baseline_value,round(current_value-baseline_value,2) comparison_difference,eligible_count,baseline_count,
CASE WHEN evaluable THEN 'evaluated' ELSE 'not_evaluable' END evaluation_status,CASE WHEN evaluable THEN hit END alert_flag FROM a ORDER BY month,metric_name;
```

### Result

[Complete result: 27 rows](results/q27.csv). Preview:

| month | metric_name | current_value | baseline_value | comparison_difference | eligible_count | baseline_count | evaluation_status | alert_flag |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 2025-04-01 | late_rate_pct | 12.5 | 25.64 | -13.14 | 16 | 39 | evaluated | false |
| 2025-04-01 | paid_sales | 27955 | 28895 | -940 | 16 | NULL | evaluated | false |
| 2025-04-01 | refund_ratio_pct | 18.41 | 9.1 | 9.31 | 16 | NULL | evaluated | true |
| 2025-05-01 | late_rate_pct | 20 | 21.43 | -1.43 | 15 | 42 | evaluated | false |
| 2025-05-01 | paid_sales | 33542.5 | 29550.83 | 3991.67 | 15 | NULL | evaluated | false |
| 2025-05-01 | refund_ratio_pct | 10.73 | 11.31 | -0.58 | 15 | NULL | evaluated | false |

### Validation

Passed. The check and its independent arithmetic are in [04_validation.sql](04_validation.sql); view the saved [validation results](results/validation.csv).

```sql
SELECT * FROM northstar_retail.validation_results WHERE question='Q27';
```

## Q28. Regional growth and repeat mix

South has the largest H2 sales growth, 51.49%, together with a 40.04-percentage-point increase in returning-sales share to 78.29%. North and West also increase their returning-sales mix. Full-history sequencing avoids reclassifying H1 buyers as new in H2, but the mix change alone does not establish loyalty, causation, or future retention.

### Query

```sql
SET search_path TO northstar_retail, public;
WITH a AS(SELECT r.region,h.half,t.purchase_type,count(s.order_id) orders,count(DISTINCT s.customer_id) customers,coalesce(sum(s.paid),0) paid_merchandise_value,coalesce(sum(s.contribution),0) contribution
FROM(SELECT DISTINCT region FROM customers)r CROSS JOIN(VALUES('H1'),('H2'))h(half) CROSS JOIN(VALUES('first_time'),('returning'))t(purchase_type)
LEFT JOIN sequenced_sales s ON s.region=r.region AND s.half=h.half AND s.purchase_type=t.purchase_type GROUP BY r.region,h.half,t.purchase_type)
SELECT *,round(100.0*sum(orders) FILTER(WHERE purchase_type='returning') OVER w/NULLIF(sum(orders) OVER w,0),2) returning_order_share_pct,
round(100*sum(paid_merchandise_value) FILTER(WHERE purchase_type='returning') OVER w/NULLIF(sum(paid_merchandise_value) OVER w,0),2) returning_sales_share_pct FROM a WINDOW w AS(PARTITION BY region,half) ORDER BY region,half,purchase_type;
```

### Result

[Complete result: 12 rows](results/q28.csv). Preview:

| region | half | purchase_type | orders | customers | paid_merchandise_value | contribution | returning_order_share_pct | returning_sales_share_pct |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| North | H1 | first_time | 12 | 12 | 22480 | 6211 | 71.43 | 74.84 |
| North | H1 | returning | 30 | 12 | 66852.5 | 14911 | 71.43 | 74.84 |
| North | H2 | first_time | 6 | 6 | 12460 | 2504 | 86.05 | 87.37 |
| North | H2 | returning | 37 | 14 | 86197.5 | 26854.5 | 86.05 | 87.37 |
| South | H1 | first_time | 11 | 11 | 26570 | 6822 | 50 | 38.26 |
| South | H1 | returning | 11 | 5 | 16462.5 | 6057 | 50 | 38.26 |

**region comparison:** [Complete CSV](results/q28_region_comparison.csv)

```sql
WITH a AS(SELECT region,half,sum(paid) sales,100*sum(paid) FILTER(WHERE purchase_type='returning')/NULLIF(sum(paid),0) share FROM sequenced_sales GROUP BY region,half) SELECT a.region,a.sales h1_sales,b.sales h2_sales,b.sales-a.sales absolute_sales_change,round(100*(b.sales-a.sales)/NULLIF(a.sales,0),2) sales_growth_pct,round(a.share,2) h1_returning_sales_share_pct,round(b.share,2) h2_returning_sales_share_pct,round(b.share-a.share,2) returning_share_change_pp FROM a JOIN a b ON b.region=a.region AND b.half='H2' WHERE a.half='H1' ORDER BY a.region;
```

| region | h1_sales | h2_sales | absolute_sales_change | sales_growth_pct | h1_returning_sales_share_pct | h2_returning_sales_share_pct | returning_share_change_pp |
| --- | --- | --- | --- | --- | --- | --- | --- |
| North | 89332.5 | 98657.5 | 9325 | 10.44 | 74.84 | 87.37 | 12.53 |
| South | 43032.5 | 65190 | 22157.5 | 51.49 | 38.26 | 78.29 | 40.04 |
| West | 49267.5 | 56812.5 | 7545 | 15.31 | 54.58 | 70.9 | 16.32 |

### Validation

Passed. The check and its independent arithmetic are in [04_validation.sql](04_validation.sql); view the saved [validation results](results/validation.csv).

```sql
SELECT * FROM northstar_retail.validation_results WHERE question='Q28';
```

## Q29. Service recovery review queue

Customer 32 ranks first: one affected Q4 order, seven days maximum lateness, eight annual qualifying orders, and INR 7,594 annual contribution. Its score is 0 + 2 + 2 + 1 = 5; the policy values severity, positive contribution, and purchase frequency, with a separate repeat-issue component. Support resolution, prior compensation, delivery follow-up, and contact permission should be checked before outreach.

### Query

```sql
SET search_path TO northstar_retail, public;
WITH a AS(SELECT customer_id,count(*) affected_orders_q4,max(delivered_date-promised_delivery_date) max_late_days FROM sales WHERE order_date>=DATE '2025-10-01' AND order_date<DATE '2026-01-01' AND delivered_date-promised_delivery_date>3 GROUP BY customer_id),
b AS(SELECT a.*,h.orders annual_orders,h.contribution annual_contribution,CASE WHEN affected_orders_q4>=2 THEN 3 ELSE 0 END repeat_issue_points,CASE WHEN max_late_days>=7 THEN 2 ELSE 0 END severity_points,CASE WHEN h.contribution>0 THEN 2 ELSE 0 END value_points,CASE WHEN h.orders>=3 THEN 1 ELSE 0 END frequency_points FROM a JOIN customer_history h USING(customer_id)),
c AS(SELECT *,repeat_issue_points+severity_points+value_points+frequency_points total_score FROM b),d AS(SELECT *,row_number() OVER(ORDER BY total_score DESC,annual_contribution DESC,customer_id) priority_rank FROM c)
SELECT * FROM d WHERE priority_rank<=10 ORDER BY priority_rank;
```

### Result

[Complete result: 10 rows](results/q29.csv). Preview:

| customer_id | affected_orders_q4 | max_late_days | annual_orders | annual_contribution | repeat_issue_points | severity_points | value_points | frequency_points | total_score | priority_rank |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 32 | 1 | 7 | 8 | 7594 | 0 | 2 | 2 | 1 | 5 | 1 |
| 5 | 1 | 7 | 8 | 4428 | 0 | 2 | 2 | 1 | 5 | 2 |
| 31 | 1 | 7 | 5 | 4303.5 | 0 | 2 | 2 | 1 | 5 | 3 |
| 48 | 1 | 8 | 2 | 1099 | 0 | 2 | 2 | 0 | 4 | 4 |
| 50 | 1 | 8 | 1 | 774 | 0 | 2 | 2 | 0 | 4 | 5 |
| 37 | 1 | 6 | 4 | 4511 | 0 | 0 | 2 | 1 | 3 | 6 |

### Validation

Passed. The check and its independent arithmetic are in [04_validation.sql](04_validation.sql); view the saved [validation results](results/validation.csv).

```sql
SELECT * FROM northstar_retail.validation_results WHERE question='Q29';
```

## Q30. Leadership action register

Electronics refunds lead the action register at INR 21,640 across 12 affected orders, equal to 5.87% of company net revenue. North loss-making orders follow at INR 8,424.50 across nine orders, then Fitness refunds at INR 7,410 across ten. These overlapping exposures are not additive savings or predicted recoverable amounts; the leadership memo defines three investigations and measurable KPIs.

### Query

```sql
SET search_path TO northstar_retail, public;
WITH a AS(SELECT 'category_refunds'::text candidate_type,category entity_name,count(DISTINCT order_id) FILTER(WHERE refund_amount>0) affected_orders,sum(refund_amount) exposure_inr,'Product Quality / Category Manager'::text suggested_owner FROM allocated_lines GROUP BY category
UNION ALL SELECT 'warehouse_shipping_shortfall',warehouse,count(*) FILTER(WHERE shipping_cost>shipping_charged),sum(greatest(shipping_cost-shipping_charged,0)),'Logistics Finance' FROM sales GROUP BY warehouse
UNION ALL SELECT 'region_loss_orders',region,count(*) FILTER(WHERE contribution<0),-sum(contribution) FILTER(WHERE contribution<0),'Regional Commercial / Finance' FROM sales GROUP BY region),
b AS(SELECT *,row_number() OVER(ORDER BY exposure_inr DESC,candidate_type,entity_name) rank FROM a WHERE exposure_inr>0)
SELECT rank,candidate_type,entity_name,affected_orders,round(exposure_inr,2) exposure_inr,round(100*exposure_inr/NULLIF((SELECT sum(revenue) FROM sales),0),2) exposure_pct_of_company_net_revenue,suggested_owner FROM b WHERE rank<=5 ORDER BY rank;
```

### Result

[Complete result: 5 rows](results/q30.csv). Preview:

| rank | candidate_type | entity_name | affected_orders | exposure_inr | exposure_pct_of_company_net_revenue | suggested_owner |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | category_refunds | Electronics | 12 | 21640 | 5.87 | Product Quality / Category Manager |
| 2 | region_loss_orders | North | 9 | 8424.5 | 2.28 | Regional Commercial / Finance |
| 3 | category_refunds | Fitness | 10 | 7410 | 2.01 | Product Quality / Category Manager |
| 4 | category_refunds | Home | 8 | 7047.5 | 1.91 | Product Quality / Category Manager |
| 5 | region_loss_orders | South | 9 | 5538 | 1.5 | Regional Commercial / Finance |

**source trace:** [Complete CSV](results/q30_source_trace.csv)

```sql
SELECT 'category_refunds' candidate_type,category entity_name,order_id,item_number,refund_amount exposure_inr FROM allocated_lines WHERE refund_amount>0 UNION ALL SELECT 'warehouse_shipping_shortfall',warehouse,order_id,NULL,greatest(shipping_cost-shipping_charged,0) FROM sales WHERE shipping_cost>shipping_charged UNION ALL SELECT 'region_loss_orders',region,order_id,NULL,-contribution FROM sales WHERE contribution<0 ORDER BY 1,2,3,4;
```

| candidate_type | entity_name | order_id | item_number | exposure_inr |
| --- | --- | --- | --- | --- |
| category_refunds | Accessories | 1038 | 1 | 630 |
| category_refunds | Accessories | 1081 | 1 | 1500 |
| category_refunds | Accessories | 1085 | 2 | 237.5 |
| category_refunds | Accessories | 1095 | 2 | 175 |
| category_refunds | Accessories | 1130 | 2 | 225 |

### Validation

Passed. The check and its independent arithmetic are in [04_validation.sql](04_validation.sql); view the saved [validation results](results/validation.csv).

```sql
SELECT * FROM northstar_retail.validation_results WHERE question='Q30';
```

## Manual boundary checks

- March rolling window: January–March revenue INR 80,262.50 and contribution INR 23,532.50; weighted margin 29.32%.
- A first purchase on 2025-10-02 has day 90 on 2025-12-31 and is eligible. A first purchase on 2025-10-03 has day 90 on the exclusive cutoff and is ineligible.
- A two-unit line with one returned unit has 50% returned units, even though its return-bearing-line indicator is 100%.
- First service-recovery score: customer 32 has 0 repeat-issue + 2 severity + 2 value + 1 frequency = 5 points.
