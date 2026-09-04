select *
from {{ ref('fct_customer_orders') }}

{{ limit_data_in_dev(10) }}