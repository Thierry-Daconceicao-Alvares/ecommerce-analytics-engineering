{{ config(severity='warn') }}

select distinct sales.order_id
from {{ ref('stg_sales') }} as sales
left join {{ ref('stg_orders') }} as orders
    on sales.order_id = orders.order_id
where orders.order_id is null
