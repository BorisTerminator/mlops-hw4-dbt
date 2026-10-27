# Полный цикл с нуля: make install up load all
# На Windows: mingw32-make (идёт с MinGW) или make из Git for Windows / MSYS2.

ifeq ($(OS),Windows_NT)
    BIN := .venv/Scripts
else
    BIN := .venv/bin
endif

PYTHON ?= python
DBT := $(BIN)/dbt
DBT_FLAGS := --project-dir dbt --profiles-dir dbt
SQLFLUFF := $(BIN)/sqlfluff
DOCS_PORT ?= 8080

# Git Bash иначе переписывает /sql/... в аргументах docker в windows-пути
export MSYS_NO_PATHCONV := 1

.PHONY: help install up load down deps seed run test unit-test build docs docs-serve lint fix pre-commit all clean

help:
	@echo "install     - создать .venv и поставить dbt, sqlfluff, pre-commit"
	@echo "up / down   - поднять / остановить ClickHouse (down удаляет данные)"
	@echo "load        - залить data/train.csv в transactions_db.transactions"
	@echo "deps        - dbt deps: dbt_utils, dbt_date, dbt_expectations"
	@echo "seed run    - загрузить справочник штатов / собрать модели"
	@echo "test        - все тесты: generic, singular, unit"
	@echo "unit-test   - только unit-тесты"
	@echo "build       - seed + run + test в порядке DAG"
	@echo "docs        - сгенерировать dbt Docs; docs-serve - открыть на :$(DOCS_PORT)"
	@echo "lint / fix  - sqlfluff по моделям и тестам"
	@echo "pre-commit  - установить хуки и прогнать их по всем файлам"
	@echo "all         - deps + seed + run + test"

install:
	$(PYTHON) -m venv .venv
	$(BIN)/python -m pip install --upgrade pip
	$(BIN)/pip install -r requirements.txt

up:
	docker compose up -d --wait

load:
	docker compose exec -T clickhouse clickhouse-client --queries-file /sql/02_load.sql

down:
	docker compose down -v

deps:
	$(DBT) deps $(DBT_FLAGS)

seed:
	$(DBT) seed $(DBT_FLAGS)

run:
	$(DBT) run $(DBT_FLAGS)

test:
	$(DBT) test $(DBT_FLAGS)

unit-test:
	$(DBT) test $(DBT_FLAGS) --select test_type:unit

build:
	$(DBT) build $(DBT_FLAGS)

docs:
	$(DBT) docs generate $(DBT_FLAGS)

docs-serve: docs
	$(DBT) docs serve $(DBT_FLAGS) --port $(DOCS_PORT)

lint:
	$(SQLFLUFF) lint dbt/models dbt/tests

fix:
	$(SQLFLUFF) fix dbt/models dbt/tests

pre-commit:
	$(BIN)/pre-commit install
	$(BIN)/pre-commit run --all-files

all: deps seed run test

clean:
	$(DBT) clean $(DBT_FLAGS)
