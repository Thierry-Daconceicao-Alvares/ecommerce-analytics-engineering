with sales as (

    select
        order_id,
        product_id,
        quantity,
        line_net_sales
    from {{ ref('stg_sales') }}

),

aggregated as (

    select
        order_id,
        sum(quantity) as qty_product,
        count(distinct product_id) as product_count,
        count(*) as sales_line_count,
        sum(line_net_sales) as sales_net_sales
    from sales
    group by order_id

)

select
    order_id,
    qty_product,
    product_count,
    sales_line_count,
    sales_net_sales
from aggregated
