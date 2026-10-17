# Client and integration compatibility

Status: maintained
Reviewed: 2026-10-16
Evidence: [TOC](../addon/ConsolePort_Forever/ConsolePort_Forever.toc),
[locked packages](../dependencies/lock.json),
[native source manifest](../evidence/native/manifest.json),
[ConsolePort contracts](../evidence/consoleport-contracts/manifest.json).

## Target and support boundary

Candidate.39 qualifies the same ConsolePort 3.3.10 default-ring source with guarded
ordinary validation/rebuild/edit adapters, additive version1 utility storage and
an independent kill switch. Native protected bodies/compiler/dispatch stay
unchanged. Source-level API and transition proof does not certify Retail engine
taint, hardware timing or performance; broader acceptance remains separate.
[Qualification](reference/SHARED-UTILITY-RING-RUNTIME-2026-10-14.md).

The current personal target is Retail, TOC interface `120100`, ConsolePort
3.3.10, Store schema 3 and configuration revision20. The
[current checkpoint](IMPLEMENTATION-STATUS.md) owns installed/accepted candidate
identity; candidate.35 does not change these native contracts. The capability probe records
`GetBuildInfo` metadata/readiness; it does not itself establish an all-build
support guarantee. No Classic or native Forever client support claim is made
for this companion. Third-party multi-client TOCs do not extend our support scope.

Candidate.37 retains these contracts and uses optional `issecurevariable` only
for read-only public labels on blocked-event observations; missing/unavailable
labels are omitted. Native cooldown setters and bar lifecycle remain untouched.
The [combat error audit](reference/COMBAT-ERROR-AUDIT-2026-10-13.md) distinguishes
demonstrated observer defects from the still-unknown Retail taint writer.

The Forever comparison snapshot is a separate source reference: branch `forever`,
1.60.1 build 70205, commit `e3ecc27b64d30fdc735a3f6579b866858f9f9df1`.
It describes inspected source, not a current Forever client test.
See [reference provenance](reference/EVIDENCE.md).

## Locked package identities

October 16 fresh official discovery and selective retrieval qualify BetterBags
v0.5.16, Plater-v661, DynamicCam 2.21.4 and ExtraFade 1.18.1 in the current lock. ConsolePort remains
3.3.10. The [fresh receipt](../evidence/dependencies/stable-recheck.json) reports
all current. New [versioned contracts](../evidence/integration-contracts-candidate41/manifest.json)
retain the old captures unchanged. Native item/merchant tests exercise the new
BetterBags input methods; optional Perf registration is modeled. DynamicCam's
current native RefreshConfig and defaults execute alongside the retained older
contract; AceDB ownership and profile lifecycle remain intact. ExtraFade's native
hide-module changes preserve its optional flat-settings contract. Folder closure
and notices are qualified. These four packages are prepared but not installed by
the Forever-only update. Exact guards additionally retain installed BetterBags
v0.5.14, DynamicCam 2.21.1/2.21.2 and ExtraFade 1.18.0; Plater has no Forever profile adapter. Offline source qualification
does not establish Retail performance or taint acceptance.
[Selective qualification](../evidence/dependencies/candidate41-selective-qualification.json)
records the new archive delta and exact closure/notice evidence.

| Package owner | Locked version | Companion integration |
| --- | --- | --- |
| seblindfors/ConsolePort | 3.3.10 | Required main/bar plus native optional suite contracts. Exact guards in routing, rings, skin and UI; ground interception is retired. |
| Cidan/BetterBags | v0.5.16 | Audited bag adapter/custom UI path; full context takeover suspended. |
| seblindfors/Immersion | 1.4.61 | Reviewed flat settings and Forever-owned Required Items correction. Preserve upstream bytes and ImmersionSetup. |
| curseforge/Immersion_ExtraFade | 1.18.1 | Optional reviewed integration fields; retain exact 1.18.0 compatibility. |
| curseforge/DynamicCam | 2.21.4 | Managed native profile copies; preserve foreign profiles and selection lifecycle; retain 2.21.1/2.21.2. |
| xod-wow/LiteMount | 12.1.5-1 | All 115 files already match on disk before this Forever deployment; adapter additionally retains 12.1.0-1/12.1.0-2 support. No guessed second default icon. |
| SFX-WoW/Masque | 12.1.0 | Preserve native integration and composed round-face regression contracts. |
| Tercioo/Plater-Nameplates | Plater-v661 | Pack dependency; no Forever Plater profile adapter or profile/WTF installer. |
| SLOKnightfall/BetterWardrobe | 6.12.3 | Adopted package coverage including SourceData helper; no dedicated Forever settings adapter. |

