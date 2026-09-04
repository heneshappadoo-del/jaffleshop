with

-- Import CTEs

customers as (

    select *
    from {{ ref('stg_jaffle_shop__customers') }}

),

orders as (

    select *
    from {{ ref('stg_jaffle_shop__orders') }}

),

payments as (

    select *
    from {{ ref('stg_stripe__payments') }}

),

-- Marts

order_payments as (

    select
        payments.order_id,
        max(
            payments.payment_created_at
        ) as payment_finalized_date,
        sum(
            payments.payment_amount
        ) as total_amount_paid

    from payments

    where payments.payment_status <> 'fail'

    group by
        payments.order_id

),

paid_orders as (

    select
        orders.order_id,
        orders.customer_id,
        orders.order_placed_at,
        orders.order_status,
        order_payments.total_amount_paid,
        order_payments.payment_finalized_date,
        customers.givenname as customer_first_name,
        customers.surname as customer_last_name,
        orders.transaction_seq,
        orders.customer_sales_seq,
        orders.new_vs_returning as nvsr,
        orders.first_order_date as fdos

    from orders

    left join order_payments
        on orders.order_id = order_payments.order_id

    left join customers
        on orders.customer_id = customers.customer_id

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
        paid_orders.transaction_seq,
        paid_orders.customer_sales_seq,
        paid_orders.nvsr,

        -- Calculate the running lifetime value for each customer
        sum(
            paid_orders.total_amount_paid
        ) over (
            partition by paid_orders.customer_id
            order by
                paid_orders.order_placed_at,
                paid_orders.order_id
            rows between unbounded preceding and current row
        ) as customer_lifetime_value,

        paid_orders.fdos

    from paid_orders

)

select *
from final