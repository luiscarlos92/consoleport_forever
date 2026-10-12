# Test work in ConsolePort Forever

Status: maintained
Reviewed: 2026-10-11
Evidence: [validation map](../docs/TESTING.md), [compiler lesson](../docs/CANDIDATE25-SILENT-PING-2026-10-10.md).

Read the root instructions and validation map. Derive expected behavior from the
approved requirement/user observation before the fixture. Exercise actual relevant
native functions, handlers, restricted compilation and dispatch boundaries;
model unavailable C APIs explicitly and state the limit. Preserve old-defect
reproduction and meaningful negative controls rather than matching implementation
text or weakening assertions for green results.

`tests/fixtures` is immutable captured input. Simulations create guarded fresh
copies under repo `scratch`; they never read/write live game configuration or
execute provisioning scripts. Loaded/tested modules may be disabled by policy.
Check state/class/ownership/transition cases appropriate to the change, including
manual edits and held release. Native pixels, taint and controller timing remain
separate Retail acceptance.

Use `./tools/Test-All.ps1` for runtime/tool changes and full release gates.
The runner and build validator own suite membership; do not add fixed duplicate
pass-count requirements. New meaningful checker tests belong in `test_*.py` so
the existing tooling runner discovers them. Maintained docs/skills use the
read-only `python -B tools/check_documentation.py` check.
