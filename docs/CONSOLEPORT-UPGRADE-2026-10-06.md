# ConsolePort 3.3.9 compatibility update — October 6, 2026

Candidate **2.0.0-candidate.4** restores Forever's activation with the user's newly installed official ConsolePort **3.3.9**. The prior candidate deliberately accepted only 3.3.5. The user authorized the repo update, all offline tests, and Retail deployment before their next manual test.

## Scope and source review

- Exact official stable ZIP: [ConsolePort 3.3.9](https://github.com/seblindfors/ConsolePort/releases/tag/3.3.9), 17,816,021 bytes, SHA-256 `d9cd6ce097c7bbafc0963a527243fd36f8cc6d1d294785154bf1886f58dbc640`. The resolver verified GitHub's advertised digest.
- Compared to 3.3.5: 44 changed files, one added legacy-decoder file and five removed serializer/compression library files. Changes include centralized binding claims, retained unmatched modifier states, dispatch readiness, native keyboard version-2 restoration, account-wide bar data sources, native export encoding and safe Edit Mode hover substitutions.
- All five companion compatibility guards and the current tests target 3.3.9. Native sources remain unmodified; 33 exact files were captured for source-contract tests. Historical reference snapshots remain immutable.
- The remaining 17 dependency identities are unchanged and official latest stable sources were rechecked. Coverage, original notices, media and package evidence were regenerated against the new lock.
- StoreSchema **3** and configuration revision **12** remain unchanged. No new layout, binding or preference defaults are introduced. Native ConsolePort migrations remain upstream-owned.

The adapter reads the native active `Layout`. Tests exercise both character and account-wide sources, inactive-copy preservation, explicit opt-out, account defaults and a new character. Forever does not select shared layouts automatically. Its UI input bridge still uses native Input, which now delegates to Layers; the host runs the complete pinned Layers resolver rather than replacing its arbitration with a stub.

## Verification

- **34 runtime/source suites passed**, including actual-TOC lifecycle and persistence; native binding claims and restoration after modal/UI closure; protected/ordinary unmatched state drivers; keyboard restoration only from version 1; selected-bank/dispatch readiness; shared-layout isolation; and safe native Edit Mode hover substitutions.
- **24 tooling tests passed**, covering path guards, dependency qualification, retained inactive package companions, recipe verification, companion-only vendor/WTF preservation and interruption rollback.
- All 18 official source identities match the dependency lock. All downloaded/unpacked dependency bytes remain clean.
- Lua 5.1 syntax is checked; Fengari runs Lua 5.3 host semantics. These tests do not certify real protected execution, hardware input, combat, rendered appearance or saved-state behavior in Retail.

Exact test receipts are retained under `evidence/test-results/consoleport-3.3.9-*`; the detailed package comparison is `evidence/dependencies/consoleport-upgrade-3.3.9.json`.

## Build and deployment

### Packaging correction and final deployment scope

CurseForge reported DBM Vanilla r830 corrupt because the earlier full-pack policy removed `DBM-Azeroth` and `DBM-Test-Vanilla`. The version and retained source bytes were correct; the package was incomplete. The user reinstalled r830 through CurseForge. Packaging now retains those native inactive companions and bundled helpers unchanged; WoW's original TOCs control load eligibility. Regression coverage brings tooling checks to **24**.

The final update deploys **only ConsolePort_Forever** through `tools/deploy_companion.py`. It validates the tested ConsolePort version, backs up the companion and canonical WTF, verifies every vendor file before/after, and replaces only the companion. It never writes vendor addon files or live WTF. The earlier full candidate.4 archive is retained as superseded evidence and is used only as a checksum-verified source of the already-tested companion payload, never for full-pack installation. The slow full-pack rehearsal was stopped on the separate scratch copy; its backups remain retained.

The source is committed and pushed. Future full packaging preserves 42 folders from the companion and 18 official packages. The earlier 40-folder archive stays local under `dist/2.0.0-candidate.4` as superseded evidence; only its already-tested companion payload was used in the final deployment. No third-party pack is published.

### Verified live deployment — 18:47:33 America/Toronto

Candidate.4 is installed beside ConsolePort **3.3.9**. All **43** deployed companion files match the current Git product source. All **3,693** vendor files, **296** canonical WTF files and **42** character junctions remained unchanged. The tool replaced only `ConsolePort_Forever`; settings persistence remains owned by WoW and the in-game installer.

- Product source: `de5fd2f47d0dea94c2ba7778fcefe808805517e5`; deployment tooling/package correction: `b623ceb99f28e9344cd2402a622432963c0c5129`.
- Latest [GitHub Windows CI](https://github.com/luiscarlos92/consoleport_forever/actions/runs/37542526711): success; 34 runtime/source suites and 24 tooling tests, with fresh verification of all 18 pinned official archives.
- Verified payload archive SHA-256: `42359d5a9eb9e05c1b8d1e500bb321290233040d9aa4133b74d3508dcc9cf27c`.
- Fresh companion plus canonical WTF backup: `C:\Users\luisr\WoW-Backups\ConsolePort-Forever\20261006T224647Z-ad965326de5e`. Vendor files were untouched and therefore not replaced or recopied in this scoped backup. The user's full `Backup_Addons_20261006.rar` remains retained separately.
- Parked previous companion: `C:\Users\luisr\OneDrive\Documents\03 Gaming\World of Warcraft\_retail_\Interface\.cpf-companion-stage-20261006T224647Z-ad965326de5e\previous`.
- Exact readback evidence: `evidence/delivery/live-install-candidate4.json`.

## Manual Retail acceptance

After deployment, log in and check `/cpf status` and `/cpf diagnose`. Confirm ConsolePort 3.3.9 and candidate.4, then test the crossbar/modifiers, rings, bags, ordinary windows, Edit Mode, keyboard and a reload. Already accepted revision-12 fields should not require a fresh review solely because the code changed. Exact gesture/selector/icon/scroll parity gates remain as documented in the existing manual test cases.
