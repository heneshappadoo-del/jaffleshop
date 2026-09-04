{% macro limit_data_in_dev(row_count=1000) %}

    {% if target.name == 'default' %}

        limit {{ row_count }}

    {% endif %}

{% endmacro %}