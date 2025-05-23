{% test less_than_or_equal_to(model, column_name, value) %}

select
    {{ column_name }} as value_field
from {{ model }}
where {{ column_name }} is not null
    and {{ column_name }} <= {{ value }}

{% endtest %}
