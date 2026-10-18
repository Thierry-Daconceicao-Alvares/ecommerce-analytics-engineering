with all_orders as (

    select
        order_id,
        customer_id,
        order_date
    from {{ ref('int_orders_enriched') }}

),

orders_2026 as (

    select
        order_id,
        customer_id,
        order_date
    from all_orders
    where
        order_date >= date '2026-01-01'
        and order_date < date '2027-01-01'

),

available_history as (

    select min(order_date) as first_available_order_date
    from all_orders

),

order_history as (

    select
        current_order.order_id,
        count(previous_order.order_id) as previous_orders_12m
    from orders_2026 as current_order
    left join all_orders as previous_order
        on
            current_order.customer_id = previous_order.customer_id
            and previous_order.order_date
            >= {{ months_before('current_order.order_date', 12) }}
            and previous_order.order_date < current_order.order_date
    group by current_order.order_id

)

select
    current_order.order_id,
    current_order.customer_id,
    current_order.order_date,

    {{ months_before('current_order.order_date', 12) }}
        as history_window_start,

    current_order.order_date as history_window_end_exclusive,

    history.previous_orders_12m,

    current_order.order_date
    >= {{ months_after('available_history.first_available_order_date', 12) }}
        as history_window_complete

from orders_2026 as current_order
inner join order_history as history
    on current_order.order_id = history.order_id
cross join available_history
