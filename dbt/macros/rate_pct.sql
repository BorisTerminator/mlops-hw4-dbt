{#
    Доля в процентах с округлением; при нулевом знаменателе возвращает 0, а не inf/nan.
    Пример: {{ rate_pct('sum(is_fraud)', 'count()') }}
#}
{% macro rate_pct(numerator, denominator, precision=2) -%}
    if({{ denominator }} = 0, 0, round(100.0 * {{ numerator }} / {{ denominator }}, {{ precision }}))
{%- endmacro %}
