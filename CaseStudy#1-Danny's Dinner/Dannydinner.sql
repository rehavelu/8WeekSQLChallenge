# What is the total amount each customer spent at the restaurant?
select customer_id,SUM(price) as total_amount
from sales s
join menu m
using(product_id)
group by customer_id;

#How many days has each customer visited the restaurant?
select customer_id,COUNT(order_date) as No_of_visits
from sales s
group by customer_id;

#What was the first item from the menu purchased by each customer?
with cte_product as
( select s.customer_id,m.product_id,product_name,
row_number()OVER (PARTITION BY customer_id ORDER BY order_date)row_a
from sales s
join menu m
using(product_id)
)
select customer_id, product_id,product_name from cte_product
where row_a=1;

#What is the most purchased item on the menu and how many times was it purchased by all customers?
select product_id,COUNT(product_id) AS no_of_occurences
from sales
group by product_id
order by no_of_occurences desc 
limit 1;

#Which item was the most popular for each customer?
with cte as(
select customer_id,product_id,COUNT(product_id) as cnt
from sales
group by customer_id,product_id
),
cte_rank as (select *,dense_rank() over(partition by customer_id order by cnt desc) as rnk
from cte)
select c.customer_id,c.product_id,m.product_name,c.cnt
from cte_rank c
left join menu m
on c.product_id=m.product_id
where c.rnk=1
group by c.customer_id,c.product_id,m.product_name;

 # Which item was purchased first by the customer after they became a member?
with cte as(
select s.customer_id,s.product_id,s.order_date,m.join_date,
dense_rank() over(partition by s.customer_id order by order_date) as rnk
from sales s 
join members m
on s.customer_id=m.customer_id
and s.order_date>=m.join_date)

select r.customer_id,r.order_date,p.product_name
from cte r
join menu p
on r.product_id=p.product_id
where rnk=1;

#Which item was purchased just before the customer became a member?
with cte as(
select s.customer_id,s.product_id,s.order_date,m.join_date,
dense_rank() over(partition by s.customer_id order by order_date desc) as rnk
from sales s 
join members m
on s.customer_id=m.customer_id
and s.order_date<m.join_date)

select r.customer_id,r.order_date,r.join_date,p.product_name
from cte r
join menu p
on r.product_id=p.product_id
where rnk=1;

#What is the total items and amount spent for each member before they became a member?
with cte as(
select s.customer_id,s.product_id,s.order_date,m.join_date
from sales s 
join members m
on s.customer_id=m.customer_id
and s.order_date<m.join_date)

select r.customer_id,Count(p.product_name)as Item_count,SUM(price) as total_amount
from cte r
join menu p
on r.product_id=p.product_id
group by customer_id;

#If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
with cte as (
select *,(case when product_name='sushi' then 2*10*price
             else 10*price
	    end) as points
from menu)
select customer_id,SUM(cte.points) as total_amount
from cte 
join sales s
on cte.product_id=s.product_id
group by customer_id;

#In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
with cte as(
select customer_id,join_date,date_add(join_date, interval 6 day) as Discount_date,
last_day('2021-01-01') as last_date
from  members m
)
select s.customer_id,
 sum(case
  when m.product_name = 'sushi' then 2 * 10 * m.price
  when s.order_date between cte.join_date and cte.discount_date then 2 * 10 * m.price
  else 10 * m.price
  end) as points
from cte
join sales s
 on cte.customer_id = s.customer_id
join menu m
 on s.product_id = m.product_id
where s.order_date < cte.last_date
group by s.customer_id;

#bonus 1
select s.customer_id,s.order_date,p.product_name,p.price,
(case when s.order_date>=m.join_date then 'Y'
	  else 'N'
end) as member
from sales s
left join menu p
on s.product_id=p.product_id
left join members m
on s.customer_id=m.customer_id
order by customer_id;

#bonus 2
with cte as (
select s.customer_id,s.order_date,p.product_name,p.price,
case when s.order_date>=m.join_date then 'Y'
	  else 'N'
end as member
from sales s
left join menu p
on s.product_id=p.product_id
left join members m
on s.customer_id=m.customer_id
)
select * ,case when cte.member='Y' then dense_rank() over( partition by customer_id,cte.member order by order_date)
               else null
          end as ranking
from cte
order by 1,2