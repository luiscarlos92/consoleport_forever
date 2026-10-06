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
- **21 tooling tests passed**, covering path guards, dependency qualification, recipe verification and installer/restore simulations.
- All 18 official source identities match the dependency lock. All downloaded/unpacked dependency bytes remain clean.
- Lua 5.1 syntax is checked; Fengari runs Lua 5.3 host semantics. These tests do not certify real protected execution, hardware input, combat, rendered appearance or saved-state behavior in Retail.

Exact test receipts are retained under `evidence/test-results/consoleport-3.3.9-*`; the detailed package comparison is `evidence/dependencies/consoleport-upgrade-3.3.9.json`.

## Build and deployment

The source must be committed, pushed and tested before the pack can be built. The full personal pack uses 40 selected addon folders and the 18 pinned official packages. Generated archives stay local in `dist/2.0.0-candidate.4`; no third-party pack is published.

Deployment evidence, pack digest, fresh full AddOns/WTF backup and final readback will be appended after the guarded rehearsal and live installation. Ordinary installation never edits WTF and preserves all 42 character junctions. The user's `Backup_Addons_20261006.rar` remains retained separately.

## Manual Retail acceptance

After deployment, log in and check `/cpf status` and `/cpf diagnose`. Confirm ConsolePort 3.3.9 and candidate.4, then test the crossbar/modifiers, rings, bags, ordinary windows, Edit Mode, keyboard and a reload. Already accepted revision-12 fields should not require a fresh review solely because the code changed. Exact gesture/selector/icon/scroll parity gates remain as documented in the existing manual test cases.
