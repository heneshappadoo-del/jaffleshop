{% macro generate_surrogate_key(column_name) %}

    md5(cast({{ column_name }} as varchar))

{% endmacro %}