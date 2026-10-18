# Looker semantic layer

This directory contains the LookML semantic layer of the project. It exposes
the dbt mart `fct_orders_dashboard` as a governed Explore, so that every
dashboard and ad-hoc analysis uses the same metric definitions.

## Files

- `manifest.lkml`: project constants (`gcp_project`, `analytics_dataset`) that
  locate the dbt marts in BigQuery.
- `ecommerce.model.lkml`: Looker model and `orders` Explore.
- `views/orders.view.lkml`: dimensions, measures and semantic logic.

## Source and grain

The `orders` view reads:

```text
`@{gcp_project}.@{analytics_dataset}.fct_orders_dashboard`
```

The mart has one row per order, so `order_id` is declared as the primary key.
Every measure is therefore safe from fan-out.

## Semantic segmentation

The user-facing `customer_segment` dimension is derived in LookML from
`previous_orders_12m`:

- `0` previous order: `New`
- `1` to `3` previous orders: `Returning`
- `4` or more previous orders: `VIP`
- unavailable history (2025 orders): `Not available`

The raw dbt field `order_segmentation` stays available as a hidden technical
field for reconciliation and debugging. Orders without history are labelled
`Not available` rather than being silently counted as `New`.

## Measures

Orders, Unique Customers, Total Revenue, Average Order Value, Total Units Sold,
Average Units per Order and Average Product References per Order. An
`Analysis Metric` parameter switches a single field between revenue, orders and
units for guided exploration.

## Deployment checklist

1. Add this directory to the Looker project repository.
2. Set `gcp_project` and `analytics_dataset` in `manifest.lkml`.
3. Replace `REPLACE_WITH_LOOKER_CONNECTION_NAME` in `ecommerce.model.lkml` with
   the name of the BigQuery connection configured in Looker.
4. Validate the LookML, commit and deploy.
5. In the `Orders` Explore, check revenue and order counts against the dbt marts
   and the `customer_segment` distribution against `fct_orders_2026_segmented`.
6. Test the `Analysis Metric` parameter.

## Known limitation

The BigQuery project used for the validated run has no billing enabled and
expires tables and partitions after 60 days, so the dbt marts are views. In a
production project they would be partitioned and clustered tables.
