# Forever controller UI parity — October 8, 2026

Candidate.12 / configuration revision 15. The user authorized implementing the
attached Forever reference, closed-WoW deployment, and automatic application of
the necessary bindings on first use. Forever appearance and behavior take
precedence over the previous companion arrangement. Do not substitute the old
R2+menu opener for the photographed class shortcut.

Research uses Blizzard-authored Forever UI source pinned at
`15666a6e67938a1ab5caf041406464251db111ca` and the official ConsolePort 3.3.10 package.
The 14 source files, individual hashes and original URLs are retained in
`evidence/forever-ui/native-manifest.json`. No vendor source is modified.

- [Blizzard action-button source](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_GamepadActionBars/ActionBarButton.lua)
  supplies circle borders for normal/pressed/hover/selected states, a circular
  icon mask and separate circle effects. Empty-slot artwork includes grey
  D-pad arrows and controller-specific face symbols. Shapes uses PlayStation
  cross/circle/square/triangle; Letters uses Xbox labels; Reverse swaps labels.
- [Blizzard class flyouts](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_GamepadActionBars/Camelot/ClassSpellFlyout.lua)
  assigns warrior flyout 269 to the right class button, druid 262 and paladin 270
  to the left. The screenshot's warrior RB+RT opens its stance selector.
  [The XML](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_GamepadActionBars/MainActionBarFrame.xml)
  pairs each class button with its same-side shoulder and trigger prompt.
- [Official ConsolePort device API](https://github.com/seblindfors/ConsolePort/blob/3.3.10/ConsolePort/Model/Gamepad/Gamepad.lua)
  exposes the selected device's glyphs and actual modifier-button index.
  [DualSense metadata](https://github.com/seblindfors/ConsolePort/blob/3.3.10/ConsolePort/Model/Gamepad/PlayStation5.lua)
  maps shoulders to L1/R1 and triggers to L2/R2. Xbox uses LB/RB and LT/RT.

Implementation

HUDPresentation.lua owns decorative layers only. All 32 face/D-pad cells retain
an independent grey default glyph backdrop, including unused action slots. The
16 face buttons use circle borders, backgrounds, flashes, cooldowns, casting,
reticle and interrupt masks. The already-retained Forever sheet supplies the
thin round border fallback (x 1044–1089, y 552–597 of 2048 square); it was inspected
from the actual BLP. Native Forever atlases are used only when Retail's
C_Texture.GetAtlasInfo confirms them; otherwise clean official ConsolePort
circular artwork and device glyphs are referenced. No new bitmap is redistributed.

Each of the three modifier banks has its own always-present trigger prompt:
left, right, and left+right. Prompts follow native modifier assignment and the
selected controller, including device/icon changes and bank/Masque rebuilds.
Targeting shoulder glyphs also follow that device, replacing hard-coded PS5 labels.
Existing geometry, native visibility/alpha drivers and all action slots remain.

ClassActions.lua implements the class-specific physical shortcut using native
ConsolePort's existing secure ring: warrior/right and Retail classes without a
Forever-specific left selector use CTRL-PADRSHOULDER (R1+R2/RB+RT); druid/paladin
use SHIFT-PADLSHOULDER (L1+L2/LB+LT). The legacy menu shortcut is cleared only when
it opens that same class ring. Unrelated menu/keyboard bindings remain. Learned
Retail forms/stances are added through native spell discovery/validation; manual
ring entries/order/metadata remain. The badge displays the active stance when
available and never advertises an unbound opener. This reuses native ring selection;
Forever's original client-specific protected flyout implementation is unavailable
in Retail. No custom gameplay paging or UI claim takeover is re-enabled.

First login

For an already accepted revision-14 character with accepted native ring data,
the addon automatically backs up and applies just the class chord and ring data
through its tested native binding and transaction adapters, outside combat/Edit
Mode and with the ring closed. It saves character bindings in game, advances to
revision 15 and verifies persistence on reload. Repeat login does not reapply.
Unavailable dependencies/protected conditions defer the transaction. A clean or
previously unaccepted setup continues through the normal initial install flow,
which now includes these bindings. Live WTF is never edited through file tools.
The migration transaction is the latest /cpf restore backup and contains actual
pre-migration bindings and ring contents. Failure uses existing compensation.

Validation

T24 covers all 32 backdrops, PS/Xbox/Reverse device changes, left/right class
prompts, absent/present native atlases, round effects, mask replacement, combat
deferral, sparse regions, native cooldown/range colors and Masque/bank recreation.
T43 checks class side, native ring suffix/validation/secure action compilation,
scoped proposals, unrelated-key preservation, idempotence and transaction restore.
The actual TOC bootstrap tests automatic revision-14 migration for warrior,
druid and paladin, actual binding save, no extra review, repeat-login no-op and
native binding-bank restore. T41 also sends the class chord through actual native
Layers/Input resolution and the native ring Hold body on both edges during
repeated UI/combat cycles, preserving all 32 native gameplay destinations. T42
continues to cover native ground targeting dispatch. Full runtime and tooling
reports are required before packaging. Offline fixtures do not establish actual
Retail hardware, visual or taint acceptance.

Dependency check

All nine official stable Retail releases were freshly checked this session.
Official DynamicCam 2.21.1 / file 8995535 and ExtraFade 1.18.0 / file 8995675 listings
and file pages were reviewed; seven GitHub latest stable identities were queried
with check_stable_sources.py --discover. All match the lock. No dependency was
downloaded, extracted or selected for deployment. The scoped delivery contains
only ConsolePort_Forever, preserving all vendors, inactive helpers, WTF and links.

Deployment outcome

The exact Forever-only package was installed at 06:16:20 UTC on October 8.
All 52 files match the tested ZIP. Independent readback confirms 1,949 vendor
files, 298 WTF files, 42 links and anchors unchanged, and verifies retained
companion/configuration backups. No dependency was copied. Both current saved
characters are accepted revision 14 with accepted bindings/rings, so the first
eligible login performs the authorized class migration automatically. Reports:
`evidence/delivery/live-install-candidate12.json` and
`evidence/delivery/candidate12-independent-readback.json`. All 43 runtime/source
and 39 tooling suites passed. Real Retail appearance, combat and controller
acceptance still require the user's login; the agent did not launch the game.
