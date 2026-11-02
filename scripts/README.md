# Scripts

This folder holds the script that generates the sample data.

```text
scripts/
├── README.md           This file
└── generate_seed.py    Sample data generator
```

## Files

### `generate_seed.py`

Generates [`../seed_data.sql`](../seed_data.sql), the SQL script that fills the database with sample data. It needs Python 3 and no extra packages.

Run it from the repository root and pass the output path:

```bash
python3 scripts/generate_seed.py seed_data.sql
```

The script defines:

- **Roles, employees, and projects:** fixed lists at the top of the file, including each project's dates, team, and task count.
- **Tasks, work records, and reviews:** generated for each project. Reviews can reject a task, which leads to more work and another review.
- **Patterns:** deliberate signals for analysis, such as an overloaded engineer and a project in trouble.
- **Edge cases:** deliberate data problems, such as `NULL` results and zero-hour records. Comments marked `planted` show where patterns and edge cases are added.

A fixed random seed and a fixed snapshot date (`2026-11-02`) mean that the same script always produces the same file.

### After changing the generator

Any change to the generator can change the data, so:

1. Regenerate `seed_data.sql`.
2. Run [`../validation/validate.sh`](../validation/README.md).
3. Review any failed checks. If the new values are intended, update the expected values in the validation files and in [`../docs/VALIDATION.md`](../docs/VALIDATION.md).
