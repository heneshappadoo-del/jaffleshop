with

-- Import CTEs

customers as (

    select *
    from {{ source('jaffle_shop', 'customers') }}

),

orders as (

    select *
    from {{ source('jaffle_shop', 'orders') }}

),

payments as (

    select *
    from {{ source('stripe', 'payment') }}

),

-- Logical CTEs

order_payments as (

    select
        payments.orderid as order_id,
        max(payments.created) as payment_finalized_date,
        sum(payments.amount) / 100.0 as total_amount_paid

    from payments

    where payments.status <> 'fail'

    group by
        payments.orderid

),

paid_orders as (

    select
        orders.id as order_id,
        orders.user_id as customer_id,
        orders.order_date as order_placed_at,
        orders.status as order_status,
        order_payments.total_amount_paid,
        order_payments.payment_finalized_date,
        customers.first_name as customer_first_name,
        customers.last_name as customer_last_name

    from orders

    left join order_payments
        on orders.id = order_payments.order_id

    left join customers
        on orders.user_id = customers.id

),

-- Final CTE

final as (

    select
        paid_orders.order_id,
        paid_orders.customer_id,
        paid_orders.order_placed_at,
        paid_orders.order_status,
        paid_orders.total_amount_paid,
        paid_orders.payment_finalized_date,
        paid_orders.customer_first_name,
        paid_orders.customer_last_name,

        -- Sequence of all transactions across all customers
        row_number() over (
            order by
                paid_orders.order_id
        ) as transaction_seq,

        -- Sequence of transactions for each individual customer
        row_number() over (
            partition by paid_orders.customer_id
            order by
                paid_orders.order_placed_at,
                paid_orders.order_id
        ) as customer_sales_seq,

        -- Identify whether this is the customer's first order
        case
            when (
                row_number() over (
                    partition by paid_orders.customer_id
                    order by
                        paid_orders.order_placed_at,
                        paid_orders.order_id
                )
            ) = 1
                then 'new'
            else 'return'
        end as nvsr,

        -- Running lifetime value for each customer
        sum(paid_orders.total_amount_paid) over (
            partition by paid_orders.customer_id
            order by
                paid_orders.order_placed_at,
                paid_orders.order_id
            rows between unbounded preceding and current row
        ) as customer_lifetime_value,

        -- Date of the customer's first order
        first_value(paid_orders.order_placed_at) over (
            partition by paid_orders.customer_id
            order by
                paid_orders.order_placed_at,
                paid_orders.order_id
        ) as fdos

    from paid_orders

)

select *
from final