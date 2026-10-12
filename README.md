# ConsolePort Forever

Status: maintained
Reviewed: 2026-10-11
Evidence: [current implementation status](docs/IMPLEMENTATION-STATUS.md).

A personal World of Warcraft Retail controller HUD and configuration companion
for ConsolePort, inspired by WoW Forever. It combines reviewed configuration,
native controller routing, artwork and optional integrations while preserving
upstream addon files and player edits.

The installed checkpoint is candidate.30. Its reported ping-ring and Immersion
Required Items defects are accepted in Retail; this is not blanket acceptance.
[Current status](docs/IMPLEMENTATION-STATUS.md) owns installation/acceptance facts.

## Documentation

| Need | Read |
| --- | --- |
| Agent rules | [AGENTS.md](AGENTS.md) |
| Intent and exclusions | [Requirements](docs/REQUIREMENTS.md) |
| Modules, startup and ownership | [Architecture](docs/ARCHITECTURE.md) |
| Settings, journals and in-game commands | [Configuration contracts](docs/reference/RUNTIME-CONFIGURATION.md) |
| Visual feedback and dormant UI routes | [Presentation/UI](docs/reference/PRESENTATION-AND-UI.md) |
| Buttons, gestures and states | [Controller spec](docs/CONTROLLER_SPEC.md), [state matrix](docs/STATE_MATRIX.md) |
| Client/dependency assumptions | [Compatibility](docs/COMPATIBILITY.md) |
| Setup and maintenance | [Development](docs/DEVELOPMENT.md) |
| Checks and Retail proof limits | [Testing](docs/TESTING.md) |
| Open reports and gated capabilities | [Known issues](docs/KNOWN_ISSUES.md) |
| Changes and rationale | [Changelog](CHANGELOG.md), [decisions](docs/decisions/README.md) |
| Evidence, history and plans | [Reference index](docs/reference/README.md), [plans](docs/plans/README.md) |

## Development

Use Node 24 and Python 3.14 in this checkout:

```powershell
npm ci --ignore-scripts --no-audit --no-fund
python -B tools/check_documentation.py
./tools/Test-All.ps1
```

A fresh clone also needs the exact dependency cache populated through the
[dependency workflow](docs/DEPENDENCY-WORKFLOW.md). Tests themselves do not fetch
packages or read live game data. Read [setup](docs/DEVELOPMENT.md#setup) before
using refresh or reference-generation tools.

This checkout is the only working source of truth. OneDrive contains production
storage and the user's untouched `Documents`. Installation needs separate
current authorization with WoW closed. Public/adaptive product work is deferred.
