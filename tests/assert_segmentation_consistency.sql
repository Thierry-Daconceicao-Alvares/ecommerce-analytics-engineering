{{ config(severity='error') }}

select
    order_id,
    previous_orders_12m,
    order_segmentation
from {{ ref('int_orders_segmented') }}
where
    (order_segmentation = 'New' and previous_orders_12m != 0)
    or (
        order_segmentation = 'Returning'
        and (previous_orders_12m < 1 or previous_orders_12m > 3)
    )
    or (order_segmentation = 'VIP' and previous_orders_12m < 4)
