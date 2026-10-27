{{ config(order_by='us_state') }}

with transactions as (

    select * from {{ ref('stg_transactions') }}

),

states as (

    select * from {{ ref('states') }}

),

by_state as (

    select
        us_state,
        count() as transactions_count,
        sum(is_fraud) as fraud_count,
        uniqExact(customer_id) as unique_customers,
        uniqExactIf(customer_id, is_fraud = 1) as fraud_victim_customers,
        uniqExact(merchant_name) as unique_merchants,
        uniqExactIf(merchant_name, is_fraud = 1) as fraud_merchants,
        round(sum(amount), 2) as total_amount,
        round(sumIf(amount, is_fraud = 1), 2) as fraud_amount,
        round(avg(amount), 2) as avg_amount
    from transactions
    group by us_state

)

select
    by_state.us_state,
    states.state_name,
    states.region,
    states.division,
    by_state.transactions_count,
    by_state.fraud_count,
    {{ rate_pct('by_state.fraud_count', 'by_state.transactions_count') }} as fraud_rate_pct,
    by_state.unique_customers,
    by_state.fraud_victim_customers,
    by_state.unique_merchants,
    by_state.fraud_merchants,
    by_state.total_amount,
    by_state.fraud_amount,
    {{ rate_pct('by_state.fraud_amount', 'by_state.total_amount') }} as fraud_amount_share_pct,
    by_state.avg_amount,
    row_number() over (
        order by by_state.fraud_count / by_state.transactions_count desc
    ) as fraud_rate_rank
from by_state
left join states on by_state.us_state = states.state_code
