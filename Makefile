DBT_ARGS := --profiles-dir profiles --target local

.PHONY: help setup data build lint fix docs clean

help:  ## List the available commands
	@grep -E '^[a-z]+:.*## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "} {printf "  %-8s %s\n", $$1, $$2}'

setup:  ## Install the Python dependencies
	pip install -r requirements.txt

data:  ## Generate the synthetic sample dataset in DuckDB
	python scripts/generate_sample_data.py

build: data  ## Build and test every model on DuckDB
	dbt build $(DBT_ARGS)

lint:  ## Lint SQL models and tests
	sqlfluff lint models tests

fix:  ## Auto-format SQL models and tests
	sqlfluff fix models tests

docs: data  ## Generate and serve the dbt documentation site
	dbt docs generate $(DBT_ARGS) && dbt docs serve $(DBT_ARGS)

clean:  ## Remove build artifacts and the local database
	rm -rf target dbt_packages logs ecommerce.duckdb
