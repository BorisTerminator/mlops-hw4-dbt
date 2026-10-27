{{ config(order_by='customer_id') }}

with transactions as (

    select * from {{ ref('stg_transactions') }}

),

customer_categories as (

    select
        customer_id,
        category,
        count() as category_transactions
    from transactions
    group by customer_id, category

),

top_category as (

    -- любимая категория клиента: та, где у него больше всего транзакций
    select
        customer_id,
        argMax(category, category_transactions) as top_category
    from customer_categories
    group by customer_id

),

customers as (

    -- атрибуты клиента одинаковы во всех его транзакциях, any() берёт любое из значений
    select
        customer_id,
        any(first_name) as first_name,
        any(last_name) as last_name,
        any(gender) as gender,
        any(city) as city,
        any(us_state) as us_state,
        any(job) as job,
        min(transaction_time) as first_transaction_at,
        max(transaction_time) as last_transaction_at,
        count() as transactions_count,
        round(sum(amount), 2) as total_amount,
        round(avg(amount), 2) as avg_amount,
        round(max(amount), 2) as max_amount,
        sum(is_fraud) as fraud_count,
        round(sumIf(amount, is_fraud = 1), 2) as fraud_amount,
        if(sum(is_fraud) = 0, null, maxIf(transaction_time, is_fraud = 1)) as last_fraud_at
    from transactions
    group by customer_id

),

scored as (

    select
        customers.*,
        top_category.top_category,
        dateDiff('day', customers.first_transaction_at, customers.last_transaction_at) + 1 as active_days,
        {{ rate_pct('customers.fraud_count', 'customers.transactions_count') }} as fraud_rate_pct
    from customers
    inner join top_category on customers.customer_id = top_category.customer_id

)

select
    customer_id,
    first_name,
    last_name,
    gender,
    city,
    us_state,
    job,
    top_category,
    first_transaction_at,
    last_transaction_at,
    active_days,
    transactions_count,
    total_amount,
    avg_amount,
    max_amount,
    fraud_count,
    fraud_amount,
    fraud_rate_pct,
    last_fraud_at,
    case
        when fraud_rate_pct >= {{ var('risk_high_fraud_rate_pct') }} then 'HIGH'
        when fraud_rate_pct >= {{ var('risk_medium_fraud_rate_pct') }} then 'MEDIUM'
        else 'LOW'
    end as risk_segment
from scored
