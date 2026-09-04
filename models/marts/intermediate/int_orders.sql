with

orders as (

    select *
    from {{ ref('stg_jaffle_shop__orders') }}

),

payments as (

    select *
    from {{ ref('stg_stripe__payment') }}

    where payment_status <> 'fail'

),

completed_payments as (

    select
        payments.order_id,
        max(
            payments.payment_created
        ) as payment_finalized_date,
        sum(
            payments.payment_amount
        ) as total_amount_paid

    from payments

    group by
        payments.order_id

),

paid_orders as (

    select
        orders.order_id,
        orders.customer_id,
        orders.order_date,
        orders.order_status,
        orders.valid_order_date,
        completed_payments.total_amount_paid,
        completed_payments.payment_finalized_date

    from orders

    left join completed_payments
        on orders.order_id = completed_payments.order_id

)

select *
from paid_orders