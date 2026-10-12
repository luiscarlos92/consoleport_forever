# Development workflow

Status: maintained
Reviewed: 2026-10-11
Evidence: [approved system](decisions/0001-repository-development-system.md),
[package scripts](../package.json), [CI](../.github/workflows/tests.yml),
[path guards](../tools/repository_paths.py).

## Setup

Work only in this checkout. Use Node 24, Python 3.14 and PowerShell as configured
by existing CI. Install development packages with
`npm ci --ignore-scripts --no-audit --no-fund`.

`./tools/Resolve-Dependencies.ps1` verifies an already populated lock/cache without
network. Fresh clones need official cache retrieval through the
[dependency procedure](DEPENDENCY-WORKFLOW.md); use selective refresh for actual
changed packages. Exact pinned retrieval/verification is the separate CI network
stage. Tests do not fetch packages or read live game paths.

`node tools/extract_reference.cjs` regenerates data-only Reference.lua from
captured definitions; this is an intentional product change, not a routine setup
step. Runtime captured/accepted state takes precedence over defaults. The saved
Edit Mode reference is separately sourced. Do not overwrite generated data to
match a plausible layout without evidence and authorization.

In-game `/cpf install` and `/cpf update` both open configuration review; they do
not fetch/install code. Review considers current native fields and retained
ownership, not a bulk preset reset. Restore, interrupted-transaction recovery,
native binding-selection recovery and transient-view review are separate
commands. Their exact scope and persistent state are documented in the
[runtime configuration reference](reference/RUNTIME-CONFIGURATION.md#commands-and-diagnostic-retention).

## Repository map

| Path | Role |
| --- | --- |
| `addon/ConsolePort_Forever` | Product; TOC defines actual load order. |
| `tests/harness`, `tools/test-all.cjs` | Native-source and modeled Lua execution, syntax and regression gates. |
| `tests/test_*.py` | Guarded tooling/deployment simulations and documentation checker cases. |
| `tools` | Current qualification/build/install/check commands. Read [scoped rules](../tools/AGENTS.md). |
| `dependencies` | Official sources/lock; cache and unpacked archives are ignored local inputs. |
| `evidence` | Retained source contracts, test/delivery/acceptance receipts and research. |
| `reference`, `tests/fixtures` | Immutable original reference inputs. |
| `fallbacks` | Inactive qualified code, outside runtime/TOC. |
| `archive/onedrive-legacy` | Imported historical work; embedded paths/scripts are not executable instructions. |
| `scratch`, `dist` | Ignored repository-local working outputs and artifacts. |
| `.agents/skills` | Three approved reusable workflows. |

## Choose the workflow

1. Establish current authority, requirement, actual enabled code and relevant
   user observations. Use [evidence labels](reference/EVIDENCE.md).
2. For runtime/dependency/packaging/executable tooling changes, freshly check all
   official stable Retail sources before editing; qualify changed contracts.
   Read-only or documentation/agent-instruction-only work is exempt if it changes
   none of those contracts. The exemption does not declare dependencies current.
3. Investigate material uncertainties before implementation. For bugs, use the
   regression skill; derive expected behavior from requirements and user intent,
   not the test fixture. Preserve manual edits and accepted native behavior.
4. Make focused authorized changes, update affected documentation and run
   [applicable checks](TESTING.md). Record proof limits and remaining observations.
5. Package/deploy only within separately established delivery authority.

Git history uses descriptive imperative commits, with implementation and delivery
records often separated. Existing history is linear on main with no release tags
found during the audit; this is an observation, not a requirement to avoid PRs.
Use the app's `codex/` prefix when creating a branch. No new branch/PR policy,
mandatory hook or publishing workflow is introduced. Build tooling currently
requires clean source pushed on main; do not silently rewrite that contract.

## Documentation maintenance

For every change, identify which rows apply; update those pages or state why
their existing text remains accurate. Unaffected documents need no edits.

| Trigger | Review/update |
| --- | --- |
| Approved/withdrawn feature or scope | Requirements; controller/states if relevant; known issues and bounded plan. |
| Controller command, gesture, priority | Controller spec and state matrix; tests and scoped acceptance. |
| Bug diagnosis/fix | Known issue status, meaningful regression and changelog when release-relevant. |
| Architecture/initialization/ownership | Architecture; decision record for significant rationale. |
| Setting/persistence/migration | Requirements, architecture, compatibility if assumptions change; ownership/rollback tests. |
| Client/API/dependency | Compatibility and affected pinned contracts/tests/notices; dependency evidence. |
| Deliberate Forever difference | Requirement and decision; source/evidence distinction in reference material. |
| New recurring workflow | Assess skill value/overlap; create only after user-approved scope. |
| Release prepared/installed/accepted | Changelog/current status and delivery/checklist evidence as applicable; do not duplicate receipts in AGENTS. |

Maintained pages use `Status: maintained`, `Reviewed: YYYY-MM-DD` and `Evidence:`
links. The date records an actual review, not automatic freshness. Behavioral
claims separately identify source/requirement/activation/validation. Preserve
unknown, deferred, superseded and stale information explicitly. New decisions
record context, authority, implications, alternatives and supersession.

For behavioral reconciliation, follow the TOC and actual bootstrap call sites,
then policy/acceptance flags, native probe, write/dispatch guard and event order.
Distinguish reusable helper/test models from production callers. Check both
generic preservation and feature-specific augmentation/migration before promising
that an edit remains untouched. Preserve older dated records as historical
evidence and correct maintained guidance; explicitly record any stale label or
requirement/implementation difference instead of silently repairing runtime code.
The [October 11 reconciliation](reference/CODE-DOCUMENTATION-RECONCILIATION-2026-10-11.md)
shows the source-to-document mapping.

Run `python -B tools/check_documentation.py`. It checks maintained navigation,
local targets/anchors, metadata and skill structure, not semantic truth or remote
URL availability. Historical reports/archive text is excluded intentionally;
use the [migration map](reference/README.md#historical-paths) for old paths.

## Durable evidence

Current routine release preparation uses `python -B tools/build_update.py` with
`--dependency OWNER/REPO` only for actual qualified changes and optional `--label`
to retain earlier same-version artifacts. It requires clean tested source pushed
on main. The scoped installer accepts `--retail-root`, `--pack`, `--sha256`,
`--backup-root` and `--user-install`; preview omits `--execute`. Check current user
delivery authority and closed WoW by default before that stage. Explicitly requested
existing-Forever-only updates use `--allow-running-companion` under
[decision 0004](decisions/0004-scoped-delivery.md); full install, dependencies and
restore cannot use it. Only add `--execute` for the
authorized installation. Independently verify selected files, other addons,
canonical WTF, topology and prior backups; retain receipts. The [release skill](../.agents/skills/forever-scoped-release/SKILL.md)
routes the full workflow. Retained older procedure pages are historical context,
not current candidate counts or fresh authority.

Do not copy entire session transcripts into the public repo. Preserve necessary
decisions and limited supporting quotations with session/date provenance; user
messages and assistant conclusions have different authority. Retain exact
source/test manifests in `evidence`; current scratch reports are needed by release
gates. Historical passed reports are not current qualification after file changes.
The [audit](reference/DEVELOPMENT-HISTORY.md) describes accessible history limits.
