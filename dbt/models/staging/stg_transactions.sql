{#
    Очищенные транзакции: одна строка на транзакцию, единые имена колонок и типы,
    суррогатные ключи транзакции и клиента, календарные и вычисляемые поля.
#}

with source as (

    select * from {{ source('transactions_db', 'transactions') }}

),

cleaned as (

    select
        transaction_time,
        -- технический префикс `fraud_` есть у всех мерчантов, к названию он не относится
        trim(replaceRegexpOne(merch, '^fraud_', '')) as merchant_name,
        lower(trim(cat_id)) as category,
        round(toFloat64(amount), 2) as amount,
        trim(name_1) as first_name,
        trim(name_2) as last_name,
        upper(trim(gender)) as gender,
        trim(street) as street,
        trim(one_city) as city,
        upper(trim(us_state)) as us_state,
        -- индекс хранился числом и потерял ведущие нули (02861 -> 2861)
        leftPad(toString(post_code), 5, '0') as post_code,
        toFloat64(lat) as customer_lat,
        toFloat64(lon) as customer_lon,
        toUInt32(population_city) as city_population,
        trim(jobs) as job,
        toFloat64(merchant_lat) as merchant_lat,
        toFloat64(merchant_lon) as merchant_lon,
        toUInt8(target) as is_fraud
    from source

)

select
    -- в источнике нет id: транзакцию однозначно задают время, клиент, мерчант и сумма
    {{ dbt_utils.generate_surrogate_key([
        'transaction_time', 'first_name', 'last_name', 'street', 'merchant_name', 'amount'
    ]) }} as transaction_id,
    -- имя клиента не уникально (956 имён на 965 клиентов), поэтому ключ включает адрес
    {{ dbt_utils.generate_surrogate_key(['first_name', 'last_name', 'street', 'post_code']) }} as customer_id,

    transaction_time,
    toDate(transaction_time) as transaction_date,
    toHour(transaction_time) as transaction_hour,
    {{ dbt_date.day_of_week('transaction_time', isoweek=true) }} as day_of_week,
    {{ dbt_date.day_name('transaction_time', short=false) }} as day_name,
    {{ dbt_date.day_of_week('transaction_time', isoweek=true) }} in (6, 7) as is_weekend,

    merchant_name,
    category,
    amount,
    {{ amount_bucket('amount') }} as amount_bucket,
    amount >= {{ var('large_amount_threshold') }} as is_large_amount,

    first_name,
    last_name,
    gender,
    street,
    city,
    us_state,
    post_code,
    customer_lat,
    customer_lon,
    city_population,
    job,
    merchant_lat,
    merchant_lon,
    -- расстояние по дуге большого круга между клиентом и мерчантом, км
    round(greatCircleDistance(customer_lon, customer_lat, merchant_lon, merchant_lat) / 1000, 2)
        as distance_to_merchant_km,

    is_fraud
from cleaned
