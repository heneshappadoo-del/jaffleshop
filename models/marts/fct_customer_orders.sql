with

customers as (

    select *
    from {{ ref('stg_jaffle_shop__customers') }}

),

orders as (

    select *
    from {{ ref('int_orders') }}

),

customer_orders as (

    select
        orders.*,
        customers.first_name,
        customers.last_name,

        min(orders.valid_order_date) over (
            partition by orders.customer_id
        ) as first_order_date,

        max(orders.valid_order_date) over (
            partition by orders.customer_id
        ) as most_recent_order_date,

        count(*) over (
            partition by orders.customer_id
        ) as order_count,

        sum(
            nvl2(orders.valid_order_date, 1, 0)
        ) over (
            partition by orders.customer_id
        ) as non_returned_order_count,

        sum(
            nvl2(
                orders.valid_order_date,
                orders.total_amount_paid,
                0
            )
        ) over (
            partition by orders.customer_id
        ) as total_lifetime_value

    from orders

    inner join customers
        on orders.customer_id = customers.customer_id

),

add_avg_order_values as (

    select
        customer_orders.*,

        customer_orders.total_lifetime_value
        / nullif(
            customer_orders.non_returned_order_count,
            0
        ) as avg_non_returned_order_value

    from customer_orders

),

final as (

    select
        add_avg_order_values.order_id,
        add_avg_order_values.customer_id,
        add_avg_order_values.order_date as order_placed_at,
        add_avg_order_values.order_status,
        add_avg_order_values.total_amount_paid,
        add_avg_order_values.payment_finalized_date,
        add_avg_order_values.first_name as customer_first_name,
        add_avg_order_values.last_name as customer_last_name,

        row_number() over (
            order by
                add_avg_order_values.order_date,
                add_avg_order_values.order_id
        ) as transaction_seq,

        row_number() over (
            partition by add_avg_order_values.customer_id
            order by
                add_avg_order_values.order_date,
                add_avg_order_values.order_id
        ) as customer_sales_seq,

        case
            when (
                rank() over (
                    partition by add_avg_order_values.customer_id
                    order by
                        add_avg_order_values.order_date,
                        add_avg_order_values.order_id
                )
            ) = 1
                then 'new'
            else 'return'
        end as nvsr,

        sum(
            add_avg_order_values.total_amount_paid
        ) over (
            partition by add_avg_order_values.customer_id
            order by
                add_avg_order_values.order_date,
                add_avg_order_values.order_id
            rows between unbounded preceding and current row
        ) as customer_lifetime_value,

        add_avg_order_values.first_order_date as fdos,
        add_avg_order_values.most_recent_order_date,
        add_avg_order_values.order_count,
        add_avg_order_values.non_returned_order_count,
        add_avg_order_values.total_lifetime_value,
        add_avg_order_values.avg_non_returned_order_value

    from add_avg_order_values

)

select *
from final