The lock is authoritative for exact files, archive hashes and selected folders.
The October 13 check found LiteMount 12.1.5-1: the complete 115-file package adds
no folders/files and removes none. Only TOC/version, changelog and bundled
MountsRarity timestamp/data change; native action/button/rule/configuration code
and notices are identical. Its TOC retains Retail interface 120100. Qualification
does not imply engine acceptance. All 115 qualified files already match on disk
in the pre-deployment snapshot; this investigation performs no LiteMount
replacement. Loaded engine metadata is separate from that disk evidence. The
urgent diagnostic delivery uses the tested Forever-only running-game route.
Candidate.38's diagnostic posthooks target only matching stock `UpdateAction`
methods on at most 102 named native buttons. They inspect security labels without
reading action values or invoking updates. C posthook/stack behavior remains a
Retail proof boundary; no taint-clearing ability is claimed.
The table is a reviewed snapshot, not a fresh-check substitute.
[Sources](../dependencies/sources.json) and
[stable recheck](../evidence/dependencies/stable-recheck.json) record official
discovery. DBM, HideClassBars and SharedMedia_Causese are retired, not missing
requirements. Keep inactive helpers and unrelated folders unless named retirement
is authorized.

## Runtime/API constraints

Candidate.41 activates the follower adapter from the exact public active zone
ability 426756. It needs neither PartyInfo nor LFG queue flags. The former
PartyInfo gate referenced an API absent from the captured Blizzard contract;
the corrected fixture rejects undeclared APIs and executes the real utility
initialization. The native protected named-spell route and server follower state
remain authoritative. [Activation investigation](reference/FOLLOWER-DUNGEON-ACTIVATION-2026-10-16.md)
records the demonstrated startup defect and subsequent scoped user acceptance
of candidate.41. This does not extend the supported client/API contract or imply
blanket taint, hardware, rendering or performance acceptance.

- Native secure frames/handlers, restricted macro dispatch and native ownership
  are separate from public Lua callbacks. A public clock cannot gate protected work.
- Blizzard's pinned restricted compiler rejects constructs ordinary Lua accepts.
  Lua 5.1 syntax and Fengari Lua 5.3 execution are different checks.
- Main reviewed/protected configuration waits outside combat/Edit Mode.
  Individual guards differ: preference Apply blocks combat only, ping refresh
  defers combat, and saved diagnostic bookkeeping has its own rules. Qualified
  predeclared secure input may operate in combat; public refresh is not equivalent
  authority. Do not infer a universal Edit Mode guard from the main `CanWrite`.
- Retail secret values must not be compared/coerced as ordinary public values.
  Offline tagging models are incomplete; retain native feedback and proof limits.
- Native TOC/load conditions, method identity, ownership, data readiness and
  optional-addon presence matter alongside version strings. Unknown contracts
  fail closed and report pending rather than modifying upstream.
- Native saved layouts and game-owned action persistence remain authoritative.
  Shared physical SavedVariables paths cannot identify character ownership.

On an update, inspect affected upstream source/closure/notices and refresh pinned
contracts only through their capture workflow. Changing a guard string alone is
not qualification. See [dependency procedure](DEPENDENCY-WORKFLOW.md) and
[testing](TESTING.md). Update this page when a supported assumption changes.

Circle qualification additionally uses the pinned native saved-macro branch,
inherited secure template, synchronous UPDATE_MACROS and constants for 120 account
and 30 character macros. Unknown limits/APIs, secret reads, edited/duplicate names
and full capacity defer without overwrite. Native RunMacro permissions and secure
provenance still require Retail acceptance; the reported RunMacroText route is
removed. [Repair research](reference/CIRCLE-BLOCKED-ACTION-2026-10-12.md).

## Optional integration behavior

Exact version alone is insufficient: BetterBags needs the physical initialized
item pool/native item identity; rings need native data/environment readiness;
UI routes require audited method identity and actual owner. BetterBags remains
dormant with custom context acquisition. LiteMount icon integration does not
change mount rules. Plater/BetterWardrobe have package qualification without a
dedicated Forever settings profile.

Immersion/ExtraFade field review preserves existing explicit typed values and
excludes missing/unknown/transient fields. DynamicCam clones the actual current
profile through its native lifecycle, rejecting unsupported namespaces/wildcard
defaults and foreign name collisions. Required Items repair additionally checks
the specific dialog, measurement methods, anchors/preferences and deferred quest
identity. [Configuration details](reference/RUNTIME-CONFIGURATION.md) record these
contracts; do not infer a generated camera preset or upstream patch from older plans.
