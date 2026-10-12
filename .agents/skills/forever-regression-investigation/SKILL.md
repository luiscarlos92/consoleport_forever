---
name: forever-regression-investigation
description: Diagnose and repair ConsolePort Forever regressions or disputed validation by tracing native ownership, state transitions and meaningful defect reproductions. Use for input, visual, persistence or integration failures; ordinary documentation edits do not need this workflow.
---

# Regression investigation

Use [current status](../../../docs/IMPLEMENTATION-STATUS.md), the affected
[requirement](../../../docs/REQUIREMENTS.md) and [state matrix](../../../docs/STATE_MATRIX.md)
to establish expected behavior and actual activation. Apply root authority rules;
this skill grants no deployment, live input or upstream mutation permission.

## Inputs and investigation

Identify reported candidate, class/spec, context, modifiers, focus/owner, transition
and observable symptom. Missing observations can remain unknown; do useful source
work before asking. Read the relevant dated diagnosis/acceptance through the
[history index](../../../docs/reference/README.md). Separate direct user intent,
persisted state, source findings and suspected live cause.

Trace the actual active code, native contract/loading, effective binding/handler,
event order, ownership and version/readiness guards. For visuals inspect final
composition, actual hierarchy and later writes; for persistence inspect GUID,
native editing and stale caches/latches. Do not infer a cause from a shown button,
white icon getter or saved binding alone. Unknown quest/engine evidence does not
justify a speculative patch.

## Reproduce and qualify

Choose relevant gates from [TESTING.md](../../../docs/TESTING.md). Execute actual
native source where the boundary matters, including the restricted compiler for
secure bodies; disclose modeled C APIs/engine/taint/timing. Demonstrate the old
defect, make the scoped authorized repair and require a meaningful negative
control to reject the old behavior. Preserve manual edits and accepted unrelated
features. Never re-enable automatic slot restoration or suspended takeover as a
convenient workaround.

Run targeted checks while developing, then the required full gates for runtime/
tool changes. Do not duplicate tests that simply restate the implementation.
Independent paired review is available when the user requests it; it is not an
automatic requirement for every bug.

## Output and stopping boundary

Produce a diagnosis with established facts, hypotheses/unknowns, change scope,
regression evidence and remaining Retail observations. Update affected specs and
[known issues](../../../docs/KNOWN_ISSUES.md). Retain exact receipts for significant
qualification; success is demonstrated defect rejection plus applicable green
checks, not a claim of live acceptance. If diagnosis cannot select a repair,
record the smallest meaningful observation needed. Preparation ends without
installation unless current user authority separately permits it.
