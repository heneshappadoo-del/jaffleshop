{% macro clean_stale_models(
    database=target.database,
    schema=target.schema,
    days=7,
    dry_run=true
) %}

    {% set get_drop_commands_query %}

        select
            table_name,

            case
                when table_type = 'BASE TABLE'
                    then
                        'drop table if exists '
                        || '"' || table_catalog || '"'
                        || '.'
                        || '"' || table_schema || '"'
                        || '.'
                        || '"' || table_name || '"'

                when table_type = 'VIEW'
                    then
                        'drop view if exists '
                        || '"' || table_catalog || '"'
                        || '.'
                        || '"' || table_schema || '"'
                        || '.'
                        || '"' || table_name || '"'
            end as drop_command

        from {{ database }}.information_schema.tables

        where upper(table_schema) = upper('{{ schema }}')

          and last_altered < dateadd(
              day,
              -{{ days }},
              current_timestamp()
          )

          and table_type in ('BASE TABLE', 'VIEW')

        order by table_name

    {% endset %}

    {{ log(
        '\nGenerating cleanup commands for '
        ~ database ~ '.' ~ schema
        ~ ' older than ' ~ days ~ ' days...\n',
        info=true
    ) }}

    {% if execute %}

        {% set results = run_query(get_drop_commands_query) %}

        {% if results is not none %}

            {% set drop_queries = results.columns[1].values() %}

            {% if drop_queries | length == 0 %}

                {{ log(
                    'No stale tables or views were found.',
                    info=true
                ) }}

            {% endif %}

            {% for drop_query in drop_queries %}

                {% if dry_run %}

                    {{ log(
                        'DRY RUN: ' ~ drop_query,
                        info=true
                    ) }}

                {% else %}

                    {{ log(
                        'Executing: ' ~ drop_query,
                        info=true
                    ) }}

                    {% call statement(
                        'drop_stale_object_' ~ loop.index,
                        fetch_result=false
                    ) %}

                        {{ drop_query }}

                    {% endcall %}

                {% endif %}

            {% endfor %}

            {% if dry_run %}

                {{ log(
                    '\nDry run completed. No database objects were dropped.',
                    info=true
                ) }}

            {% else %}

                {{ log(
                    '\nCleanup completed.',
                    info=true
                ) }}

            {% endif %}

        {% endif %}

    {% endif %}

{% endmacro %}