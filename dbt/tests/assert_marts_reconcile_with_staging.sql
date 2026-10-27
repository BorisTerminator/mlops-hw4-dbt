-- Каждая витрина — это разбиение всех транзакций на группы, поэтому сумма числа
-- транзакций и фродов по строкам витрины должна совпасть со staging.
-- Расхождение означает, что join или фильтр потерял либо размножил строки.

{% set marts = [
    'mart_daily_state_metrics',
    'mart_fraud_by_category',
    'mart_fraud_by_state',
    'mart_customer_risk_profile',
    'mart_hourly_fraud_pattern',
    'mart_merchant_analytics',
] %}

with staging as (

    select
        count() as transactions_count,
        sum(is_fraud) as fraud_count
    from {{ ref('stg_transactions') }}

),

marts as (

    {% for mart in marts %}
        select
            '{{ mart }}' as mart,
            sum(transactions_count) as transactions_count,
            sum(fraud_count) as fraud_count
        from {{ ref(mart) }}
        {% if not loop.last %}union all{% endif %}
    {% endfor %}

)

select
    marts.mart,
    marts.transactions_count,
    staging.transactions_count as expected_transactions_count,
    marts.fraud_count,
    staging.fraud_count as expected_fraud_count
from marts
cross join staging
where
    marts.transactions_count != staging.transactions_count
    or marts.fraud_count != staging.fraud_count
