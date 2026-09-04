WITH paid_orders AS (

    SELECT
        Orders.ID AS order_id,
        Orders.USER_ID AS customer_id,
        Orders.ORDER_DATE AS order_placed_at,
        Orders.STATUS AS order_status,
        p.total_amount_paid,
        p.payment_finalized_date,
        C.FIRST_NAME AS customer_first_name,
        C.LAST_NAME AS customer_last_name

    FROM {{ source('jaffle_shop', 'orders') }} AS Orders

    LEFT JOIN (

        SELECT
            ORDERID AS order_id,
            MAX(CREATED) AS payment_finalized_date,
            SUM(AMOUNT) / 100.0 AS total_amount_paid

        FROM {{ source('stripe', 'payment') }}

        WHERE STATUS <> 'fail'

        GROUP BY 1

    ) p
        ON Orders.ID = p.order_id

    LEFT JOIN {{ source('jaffle_shop', 'customers') }} C
        ON Orders.USER_ID = C.ID

),

customer_orders AS (

    SELECT
        C.ID AS customer_id,
        MIN(ORDER_DATE) AS first_order_date,
        MAX(ORDER_DATE) AS most_recent_order_date,
        COUNT(Orders.ID) AS number_of_orders

    FROM {{ source('jaffle_shop', 'customers') }} C

    LEFT JOIN {{ source('jaffle_shop', 'orders') }} AS Orders
        ON Orders.USER_ID = C.ID

    GROUP BY 1

)

SELECT
    p.*,
    ROW_NUMBER() OVER (ORDER BY p.order_id) AS transaction_seq,
    ROW_NUMBER() OVER (
        PARTITION BY customer_id
        ORDER BY p.order_id
    ) AS customer_sales_seq,

    CASE
        WHEN c.first_order_date = p.order_placed_at
        THEN 'new'
        ELSE 'return'
    END AS nvsr,

    x.clv_bad AS customer_lifetime_value,
    c.first_order_date AS fdos

FROM paid_orders p

LEFT JOIN customer_orders c
    USING (customer_id)

LEFT OUTER JOIN (

    SELECT
        p.order_id,
        SUM(t2.total_amount_paid) AS clv_bad

    FROM paid_orders p

    LEFT JOIN paid_orders t2
        ON p.customer_id = t2.customer_id
       AND p.order_id >= t2.order_id

    GROUP BY 1

) x
    ON x.order_id = p.order_id

ORDER BY order_id