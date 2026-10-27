{{ config(order_by='(day_of_week, transaction_hour)') }}

with transactions as (

    select * from {{ ref('stg_transactions') }}

),

by_window as (

    select
        day_of_week,
        transaction_hour,
        any(day_name) as day_name,
        any(is_weekend) as is_weekend,
        count() as transactions_count,
        sum(is_fraud) as fraud_count,
        round(avg(amount), 2) as avg_amount,
        round(if(sum(is_fraud) = 0, 0, avgIf(amount, is_fraud = 1)), 2) as avg_fraud_amount
    from transactions
    group by day_of_week, transaction_hour

),

with_lift as (

    select
        *,
        {{ rate_pct('fraud_count', 'transactions_count') }} as fraud_rate_pct,
        -- во сколько раз фрод в этом окне выше, чем в среднем за всю неделю
        round(
            (fraud_count / transactions_count)
            / (sum(fraud_count) over () / sum(transactions_count) over ()),
            2
        ) as fraud_lift
    from by_window

)

select
    day_of_week,
    day_name,
    is_weekend,
    transaction_hour,
    transactions_count,
    fraud_count,
    fraud_rate_pct,
    avg_amount,
    avg_fraud_amount,
    fraud_lift,
    fraud_lift >= {{ var('high_risk_window_multiplier') }} as is_high_risk_window,
    row_number() over (order by fraud_lift desc, day_of_week asc, transaction_hour asc) as risk_rank
from with_lift
