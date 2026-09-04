{% macro grant_select(
    role_name=target.role,
    database=target.database,
    schema=target.schema
) %}

    {% set grant_tables_sql %}

        grant select on all tables in schema
            {{ database }}.{{ schema }}
        to role {{ role_name }}

    {% endset %}

    {% set grant_views_sql %}

        grant select on all views in schema
            {{ database }}.{{ schema }}
        to role {{ role_name }}

    {% endset %}

    {% set grant_future_tables_sql %}

        grant select on future tables in schema
            {{ database }}.{{ schema }}
        to role {{ role_name }}

    {% endset %}

    {% set grant_future_views_sql %}

        grant select on future views in schema
            {{ database }}.{{ schema }}
        to role {{ role_name }}

    {% endset %}

    {{ log(
        'Granting select on existing tables in '
        ~ database ~ '.' ~ schema
        ~ ' to role ' ~ role_name,
        info=true
    ) }}

    {% call statement(
        'grant_existing_tables',
        fetch_result=false
    ) %}

        {{ grant_tables_sql }}

    {% endcall %}

    {{ log(
        'Granting select on existing views in '
        ~ database ~ '.' ~ schema
        ~ ' to role ' ~ role_name,
        info=true
    ) }}

    {% call statement(
        'grant_existing_views',
        fetch_result=false
    ) %}

        {{ grant_views_sql }}

    {% endcall %}

    {{ log(
        'Granting select on future tables in '
        ~ database ~ '.' ~ schema
        ~ ' to role ' ~ role_name,
        info=true
    ) }}

    {% call statement(
        'grant_future_tables',
        fetch_result=false
    ) %}

        {{ grant_future_tables_sql }}

    {% endcall %}

    {{ log(
        'Granting select on future views in '
        ~ database ~ '.' ~ schema
        ~ ' to role ' ~ role_name,
        info=true
    ) }}

    {% call statement(
        'grant_future_views',
        fetch_result=false
    ) %}

        {{ grant_future_views_sql }}

    {% endcall %}

    {{ log(
        'Select grants completed successfully for role '
        ~ role_name,
        info=true
    ) }}

{% endmacro %}