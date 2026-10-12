# 0001: Separate current knowledge from historical instructions

Status: maintained
Reviewed: 2026-10-11
Evidence: [restructure receipt](../../evidence/organization/2026-10-11/ai-native-restructure.json),
[historical snapshots](../archive/ai-native-2026-10-11/README.md),
[audit](../reference/DEVELOPMENT-HISTORY.md).

Decision: approved by the user on October 11: “I approve all, proceed with restructure.”
This accepts the preceding audit's three decisions and implementation scope.

Context: a 70,461-byte root AGENTS file, approximately 624 KB master plan and
150 KB status narrative mixed current behavior with superseded permissions and
release claims. Existing tests/tooling were substantial; navigation and authority
separation were missing.

Chosen approach: preserve original bytes as marked history, make root/current
pages concise, populate approved project docs, add six sourced decision records,
three repository-local workflow skills and scoped test/tool instructions. Add a
small read-only documentation checker to existing validation/CI. Keep runtime
locations/loading and preserved evidence unchanged; no deployment.

Freshness exception: read-only and documentation/agent-instruction-only sessions
need no upstream check when changing no runtime, dependency, packaging or
executable tooling contract. Product/tooling sessions retain fresh all-source
checks. A cached lock/table still cannot be described as fresh metadata.

Consequences: affected-document maintenance replaces duplicated release headers.
Historical links remain original, with a current migration index. Skills reference
existing procedures rather than duplicate logic. Review metadata marks actual
review; checker success does not establish semantic truth or Retail behavior.

Alternatives considered: additive docs alongside unchanged huge active pages
(retains ambiguous authority); moving all historical reports (unnecessary link
churn); more overlapping subsystem skills/new test frameworks (unnecessary cost).
Additional parity/configuration/documentation skills, hooks and public/adaptive
work remain deferred. This decision supersedes the unqualified every-session
dependency check only for the stated narrow exception.
