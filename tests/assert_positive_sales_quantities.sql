{{ config(severity='error') }}

select
    order_id,
    product_id,
    quantity
from {{ ref('stg_sales') }}
where quantity <= 0
