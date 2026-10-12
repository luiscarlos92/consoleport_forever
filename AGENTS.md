# ConsolePort Forever agent instructions

Status: maintained
Reviewed: 2026-10-11
Evidence: [approved repository system](docs/decisions/0001-repository-development-system.md).

## Start here

This personal Retail controller companion is inspired by WoW Forever. Read
[current status](docs/IMPLEMENTATION-STATUS.md), then relevant
[requirements](docs/REQUIREMENTS.md), [architecture](docs/ARCHITECTURE.md),
[controller behavior](docs/CONTROLLER_SPEC.md) and [states](docs/STATE_MATRIX.md).
Implemented, enabled, intended and Retail-accepted are separate facts.
The [reference index](docs/reference/README.md) routes evidence and history.

## Authority and boundaries

- This checkout is the sole working source of truth. Keep scripts, plans,
  research and generated work here. OneDrive WoW storage is production; never
  modify or reorganize the user's `Documents`.
- User instructions and confirmed decisions override older records. Historical
  deployment permissions are fulfilled, not reusable authorization.
- Do not edit upstream addons, immutable `reference/`, `tests/fixtures/`, pinned
  source evidence or the inactive ping fallback. Fixes belong in Forever.
- Preserve accepted functionality, manual edits, native power/feedback and
  GUID-owned class data. Automatic action-slot restoration remains removed.
- Preserve native ConsolePort binding/page/input ownership. Full custom modes,
  UI takeover and hidden-control replacement remain suspended; ground placement
  and temporary routing are separate active adapters.
- Runtime Lua/XML locations and TOC order are functional contracts. Cleanup
  alone does not justify moving them or changing loading.
- Archived scripts/absolute paths are historical evidence, not deployment
  instructions. Executing `tools/local` provisioning scripts needs separate
  explicit authorization. The native UI reference in `docs/references/pending`
  is reserved for a later feature request.
- Never directly write live WTF, prune unrelated addons or launch/operate the
  game during ordinary development. Game-input work needs a specific current
  user request and an available permitted mechanism.
- Public/adaptive product work remains deferred. Local assembly/notices do not
  grant permission to publish third-party code or assets.

## Investigate and implement

Trace actual source, active policy, native owner and event order before repairing
regressions. Separate demonstrated defects from suspected live causes; saved
files are not live engine snapshots. Do not invent Forever behavior or preferences.
For material unresolved choices, investigate options, then ask with context,
consequences, recommendation and alternatives. Record answers in requirements
or decisions; do not repeat answered questions.

Protected dispatch belongs in qualified native/secure routes. Public timers,
alpha and observations cannot authorize protected writes/actions. Restricted
snippets require the pinned native compiler; ordinary Lua parsing and
hardware-shaped mocks are insufficient. Handle unknown/secret values without
manufacturing public state. See [compatibility](docs/COMPATIBILITY.md).

## Workflows and validation

- Read [test instructions](tests/AGENTS.md) before test changes and
  [tool instructions](tools/AGENTS.md) before executable tooling changes.
- Use [regression investigation](.agents/skills/forever-regression-investigation/SKILL.md)
  for regressions/disputed proof, [dependency qualification](.agents/skills/forever-dependency-qualification/SKILL.md)
  for dependency work, and [scoped release](.agents/skills/forever-scoped-release/SKILL.md)
  for preparation and separately authorized installation.
- Read-only and documentation/agent-instruction-only sessions need no fresh
  dependency check if they change no runtime, dependency, packaging or executable
  tooling contract. Other development sessions freshly inspect every official
  stable Retail source before changes, refresh only changed packages and qualify
  affected contracts. Cached checks are not fresh checks.
- Preserve [required regression gates](docs/TESTING.md). Reproduce old failures
  and retain meaningful negative controls. Native input, actual visual
  composition and state transitions need their existing relevant coverage.
- Run `python -B tools/check_documentation.py` for maintained docs/skills.
  Run `./tools/Test-All.ps1` for runtime/executable tooling changes and release
  qualification. Reports must match the complete current source inventories.
- Report proof limits: offline results do not certify Retail engine authority,
  hardware timing, taint, rendering or persistence. Acceptance covers reported cases.

## Delivery and upkeep

Deployment requires explicit current authorization and WoW closed. Commit/push
exact tested source before packaging; use `tools/build_update.py` and scoped
`tools/deploy_update.py` preview/installer. Include only Forever and actual
qualified changed packages. Preserve other addons, WTF, junctions and verified
prior backups; retain artifact/checksum/receipt and independent readback.
See [installation](docs/INSTALLATION.md) and [checklist](docs/NEXT-DEPLOYMENT-CHECKLIST.md).
Apply the [documentation impact table](docs/DEVELOPMENT.md#documentation-maintenance)
to each change. Update affected pages or explain why none change; do not append
release history everywhere. Superseded decisions remain evidence, not instructions.
