{{ config(order_by='category') }}

with transactions as (

    select * from {{ ref('stg_transactions') }}

),

by_category as (

    select
        category,
        count() as transactions_count,
        sum(is_fraud) as fraud_count,
        count() - sum(is_fraud) as legit_count,
        round(sum(amount), 2) as total_amount,
        round(sumIf(amount, is_fraud = 1), 2) as fraud_amount,
        round(avg(amount), 2) as avg_amount,
        round(if(sum(is_fraud) = 0, 0, avgIf(amount, is_fraud = 1)), 2) as avg_fraud_amount
    from transactions
    group by category

)

select
    category,
    transactions_count,
    fraud_count,
    legit_count,
    {{ rate_pct('fraud_count', 'transactions_count') }} as fraud_rate_pct,
    total_amount,
    fraud_amount,
    {{ rate_pct('fraud_amount', 'total_amount') }} as fraud_amount_share_pct,
    avg_amount,
    avg_fraud_amount,
    -- во сколько раз уровень фрода в категории выше среднего по всем транзакциям
    round(
        (fraud_count / transactions_count)
        / (sum(fraud_count) over () / sum(transactions_count) over ()),
        2
    ) as fraud_lift,
    row_number() over (order by fraud_count / transactions_count desc) as fraud_rate_rank
from by_category
