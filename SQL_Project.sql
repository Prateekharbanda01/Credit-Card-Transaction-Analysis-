select * 
from credit_card_transactions;

/*1- write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends*/

-- TECHNIQUE 1 -- In technique 1 we use subquery--

select top 5 city, sum(amount) as total_amount, sum(amount) * 1.0 * 100/sum(cast(sum(amount) as bigint)) over() as per_contri
from credit_card_transactions
group by city
order by total_amount desc;

                                         -- OR --

-- TECHNIQUE 2 -- In technique 2 we use window function --

select top 5 city,sum(amount) as total ,sum(amount)*1.0*100/sum(cast(sum(amount) as bigint)) over() as per_contri
from credit_card_transactions
group by city
order by total desc;

/*2- write a query to print highest spend month and amount spent in that month for each card type*/

with cte as (
select card_type,DATEPART(year, transaction_Date) as year_trans,datepart(month,transaction_Date) as month_trans
,sum(amount) as total_amount
from credit_card_transactions
group by card_type, DATEPART(year, transaction_Date), datepart(month,transaction_Date)
)

select * from(
select *, rank() over(partition by card_type order by total_amount desc) as rn 
from cte) a
where rn = 1;

/*3- write a query to print the transaction details(all columns from the table) for each card type when it reaches a 
cumulative of 10,00,000 total spends(We should have 4 rows in the o/p one for each card type)*/

with cte as (
select *,sum(amount) over(partition by card_type order by transaction_Date, transaction_id) as total_amount
from credit_card_transactions
)
select * from (
select *, rank() over(partition by card_type order by total_amount) as rn
from cte 
where total_amount >= 1000000) a
where rn = 1;

/*4- write a query to find city which had lowest percentage spend for gold card type*/

select city,sum(amount) as total,sum(case when card_type = 'Gold' then amount end) as total_gold_amount
,sum(case when card_type = 'Gold' then amount end) * 1.0 * 100/sum(amount) as per_spent
from credit_card_transactions
group by city
having sum(case when card_type = 'Gold' then amount end) is not null
order by per_spent ;

/*5- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)*/

with cte as (
select City,exp_type,sum(amount) as total_amount
from credit_card_transactions
group by City,exp_type)

select distinct(city) 
,FIRST_VALUE(exp_type) over(partition by city order by total_amount) as lowest_expense_type
,FIRST_VALUE(exp_type) over(partition by city order by total_amount) as highest_expense_type
from cte
order by City;

/*6- write a query to find percentage contribution of spends by females for each expense type*/

select exp_type,sum(amount) as total_amount,sum(case when gender = 'F' then amount end) as female_expense
,sum(case when gender = 'F' then amount end) *1.0*100 / sum(amount) as per_spent
from credit_card_transactions
group by exp_type
order by per_spent;

/*7- which card and expense type combination saw highest month over month growth in Jan-2014*/

with cte as (
select card_type,exp_type,sum(amount)as total_spent,datepart(year,transaction_Date) as yt
,datepart(month,transaction_Date) as mt
from credit_card_transactions
group by card_type,exp_type,datepart(year,transaction_Date),datepart(month,transaction_Date)
)
select top 1 * , (total_spent - prev_month_spent) as mom_growth 
from (
select *,lag(total_spent,1) over(partition by card_type,exp_type order by yt,mt) as prev_month_spent
from cte) a
where prev_month_spent is not null and yt = 2014 and mt = 1
order by mom_growth desc;

/*8- during weekends which city has highest total spend to total no of transcations, ratio*/

select top 1 City, sum(amount)*1.0/ count(*) as ratio
from credit_card_transactions
where DATEPART(weekday,transaction_Date) in (1,7)
group by City
order by city desc;

/*9 - which city took least number of days to reach its 500th transaction after first transaction in that city*/

with cte as (
select *,ROW_NUMBER() over(partition by city order by transaction_Date, transaction_id) as rn
from credit_card_transactions
)
select top 1 city,min(transaction_Date) as first_date,max(transaction_Date) as fiv_hundred_date
,DATEDIFF(day,min(transaction_Date),max(transaction_Date)) as day_diff
from cte
where rn in (1,500)
group by City
having count(*) = 2
order by day_diff;




