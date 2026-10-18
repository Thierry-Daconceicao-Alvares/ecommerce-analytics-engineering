view: orders {
  label: "Orders 2025-2026"
  description: "One row per order for the 2025-2026 order and customer segmentation analysis."

  sql_table_name: `@{gcp_project}.@{analytics_dataset}.fct_orders_dashboard` ;;

  dimension: order_id {
    label: "Order ID"
    description: "Unique identifier of the order."
    primary_key: yes
    type: number
    sql: ${TABLE}.order_id ;;
    value_format_name: id
  }

  dimension: customer_id {
    label: "Customer ID"
    description: "Identifier of the customer who placed the order."
    type: number
    sql: ${TABLE}.customer_id ;;
    value_format_name: id
  }

  dimension_group: order_date {
    label: "Order Date"
    description: "Date on which the order was placed."
    type: time
    timeframes: [
      raw,
      date,
      week,
      month,
      quarter,
      year
    ]
    sql: ${TABLE}.order_date ;;
  }

  dimension: order_segmentation {
    label: "Order Segmentation - Raw"
    description: >
      Technical segmentation value produced by the dbt transformation layer.
      The user-facing semantic definition is exposed through customer_segment.
    hidden: yes
    type: string
    sql: ${TABLE}.order_segmentation ;;
    suggestions: ["New", "Returning", "VIP"]
  }

  dimension: customer_segment {
    label: "Customer Segment"
    description: >
      Semantic customer segment derived from the number of previous orders
      placed by the customer during the twelve months preceding the current
      order. Orders from 2025 do not have a complete segmentation history.
    type: string
    sql:
      CASE
        WHEN ${previous_orders_12m} IS NULL THEN 'Not available'
        WHEN ${previous_orders_12m} = 0 THEN 'New'
        WHEN ${previous_orders_12m} BETWEEN 1 AND 3 THEN 'Returning'
        WHEN ${previous_orders_12m} >= 4 THEN 'VIP'
        ELSE 'Not available'
      END ;;
    suggestions: ["New", "Returning", "VIP", "Not available"]
  }

  dimension: previous_orders_12m {
    label: "Previous Orders - 12 Months"
    description: >
      Number of orders placed by the same customer during the twelve months
      preceding the current order.
    type: number
    sql: ${TABLE}.previous_orders_12m ;;
    value_format_name: decimal_0
  }

  dimension: history_window_complete {
    label: "Complete History Window"
    description: >
      Indicates whether the complete twelve-month history is available for
      the current order.
    type: yesno
    sql: ${TABLE}.history_window_complete ;;
  }

  dimension: qty_product {
    label: "Units Sold"
    description: "Total number of units sold in the order."
    type: number
    sql: ${TABLE}.qty_product ;;
    value_format_name: decimal_0
  }

  dimension: product_count {
    label: "Product References"
    description: "Number of distinct product references in the order."
    type: number
    sql: ${TABLE}.product_count ;;
    value_format_name: decimal_0
  }

  dimension: sales_line_count {
    label: "Sales Lines"
    description: "Number of product lines associated with the order."
    type: number
    sql: ${TABLE}.sales_line_count ;;
    value_format_name: decimal_0
  }

  dimension: order_net_sales {
    label: "Order Net Sales"
    description: "Net sales amount of the order."
    type: number
    sql: ${TABLE}.order_net_sales ;;
    value_format_name: decimal_2
  }

  parameter: analysis_metric {
    label: "Analysis Metric"
    description: >
      Select the metric to use for conversational analysis or exploratory
      analysis.
    type: unquoted

    allowed_value: {
      label: "Revenue"
      value: revenue
    }

    allowed_value: {
      label: "Orders"
      value: orders
    }

    allowed_value: {
      label: "Units Sold"
      value: units
    }
  }

  dimension: selected_analysis_metric {
    label: "Selected Analysis Metric"
    description: >
      Dynamic metric selected through the Analysis Metric parameter. This field
      is hidden from the standard field picker and is intended for guided
      exploration.
    hidden: yes
    type: number
    sql:
      {% if analysis_metric._parameter_value == 'revenue' %}
        ${order_net_sales}
      {% elsif analysis_metric._parameter_value == 'orders' %}
        1
      {% else %}
        ${qty_product}
      {% endif %} ;;
    value_format_name: decimal_2
  }

  measure: orders_count {
    label: "Orders"
    description: "Count of orders. The view grain is one row per order."
    type: count
    drill_fields: [
      order_id,
      customer_id,
      order_date_date,
      order_segmentation,
      order_net_sales
    ]
  }

  measure: customers_count {
    label: "Unique Customers"
    description: "Number of distinct customers with at least one order."
    type: count_distinct
    sql: ${customer_id} ;;
  }

  measure: total_revenue {
    label: "Total Revenue"
    description: "Sum of order net sales."
    type: sum
    sql: ${order_net_sales} ;;
    value_format_name: decimal_2
  }

  measure: average_order_value {
    label: "Average Order Value"
    description: "Average net sales amount per order."
    type: average
    sql: ${order_net_sales} ;;
    value_format_name: decimal_2
  }

  measure: total_units_sold {
    label: "Total Units Sold"
    description: "Sum of all units sold across orders."
    type: sum
    sql: ${qty_product} ;;
    value_format_name: decimal_0
  }

  measure: average_units_per_order {
    label: "Average Units per Order"
    description: "Average number of units sold per order."
    type: average
    sql: ${qty_product} ;;
    value_format_name: decimal_2
  }

  measure: average_product_references_per_order {
    label: "Average Product References per Order"
    description: "Average number of distinct product references per order."
    type: average
    sql: ${product_count} ;;
    value_format_name: decimal_2
  }
}
