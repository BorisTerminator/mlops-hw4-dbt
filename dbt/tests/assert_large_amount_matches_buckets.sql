-- Флаг крупной транзакции и сегмент суммы задаются разными переменными
-- (large_amount_threshold и amount_bucket_bounds). Тест следит, чтобы они не разъехались:
-- крупными должны быть ровно сегменты large и huge.

select
    transaction_id,
    amount,
    amount_bucket,
    is_large_amount
from {{ ref('stg_transactions') }}
where is_large_amount != (amount_bucket in ('large', 'huge'))
