# ConsolePort Forever agent instructions

Status: maintained
Reviewed: 2026-10-12
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
  one-off permissions are fulfilled. The October 12 standing user instruction
  authorizes qualified Forever updates while playing unless explicitly prohibited;
  it remains active until revoked. See delivery decision 0004.
- Do not edit upstream addons, immutable `reference/`, `tests/fixtures/`, pinned
  source evidence or the inactive ping fallback. Fixes belong in Forever.
- Preserve accepted functionality, manual edits, native power/feedback and
  GUID-owned class data. Automatic action-slot restoration remains removed.
- Preserve native ConsolePort binding/page/input ownership. Full custom modes,
  UI takeover and hidden-control replacement remain suspended. Ground placement
  and its Targeting panel are retired by user instruction; temporary routing remains active.
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
- For HUD/event/cooldown/input changes, follow the
  [performance rules](docs/DEVELOPMENT.md#addon-performance): preserve immediate
  native feedback, bound workers, invalidate public caches correctly, and retain
  work-count defect reproductions plus comparable Retail profiling limits.

## Delivery and upkeep

Deployment follows the standing user authorization unless the user says otherwise.
Running-game Forever-only updates use the qualified
exception in [decision 0004](docs/decisions/0004-scoped-delivery.md); this never
authorizes game input, dependency replacement or WTF writes. Commit/push
exact tested source before packaging; use `tools/build_update.py` and scoped
`tools/deploy_update.py` preview/installer. Include only Forever and actual
qualified changed packages. Preserve other addons, WTF, junctions and verified
prior backups; retain artifact/checksum/receipt and independent readback.
See [installation](docs/INSTALLATION.md) and [checklist](docs/NEXT-DEPLOYMENT-CHECKLIST.md).
Apply the [documentation impact table](docs/DEVELOPMENT.md#documentation-maintenance)
to each change. Update affected pages or explain why none change; do not append
release history everywhere. Superseded decisions remain evidence, not instructions.
