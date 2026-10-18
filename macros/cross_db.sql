{#-
    Cross-database helpers.

    The project was built and validated on BigQuery. Every `default__`
    implementation emits exactly the BigQuery SQL that was validated, while the
    `duckdb__` implementations let the same models run locally and in CI on
    DuckDB with the synthetic sample data.
-#}


{#- Date shifted back by a number of months. -#}
{% macro months_before(date_expr, months) -%}
    {{ return(adapter.dispatch('months_before')(date_expr, months)) }}
{%- endmacro %}

{% macro default__months_before(date_expr, months) -%}
    date_sub({{ date_expr }}, interval {{ months }} month)
{%- endmacro %}

{% macro duckdb__months_before(date_expr, months) -%}
    cast({{ date_expr }} - interval {{ months }} month as date)
{%- endmacro %}


{#- Date shifted forward by a number of months. -#}
{% macro months_after(date_expr, months) -%}
    {{ return(adapter.dispatch('months_after')(date_expr, months)) }}
{%- endmacro %}

{% macro default__months_after(date_expr, months) -%}
    date_add({{ date_expr }}, interval {{ months }} month)
{%- endmacro %}

{% macro duckdb__months_after(date_expr, months) -%}
    cast({{ date_expr }} + interval {{ months }} month as date)
{%- endmacro %}


{#- First day of the month of a date, returned as a date. -#}
{% macro truncate_to_month(date_expr) -%}
    {{ return(adapter.dispatch('truncate_to_month')(date_expr)) }}
{%- endmacro %}

{% macro default__truncate_to_month(date_expr) -%}
    date_trunc({{ date_expr }}, month)
{%- endmacro %}

{% macro duckdb__truncate_to_month(date_expr) -%}
    cast(date_trunc('month', {{ date_expr }}) as date)
{%- endmacro %}


{#- Full English month name, e.g. 'November'. -#}
{% macro format_month_name(date_expr) -%}
    {{ return(adapter.dispatch('format_month_name')(date_expr)) }}
{%- endmacro %}

{% macro default__format_month_name(date_expr) -%}
    format_date('%B', {{ date_expr }})
{%- endmacro %}

{% macro duckdb__format_month_name(date_expr) -%}
    strftime({{ date_expr }}, '%B')
{%- endmacro %}


{#- One row per month of the given year, in a column named month_start. -#}
{% macro month_calendar(year) -%}
    {{ return(adapter.dispatch('month_calendar')(year)) }}
{%- endmacro %}

{% macro default__month_calendar(year) -%}
    select month_start
    from unnest(
        generate_date_array(
            date('{{ year }}-01-01'),
            date('{{ year }}-12-01'),
            interval 1 month
        )
    ) as month_start
{%- endmacro %}

{% macro duckdb__month_calendar(year) -%}
    select cast(generate_series as date) as month_start
    from generate_series(
        date '{{ year }}-01-01',
        date '{{ year }}-12-01',
        interval 1 month
    )
{%- endmacro %}
