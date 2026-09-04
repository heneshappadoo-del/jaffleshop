with

source as (

    select *
    from {{ source('jaffle_shop', 'orders') }}

),

transformed as (

    select
        id as order_id,
        user_id as customer_id,
        order_date as order_placed_at,
        status as order_status,

        -- Sequence of every transaction
        row_number() over (
            order by id
        ) as transaction_seq,

        -- Sequence of sales for each customer
        row_number() over (
            partition by user_id
            order by
                order_date,
                id
        ) as customer_sales_seq,

        -- Identify new versus returning customers
        case
            when (
                row_number() over (
                    partition by user_id
                    order by
                        order_date,
                        id
                )
            ) = 1
                then 'new'
            else 'return'
        end as new_vs_returning,

        -- Find the first order date for each customer
        first_value(order_date) over (
            partition by user_id
            order by
                order_date,
                id
        ) as first_order_date

    from source

)

select *
from transformed