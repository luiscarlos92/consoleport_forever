# Candidate.16 — model gaps and native visual repairs

The user confirms candidate.15's duplicate aura row is fixed and roundness stays
correct. Trigger labels disappeared and ready round spells still look grey in
combat. Previous passing tests did not establish actual rendering success.

Concrete trigger defect: native CPGroupBar factory creates banks under
ConsolePortBarManager, an unanchored secure frame (official Manager.xml). Native
SetCommonProps positions banks relative to UIParent. Candidate.15 positioned its
independent trigger anchor relative to the manager instead. A shown frame/glyph
therefore had no valid screen rectangle. The old geometry model parented native
banks to UIParent and masked this defect. Read-only saved client diagnostics also
reported two decorative groups without valid clear placement. Now T45/T50 run the
exact current official Group factory and unanchored manager hierarchy, test actual
glyph visibility/effective alpha and rectangles. Reverting the anchor to manager
must fail. Trigger positions remain at inactive geometry through combat changes.

The class chord chooses the bank: paladin/druid L1+L2 places the badge below L2;
R1+R2 stays below R2. Approved 26-unit icon/18-unit prompt and relative anchor stay.
An unprotected OnUpdate mirrors the owning bank's live alpha through selection
fade. Source-bank show/hide is mirrored; callbacks from an old bank cannot hide
an ornament reassigned to the other bank. T51 checks side, proportional placement,
exact dimensions, five fade samples and hide/show/reassignment.

Concrete colour event-order defect: T49 originally tested recovery after our
explicit refresh, then treated passed cached native availability flags as actual
usability without reconnecting them to the query. Native LAB UpdateUsable may
write a cached unavailable tint after our refresh. The texture hook only repaired
desaturation/opacity, leaving this later tint grey. A new reproduction executes
actual native UpdateUsable after the custom refresh, with cached unavailable flags
and a currently usable native action query. Candidate.15 fails that assertion.
Now the final setter hook reconciles current native usability colours with a
reentrancy guard. Actual unusable/resource/range colours remain tested. A nil
no-mana result is normalized false without inventing a usability result.
This proves a source failure path; it does not establish that every live grey
icon has this cause. The user still must confirm Retail rendering.

To make remaining failures diagnosable, bounded combat/peace snapshots retain
observed values: incoming native tint, resulting icon tint/alpha/effective alpha,
desaturation, usability query, slot/spell query and shown/alpha states of overlays
and cooldowns, including D-pad controls. They record observations rather than
expected values, preserve combat evidence after combat ends, and replace secret
values with [opaque] markers. Automatic snapshots are throttled, with immediate
combat-state transition capture. /cpf diagnose forces a snapshot. All data saves
through normal in-game SavedVariables; no filesystem WTF edits. T52 checks the
observed grey-ready case, cooldown shading, opaque handling and evidence retention.

The actual Masque Normal_Custom retirement and round sprites/masks remain.
Ground.lua is byte-identical to user-tested candidate.13. Native aura row fix,
revision 17 bindings and input recovery remain. All full native T41/T42 dispatch
checks and full runtime/tooling suites are required before scoped deployment.

Nine official stable Retail dependencies freshly checked: all current, none
updated/downloaded/reshipped. Deployment uses scoped builder/installer with WoW
closed, backups, unchanged WTF/unselected addons/junctions and independent readback.

Validation: all 52 runtime/source suites and 39 tooling checks passed. Reports
are retained in evidence/forever-ui/candidate16-runtime-tests.json and
candidate16-tooling-tests.json. These are offline/source execution results;
Retail rendering acceptance remains pending the user test.
