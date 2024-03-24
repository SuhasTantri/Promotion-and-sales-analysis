-- Ad hoc analysis 
select * from fact_events;
/* Create a list of products with base price greater than 500 and are 
featured in promo type of BOGOF*/
select f.product_code, f.base_price,f.product_code,dp.product_name
from fact_events f join dim_products dp
on dp.product_code = f.product_code
where f.base_price > 500 and f.promo_type = 'BOGOF'
group by 1,2,3,4;

/* Generate a report that gives an overview of the number of stores in each city
City with highest stores should be displayed on top*/
select city, count(store_id) as store_count from dim_stores
group by city
order by count(store_id)desc;

/*Generate a report that displays each campaign along with total revenue generated
before and after campaign*/
select distinct promo_type from fact_events;
select dc.campaign_name,round(sum(base_price * quantity_sold_before_promo)/1000000,1) as revenue_before_promo, 
	round(sum(case
		when promo_type IN ('50% OFF','BOGOF') then (base_price/2)*quantity_sold_after_promo
        when promo_type = '25% OFF' then (base_price/4)*quantity_sold_after_promo
        when promo_type = '33% OFF' then (base_price*(1-0.33))*quantity_sold_after_promo
        else (base_price * quantity_sold_after_promo)- 500
	end)/1000000,1) as revenue_after_promo
from fact_events fe
join dim_campaigns dc
on fe.campaign_id = dc.campaign_id
group by dc.campaign_name;

/* Produce a report that calculates Incremental Sold Quantity for each category
during Diwali campaign. Additionally provide rankings for the categories based on ISU%
and rank order*/
select dp.category,((sum(quantity_sold_after_promo)/sum(quantity_sold_before_promo))-1)*100.0 as ISU,
dense_rank() over(order by ((sum(quantity_sold_after_promo)/sum(quantity_sold_before_promo))-1)*100.0 desc) as 'rank'
from fact_events f
join dim_products dp on
dp.product_code = f.product_code
where campaign_id = 'CAMP_DIW_01'
group by dp.category;

/* Create a report featuring top 5 products , ranked by Incremental revenue percentage
across all campaigns. Report will have Product name, IR% and category*/
with cte as(select dp.product_name,round(sum(base_price * quantity_sold_before_promo)/1000000,1) as revenue_before_promo, 
	round(sum(case
		when promo_type IN ('50% OFF','BOGOF') then (base_price/2)*quantity_sold_after_promo
        when promo_type = '25% OFF' then (base_price/4)*quantity_sold_after_promo
        when promo_type = '33% OFF' then (base_price*(1-0.33))*quantity_sold_after_promo
        else (base_price * quantity_sold_after_promo)- 500
	end)/1000000,1) as revenue_after_promo
from fact_events fe
join dim_products dp
on fe.product_code = dp.product_code
group by dp.product_name)
select * from (select product_name, ((revenue_after_promo/revenue_before_promo)-1)*100.0 as "IR%",
dense_rank() over(order by ((revenue_after_promo/revenue_before_promo)-1)*100.0 desc) as r
from cte) a
where r<=5;

-- Store Performance analysis
/* Top 10 stores in terms of Incremental revenue*/
with cte as(select ds.store_id,round(sum(base_price * quantity_sold_before_promo)/1000000,1) as revenue_before_promo, 
	round(sum(case
		when promo_type IN ('50% OFF','BOGOF') then (base_price/2)*quantity_sold_after_promo
        when promo_type = '25% OFF' then (base_price/4)*quantity_sold_after_promo
        when promo_type = '33% OFF' then (base_price*(1-0.33))*quantity_sold_after_promo
        else (base_price * quantity_sold_after_promo)- 500
	end)/1000000,1) as revenue_after_promo
from fact_events fe
join dim_stores ds
on fe.store_id = ds.store_id
group by ds.store_id)
select * from (select store_id, ((revenue_after_promo/revenue_before_promo)-1)*100.0 as "IR%",
dense_rank() over(order by ((revenue_after_promo/revenue_before_promo)-1)*100.0 desc) as r
from cte) a
where r<=10;

-- Bottom 10 stores in terms of ISU during promotional period
select * from (select ds.store_id,((sum(quantity_sold_after_promo)/sum(quantity_sold_before_promo))-1)*100.0 as ISU,
dense_rank() over(order by ((sum(quantity_sold_after_promo)/sum(quantity_sold_before_promo))-1)*100.0) as r
from fact_events f
join dim_stores ds on
ds.store_id = f.store_id
group by ds.store_id) a
where r<=10; 

