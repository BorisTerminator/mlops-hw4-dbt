{#
    Сегмент суммы транзакции: micro / small / medium / large / huge.
    Границы берутся из переменной amount_bucket_bounds в dbt_project.yml,
    верхняя граница сегмента не включается: 10.00 уже small, а не micro.
#}
{% macro amount_bucket(column) -%}
    {%- set bounds = var('amount_bucket_bounds') -%}
    case
        when {{ column }} < {{ bounds['micro'] }} then 'micro'
        when {{ column }} < {{ bounds['small'] }} then 'small'
        when {{ column }} < {{ bounds['medium'] }} then 'medium'
        when {{ column }} < {{ bounds['large'] }} then 'large'
        else 'huge'
    end
{%- endmacro %}
