# Validation

This folder holds the automated validation suite. It builds the database from scratch and checks the data and the business rules. The [validation protocol](../docs/VALIDATION.md) defines the steps and pass criteria.

```text
validation/
├── README.md         This file
├── validate.sh       Runs the full validation
├── checks.sql        Data checks
├── triggers.sql      Trigger tests
└── known_gaps.sql    Probes for rules the schema doesn't enforce
```

## How to run

You need Docker, Python 3, and OpenSSL. From the repository root, run:

```bash
./validation/validate.sh
```

The last line of the output is `RESULT: PASS` or `RESULT: FAIL`, and the exit code is `0` or `1` to match. Failed checks show the expected and actual values.

## Files

### `validate.sh`

Runs every step in order:

1. Regenerates the sample data and confirms it matches `seed_data.sql`.
2. Starts a temporary SQL Server container, then loads the schema and the data.
3. Runs `checks.sql` and compares the results.
4. Runs `triggers.sql` and compares the results.
5. Runs the seed again and confirms it's refused.
6. Runs `known_gaps.sql` and prints the results.

The container has a random password and publishes no ports, and the script removes it on exit. Your other databases aren't touched. To test another SQL Server version, set `MSSQL_IMAGE`.

### `checks.sql`

Runs 40 read-only checks on the loaded data:

- **Row counts:** the number of rows in each table.
- **Consistency:** rules the data must follow, where the expected number of violations is 0.
- **Edge cases:** the number of deliberate data problems.
- **Reference metrics:** known totals and the patterns built into the data.

Each row of output has the format `section|check|expected|actual`, and a check passes when the last two values are equal.

### `triggers.sql`

Attempts one invalid change for each of the five triggers, and each attempt must fail with its expected error. It then confirms that the row counts didn't change. The script expects freshly loaded data, because `validate.sh` runs it on the temporary database.

### `known_gaps.sql`

Attempts four changes that should arguably be invalid but that the schema may accept. It rolls back each attempt and reports `OPEN` if the change was accepted or `CLOSED` if it was blocked. These results don't affect the overall result.

## Adding a check

- **Data check:** add a row to `checks.sql` in the same four-column format.
- **Trigger test:** add a block to `triggers.sql` that prints `trigger|name|expected error|actual error`.

Then add it to [`../docs/VALIDATION.md`](../docs/VALIDATION.md), including any change to the check counts.
