{% set analysis_year = var('analysis_year', 2026) %}

{{ config(materialized='view') }}

with calendar as (
    {{ month_calendar(analysis_year) }}
),

monthly_products as (
    select
        {{ truncate_to_month('order_date') }} as month_start,
        count(*) as number_of_orders,
        round(avg(qty_product), 2) as average_products_per_order
    from {{ ref('fct_orders_2025_2026') }}
    where
        order_date >= date('{{ analysis_year }}-01-01')
        and order_date < date('{{ analysis_year + 1 }}-01-01')
    group by month_start
)

select
    extract(month from calendar.month_start) as month_number,
    {{ format_month_name('calendar.month_start') }} as month_name,
    coalesce(monthly_products.number_of_orders, 0) as number_of_orders,
    monthly_products.average_products_per_order
from calendar
left join monthly_products
    on calendar.month_start = monthly_products.month_start
order by month_number
