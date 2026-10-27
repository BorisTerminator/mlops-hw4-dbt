-- fraud_rate_pct во всех витринах — процент, он обязан лежать в [0, 100].
-- Выход за границы — признак ошибки в числителе или знаменателе rate_pct.

{% set marts = [
    'mart_daily_state_metrics',
    'mart_fraud_by_category',
    'mart_fraud_by_state',
    'mart_customer_risk_profile',
    'mart_hourly_fraud_pattern',
    'mart_merchant_analytics',
] %}

{% for mart in marts %}
    select
        '{{ mart }}' as mart,
        fraud_rate_pct
    from {{ ref(mart) }}
    where fraud_rate_pct < 0 or fraud_rate_pct > 100 or isNaN(fraud_rate_pct)
    {% if not loop.last %}union all{% endif %}
{% endfor %}
