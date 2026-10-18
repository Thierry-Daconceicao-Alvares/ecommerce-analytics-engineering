{{ config(materialized='view') }}

select
    order_date,
    customer_id,
    order_id,
    order_net_sales,
    qty_product,
    product_count,
    sales_line_count,
    sales_net_sales,
    sales_reconciliation_difference,
    history_window_start,
    history_window_end_exclusive,
    previous_orders_12m,
    history_window_complete,
    order_segmentation
from {{ ref('int_orders_segmented') }}
where
    order_date >= date '2026-01-01'
    and order_date < date '2027-01-01'
