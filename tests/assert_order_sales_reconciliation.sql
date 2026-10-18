{{ config(severity='error') }}

select
    order_id,
    order_net_sales,
    sales_net_sales,
    sales_reconciliation_difference
from {{ ref('int_orders_enriched') }}
where
    sales_net_sales is null
    or abs(sales_reconciliation_difference) > 0.01
