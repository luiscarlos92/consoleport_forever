# ConsolePort Forever

Personal Retail controller UI companion. Version **2.0.0-candidate.1** is built and verified for personal in-game testing. Development and simulations stay isolated from the installed game; live installation requires the user's explicit request.

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

The replacement runtime and adapters are loaded through the TOC. The complete personal pack includes 40 addon folders from the companion and 18 official stable dependency packages. Read [delivery details](docs/DELIVERY.md), [guarded installation and backup instructions](docs/INSTALLATION.md), and [the Retail acceptance checklist](docs/ACCEPTANCE.md). Use the verified pack and guarded installer rather than copying individual source folders.

The candidate passes 32 runtime/source suites and 21 tooling tests, including backup/install/restore rehearsals with 42 copied character junctions. Actual Retail hardware, secure combat, taint, appearance and persistence remain acceptance tests. Exact ring gestures, gameplay Circle priority, learned class/pet activation, loot hold, held cinematic skip, the missing second mount icon and unaudited scrolling retain their documented baseline/pending gates; candidate readiness does not claim full parity.

Installed third-party copies are immutable migration references, not pack payloads. Current packages remain unmodified and retain their original notices. The personal UI pack must assemble only approved dependency coverage and record distribution restrictions where applicable.
