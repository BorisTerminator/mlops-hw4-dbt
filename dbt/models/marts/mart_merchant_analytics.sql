{{ config(order_by='merchant_name') }}

with transactions as (

    select * from {{ ref('stg_transactions') }}

),

merchant_categories as (

    select
        merchant_name,
        category,
        count() as category_transactions
    from transactions
    group by merchant_name, category

),

primary_category as (

    -- у 7 мерчантов по две категории; основная та, где больше транзакций
    select
        merchant_name,
        argMax(category, category_transactions) as primary_category,
        count() as categories_count
    from merchant_categories
    group by merchant_name

),

merchants as (

    select
        merchant_name,
        count() as transactions_count,
        uniqExact(customer_id) as unique_customers,
        round(sum(amount), 2) as turnover,
        round(avg(amount), 2) as avg_amount,
        sum(is_fraud) as fraud_count,
        round(sumIf(amount, is_fraud = 1), 2) as fraud_amount,
        min(transaction_date) as first_transaction_date,
        max(transaction_date) as last_transaction_date
    from transactions
    group by merchant_name

),

with_lift as (

    select
        merchants.*,
        primary_category.primary_category,
        primary_category.categories_count,
        {{ rate_pct('merchants.fraud_count', 'merchants.transactions_count') }} as fraud_rate_pct,
        -- во сколько раз уровень фрода у мерчанта выше среднего по всем мерчантам
        round(
            (merchants.fraud_count / merchants.transactions_count)
            / (sum(merchants.fraud_count) over () / sum(merchants.transactions_count) over ()),
            2
        ) as fraud_lift
    from merchants
    inner join primary_category on merchants.merchant_name = primary_category.merchant_name

)

select
    merchant_name,
    primary_category,
    categories_count,
    first_transaction_date,
    last_transaction_date,
    transactions_count,
    unique_customers,
    turnover,
    avg_amount,
    fraud_count,
    fraud_amount,
    fraud_rate_pct,
    fraud_lift,
    (
        fraud_lift >= {{ var('suspicious_merchant_fraud_multiplier') }}
        and transactions_count >= {{ var('suspicious_merchant_min_transactions') }}
    ) as is_suspicious
from with_lift
