#!/usr/bin/env python3
"""Generates seed_data.sql for database.sql. Deterministic: same seed -> same file."""
import random
import sys
from collections import defaultdict
from datetime import date, timedelta

random.seed(20261102)
TODAY = date(2026, 11, 2)
OUT = sys.argv[1]

ROLES = ["Manager", "Tech Lead", "Senior Software Engineer", "Software Engineer",
         "QA Engineer", "DevOps Engineer", "Data Engineer"]

# name, role, skill (lower = more defects/rejections), speed (higher = later delivery)
EMP = [
    ("Dana Levi", "Manager", 0, 0), ("Yossi Cohen", "Manager", 0, 0),
    ("Michal Peretz", "Manager", 0, 0), ("Eitan Barak", "Manager", 0, 0),
    ("Ruth Avraham", "Manager", 0, 0),
    ("Noa Shapira", "Senior Software Engineer", 0.85, 0.85),
    ("Amit Friedman", "Senior Software Engineer", 0.8, 0.9),
    ("Tal Mizrahi", "Senior Software Engineer", 0.75, 1.0),
    ("Lior Katz", "Senior Software Engineer", 0.8, 0.95),
    ("Shira Golan", "Software Engineer", 0.7, 1.0),
    ("Omer Dahan", "Software Engineer", 0.65, 1.05),
    ("Maya Ben David", "Software Engineer", 0.7, 1.0),
    ("Idan Rosen", "Software Engineer", 0.3, 1.45),   # planted: weak performer
    ("Gal Azulay", "Software Engineer", 0.65, 1.1),
    ("Yael Harel", "Software Engineer", 0.75, 0.95),
    ("Nadav Stern", "Software Engineer", 0.6, 1.1),
    ("Hila Biton", "Software Engineer", 0.7, 1.0),
    ("Roni Weiss", "Software Engineer", 0.65, 1.05),
    ("Adi Malka", "QA Engineer", 0.8, 0.95),
    ("Ben Oren", "QA Engineer", 0.75, 1.0),
    ("Keren Sasson", "QA Engineer", 0.8, 1.0),
    ("Doron Levin", "DevOps Engineer", 0.8, 0.95),
    ("Inbar Tzur", "DevOps Engineer", 0.75, 1.0),
    ("Eyal Nissim", "Data Engineer", 0.8, 0.95),
    ("Sivan Ohana", "Data Engineer", 0.7, 1.0),
    ("Matan Regev", "Data Engineer", 0.7, 1.05),
    ("Tamar Gross", "Software Engineer", 0.7, 1.0),   # planted: on no project
    ("Asaf Lavi", "QA Engineer", 0.7, 1.0),           # planted: on no project
    ("Orly Hazan", None, 0, 0),                       # planted: NULL role, no project
    ("Rami Dagan", "Manager", 0, 0),                  # planted: covers reviews only
]
NAME = {i: e[0] for i, e in enumerate(EMP)}
ROLE = {i: e[1] for i, e in enumerate(EMP)}
SKILL = {i: e[2] for i, e in enumerate(EMP)}
SPEED = {i: e[3] for i, e in enumerate(EMP)}
by_name = {e[0]: i for i, e in enumerate(EMP)}
OVERLOADED = by_name["Noa Shapira"]
COVER_MGR = by_name["Rami Dagan"]

