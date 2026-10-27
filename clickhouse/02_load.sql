-- Загрузка train.csv в таблицу-источник. Повторный запуск не дублирует данные:
-- таблица сначала очищается.
-- FROM INFILE читает файл на стороне clickhouse-client, поэтому скрипт запускается
-- внутри контейнера, где каталог data/ смонтирован в /data.
-- Время в CSV без секунд («2019-12-27 15:21»), поэтому best_effort-разбор даты.

TRUNCATE TABLE transactions_db.transactions;

INSERT INTO transactions_db.transactions
FROM INFILE '/data/train.csv'
SETTINGS date_time_input_format = 'best_effort'
FORMAT CSVWithNames;

SELECT count() AS loaded_rows FROM transactions_db.transactions;
