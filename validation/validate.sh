#!/usr/bin/env bash
# Runs the validation protocol in docs/VALIDATION.md against a throwaway SQL Server container.
# The container publishes no ports, uses a random password, and is removed on exit.
# Exit code: 0 when every check passes, 1 otherwise.
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IMAGE="${MSSQL_IMAGE:-mcr.microsoft.com/mssql/server:2025-latest}"
CONTAINER="epm-validate-$$"
PASSWORD="Va1!$(openssl rand -hex 16)"
SQLCMD=(/opt/mssql-tools18/bin/sqlcmd -C -S localhost -U sa)
WORK="$(mktemp -d)"
FAILED=0

cleanup() {
  docker rm -f "$CONTAINER" >/dev/null 2>&1
  rm -rf "$WORK"
}
trap cleanup EXIT

q() { docker exec -e "SQLCMDPASSWORD=$PASSWORD" "$CONTAINER" "${SQLCMD[@]}" "$@"; }

step() {
  if [ "$2" -eq 0 ]; then
    echo "PASS  $1"
  else
    echo "FAIL  $1"
    FAILED=1
  fi
}

# Compares section|check|expected|actual rows and prints one line per check
compare() {
  awk -F'|' '
    $1 ~ /^(row_count|consistency|edge_case|reference|after_triggers|trigger)$/ && NF == 4 {
      n++
      if ($3 == $4) { pass++ } else { bad = 1; printf "FAIL  %s: %s (expected %s, got %s)\n", $1, $2, $3, $4 }
    }
    END { printf "      %d of %d checks passed\n", pass, n; exit (bad || n == 0) }'
}

echo "== 1. Determinism"
python3 "$ROOT/scripts/generate_seed.py" "$WORK/seed_regenerated.sql" >/dev/null \
  && cmp -s "$WORK/seed_regenerated.sql" "$ROOT/seed_data.sql"
step "generator reproduces seed_data.sql byte for byte" $?

echo "== 2. Clean build"
docker run -d --platform linux/amd64 --name "$CONTAINER" -e ACCEPT_EULA=Y -e "MSSQL_SA_PASSWORD=$PASSWORD" "$IMAGE" >/dev/null || exit 1
for _ in $(seq 1 60); do
  q -Q "SELECT 1" >/dev/null 2>&1 && break
  sleep 2
done
docker cp "$ROOT/database.sql" "$CONTAINER:/tmp/database.sql" >/dev/null
docker cp "$ROOT/seed_data.sql" "$CONTAINER:/tmp/seed_data.sql" >/dev/null
for f in checks triggers known_gaps; do
  docker cp "$ROOT/validation/$f.sql" "$CONTAINER:/tmp/$f.sql" >/dev/null
done
q -b -Q "CREATE DATABASE validation_db;" >/dev/null
step "database created" $?
q -b -d validation_db -i /tmp/database.sql >/dev/null
step "schema loaded" $?
q -b -d validation_db -i /tmp/seed_data.sql >/dev/null
step "seed loaded" $?

echo "== 3. Data checks"
q -d validation_db -h-1 -W -s '|' -i /tmp/checks.sql 2>&1 | compare
step "row counts, consistency rules, edge cases, reference metrics" "${PIPESTATUS[1]}"

echo "== 4. Trigger enforcement"
q -d validation_db -h-1 -W -s '|' -i /tmp/triggers.sql 2>&1 | compare
step "each rule violation is blocked with its expected error, and no rows change" "${PIPESTATUS[1]}"

echo "== 5. Re-run protection"
q -b -d validation_db -i /tmp/seed_data.sql 2>&1 | grep -q "Msg 50010"
step "a second seed run is refused with error 50010" $?

echo "== 6. Known gaps (informational)"
q -d validation_db -h-1 -W -s '|' -i /tmp/known_gaps.sql 2>&1 | awk -F'|' '$1 == "gap" { printf "%-6s %s\n", $3, $2 }'

echo
if [ "$FAILED" -eq 0 ]; then
  echo "RESULT: PASS"
else
  echo "RESULT: FAIL"
fi
exit "$FAILED"
