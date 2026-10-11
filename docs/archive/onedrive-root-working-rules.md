# WoW addon development

The product checkout is `C:/Users/luisr/Dev/consoleport_forever`. Before making
changes, read that checkout's `AGENTS.md`, `docs/MASTER-PLAN.md` and current
implementation status.

The user's standing workflow requires a fresh check of **every dependency's
official stable Retail release before each work session**. Download/update only
changed packages in the Git checkout, inspect and test compatibility, and fix
anything required. Do not treat cached prior-session metadata as a fresh check.

On an authorized deployment with WoW closed, copy only ConsolePort_Forever and
dependencies that actually changed, using the tested scoped update builder and
installer in the product checkout. Do not repeatedly copy unchanged packages or
prune CurseForge-owned helpers/inactive addons. Never edit live WTF files through
filesystem tools. Preserve backups and junctions; normal in-game saving/review
remains game-owned. A request to prepare code without deployment stays binding
until the user later authorizes deployment.
