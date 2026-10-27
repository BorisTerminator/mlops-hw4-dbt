{{ config(order_by='(transaction_date, us_state)') }}

with transactions as (

    select * from {{ ref('stg_transactions') }}

),

states as (

    select * from {{ ref('states') }}

),

daily as (

    select
        transaction_date,
        us_state,
        count() as transactions_count,
        uniqExact(customer_id) as unique_customers,
        round(sum(amount), 2) as total_amount,
        round(avg(amount), 2) as avg_amount,
        round({{ percentile('amount', 0.95) }}, 2) as p95_amount,
        countIf(is_large_amount) as large_transactions_count,
        {{ rate_pct('countIf(is_large_amount)', 'count()') }} as large_transactions_share_pct,
        sum(is_fraud) as fraud_count,
        {{ rate_pct('sum(is_fraud)', 'count()') }} as fraud_rate_pct
    from transactions
    group by transaction_date, us_state

)

select
    daily.transaction_date,
    daily.us_state,
    states.state_name,
    states.region,
    daily.transactions_count,
    daily.unique_customers,
    daily.total_amount,
    daily.avg_amount,
    daily.p95_amount,
    daily.large_transactions_count,
    daily.large_transactions_share_pct,
    daily.fraud_count,
    daily.fraud_rate_pct
from daily
left join states on daily.us_state = states.state_code
