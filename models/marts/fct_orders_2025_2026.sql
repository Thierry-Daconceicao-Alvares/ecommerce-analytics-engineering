{{ config(materialized='view') }}

select
    order_date,
    customer_id,
    order_id,
    order_net_sales,
    qty_product
from {{ ref('int_orders_enriched') }}
where
    order_date >= date '2025-01-01'
    and order_date < date '2027-01-01'
