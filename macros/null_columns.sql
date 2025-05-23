{%- macro null_columns(column_list) -%}
    {%- for column in column_list -%}
        null as {{ column }}{% if not loop.last %},{% endif %}
    {%- endfor -%}
{%- endmacro -%}