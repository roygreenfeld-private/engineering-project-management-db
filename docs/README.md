# Documentation

This folder holds the reference documents for the database.

```text
docs/
├── README.md        This file
├── VALIDATION.md    Validation protocol
└── erd.png          Entity relationship diagram
```

## Files

### `VALIDATION.md`

The protocol that defines how the project is validated. It covers:

- how to run the validation
- the pass criteria for each step
- every data check and its expected value
- the trigger tests and their expected errors
- rules the schema doesn't enforce yet
- the latest validation result

Update it whenever you add a check or change an expected value in [`../validation/`](../validation/README.md).

### `erd.png`

The entity relationship diagram. It shows the seven tables, their columns and types, their primary and foreign keys, and how they relate to each other.

The diagram is a static image, so it doesn't update when the schema changes. If the two ever differ, [`../database.sql`](../database.sql) is correct. The diagram currently misspells one column as `task_prirority`; the actual name is `task_priority`.
