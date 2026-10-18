{% docs __overview__ %}

# E-commerce Analytics Engineering

dbt project that turns raw e-commerce orders and sales lines into tested,
documented marts, consumed by a LookML semantic layer and a Looker Studio
dashboard.

**Layers**

- `staging`: typed and renamed copies of the two sources.
- `intermediate`: sales aggregated to the order grain, reconciliation against
  orders, twelve-month purchase history and customer segmentation.
- `marts`: order facts, the dashboard mart and the reporting models.

**Key rules**

- `orders` is the authoritative source for the order grain; sales lines are
  aggregated per order before any join to prevent fan-out.
- `qty_product` is the total number of units in an order, not the number of
  product references.
- A 2026 order is `New` (0 previous orders in the past 12 months),
  `Returning` (1 to 3) or `VIP` (4 or more).

Source code and full documentation: see the repository README.

{% enddocs %}
