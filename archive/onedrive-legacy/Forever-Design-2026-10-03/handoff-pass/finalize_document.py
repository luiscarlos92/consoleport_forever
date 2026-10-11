"""Reconcile old design registers and verify the handoff without live writes."""
import hashlib
import json
from pathlib import Path
import re
from validate_handoff import ROOT, OUT, digest, inventory

MASTER = ROOT/'ConsolePort-Forever-Phased-Plan-2026-10-03.md'
MARKER = '## Historical source records — complete consolidated text'

def main():
    original=MASTER.read_text(encoding='utf-8')
    active,history=original.split(MARKER,1)
    statuses={
      'D03':'**Approved intent, secure proof pending.** H0 disallows combined-cancellation fallback; preserve baseline and record unsupported exact behavior without asking in implementation chat.',
      'D05':'**Resolved in H0:** one GUID-owned controller/ring arrangement per character; preserve native spec/loadout spell bars; no companion per-spec controller profile.',
      'D07':'**Resolved in H0:** prove extension against current ConsolePort Layers first; companion-owned secure buttons at the same geometry are approved if it fails.',
      'D09':'**Approved attempt; H0 fallback resolved:** exact secure stick-return target, unsupported gestures pending, no hold/release substitution. Existing openers retained; pet opener separately approved.',
      'D10':'**Resolved in H0:** retain L2+R3 extra action, current quest/zone ring behavior and native vehicle-exit access; unexpected overflow pending with native access preserved.',
      'D11':'**Semantic direction approved:** contextual Cross/Square/Triangle/Circle operations; BetterBags internal right-click dispatch retained where needed. Unsupported adapter gestures remain pending.',
      'D13':'**Resolved in H0:** native character binding sets with four shared faces mirrored and GUID-owned 28 cells. Preserve keyboard; linked cache remains only the current view.',
      'D15':'**Resolved in H0/H8:** per-character prompts, decline/retry, Reload now/later, fresh transaction backups retained initially, conflict-aware restore, user-run installation.',
      'D16':'**Resolved in H0:** managed copies where supported, original profiles retained; field-owned updates/backups for flat settings. Current runtime layout capture is authoritative.',
      'D17':'**Resolved in H0:** preserve current presentation/geometry; no additional compact/legend redesign. Approved focused-UI icon behavior remains D29.',
      'D18':'**Resolved in H0:** preserve current targeting/zoom/autorun/ping; no additional targeting/HUD overlay or new gameplay chord.',
      'D19':'**Resolved in H0:** retain one ordinary arrangement; no extra ordinary page-switch controls or system-menu remake.',
      'D20':'**Resolved in H0:** retain ConsolePort editor initially; no native-editor remake/new assignment gestures.',
      'D21':'**Resolved in H0:** preserve current hidden Blizzard bars/bag strip, expose Config where unnecessarily hidden; use current supported runtime visibility paths, no Modern reset.',
    }
    lines=active.splitlines(keepends=True)
    for i,line in enumerate(lines):
        match=re.match(r'^\| (D\d\d) \|',line)
        if match and match[1] in statuses:
            cells=line.rstrip('\r\n').split('|')
            cells[-2]=' '+statuses[match[1]]+' '
            lines[i]='|'.join(cells)+'\n'
    active=''.join(lines)
    replacements={
      '**Implementation handoff order:** read current decisions → finish only blocking baseline/preferences → establish confirmed Git/GitHub baseline → implement R00/R05/R06 foundation → approved secure/ring/UI/profile features → tests → full backup/audited restoration → commit and push → guarded companion code deployment → in-game install/update acceptance → runtime checklist/corrections. Do not create a remote/branch identity or deploy from this report alone.':
      '**Implementation handoff order (updated):** H0 choices → verified current-product/reference Git baseline H1 → current stable dependency lock H2/H3 → foundation and approved features H4–H6 → automated suites H7 → commit/push and verified pack/scripts H8 → deliver to user → user installation, runtime configuration acceptance and final client checks. No live deployment by the implementation chat.',
      '> Use this master document\'s current decisions and Phase 2 report. Preserve the current live configuration, linked character folder and four-bank geometry. Resolve the named pending decisions with Forever behavior explained first. Set up the confirmed Git repository before code changes. Implement approved behavior only inside ConsolePort_Forever; deliver configuration through its runtime installer/patcher. Prove protected features, back up every addon before audited restoration, commit/push before deployment, and use the consolidated acceptance checklist.':
      '> Use the updated starting instruction in H9. All preference answers are in H0; copy the current product/references into the confirmed Git repo first, build and validate the current-dependency UI pack, leave unsupported exact gestures pending, and deliver for user installation/final game tests without implementation-chat questions.',
      'D18/D20 remain open. Ordinary-window approval does not approve a full HUD/editor remake, altered zoom or targeting chords.':
      'H0 resolves D18/D20 to preserve current targeting and ConsolePort editor. Ordinary-window approval does not authorize a HUD/editor remake or altered gameplay chords.',
      'If exact sequencing fails, stop that implementation path and present D03\'s alternative: a hardware-triggered cancellation macro that can perform multiple cancellations. That semantic change has **not** been approved.':
      'If exact sequencing fails, stop that feature path, preserve baseline and mark exact Circle pending under H0. A macro that performs multiple cancellations is explicitly not an approved fallback; do not ask the unavailable user to choose it.',
      'If no valid path exists in the tested Retail build, record that mechanism as unavailable and ask before adopting a release/accept fallback. Do not silently ship the fallback as the copied gesture.':
      'If no valid path exists, record exact activation as unavailable/pending under H0, preserve baseline and continue other features. Release/accept substitution is not approved and no new implementation-chat question is required.',
      'A failed mechanism must return with evidence and a specific question; do not silently select a fallback.':
      'A failed mechanism must record evidence and remain locally pending under H0; do not select a fallback or ask a new implementation-chat question.',
      '**D05 explanation requested — native spell contents versus optional controller profiles:**':
      '**D05 explanation and final decision — native spell contents versus controller arrangements (H0 selects character-only):**',
      'D13 must choose between character binding sets with shared fields mirrored at runtime, or a shared underlying set plus character-specific secure overrides. Do not silently switch binding-set choice;':
      'H0 selects character binding sets with shared fields mirrored at runtime. Preserve keyboard bindings during the explicit approved set transition;',
      'D05 chooses storage; manual-page behavior needs explicit preservation/review.':
      'H0 chooses character arrangements with native spec spell bars preserved; retain ordinary page behavior without adding new page-switch controls.',
      'This design targets the installed 3.2.6 interfaces; a dependency upgrade requires rechecking adapters. No upgrade has been applied or selected.':
      'This earlier design targeted installed 3.2.6. H0/H2 now require current stable dependencies; H3 records 3.3.3 input-layer changes. No live upgrade has been applied in this planning pass.',
      'Capability.lua | Probe build, addon/module loaded state, required globals/methods, registered CVars and supported saved schemas. Record available/unsupported/deferred per capability. No automatic dependency upgrade.':
      'Capability.lua | Probe build, enabled/loaded/data-ready modules, methods, CVars and supported saved schemas. Record per-feature status; dependency packages are resolved externally in Git by H2, never downloaded by runtime Lua.',
      'The latest request starts analysis/design now. It does not authorize implementation or silently accept every discovered Forever behavior. See the detailed Phase 2 report and its decision register before starting code.':
      'The analysis/design choices were finalized in H0. This planning pass does not implement them; the next implementation chat follows H0–H9, including Git before product edits and user-only installation.',
      'Use these stable IDs when answering. “Proceed” applies only to the named behavior/proof, not every alternative in the row. Implementation approval still requires the separate Git/deployment phase. No preference is inferred from unanswered questions.':
      'Stable decision IDs are retained for traceability. H0 records the final answers; Git setup precedes authorized product edits. Technical proof remains distinct from user preference, and delivery is build-only for user installation.',
      'The exact per-class entry lists require the user\'s review;':
      'H0 approves learned forms/auras and current pet actions; other class utilities remain manual rather than requiring implementation-chat review;',
    }
    applied=[]
    for old,new in replacements.items():
        if old in active:
            active=active.replace(old,new)
            applied.append(old[:100])
    # Older R ticket gate wording must agree with the resolved fail-safe policy.
    active=active.replace('Failure → D07 review, not dependency patch.',
                          'Failure → approved secure-button fallback H0, never a dependency patch.')
    active=active.replace('Unsupported path → evidence and explicit fallback question.',
                          'Unsupported path → evidence and pending feature under H0, no gesture substitution.')
    active=active.replace('User confirms current baseline; no old preset substituted.',
                          'Automatic first-login capture/preservation approved in H0; no old preset substituted.')
    active=active.replace('Ambiguous classification or >8 case → concrete user review.',
                          'Ambiguous classification/>8 → pending case, native access retained under H0.')
    # Reconcile old remaining-details prose while retaining the previous record in snapshots/history.
    heading='### Remaining historical details for phase-specific decisions'
    if heading not in active:
        heading='### Remaining historical details — resolved or deferred in H0'
    start=active.index(heading)
    active=active[:start]+'''### Remaining historical details — resolved or deferred in H0

H0 resolves repository identity, profile policy, character/spec storage, binding model, retained shortcuts/presentation/editor, pet opener, backup/reload and user installation. Earlier sources do not override those answers. Exact protected input paths, unknown overflow, dependency compatibility and source retrieval follow the preserve/pending/incomplete rules. Public/adaptive work, ground targeting and keyboard changes remain deferred. No new questions are required in the implementation chat.

'''
    final=active+MARKER+history
    MASTER.write_text(final,encoding='utf-8',newline='\r\n')
    prior=(ROOT/'Forever-Design-2026-10-03/master-before-phase2.txt').read_text(encoding='utf-8-sig')
    history_equal=prior.split(MARKER,1)[1]==history
    before=json.loads((OUT/'preservation-before.json').read_text(encoding='utf-8'))
    after=inventory()
    changed=[p['path'] for p in before if not Path(p['path']).is_file() or digest(Path(p['path']))!=p['sha256']]
    sources=[]
    undefined=[]
    refs={m[1]:m[2] for m in re.finditer(r'^\[([^]]+)\]:\s+<?([^\n>]+)>?$',active,re.M)}
    for ref in set(re.findall(r'\]\[([DFA]-[^]]+)\]',active)):
        if ref not in refs: undefined.append(ref)
    for ref,path in refs.items():
        if re.match(r'^[A-Z]:[/\\]',path):
            sources.append({'reference':ref,'exists':Path(path).exists()})
    suites=re.findall(r'^\| (T\d\d) ',active,re.M)
    result={'masterSHA256':digest(MASTER),'historicalAppendixUnchanged':history_equal,
            'liveFiles':len(before),'liveInventoryUnchanged':before==after,'changedLivePaths':changed,
            'testSuites':suites,'testSuitesUnique':len(suites)==len(set(suites))==29,
            'undefinedReferences':undefined,'localSourceAnchors':sources,
            'legacyRegisterRowsUpdated':list(statuses),'textReconciliations':len(applied),
            'implementationPerformed':False,'deployed':False,'runtimeTestsPerformed':False}
    (OUT/'document-verification.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
    print(json.dumps({k:v for k,v in result.items() if k not in ['localSourceAnchors','legacyRegisterRowsUpdated']},indent=2))
    if changed or before!=after or not history_equal or undefined or not result['testSuitesUnique'] or any(not s['exists'] for s in sources):
        raise SystemExit(1)

if __name__=='__main__': main()
