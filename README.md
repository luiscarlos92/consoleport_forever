# ConsolePort Forever

Personal Retail controller UI companion. **2.0.0-candidate.7** is installed with clean **ConsolePort 3.3.10**. The [visual patch](docs/FACE-VISUAL-PATCH-2026-10-07.md) restores custom face artwork and circular masks after native refreshes. All 49 deployed files match; 3,842 dependency files, 298 WTF files and 42 character junctions are unchanged. Working targeting behavior and configuration revision 13 remain unchanged. See the [installed receipt](evidence/delivery/live-install-candidate7.json) and [manual test cases](docs/MANUAL-TEST-CASES.md).

Read [AGENTS.md](AGENTS.md) and the [dependency workflow](docs/DEPENDENCY-WORKFLOW.md): check all 9 dependencies each session, refresh only changed official packages, test compatibility, then prepare a scoped update. Deployment requires new explicit authorization and WoW closed. Never write live WTF. DBM is uninstalled and retired from active dependencies.

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

The replacement runtime and adapters are loaded through the TOC. Routine updates contain Forever and only changed qualified dependency packages; all 9 tested dependency identities are retained, including Better Wardrobe. DBM, HideClassBars and SharedMedia_Causese are retired; original history and backups remain retained. When CurseForge already manages the dependencies, use the guarded companion-only deployment in [installation instructions](docs/INSTALLATION.md); it verifies that all vendor files and WTF remain unchanged. See [delivery details](docs/DELIVERY.md) and [the Retail acceptance checklist](docs/ACCEPTANCE.md).

The candidate passes 39 runtime/source suites and 33 tooling tests, including vendor/WTF preservation and rollback after an interrupted promotion. Actual Retail hardware, secure combat, taint, appearance and persistence remain acceptance tests. Exact ring gestures, gameplay Circle priority, learned class/pet activation, loot hold, held cinematic skip, the missing second mount icon and unaudited scrolling retain their documented baseline/pending gates; candidate readiness does not claim full parity.

Installed third-party copies are immutable migration references, not pack payloads. Current packages remain unmodified and retain their original notices. The personal UI pack must assemble only approved dependency coverage and record distribution restrictions where applicable.
