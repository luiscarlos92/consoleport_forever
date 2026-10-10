"""Retain the exact current-source set used by offline contract tests."""
import json
from repository_paths import ROOT, contained, output, sha

FILES = [
    'ConsolePort/Controller/Pager.lua',
    'ConsolePort_Bar/Widget/Bar/Bar.lua',
    'ConsolePort/Controller/Mouse.lua',
    'ConsolePort/View/Cursors/Crosshair.lua',
    'ConsolePort_World/Controller/Ping.lua',
    'ConsolePort_Bar/Controller/Blizzard/Mainline.lua',
    'ConsolePort/API.lua',
    'ConsolePort/Utils/Utils.lua', 'ConsolePort/Utils/Database.lua', 'ConsolePort/Utils/Const.lua',
    'ConsolePort/Controller/Input.lua', 'ConsolePort/Controller/Layers.lua',
    'ConsolePort/Libs/External/LibActionButton-1.0/LibActionButton-1.0.lua',
    'ConsolePort_Bar/Widget/Button/Button.lua', 'ConsolePort_Bar/Widget/Group/Group.lua',
    'ConsolePort_Cursor/View/Cursor.lua', 'ConsolePort/LICENSE.md',
    'ConsolePort_Rings/Model/Container.lua', 'ConsolePort_Rings/Model/Map.lua',
    'ConsolePort_Rings/Controller/Secure.lua', 'ConsolePort_Rings/Database.lua',
    'ConsolePort_Rings/Controller/Auto.lua',
    'ConsolePort_Cursor/Controller/Stack.lua', 'ConsolePort_Cursor/Controller/Scroll.lua',
    'ConsolePort/Libs/External/RelaTable/RelaTable.lua',
    'ConsolePort/Controller/Radial.lua', 'ConsolePort/Controller/Convenience.lua',
    'ConsolePort/Libs/External/ConsolePortNode/ConsolePortNode.lua',
    'ConsolePort_Cursor/Controller/Hooks.lua',
    'ConsolePort/Controller/Modules.lua', 'ConsolePort_Menu/View/Popup/ItemMenu.lua',
    'ConsolePort/Model/Game/Bindings.lua', 'ConsolePort/Libs/Local/ActionButton.lua',
    'ConsolePort_Bar/Controller/Manager/Manager.lua',
    'ConsolePort/Model/Gamepad/Gamepad.lua', 'ConsolePort_Keyboard/View/Keyboard.lua',
    'ConsolePort_Menu/Controller/UnitMenu.lua',
    'ConsolePort/Utils/Macro.lua',
    'ConsolePort_Bar/Model/Utils.lua',
    'ConsolePort_Cursor/Controller/Scripts.lua',
    'ConsolePort_Config/Model/Database.lua',
    'ConsolePort_Config/View/Config/Config.lua',
    'ConsolePort/Model/Data/Data.lua',
    'ConsolePort_Bar/Model/Interface.lua',
    'ConsolePort_Bar/Model/Upgrade.lua',
    'ConsolePort_Bar/View/Config/Loadout.lua',
    'ConsolePort_Bar/View/Pet/Petring.lua',
    'ConsolePort_Menu/Model/Buttons.lua',
]
if __name__ == '__main__':
    lock = json.loads((ROOT / 'dependencies/lock.json').read_text(encoding='utf-8'))
    package = next(p for p in lock['packages'] if p['repo'] == 'seblindfors/ConsolePort')
    records = []
    for name in FILES:
        source = contained(ROOT / package['unpacked'] / name)
        expected = package['files'][name]
        if sha(source) != expected:
            raise ValueError('Pinned source drift: ' + name)
        target = output(ROOT / 'evidence/consoleport-contracts' / name)
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(source.read_bytes())
        if sha(source) != expected or sha(target) != expected:
            raise ValueError('Source changed during capture: ' + name)
        records.append({'path': name, 'sha256': expected})
    output(ROOT / 'evidence/consoleport-contracts/manifest.json').write_text(json.dumps({
        'version': package['version'], 'releaseURL': package['releaseURL'],
        'packageSHA256': package['sha256'], 'purpose': 'Exact unmodified source audit/test contracts; not deployed dependency copies.',
        'files': records}, indent=2), encoding='utf-8')
    print('Captured', len(records), 'pinned contract files')
