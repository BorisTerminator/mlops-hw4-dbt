{#
    Точный перцентиль с той же семантикой, что у quantileExact(p)(column) в ClickHouse:
    элемент отсортированного массива с 0-based индексом floor(p * n), т.е. 1-based
    floor(p * n) + 1, но не дальше последнего.

    Сам quantileExact(p)(column) не используется намеренно: sqlfluff (диалект clickhouse)
    не разбирает синтаксис параметрических агрегатов f(params)(args) и падает
    на всей модели с ошибкой PRS.
#}
{% macro percentile(column, p) -%}
    arrayElement(
        arraySort(groupArray({{ column }})),
        least(count({{ column }}), toUInt64(floor({{ p }} * count({{ column }}))) + 1)
    )
{%- endmacro %}
