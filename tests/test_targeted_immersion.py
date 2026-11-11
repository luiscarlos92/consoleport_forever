"""The narrow release route must reject stale proof and unrelated changes."""
import copy
from pathlib import Path
import sys
import unittest
sys.path.insert(0, str(Path(__file__).resolve().parents[1]/'tools'))
from build_update import validate_targeted_immersion


class TargetedImmersion(unittest.TestCase):
    def setUp(self):
        self.base = {'productHashes': {'addon/ImmersionExtended_Forever/Progress.lua': 'old',
                                      'addon/ConsolePort_Forever/Core.lua': 'protected'},
                     'toolingHashes': {'tools/build_update.py': 'old'}}
        self.current = copy.deepcopy(self.base)
        self.current['productHashes']['addon/ImmersionExtended_Forever/Progress.lua'] = 'new'
        self.current['toolingHashes']['tools/build_update.py'] = 'new'
        self.current['results'] = [{'id': name, 'status': 'passed'} for name in (
            'T109.forever-immersion-extension-native-lifecycle-and-layout',
            'T110.forever-immersion-extension-defect-and-work-controls')]
        self.actual = copy.deepcopy(self.current)

    def test_only_selected_extension_and_named_qualification_tools(self):
        validate_targeted_immersion(self.base, self.current, self.actual)

    def test_config_route_requires_its_own_checks_and_preserves_immersion(self):
        base = {'productHashes': {'addon/ForeverConfig_Extended/BetterBags.lua':'old',
                                 'addon/ImmersionExtended_Forever/Progress.lua':'protected'}, 'toolingHashes':{}}
        current = copy.deepcopy(base)
        current['productHashes']['addon/ForeverConfig_Extended/BetterBags.lua']='new'
        current['results']=[{'id':'T111.forever-config-diagnostics-and-retired-writes','status':'passed'}]
        validate_targeted_immersion(base,current,current,'ForeverConfig_Extended')
        current['productHashes']['addon/ImmersionExtended_Forever/Progress.lua']='foreign'
        with self.assertRaisesRegex(ValueError,'outside targeted'):
            validate_targeted_immersion(base,current,current,'ForeverConfig_Extended')

    def test_foreign_addon_or_tool_change_rejected(self):
        for group, name in [('productHashes', 'addon/ConsolePort_Forever/Core.lua'),
                            ('toolingHashes', 'tools/deploy_update.py')]:
            with self.subTest(name=name):
                current, actual = copy.deepcopy(self.current), copy.deepcopy(self.actual)
                current[group][name] = actual[group][name] = 'foreign'
                with self.assertRaisesRegex(ValueError, 'outside targeted'):
                    validate_targeted_immersion(self.base, current, actual)

    def test_stale_missing_duplicate_or_failed_proof_rejected(self):
        self.actual['productHashes']['addon/ImmersionExtended_Forever/Progress.lua'] = 'later'
        with self.assertRaisesRegex(ValueError, 'inventory changed'):
            validate_targeted_immersion(self.base, self.current, self.actual)
        for results in ([], [self.current['results'][0]] * 2,
                        [dict(r, status='failed') for r in self.current['results']]):
            with self.subTest(results=results):
                self.current['results'] = results
                with self.assertRaisesRegex(ValueError, 'Exact passing'):
                    validate_targeted_immersion(self.base, self.current, self.actual)