with cte as(select ds.city,ds.store_id,round(sum(base_price * quantity_sold_before_promo)/1000000,1) as revenue_before_promo, 
	round(sum(case
		when promo_type IN ('50% OFF','BOGOF') then (base_price/2)*quantity_sold_after_promo
        when promo_type = '25% OFF' then (base_price/4)*quantity_sold_after_promo
        when promo_type = '33% OFF' then (base_price*(1-0.33))*quantity_sold_after_promo
        else (base_price * quantity_sold_after_promo)- 500
	end)/1000000,1) as revenue_after_promo
from fact_events fe
join dim_stores ds
on fe.store_id = ds.store_id
group by 1,2)
select city,store_id, ((revenue_after_promo/revenue_before_promo)-1)*100.0 as "IR%",
dense_rank() over(partition by city order by ((revenue_after_promo/revenue_before_promo)-1)*100.0 desc) as store_rank
from cte;

-- Promotion analysis
-- Top 2 promotion types that resulted in highest incremental revenue
with cte as (select promo_type,round(sum(base_price * quantity_sold_before_promo)/1000000,1) as revenue_before_promo, 
	round(sum(case
		when promo_type IN ('50% OFF','BOGOF') then (base_price/2)*quantity_sold_after_promo
        when promo_type = '25% OFF' then (base_price/4)*quantity_sold_after_promo
        when promo_type = '33% OFF' then (base_price*(1-0.33))*quantity_sold_after_promo
        else (base_price * quantity_sold_after_promo)- 500
	end)/1000000,1) as revenue_after_promo
from fact_events fe
group by promo_type)
select * from (select *,((revenue_after_promo-revenue_before_promo)) as IR,
dense_rank() over(order by ((revenue_after_promo-revenue_before_promo)) desc) as r
from cte) a 
where r<=2;

-- Bottom 2 promotion types in terms of incremental sold units
select promo_type, (quantity_sold_after_promo-quantity_sold_before_promo) as Inc_sold_units,
dense_rank() over(order by (quantity_sold_after_promo-quantity_sold_before_promo)) as r from
fact_events
group by promo_type;

-- Difference between BOGOF or cashback versus disocunt promotions
with cte as (select promo_type,round(sum(base_price * quantity_sold_before_promo)/1000000,1) as revenue_before_promo, 
	round(sum(case
		when promo_type IN ('50% OFF','BOGOF') then (base_price/2)*quantity_sold_after_promo
        when promo_type = '25% OFF' then (base_price/4)*quantity_sold_after_promo
        when promo_type = '33% OFF' then (base_price*(1-0.33))*quantity_sold_after_promo
        else (base_price * quantity_sold_after_promo)- 500
	end)/1000000,1) as revenue_after_promo
from fact_events fe
group by promo_type)
select *,((revenue_after_promo-revenue_before_promo)) as IR,
dense_rank() over(order by ((revenue_after_promo-revenue_before_promo)) desc) as r
from cte;

-- Which promo types strikes balance between Units sold and maintaining healthy margins
with cte_1 as (select promo_type,round(sum(base_price * quantity_sold_before_promo)/1000000,1) as revenue_before_promo, 
	round(sum(case
		when promo_type IN ('50% OFF','BOGOF') then (base_price/2)*quantity_sold_after_promo
        when promo_type = '25% OFF' then (base_price/4)*quantity_sold_after_promo
        when promo_type = '33% OFF' then (base_price*(1-0.33))*quantity_sold_after_promo
        else (base_price * quantity_sold_after_promo)- 500
	end)/1000000,1) as revenue_after_promo
from fact_events fe
group by promo_type),
cte_2 as (select promo_type, (quantity_sold_after_promo-quantity_sold_before_promo) as Inc_sold_units,
dense_rank() over(order by (quantity_sold_after_promo-quantity_sold_before_promo)) as re from
fact_events
group by promo_type)
select cte_2.*,((revenue_after_promo-revenue_before_promo)) as IR,
dense_rank() over(order by ((revenue_after_promo-revenue_before_promo)) desc) as r
from cte_1 join cte_2
on cte_1.promo_type=cte_2.promo_type;
/* 500 cashback and BOGOF are the two promo_types that stike balance between
Units sold and revenue*/

-- Product and category analysis
-- Which product categories saw most significant lift in sales from promotions
select dp.category, (quantity_sold_after_promo-quantity_sold_before_promo) as Inc_sold_units,
dense_rank() over(order by (quantity_sold_after_promo-quantity_sold_before_promo) desc) as re from
fact_events f
join dim_products dp on
dp.product_code = f.product_code
group by 1;
/*Combo 1 responds exceptionally well to promotions whereas 
Grocery and Staples category responds poorly to promotions*/






