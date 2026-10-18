{{ config(severity='error') }}

select
    order_id,
    product_id,
    count(*) as duplicate_count
from {{ ref('stg_sales') }}
group by
    order_id,
    product_id
having count(*) > 1