# name, start, deadline, managers, tech lead, engineers, n_tasks, delay_risk
P = [
    ("Customer Portal",   date(2025, 1, 6),  date(2025, 6, 30),  ["Dana Levi"], "Noa Shapira",
     ["Shira Golan", "Omer Dahan", "Adi Malka", "Doron Levin"], 26, 0.1),
    ("Billing Migration", date(2025, 2, 3),  date(2025, 7, 31),  ["Yossi Cohen"], "Amit Friedman",
     ["Idan Rosen", "Gal Azulay", "Ben Oren", "Eyal Nissim"], 28, 0.3),
    ("Data Warehouse",    date(2025, 4, 1),  date(2025, 11, 28), ["Michal Peretz"], "Eyal Nissim",
     ["Sivan Ohana", "Matan Regev", "Keren Sasson", "Inbar Tzur"], 30, 0.1),
    ("Mobile App v2",     date(2025, 6, 2),  date(2025, 12, 31), ["Dana Levi"], "Tal Mizrahi",
     ["Maya Ben David", "Yael Harel", "Adi Malka", "Roni Weiss"], 30, 0.15),
    ("Security Hardening", date(2025, 8, 4), date(2026, 1, 30),  ["Eitan Barak"], "Lior Katz",
     ["Doron Levin", "Nadav Stern", "Ben Oren"], 22, 0.1),
    ("CRM Integration",   date(2025, 10, 1), date(2026, 3, 31),  ["Yossi Cohen"], "Noa Shapira",
     ["Hila Biton", "Idan Rosen", "Keren Sasson", "Sivan Ohana"], 26, 0.3),
    # planted: deadline passed, still has open tasks
    ("Logistics Platform", date(2025, 12, 1), date(2026, 8, 31), ["Ruth Avraham"], "Amit Friedman",
     ["Gal Azulay", "Roni Weiss", "Idan Rosen", "Adi Malka", "Inbar Tzur"], 34, 0.6),
    ("Analytics Dashboard", date(2026, 2, 2), date(2026, 12, 18), ["Michal Peretz"], "Eyal Nissim",
     ["Matan Regev", "Yael Harel", "Ben Oren", "Noa Shapira"], 28, 0.1),
    # planted: two managers
    ("Payments Gateway",  date(2026, 3, 2),  date(2027, 1, 29),  ["Eitan Barak", "Dana Levi"], "Lior Katz",
     ["Omer Dahan", "Hila Biton", "Shira Golan", "Keren Sasson", "Doron Levin", "Noa Shapira"], 34, 0.25),
    ("Search Revamp",     date(2026, 6, 1),  date(2027, 3, 31),  ["Ruth Avraham"], "Tal Mizrahi",
     ["Nadav Stern", "Maya Ben David", "Adi Malka", "Noa Shapira"], 24, 0.15),
    # planted: no deadline (open-ended)
    ("Internal Tooling",  date(2026, 1, 12), None,               ["Yossi Cohen"], "Lior Katz",
     ["Roni Weiss", "Inbar Tzur", "Sivan Ohana"], 16, 0.1),
    # planted: starts in the future, tasks exist but no work
    ("AI Assistant",      date(2026, 12, 1), date(2027, 6, 30),  ["Michal Peretz"], "Tal Mizrahi",
     ["Yael Harel", "Matan Regev"], 10, 0.1),
    # planted: project with no team and no tasks
    ("Office Relocation", date(2027, 1, 4),  date(2027, 4, 30),  [], None, [], 0, 0),
]
assert all(len(p[0]) <= 20 for p in P)

WORK = {
    "Software Engineer": ["Implement {} API", "Build {} UI", "Refactor {} module", "Fix {} bugs",
                          "Add {} validation", "Write {} unit tests"],
    "Senior Software Engineer": ["Design {} architecture", "Implement {} service", "Optimize {} performance",
                                 "Review {} design"],
    "Tech Lead": ["Design {} architecture", "Define {} standards", "Plan {} rollout"],
    "QA Engineer": ["Write {} test plan", "Run {} regression", "Automate {} tests", "Verify {} fixes"],
    "DevOps Engineer": ["Set up {} CI pipeline", "Provision {} environment", "Configure {} monitoring",
                        "Automate {} deployment"],
    "Data Engineer": ["Model {} schema", "Build {} ETL job", "Migrate {} data", "Validate {} data quality"],
}
AREAS = ["login", "search", "reports", "notifications", "checkout", "user profile", "permissions",
         "invoices", "audit log", "settings", "export", "import", "scheduler", "integration", "cache"]


def weekday(d, step=1):
    while d.weekday() >= 5:  # Sat/Sun; Mon-Fri work week
        d += timedelta(days=step)
    return d


def add_workdays(d, n):
    d = weekday(d)
    for _ in range(n):
        d = weekday(d + timedelta(days=1))
    return d


projects, members, tasks, records, reviews = [], [], [], [], []
day_hours = defaultdict(float)


def add_record(tid, emp, d, hours, result, limit):
    """Books hours on the first workday with free capacity. Returns the date, or None past limit."""
    cap = 11.0 if emp == OVERLOADED else 9.0
    while d <= limit and day_hours[(emp, d)] + hours > cap:
        d = weekday(d + timedelta(days=1))
    if d > limit:
        return None
    day_hours[(emp, d)] += hours
    records.append(dict(task=tid, emp=emp, hours=hours, d=d, result=result))
    return d


def hours_for(priority):
    # planted: urgent tasks take more hours per session
    base = {1: 5.5, 2: 4.75, 3: 4.0, 4: 3.25, 5: 2.5}[priority]
    return max(0.5, round(random.gauss(base, 1.25) * 4) / 4)


