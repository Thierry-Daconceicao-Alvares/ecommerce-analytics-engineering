# Project-level constants: the BigQuery location of the dbt marts is configured
# here once instead of being hard-coded in every view.

constant: gcp_project {
  value: "your-gcp-project-id"
  export: override_optional
}

constant: analytics_dataset {
  value: "ecommerce_analytics_dev"
  export: override_optional
}
