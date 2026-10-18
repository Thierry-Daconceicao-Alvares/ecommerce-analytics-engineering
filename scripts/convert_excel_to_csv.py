"""Convert the original Excel extracts to CSV files ready to be loaded into BigQuery.

Only needed for the BigQuery run with the original data. The local DuckDB run
uses scripts/generate_sample_data.py instead.

Usage:
    python scripts/convert_excel_to_csv.py --orders path/to/orders.xlsx \
        --sales path/to/sales.xlsx [--output-dir data_for_bigquery]
"""

from __future__ import annotations

import argparse
from pathlib import Path

import pandas as pd


def to_csv(excel_path: Path, output_path: Path, sheet_name: str | int = 0) -> int:
    """Write one Excel sheet to CSV with ISO dates and return the number of rows."""
    frame = pd.read_excel(excel_path, sheet_name=sheet_name)
    frame["date_date"] = pd.to_datetime(frame["date_date"]).dt.strftime("%Y-%m-%d")
    frame.to_csv(output_path, index=False)
    return len(frame)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--orders", type=Path, required=True, help="Excel file with the orders")
    parser.add_argument("--sales", type=Path, required=True, help="Excel file with the sales lines")
    parser.add_argument("--sales-sheet", default="sales", help="sheet name of the sales lines")
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path("data_for_bigquery"),
        help="folder for the CSV files (git-ignored)",
    )
    args = parser.parse_args()

    args.output_dir.mkdir(parents=True, exist_ok=True)
    for name, path, sheet in (("orders", args.orders, 0), ("sales", args.sales, args.sales_sheet)):
        output = args.output_dir / f"{name}.csv"
        print(f"Created {output}: {to_csv(path, output, sheet):,} rows")


if __name__ == "__main__":
    main()
