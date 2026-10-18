with orders as (

    select
        order_date,
        customer_id,
        order_id,
        order_net_sales
    from {{ ref('stg_orders') }}

),

sales_by_order as (

    select
        order_id,
        qty_product,
        product_count,
        sales_line_count,
        sales_net_sales
    from {{ ref('int_sales_by_order') }}

)

select
    o.order_date,
    o.customer_id,
    o.order_id,
    o.order_net_sales,

    coalesce(s.qty_product, 0) as qty_product,
    coalesce(s.product_count, 0) as product_count,
    coalesce(s.sales_line_count, 0) as sales_line_count,
    coalesce(s.sales_net_sales, cast(0 as numeric)) as sales_net_sales,

    o.order_net_sales
    - coalesce(s.sales_net_sales, cast(0 as numeric))
        as sales_reconciliation_difference

from orders as o
left join sales_by_order as s
    on o.order_id = s.order_id
