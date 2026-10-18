with orders_enriched as (

    select
        order_date,
        customer_id,
        order_id,
        order_net_sales,
        qty_product,
        product_count,
        sales_line_count,
        sales_net_sales,
        sales_reconciliation_difference
    from {{ ref('int_orders_enriched') }}

),

customer_order_history as (

    select
        order_id,
        previous_orders_12m,
        history_window_start,
        history_window_end_exclusive,
        history_window_complete
    from {{ ref('int_customer_order_history') }}

)

select
    o.order_date,
    o.customer_id,
    o.order_id,
    o.order_net_sales,
    o.qty_product,
    o.product_count,
    o.sales_line_count,
    o.sales_net_sales,
    o.sales_reconciliation_difference,

    h.previous_orders_12m,
    h.history_window_start,
    h.history_window_end_exclusive,
    h.history_window_complete,

    case
        when h.previous_orders_12m = 0 then 'New'
        when h.previous_orders_12m between 1 and 3 then 'Returning'
        when h.previous_orders_12m >= 4 then 'VIP'
        else 'Unknown'
    end as order_segmentation

from orders_enriched as o
inner join customer_order_history as h
    on o.order_id = h.order_id
