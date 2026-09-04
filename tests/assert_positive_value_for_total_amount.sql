select *
from {{ ref('stg_stripe__payment') }}

where payment_amount < 0