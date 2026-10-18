{{ config(materialized='view') }}

with orders_2025 as (

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
        cast(null as int64) as previous_orders_12m,
        cast(null as date) as history_window_start,
        cast(null as date) as history_window_end_exclusive,
        cast(null as bool) as history_window_complete,
        cast(null as string) as order_segmentation
    from {{ ref('int_orders_enriched') }}
    where
        order_date >= date '2025-01-01'
        and order_date < date '2026-01-01'

),

orders_2026 as (

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
        previous_orders_12m,
        history_window_start,
        history_window_end_exclusive,
        history_window_complete,
        order_segmentation
    from {{ ref('fct_orders_2026_segmented') }}
    where
        order_date >= date '2026-01-01'
        and order_date < date '2027-01-01'

)

select * from orders_2025

union all

select * from orders_2026
