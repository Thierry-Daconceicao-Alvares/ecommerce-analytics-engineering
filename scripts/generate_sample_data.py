"""Generate a synthetic e-commerce dataset with the schema of the original sources.

The original dataset cannot be redistributed. This script builds a
deterministic, realistic sample so that anyone can run the full dbt project
locally on DuckDB, and so that CI can build and test every model on each push.

The figures quoted in the README come from the original dataset on BigQuery,
not from this sample.

Usage:
    python scripts/generate_sample_data.py                  # writes ecommerce.duckdb
    python scripts/generate_sample_data.py --csv-dir data   # also exports CSV files
"""

from __future__ import annotations

import argparse
import csv
import datetime as dt
import os
import random
import tempfile
from dataclasses import dataclass
from decimal import ROUND_HALF_UP, Decimal
from pathlib import Path

import duckdb

START_DATE = dt.date(2025, 7, 9)  # first order date of the original dataset
END_DATE = dt.date(2026, 12, 31)
CENT = Decimal("0.01")

# Relative order volume by month: classic retail seasonality, peak in November.
MONTH_WEIGHTS = {
    1: 0.85,
    2: 0.80,
    3: 0.95,
    4: 0.90,
    5: 0.95,
    6: 0.90,
    7: 0.85,
    8: 0.80,
    9: 0.95,
    10: 1.05,
    11: 1.45,
    12: 1.30,
}

ORDERS_DDL = """
    create or replace table {schema}.orders (
        date_date date,
        customers_id bigint,
        orders_id bigint,
        net_sales decimal(12, 2)
    )
"""
SALES_DDL = """
    create or replace table {schema}.sales (
        date_date date,
        customer_id bigint,
        order_id bigint,
        products_id bigint,
        net_sales decimal(12, 2),
        qty bigint
    )
"""


@dataclass(frozen=True)
class Product:
    product_id: int
    unit_price: Decimal
    popularity: float


def geometric(rng: random.Random, p: float, cap: int) -> int:
    """Number of failures before the first success, capped."""
    k = 0
    while rng.random() > p and k < cap:
        k += 1
    return k


def build_catalog(rng: random.Random, size: int) -> list[Product]:
    catalog = []
    for rank in range(1, size + 1):
        price = Decimal(str(max(1.5, rng.lognormvariate(2.2, 0.55)))).quantize(CENT)
        catalog.append(Product(1000 + rank, price, 1 / rank**0.9))
    return catalog


def customer_order_dates(rng: random.Random, span_days: int) -> list[dt.date]:
    """Order dates of one customer: first order on activation, then a seasonal Poisson process."""
    activation = START_DATE + dt.timedelta(days=int(rng.uniform(0, span_days * 0.95)))
    rate_per_day = min(0.12, 0.0035 * rng.paretovariate(1.6))
    max_weight = max(MONTH_WEIGHTS.values())

    dates = [activation]
    current = dt.datetime.combine(activation, dt.time())
    end = dt.datetime.combine(END_DATE, dt.time(23, 59))
    while True:
        current += dt.timedelta(days=rng.expovariate(rate_per_day * max_weight))
        if current > end:
            return dates
        if rng.random() < MONTH_WEIGHTS[current.month] / max_weight:  # seasonal thinning
            dates.append(current.date())


def order_lines(rng: random.Random, catalog: list[Product]) -> list[tuple[Product, int]]:
    """Distinct products of one order with their quantities."""
    n_products = 1 + geometric(rng, p=0.35, cap=11)
    weights = [product.popularity for product in catalog]
    chosen: dict[int, Product] = {}
    while len(chosen) < n_products:
        product = rng.choices(catalog, weights=weights)[0]
        chosen.setdefault(product.product_id, product)
    return [(product, 1 + geometric(rng, p=0.30, cap=19)) for product in chosen.values()]


def generate(seed: int, n_customers: int, n_products: int) -> tuple[list[tuple], list[tuple]]:
    rng = random.Random(seed)
    catalog = build_catalog(rng, n_products)
    span_days = (END_DATE - START_DATE).days

    raw_orders = []
    for index in range(n_customers):
        customer_id = 100_001 + index
        raw_orders += [(day, customer_id) for day in customer_order_dates(rng, span_days)]
    raw_orders.sort()

    orders, sales = [], []
    for position, (day, customer_id) in enumerate(raw_orders):
        order_id = 5_100_001 + position
        order_total = Decimal("0.00")
        for product, qty in order_lines(rng, catalog):
            line_total = (product.unit_price * qty).quantize(CENT, rounding=ROUND_HALF_UP)
            order_total += line_total
            sales.append((day, customer_id, order_id, product.product_id, line_total, qty))
        orders.append((day, customer_id, order_id, order_total))

    # One sales line whose order is missing from `orders`, mirroring the data
    # quality issue found in the original data (caught by a warning-level test).
    orphan_product = catalog[0]
    sales.append(
        (
            END_DATE,
            100_001,
            5_100_001 + len(orders),
            orphan_product.product_id,
            orphan_product.unit_price,
            1,
        )
    )
    return orders, sales


def load_duckdb(db_path: Path, schema: str, csv_dir: Path) -> None:
    """Create the raw tables and bulk-load them from the CSV files."""
    with duckdb.connect(str(db_path)) as con:
        con.execute(f"create schema if not exists {schema}")
        for table, ddl in (("orders", ORDERS_DDL), ("sales", SALES_DDL)):
            con.execute(ddl.format(schema=schema))
            csv_path = (csv_dir / f"{table}.csv").as_posix()
            con.execute(
                f"insert into {schema}.{table} select * from read_csv('{csv_path}', header = true)"
            )


def write_csv(csv_dir: Path, orders: list[tuple], sales: list[tuple]) -> None:
    csv_dir.mkdir(parents=True, exist_ok=True)
    files = {
        "orders.csv": (["date_date", "customers_id", "orders_id", "net_sales"], orders),
        "sales.csv": (
            ["date_date", "customer_id", "order_id", "products_id", "net_sales", "qty"],
            sales,
        ),
    }
    for name, (header, rows) in files.items():
        with open(csv_dir / name, "w", newline="", encoding="utf-8") as handle:
            writer = csv.writer(handle)
            writer.writerow(header)
            writer.writerows(rows)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument(
        "--db-path",
        type=Path,
        default=Path(os.environ.get("DUCKDB_PATH", "ecommerce.duckdb")),
        help="DuckDB file to write (default: $DUCKDB_PATH or ecommerce.duckdb)",
    )
    parser.add_argument(
        "--schema", default="ecommerce_raw", help="target schema for the raw tables"
    )
    parser.add_argument("--seed", type=int, default=42, help="random seed (deterministic output)")
    parser.add_argument("--customers", type=int, default=1600, help="number of customers")
    parser.add_argument("--products", type=int, default=400, help="number of products")
    parser.add_argument("--csv-dir", type=Path, help="optional folder to also export CSV files")
    args = parser.parse_args()

    orders, sales = generate(args.seed, args.customers, args.products)
    if args.csv_dir:
        write_csv(args.csv_dir, orders, sales)
        load_duckdb(args.db_path, args.schema, args.csv_dir)
    else:
        with tempfile.TemporaryDirectory() as tmp:
            write_csv(Path(tmp), orders, sales)
            load_duckdb(args.db_path, args.schema, Path(tmp))

    print(
        f"Wrote {len(orders):,} orders and {len(sales):,} sales lines "
        f"({START_DATE} to {END_DATE}) to {args.db_path} [{args.schema}]"
    )


if __name__ == "__main__":
    main()
