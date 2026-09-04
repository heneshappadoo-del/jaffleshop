{{ config(
    materialized='incremental',
    unique_key='order_id',
    incremental_strategy='merge'
) }}

with orders as (

    select *
    from {{ ref('stg_jaffle_shop__orders') }}

),

payments as (

    select *
    from {{ ref('stg_stripe__payment') }}

),

order_payments as (

    select
        order_id,
        sum(payment_amount) as amount

    from payments

    where payment_status <> 'fail'

    group by 1

),

final as (

    select
        orders.order_id,
        orders.customer_id,
        orders.order_date,
        coalesce(order_payments.amount, 0) as amount

    from orders

    left join order_payments
        on orders.order_id = order_payments.order_id

    {% if is_incremental() %}

        where orders.order_date >
        (
            select coalesce(
                max(order_date),
                to_date('1900-01-01')
            )
            from {{ this }}
        )

    {% endif %}

)

select *
from final