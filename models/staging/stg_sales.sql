with source_data as (
    select
        date_date,
        customer_id,
        order_id,
        products_id,
        net_sales,
        qty
    from {{ source('raw_ecommerce', 'sales') }}
),

renamed as (
    select
        cast(date_date as date) as order_date,
        cast(customer_id as int64) as customer_id,
        cast(order_id as int64) as order_id,
        cast(products_id as int64) as product_id,
        cast(net_sales as numeric) as line_net_sales,
        cast(qty as int64) as quantity
    from source_data
)

select
    order_date,
    customer_id,
    order_id,
    product_id,
    line_net_sales,
    quantity
from renamed
