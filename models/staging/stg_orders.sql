with source_data as (
    select
        date_date,
        customers_id,
        orders_id,
        net_sales
    from {{ source('raw_ecommerce', 'orders') }}
),

renamed as (
    select
        cast(date_date as date) as order_date,
        cast(customers_id as int64) as customer_id,
        cast(orders_id as int64) as order_id,
        cast(net_sales as numeric) as order_net_sales
    from source_data
)

select
    order_date,
    customer_id,
    order_id,
    order_net_sales
from renamed
