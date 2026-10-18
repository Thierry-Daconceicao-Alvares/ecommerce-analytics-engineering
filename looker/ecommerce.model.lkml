connection: "REPLACE_WITH_LOOKER_CONNECTION_NAME"

include: "/views/*.view.lkml"

label: "E-commerce Analytics"

explore: orders {
  label: "Orders"
  description: >
    Explore for daily analysis of 2026 orders, revenue, units sold and
    customer segmentation. The underlying view contains one row per order.
}
