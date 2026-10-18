# E-commerce marketing dashboard specification

## Objective

Provide a daily view of e-commerce order performance for business and marketing
stakeholders.

The dashboard should help users understand:

- how order volume evolves over time;
- how revenue and average order value evolve;
- how many units are sold per order;
- how customer segments contribute to performance;
- where additional investigation may be needed.

## Target users

- Marketing managers;
- Growth and CRM teams;
- E-commerce business owners;
- Analytics and BI stakeholders.

## Primary data source

```text
<gcp_project>.ecommerce_analytics_dev.fct_orders_dashboard
```

The same mart is exposed in Looker through the `orders` Explore
(see `looker/README.md`) and declared as a dbt exposure.

The source grain is:

```text
one row per order
```

## Global filters

- Order date;
- Customer segment;
- Customer ID;
- Order year;
- Complete history window.

The customer segment filter should clearly distinguish:

- New;
- Returning;
- VIP;
- Not available.

## KPI cards

The first row should contain:

1. Total orders;
2. Unique customers;
3. Total revenue;
4. Average order value;
5. Total units sold;
6. Average units per order.

All KPI definitions must remain consistent with the LookML semantic layer.

## Recommended dashboard sections

### 1. Daily performance trend

A time-series chart showing:

- order date;
- order count;
- total revenue.

Purpose:

- identify daily peaks and declines;
- detect unusual changes in performance;
- compare recent activity with the previous period.

### 2. Customer segment performance

A stacked bar or column chart showing:

- customer segment;
- order count;
- total revenue;
- average order value.

Purpose:

- understand the contribution of New, Returning and VIP customers;
- identify whether growth is acquisition-driven or retention-driven.

Segmentation is available for 2026. Historical orders without a complete segmentation
history must not be silently interpreted as New customers.

### 3. Monthly order volume

A monthly column chart showing:

- month;
- number of orders.

Known result:

- November has the highest order volume, with 389 orders.

### 4. Average units per order

A monthly line chart showing:

- month;
- average units sold per order.

Known results:

- March has the highest average, with 15.10 units per order;
- November has the lowest average, with 10.48 units per order.

This contrast should be investigated because November has the highest order volume
but the lowest average number of units per order.

### 5. Data quality and coverage note

The dashboard should display a visible note:

- data starts on 2025-07-09;
- 2025 is a partial year;
- segmentation is available for 2026;
- one orphan order exists in `sales` but not in `orders`;
- the orphan order is `5361303`.

## Business questions

The dashboard should help answer:

- Are orders increasing or decreasing over time?
- Is growth driven by new or returning customers?
- Are VIP customers contributing a disproportionate share of revenue?
- Does higher order volume correspond to larger baskets?
- Which periods require further marketing investigation?
- Is the observed trend supported by complete historical data?

## Important analytical limitations

The data does not contain:

- sessions;
- marketing channels;
- campaign IDs;
- ad spend;
- impressions;
- clicks;
- conversion denominators.

Therefore, the dashboard must not claim:

- campaign ROI;
- channel attribution;
- conversion rate;
- causal marketing impact.

These analyses would require additional source data.

## Design principle

The dashboard should prioritize:

```text
Decision usefulness > visual density
```

Each chart should answer a specific business question and should expose the
relevant dimensions for drill-down.
