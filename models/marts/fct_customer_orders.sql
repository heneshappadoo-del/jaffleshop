with

customers as (

    select *
    from {{ ref('stg_jaffle_shop__customers') }}

),

paid_orders as (

    select *
    from {{ ref('int_orders') }}

),

final as (

    select
        paid_orders.order_id,
        paid_orders.customer_id,
        paid_orders.order_date,
        paid_orders.order_status,
        paid_orders.valid_order_date,
        paid_orders.total_amount_paid,
        paid_orders.payment_finalized_date,
        customers.first_name,
        customers.last_name,

        -- Sales transaction sequence
        row_number() over (
            order by
                paid_orders.order_date,
                paid_orders.order_id
        ) as transaction_seq,

        -- Customer sales sequence
        row_number() over (
            partition by paid_orders.customer_id
            order by
                paid_orders.order_date,
                paid_orders.order_id
        ) as customer_sales_seq,

        -- New versus returning customer
        case
            when (
                rank() over (
                    partition by paid_orders.customer_id
                    order by
                        paid_orders.order_date,
                        paid_orders.order_id
                )
            ) = 1
                then 'new'
            else 'return'
        end as nvsr,

        -- Running customer lifetime value
        sum(
            paid_orders.total_amount_paid
        ) over (
            partition by paid_orders.customer_id
            order by
                paid_orders.order_date,
                paid_orders.order_id
            rows between unbounded preceding and current row
        ) as customer_lifetime_value,

        -- First valid day of sale
        first_value(
            paid_orders.valid_order_date
        ) ignore nulls over (
            partition by paid_orders.customer_id
            order by
                paid_orders.order_date,
                paid_orders.order_id
        ) as fdos

    from paid_orders

    left join customers
        on paid_orders.customer_id = customers.customer_id

)

select *
from final