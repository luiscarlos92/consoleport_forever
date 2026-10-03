# ConsolePort Forever

Personal Retail controller UI companion under implementation. Development is isolated from the installed game. This checkout is **not yet an installable candidate**. No live installation is authorized in the implementation runs.

Read [the active master plan](docs/MASTER-PLAN.md) and [implementation status](docs/IMPLEMENTATION-STATUS.md) before continuing. The untouched installed companion, dependency snapshots, configuration, assets and junction inventory were captured and pushed as baseline `15a191ab06b6d4562d63761116ca2c248150c3cc`.

From this checkout, with Node 24 and Python 3.14:

```powershell
npm ci --ignore-scripts --no-audit --no-fund
./tools/Test-All.ps1
./tools/Resolve-Dependencies.ps1          # Verify existing lock/cache; no network
./tools/Resolve-Dependencies.ps1 -Refresh # Explicitly resolve official stable releases
node tools/extract_reference.cjs         # Regenerate data-only current definitions
```

Caches and unpacked dependencies are local, ignored artifacts. After a fresh clone, the explicit dependency refresh is necessary to populate them. Tests themselves do not fetch packages or access live game data. Saved-variable parsing rejects executable statements. Tests use Lua 5.1 syntax checks and Fengari's Lua 5.3 semantics; passing them does not certify Retail restricted execution, hardware gestures or appearance.

The new foundation modules remain outside the TOC until orchestration and adapters replace the legacy installer. Do not copy this unfinished addon into WoW. Pack building, guarded installation and restore entry points will be delivered after implementation and fake-root validation.

Installed third-party copies are immutable migration references, not pack payloads. Current packages remain unmodified and retain their original notices. The personal UI pack must assemble only approved dependency coverage and record distribution restrictions where applicable.
