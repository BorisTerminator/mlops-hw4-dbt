-- Таблица-источник для dbt: те же транзакции, что в ДЗ №2 (train.csv, 786 431 строка).
-- Типы взяты из схемы задания: строки как есть, суммы и координаты Float64, target UInt8.
-- Чистка и нормализация - забота staging-слоя dbt, здесь данные лежат «сырыми».

CREATE DATABASE IF NOT EXISTS transactions_db;

CREATE TABLE IF NOT EXISTS transactions_db.transactions
(
    transaction_time DateTime,
    merch            String,
    cat_id           String,
    amount           Float64,
    name_1           String,
    name_2           String,
    gender           String,
    street           String,
    one_city         String,
    us_state         String,
    post_code        UInt32,
    lat              Float64,
    lon              Float64,
    population_city  UInt32,
    jobs             String,
    merchant_lat     Float64,
    merchant_lon     Float64,
    target           UInt8
)
ENGINE = MergeTree
ORDER BY (us_state, transaction_time);
