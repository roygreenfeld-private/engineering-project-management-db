# Validation Protocol

This protocol checks that the schema builds from scratch, that the sample data is consistent, and that the triggers enforce the business rules. Run it after any change to `database.sql`, `seed_data.sql`, or `scripts/generate_seed.py`.

## How to run

**Requirements:** Docker, Python 3, and OpenSSL.

```bash
./validation/validate.sh
```

The script starts a throwaway SQL Server container with a random password and no published ports. It removes the container on exit and doesn't touch any other database. The first run also downloads the SQL Server image.

The exit code is `0` when every step passes and `1` otherwise. To test another SQL Server version, set `MSSQL_IMAGE`.

## Pass criteria

A run passes only if steps 1 to 5 all pass. Step 6 is informational.

| # | Step | What is checked | Pass condition |
|---|------|-----------------|----------------|
| 1 | Determinism | Regenerates the seed file and compares it with `seed_data.sql` | Files are byte-identical |
| 2 | Clean build | Creates an empty database, then loads the schema and the seed | No errors |
| 3 | Data checks | 40 checks in `validation/checks.sql` | Every actual value equals its expected value |
| 4 | Trigger enforcement | 5 rule violations and 3 row counts in `validation/triggers.sql` | Each violation fails with its expected error, and row counts don't change |
| 5 | Re-run protection | Runs the seed a second time | Refused with error `50010` |
| 6 | Known gaps | 4 probes in `validation/known_gaps.sql`, each rolled back | Reported only; never fails the run |

## Data checks (step 3)

### Row counts (7 checks)

| Table | Rows |
|-------|------|
| `ROLES` | 7 |
| `EMPLOYEES` | 30 |
| `PROJECTS` | 13 |
| `EMPLOYEES_IN_PROJECT` | 72 |
| `TASKS` | 308 |
| `TASK_RECORD_BY_ENGINEER` | 1,263 |
| `REVIEWS` | 366 |

### Consistency rules (17 checks)

Each rule counts violations, and the expected count is 0.

| Area | Rules |
|------|-------|
| Dates | A task deadline falls within its project's dates. A record falls within its project's dates. No record or review is dated after the snapshot date. No record falls on a weekend. |
| Task status | A `Not Started` task has no records. `In Progress` and `Completed` tasks have at least one record. An approved task is `Completed`. |
| Review flow | No record follows an approval. No task is approved twice. No review follows an approval. |
| People | Managers own no tasks. Record authors belong to the task's project. No employee logs more than 11 hours in a day. |
| Naming | Task names are unique within a project. |

### Edge cases (9 checks)

The sample data includes these cases on purpose, so that queries have to handle them. The expected values were calculated separately from the seed file.

| Case | Count |
|------|-------|
| Records with a `NULL` result | 30 |
| Zero-hour records | 19 |
| Tasks with a `NULL` deadline | 14 |
| Records logged by someone other than the task owner | 61 |
| Reviews by a manager who isn't on the project | 8 |
| `Completed` tasks with no review | 5 |
| Employees on no project | 4 |
| Projects with no tasks | 1 |
| Employees with a `NULL` role | 1 |

### Reference metrics (7 checks)

| Metric | Value |
|--------|-------|
| Total hours logged | 5,163.5 |
| Reviews approved | 72.7% |
| Tasks owned by Noa Shapira | 40 |
| Review rejections on Idan Rosen's tasks | 59.4% |
| Logistics Platform tasks approved on time | 32.1% |
| Average hours per record, priority 1 | 5.41 |
| Average hours per record, priority 5 | 2.56 |

## Trigger enforcement (step 4)

| Trigger | Violation attempted | Expected error |
|---------|---------------------|----------------|
| `trg_task_deadline` | Task deadline after the project deadline | 50001 |
| `trg_record_date` | Record dated outside the project | 500001 |
| `trg_manager_review` | Review by a non-manager | 50001 |
| `trg_review_date` | Review dated before any record on the task | 500001 |
| `trg_project_deadline` | Project deadline moved before a task deadline | 50004 |

## Known gaps (step 6)

The schema currently accepts these changes. Each one is reported as `OPEN` until a constraint or trigger blocks it, and then as `CLOSED`.

- Moving a project's start date can leave records before the new start.
- Deleting records can leave a review with no record behind it.
- A manager who isn't assigned to a task can log an engineer record on it.
- An approved task with records can return to `Not Started`.

Step 6 assumes step 4 passed. If a trigger failed to block its update, the change stays in the database and later probes can report misleading results.

## Latest result

Run on 2026-11-02 with the `mcr.microsoft.com/mssql/server:2025-latest` image and Python 3.14: **all steps passed**, and all 4 known gaps were `OPEN`.

To confirm that the checks can fail, a tampered copy was also run, with one review moved past the snapshot date and `trg_project_deadline` disabled. That run failed at steps 1, 3, and 4, and it named both faults.
