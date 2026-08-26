select *
from {{ ref('stg_stripe__payments') }}
where amount < 0