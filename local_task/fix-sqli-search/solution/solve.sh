#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PYEOF'
import pathlib

f = pathlib.Path("/app/routers/items.py")
src = f.read_text()

vulnerable = (
    "        query = (\n"
    "            f\"SELECT * FROM items \"\n"
    "            f\"WHERE name LIKE '%{q}%' ORDER BY id ASC\"\n"
    "        )\n"
    "        rows = await conn.fetch(query)"
)
fixed = (
    "        rows = await conn.fetch(\n"
    "            \"SELECT * FROM items WHERE name LIKE $1 ORDER BY id ASC\",\n"
    "            f\"%{q}%\",\n"
    "        )"
)

if vulnerable not in src:
    raise SystemExit("ERROR: vulnerable pattern not found — source may have changed")

f.write_text(src.replace(vulnerable, fixed))
print("Patched /app/routers/items.py")
PYEOF

cd /app
pytest tests/ -q
echo "All tests pass."