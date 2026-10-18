{% set analysis_year = var('analysis_year', 2026) %}

{{ config(materialized='view') }}

select
    {{ analysis_year }} as analysis_year,
    count(*) as number_of_orders
from {{ ref('fct_orders_2025_2026') }}
where
    order_date >= date('{{ analysis_year }}-01-01')
    and order_date < date('{{ analysis_year + 1 }}-01-01')
