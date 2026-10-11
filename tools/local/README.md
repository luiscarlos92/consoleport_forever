# User provisioning scripts

These two user-authored PowerShell scripts were relocated from the OneDrive WoW
root on October 11, 2026. `Setup-WoW-OneDrive.ps1` uses an explicit production
destination after relocation; `Setup-WoW-CharacterTemplateLinks.ps1` already
contains the correct absolute production path.

They are historical local provisioning tools with destructive operations,
including removal of local game folders and replacement of character folders
with junctions. They were parsed for syntax only during organization and were
not executed. They are not the routine addon deployment workflow. Routine
updates use the tested scoped `tools/build_update.py` and `tools/deploy_update.py`
after explicit authorization with WoW closed.
