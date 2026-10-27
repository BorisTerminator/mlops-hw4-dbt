{#
    Реализация dbt_expectations.regexp_instr для ClickHouse: в пакете её нет,
    а функции regexp_instr в ClickHouse не существует. Подхватывается через dispatch
    (см. блок dispatch в dbt_project.yml).

    Тесты пакета сравнивают результат с нулём (> 0 — совпало, = 0 — нет), поэтому
    хватает match(), который возвращает 1/0. Флаги re2 передаются в начале шаблона: (?i).
#}
{% macro clickhouse__regexp_instr(source_value, regexp, position, occurrence, is_raw, flags) %}
    {%- if position != 1 or occurrence != 1 -%}
        {{ exceptions.raise_compiler_error(
            "clickhouse__regexp_instr supports only position=1 and occurrence=1"
        ) }}
    {%- endif -%}
    {%- if flags -%}
        {{ dbt_expectations._validate_re2_flags(flags) }}
        {%- set regexp = "(?" ~ flags ~ ")" ~ regexp -%}
    {%- endif -%}
    match({{ source_value }}, '{{ regexp }}')
{% endmacro %}