for pid, (pname, start, deadline, mgrs, lead, engs, n_tasks, risk) in enumerate(P):
    projects.append((pid, pname, start, deadline))
    for m in mgrs:
        members.append((pid, by_name[m], "Manager"))
    if lead:
        members.append((pid, by_name[lead], "Tech Lead"))
    team = [by_name[e] for e in engs]
    for e in team:
        members.append((pid, e, ROLE[e]))
    if not n_tasks:
        continue

    span_end = deadline or TODAY + timedelta(days=120)
    span = (span_end - start).days
    assignees = team + [by_name[lead]]
    qa = [e for e in team if ROLE[e] == "QA Engineer"]
    managers = [by_name[m] for m in mgrs]
    used_names = set()

    for t in range(n_tasks):
        # planted: Noa carries about three times a normal share on the 2026 projects
        if OVERLOADED in team and random.random() < 0.3:
            emp = OVERLOADED
        else:
            emp = random.choice(assignees)
        role = "Tech Lead" if emp == by_name[lead] else ROLE[emp]
        while True:
            tname = random.choice(WORK[role]).format(random.choice(AREAS))
            if tname not in used_names:
                used_names.add(tname)
                break
        priority = random.choices([1, 2, 3, 4, 5], weights=[10, 25, 35, 20, 10])[0]

        # tasks are staggered over the project, each 2-6 weeks long
        win_start = start + timedelta(days=int(span * 0.85 * t / n_tasks) + random.randint(0, 7))
        win_start = weekday(win_start)
        win_len = random.randint(14, 42)
        task_dl = weekday(win_start + timedelta(days=win_len), -1)
        if deadline and task_dl > deadline:
            task_dl = weekday(deadline, -1)
        has_deadline = random.random() > 0.05  # planted: some tasks have no deadline

        tid = len(tasks)
        task = dict(id=tid, emp=emp, project=pid, name=tname, priority=priority,
                    status="Not Started", deadline=task_dl if has_deadline else None)
        tasks.append(task)

        if win_start > TODAY:
            continue  # future task: Not Started, no work
        # planted: on an overdue project, some late tasks never even started
        if pname == "Logistics Platform" and t > n_tasks * 0.8 and random.random() < 0.5:
            continue

        slip = SPEED[emp] * (1 + risk * random.random() * 1.2)
        duration = max(4, int((task_dl - win_start).days * random.uniform(0.55, 0.95) * slip))
        planned_end = win_start + timedelta(days=duration)
        limit = min(TODAY, deadline) if deadline else TODAY
        sessions = max(2, duration // random.randint(4, 7))
        cur = win_start
        step = max(1, duration // sessions)
        n_found = 0
        last = None
        for s in range(sessions):
            if cur > limit:
                break
            # defects fall as the task nears completion; weak engineers leave more behind
            progress = s / max(1, sessions - 1)
            mean = (1 - SKILL[emp]) * 6 * (1.15 - progress)
            n_found = max(0, int(random.gauss(mean, 1.0)))
            author = emp
            if qa and emp not in qa and random.random() < 0.08:
                author = random.choice(qa)  # planted: QA logs a verification record on someone else's task
            hours = hours_for(priority)
            result = n_found
            if random.random() < 0.03:
                result = None  # planted: record with no result yet
            if random.random() < 0.015:
                hours = 0.0    # planted: zero-hour check-in
            d = add_record(tid, author, cur, hours, result, limit)
            if d is None:
                break
            last = max(last, d) if last else d
            cur = weekday(cur + timedelta(days=step + random.randint(0, 2)))

        if last is None:
            continue
        task["status"] = "In Progress"
        if planned_end > TODAY or (cur <= planned_end and planned_end > limit):
            continue  # still being worked on at snapshot date

        # review cycles: rejection is driven by remaining defects and engineer skill
        rd = last
        approved = False
        for cycle in range(4):
            rd = add_workdays(rd, random.randint(1, 4))
            if rd > TODAY:
                break
            mgr = random.choice(managers)
            if random.random() < 0.015:
                mgr = COVER_MGR  # planted: reviewer who is not on the project
            p_reject = max(0.04, min(0.8, (1 - SKILL[emp]) * 1.0 + n_found * 0.06 - cycle * 0.15))
            ok = random.random() > p_reject
            reviews.append(dict(mgr=mgr, task=tid, result="Approved" if ok else "Rejected", d=rd))
            if ok:
                approved = True
                break
            # rework after a rejection
            cur = add_workdays(rd, 1)
            lastw = None
            for s in range(random.randint(1, 3)):
                if cur > limit:
                    break
                n_found = max(0, n_found - random.randint(0, 2))
                d = add_record(tid, emp, cur, hours_for(priority), n_found, limit)
                if d is None:
                    break
                lastw = d
                cur = add_workdays(d, random.randint(1, 3))
            if lastw is None:
                break  # nothing more could be booked before the limit
            rd = lastw
        if approved:
            task["status"] = "Completed"

# planted: engineer marked the task Completed, manager has not reviewed it yet
pending = [t for t in tasks if t["status"] == "In Progress"
           and not any(r["task"] == t["id"] for r in reviews)
           and any(rec["task"] == t["id"] for rec in records)]
for t in random.sample(pending, min(5, len(pending))):
    t["status"] = "Completed"

# ids in chronological order, starting at 0 like IDENTITY(0,1)
records.sort(key=lambda r: (r["d"], r["task"], r["emp"]))
reviews.sort(key=lambda r: (r["d"], r["task"]))


def lit(v):
    if v is None:
        return "NULL"
    if isinstance(v, date):
        return f"'{v.isoformat()}'"
    if isinstance(v, str):
        return "'" + v.replace("'", "''") + "'"
    if isinstance(v, float):
        return f"{v:.2f}"
    return str(v)


def insert(out, table, cols, rows, identity=False):
    out.append(f"-- {table}: {len(rows)} rows")
    if identity:
        out.append(f"SET IDENTITY_INSERT {table} ON;")
    # a single VALUES list is limited to 1000 rows
    for i in range(0, len(rows), 500):
        out.append(f"INSERT INTO {table} ({', '.join(cols)}) VALUES")
        chunk = rows[i:i + 500]
        out.append(",\n".join("  (" + ", ".join(lit(v) for v in row) + ")" for row in chunk) + ";")
    if identity:
        out.append(f"SET IDENTITY_INSERT {table} OFF;")
    out.append("")


out = [
    "-- Seed data for database.sql. Run after the schema, in the same database, as one batch.",
    f"-- Snapshot date: {TODAY.isoformat()}. Fixed dates, so use this date instead of GETDATE() for stable KPI answers.",
    "-- Any error rolls back the whole script, leaving the tables empty.",
    "SET NOCOUNT ON;",
    "SET XACT_ABORT ON;",
    "",
    "IF EXISTS (SELECT 1 FROM PROJECTS) OR EXISTS (SELECT 1 FROM ROLES) OR EXISTS (SELECT 1 FROM EMPLOYEES)",
    "    THROW 50010, 'Tables already contain data, seed was not applied', 1;",
    "",
    "BEGIN TRANSACTION;",
    "",
]
insert(out, "ROLES", ["role_name"], [(r,) for r in ROLES])
insert(out, "EMPLOYEES", ["employee_id", "employee_name", "employee_role"],
       [(i, NAME[i], ROLE[i]) for i in range(len(EMP))], True)
insert(out, "PROJECTS", ["project_id", "project_name", "project_start_date", "project_deadline"], projects, True)
insert(out, "EMPLOYEES_IN_PROJECT", ["project_id", "employee_id", "role_name"], members)
insert(out, "TASKS", ["task_id", "employee_id", "project_id", "task_name", "task_priority",
                      "task_current_status", "task_deadline"],
       [(t["id"], t["emp"], t["project"], t["name"], t["priority"], t["status"], t["deadline"]) for t in tasks], True)
insert(out, "TASK_RECORD_BY_ENGINEER", ["record_num", "task_id", "employee_id", "hours_spent", "record_date",
                                        "result_of_record"],
       [(i, r["task"], r["emp"], float(r["hours"]), r["d"], r["result"]) for i, r in enumerate(records)], True)
insert(out, "REVIEWS", ["review_id", "manager_id", "task_id", "result_of_review", "review_date"],
       [(i, r["mgr"], r["task"], r["result"], r["d"]) for i, r in enumerate(reviews)], True)
out += ["COMMIT TRANSACTION;", ""]

text = "\n".join(out)
with open(OUT, "w") as f:
    f.write(text)
print(f"projects={len(projects)} employees={len(EMP)} members={len(members)} tasks={len(tasks)} "
      f"records={len(records)} reviews={len(reviews)} bytes={len(text)}")
