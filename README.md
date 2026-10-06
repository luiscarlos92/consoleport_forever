# ConsolePort Forever

Personal Retail controller UI companion. Version **2.0.0-candidate.4** targets clean **ConsolePort 3.3.9**. Development and simulations stay isolated from the installed game; live installation requires the user's explicit request. See [the compatibility update](docs/CONSOLEPORT-UPGRADE-2026-10-06.md), [the latest complete WTF audit](docs/WTF-AUDIT-2026-10-04-THIRD.md), [verified deployments](docs/LIVE-INSTALL-2026-10-04.md), and [35 step-by-step test cases with results](docs/MANUAL-TEST-CASES.md).

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

The replacement runtime and adapters are loaded through the TOC. Full personal packaging preserves 42 addon folders from the companion and 18 official packages, including DBM's inactive bundled modules. When CurseForge already manages the dependencies, use the guarded companion-only deployment in [installation instructions](docs/INSTALLATION.md); it verifies that all vendor files and WTF remain unchanged. See [delivery details](docs/DELIVERY.md) and [the Retail acceptance checklist](docs/ACCEPTANCE.md).

The candidate passes 34 runtime/source suites. The corrected packaging and companion-only deployment pass 24 tooling tests, including vendor/WTF preservation and rollback after an interrupted promotion. Actual Retail hardware, secure combat, taint, appearance and persistence remain acceptance tests. Exact ring gestures, gameplay Circle priority, learned class/pet activation, loot hold, held cinematic skip, the missing second mount icon and unaudited scrolling retain their documented baseline/pending gates; candidate readiness does not claim full parity.

Installed third-party copies are immutable migration references, not pack payloads. Current packages remain unmodified and retain their original notices. The personal UI pack must assemble only approved dependency coverage and record distribution restrictions where applicable.
