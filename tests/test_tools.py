import io
import json
from pathlib import Path
import sys
import os
import subprocess
import tempfile
import unittest
from unittest.mock import patch
import zipfile
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from repository_paths import ROOT, contained, output, fixture_copy, sha
from resolve_dependencies import members
import resolve_dependencies
import audit_dependencies
from audit_dependencies import runtime_closure
from inventory_notices import inventory
import audit_migration


class ToolGuards(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        output(ROOT/'scratch').mkdir(exist_ok=True)

    def test_adopted_dependency_coverage_preserves_reference(self):
        installed = ['Existing', 'Helper']
        sources = {'additionalAddonFolders':['BetterWardrobe', 'Existing']}
        self.assertEqual(resolve_dependencies.selected_coverage(installed,sources), ['BetterWardrobe','Existing','Helper'])
        self.assertEqual(installed,['Existing','Helper'])
        for value in [['../escape'], ['C:escape'], ['CON'], 'BetterWardrobe']:
            with self.assertRaises(ValueError):
                resolve_dependencies.selected_coverage(installed,{'additionalAddonFolders':value})

    def test_retired_coverage_is_explicit_and_survives_future_resolution(self):
        installed=['Keep','HideClassBars','DBM-Core']
        sources={'retiredAddonFolders':{n:{'owner':'retired/Owner','reason':'User removed'} for n in installed[1:]}}
        self.assertEqual(resolve_dependencies.selected_coverage(installed,sources),['Keep'])
        self.assertEqual(installed,['Keep','HideClassBars','DBM-Core'])
        for retired in [[],{'../escape':{'owner':'x','reason':'x'}},{'Keep':{}}]:
            with self.assertRaises(ValueError): resolve_dependencies.selected_coverage(installed,{'retiredAddonFolders':retired})

    def test_empty_toc_fields_do_not_hide_required_dependencies(self):
        for newline in ['\n','\r\n']:
            text=newline.join(['## Interface: 120100','## Version: 6.12.3','## Notes:','## Dependencies: Blizzard_Collections, Blizzard_Transmog','Main.lua',''])
            row=resolve_dependencies.metadata([('BetterWardrobe/BetterWardrobe.toc',text.encode())])[0]['BetterWardrobe/BetterWardrobe.toc']
            self.assertEqual(row['Notes'],'')
            self.assertEqual(row['Dependencies'],'Blizzard_Collections, Blizzard_Transmog')
            self.assertEqual(row['Version'],'6.12.3')

    def test_native_required_addons_are_explicit_and_hash_qualified(self):
        self.assertEqual(audit_dependencies.native_addon_dependencies({'Blizzard_Unknown','ThirdParty'}),{})
        native = audit_dependencies.native_addon_dependencies({'Blizzard_Collections','Blizzard_Transmog'})
        self.assertEqual(set(native),{'Blizzard_Collections','Blizzard_Transmog'})
        self.assertTrue(all(row['clientOwned'] and not row['shipped'] for row in native.values()))
        with patch.object(audit_dependencies,'sha',return_value='drift'):
            with self.assertRaises(ValueError):
                audit_dependencies.native_addon_dependencies({'Blizzard_Collections'})

    def test_matching_packaged_migration_classification(self):
        self.assertEqual(audit_migration.classify(b'x\r\n',b'x\n','Example/a.lua'),'line-endings-only')
        with tempfile.TemporaryDirectory(dir=ROOT/'scratch') as temp:
            scope=Path(temp); baseline=scope/'baseline';baseline.mkdir()
            sources={'Example/format.lua':b'local x = 1 -- original\n',
                     'Example/message.lua':b'local message="a b"\n',
                     'Example/package-only.txt':b'original'}
            installed={'Example/format.lua':b'local x=1 -- edited comment\n',
                       'Example/message.lua':b'local message="a  b"\n',
                       'Example/installed-only.txt':b'custom'}
            for name,data in installed.items():
                path=baseline/name;path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(data)
            cache=scope/'matching.zip'
            with zipfile.ZipFile(cache,'w') as archive:
                for name,data in sources.items(): archive.writestr(name,data)
            import hashlib
            package={'repo':'example/Addon','version':'old','cache':str(cache.relative_to(ROOT)),
                     'sha256':sha(cache),'expectedDigest':'sha256:'+sha(cache),
                     'files':{n:hashlib.sha256(b).hexdigest() for n,b in sources.items()}}
            imm=scope/'official'/'Immersion';imm.mkdir(parents=True)
            (imm/'Config.lua').write_bytes(b'local original=true')
            original={'repo':'seblindfors/Immersion','version':'1.4.61','releaseURL':'https://example.invalid/official',
                      'assetURL':'https://example.invalid/official.zip','sha256':'test','bytes':19,
                      'unpacked':str(imm.parent.relative_to(ROOT)),'files':{'Immersion/Config.lua':sha(imm/'Config.lua')}}
            with patch.object(audit_migration,'BASE',baseline):
                result=audit_migration.audit([package],{'packages':[original]})
                rows={r['path']:r for r in result['files']}
                self.assertEqual(rows['Example/format.lua']['classification'],'Lua-formatting-comments-only')
                self.assertEqual(rows['Example/message.lua']['classification'],'substantive-Lua-change')
                self.assertEqual(rows['Example/installed-only.txt']['classification'],'installed-only')
                self.assertEqual(rows['Example/package-only.txt']['classification'],'package-only')
                self.assertEqual((baseline/'Example/message.lua').read_bytes(),installed['Example/message.lua'])
                package['files']['Example/message.lua']='drift'
                with self.assertRaises(ValueError): audit_migration.audit([package],{'packages':[original]})

    def test_native_runtime_package_closure(self):
        files={'Example/Example.toc':b'## Interface: 120100\n## RequiredDeps: ConsolePort\nView/Main.xml\n',
               'Example/View/Main.xml':b'<Ui><!-- <Script file="unused.lua"/> --><Include file="../Shared.xml"/><Script file="Main.lua"/></Ui>',
               'Example/Shared.xml':b'<Ui><Script file="Shared.lua"/></Ui>',
               'Example/Shared.lua':b'local original=true', 'Example/View/Main.lua':b'local original=true'}
        self.assertEqual(len(runtime_closure('Example',files)['runtimeFiles']),5)
        self.assertEqual(runtime_closure('Example',files)['metadata']['RequiredDeps'],'ConsolePort')
        conditional=dict(files);conditional['Example/Example.toc']+=b'Shared.lua [ExcludeLoadGameType classic]\n'
        self.assertEqual(len(runtime_closure('Example',conditional)['runtimeFiles']),5)
        missing=dict(files);del missing['Example/Shared.lua']
        with self.assertRaises(ValueError): runtime_closure('Example',missing)
        escape=dict(files);escape['Example/View/Main.xml']=b'<Ui><Script file="../../Other/Main.lua"/></Ui>'
        escape['Other/Main.lua']=b'not-owned'
        with self.assertRaises(ValueError): runtime_closure('Example',escape)

    def test_inactive_official_package_companions_are_preserved(self):
        files={'Retail/Retail.toc':b'## Interface: 120100\nMain.lua\n',
               'Retail/Main.lua':b'local original=true',
               'Classic/Classic.toc':b'## Interface: 11508\n## AllowLoadGameType: vanilla\n## RequiredDeps: Retail\nMain.lua\n',
               'Classic/Main.lua':b'local original=true'}
        with self.assertRaises(ValueError): runtime_closure('Classic',files)
        closure=runtime_closure('Classic',files,require_retail=False)
        self.assertEqual(closure['metadata']['AllowLoadGameType'],'vanilla')
        with tempfile.TemporaryDirectory(dir=ROOT/'scratch') as temp:
            source=Path(temp)
            for name,data in files.items():
                path=source/name;path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(data)
            package={'repo':'example/Addon','unpacked':str(source.relative_to(ROOT)),
                'addonFolders':['Retail','Classic'],'files':{name:sha(source/name) for name in files},
                'toc':resolve_dependencies.metadata(list(files.items()))[0]}
            with patch.object(audit_dependencies,'verify',return_value={'Retail':'example/Addon','Classic':'example/Addon'}),patch.object(audit_dependencies,'voice_provenance',return_value={}):
                coverage=audit_dependencies.audit({'installedFolders':['Retail','Classic'],'packages':[package]})
            self.assertEqual(set(coverage['selectedFolders']),{'Retail','Classic'})
            self.assertFalse(coverage['selectedFolders']['Classic']['eligibleForRetail'])
            self.assertNotIn('Classic',coverage['excludedFolders'])

    def test_notice_sources_are_distinct_from_permission(self):
        with tempfile.TemporaryDirectory(dir=ROOT/'scratch') as temp:
            scope=Path(temp)
            source=scope/'source'/'Addon'; source.mkdir(parents=True)
            for name,data in {'LICENSE.txt':b'\r\nOriginal terms\r\n',
                'lib.lua':b'-- Copyright maintainer\nlocal original=true',
                'art.tga':b'Copyright byte sequence in image'}.items(): (source/name).write_bytes(data)
            files={'Addon/'+p.name:sha(p) for p in source.iterdir()}
            package={'repo':'example/Addon','version':'1','releaseURL':'https://example.invalid/official',
                'sha256':'test-only','unpacked':str(source.parent.relative_to(ROOT)), 'files':files}
            coverage={'lockSHA256':sha(ROOT/'dependencies/lock.json'),
                'selectedFolders':{'Addon':{'owner':'example/Addon'}},
                'distribution':{'restrictedOfficialAssembly':['example/Addon']}}
            with patch('inventory_notices.verify') as qualified:
                result=inventory({'packages':[package]},coverage,scope/'notices')
                qualified.assert_called_once()
                row=result['packages'][0]
                self.assertFalse(result['releaseNoticeReviewComplete'])
                self.assertFalse(result['packDistributionReady'])
                self.assertTrue(row['assemblyRequiredByCoverage'])
                self.assertEqual(len(row['noticeFiles']),1)
                self.assertEqual(len(row['embeddedNoticeSources']),1)
                self.assertEqual((ROOT/row['noticeFiles'][0]['copy']).read_bytes(),(source/'LICENSE.txt').read_bytes())
                self.assertEqual({name:sha(source.parent/name) for name in files},files)
                (source/'LICENSE.txt').write_bytes(b'tampered')
                with self.assertRaises(ValueError): inventory({'packages':[package]},coverage,scope/'rejected')

    def test_fresh_official_download_and_expired_metadata(self):
        from datetime import datetime,timezone
        source={'repo':'curseforge/Example','addon':'Example','projectID':1,'fileID':123456,
                'filename':'Example.zip','version':'1.0','url':'https://example.invalid/release',
                'latestURL':'https://example.invalid/latest','license':'MIT','supportsRetail':True,
                'metadataVerifiedAt':datetime.now(timezone.utc).isoformat()}
        stream=io.BytesIO()
        with zipfile.ZipFile(stream,'w') as archive:
            archive.writestr('Example/Example.toc',b'## Interface: 120100\n## Version: 1.0\nMain.lua\n')
            archive.writestr('Example/Main.lua',b'original')
        with tempfile.TemporaryDirectory(dir=ROOT/'scratch') as temp:
            with patch.object(resolve_dependencies,'ROOT',Path(temp)),patch.object(resolve_dependencies,'fetch',return_value=stream.getvalue()) as fetch:
                resolve_dependencies.curseforge_package(source)
                resolve_dependencies.curseforge_package(source)
                self.assertEqual(fetch.call_count,2,'refresh accepted unqualified stale cache')
                expired=dict(source,metadataVerifiedAt='2020-01-01T00:00:00Z')
                with self.assertRaises(ValueError): resolve_dependencies.curseforge_package(expired)
                self.assertEqual(fetch.call_count,2)

    def test_output_links_and_immutable_scopes(self):
        for path in [ROOT/'reference/test', ROOT/'tests/fixtures/test']:
            with self.assertRaises(ValueError):
                output(path)
        output(ROOT/'scratch').mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(dir=ROOT/'scratch') as temp:
            scope=Path(temp)
            target=scope/'target'
            target.mkdir()
            marker=target/'unchanged'
            marker.write_text('baseline')
            alias=scope/'alias'
            if os.name=='nt':
                script="New-Item -ItemType Junction -Path '"+str(alias).replace("'","''")+"' -Value '"+str(target).replace("'","''")+"' | Out-Null"
                subprocess.run(['powershell','-NoProfile','-Command',script],check=True,capture_output=True,creationflags=subprocess.CREATE_NO_WINDOW)
            else:
                alias.symlink_to(target,target_is_directory=True)
            try:
                with self.assertRaises(ValueError): output(alias/'new',scope)
                with self.assertRaises(ValueError): output(alias/'new',alias)
                # The Node report/extraction writer must reject the same alias.
                code="const {output}=require('./tools/repository_paths.cjs'); for(const p of process.argv.slice(1)){ let rejected=false; try{output(p)}catch{rejected=true} if(!rejected)process.exit(2); }"
                subprocess.run(['node','-e',code,str(alias/'new'),str(ROOT/'reference/new'),str(ROOT/'tests/fixtures/new')],cwd=ROOT,check=True,capture_output=True)
                self.assertEqual(marker.read_text(),'baseline')
                self.assertFalse((target/'new').exists())
            finally:
                # Remove only the link itself; no recursive operation on alias.
                if os.name=='nt': os.rmdir(alias)
                else: alias.unlink()

    def test_qualify_official_archive_without_patching(self):
        def archive(files):
            stream=io.BytesIO()
            with zipfile.ZipFile(stream,'w') as z:
                for name,body in files.items(): z.writestr(name,body)
            return stream.getvalue()
        with tempfile.TemporaryDirectory(dir=ROOT/'scratch') as temp:
            previous=resolve_dependencies.ROOT
            resolve_dependencies.ROOT=Path(temp)
            source={'repo':'official/Example','addon':'Example','url':'https://example.invalid/release'}
            try:
                files={'Example/Example.toc':b'## Interface: 120100\n## Version: 1.0\nMain.lua\n',
                       'Example/Main.lua':b'local original=true\n',
                       'Example/Libs/Lib/Lib.toc':b'## Interface: 30300\n## Version: @project-version@\n'}
                entry=resolve_dependencies.materialize(source,archive(files),'https://example.invalid/archive','1.0')
                self.assertIn('Example/Libs/Lib/Lib.toc',entry['metadataAdvisories'])
                base=Path(temp)/entry['unpacked']
                for name,body in files.items(): self.assertEqual((base/name).read_bytes(),body)
                bad=dict(files)
                bad['Example/Example.toc']=b'## Interface: 120100\n## Version: @project-version@\nMain.lua\n'
                with self.assertRaises(ValueError): resolve_dependencies.materialize(source,archive(bad),'https://example.invalid/archive','1.0')
                bad=dict(files)
                bad['Example/Main.lua']=b'changed source'
                old_hash=sha(Path(temp)/entry['cache'])
                with self.assertRaises(ValueError): resolve_dependencies.materialize(source,archive(bad),'https://example.invalid/archive','1.0')
                self.assertEqual(sha(Path(temp)/entry['cache']),old_hash,'failed qualification corrupted cache')
                missing={'tag/Example.toc':b'## Interface: 120100\n## Version: 1.0\nMissing.lua\n'}
                with self.assertRaises(ValueError): resolve_dependencies.materialize(source,archive(missing),'https://example.invalid/archive','1.0','tag')
                for version in ['../bad','C:bad','CON','1.0.']:
                    with self.assertRaises(ValueError): resolve_dependencies.materialize(source,archive(files),'https://example.invalid/archive',version)
            finally: resolve_dependencies.ROOT=previous

    def test_live_aliases_refused(self):
        for path in ['C:/Program Files (x86)/World of Warcraft/_retail_/WTF/test',
                     'C:/Users/luisr/OneDrive/Documents/03 Gaming/World of Warcraft/_retail_/Interface/test',
                     ROOT / 'reference/config/test']:
            with self.assertRaises(ValueError):
                contained(path, ROOT / 'scratch')

    def test_archive_attacks(self):
        for name in ['../test.lua', '/test.lua', 'C:/test.lua', 'CON.lua', 'folder/a.exe', 'folder./x.lua']:
            stream=io.BytesIO()
            with zipfile.ZipFile(stream,'w') as archive:
                archive.writestr(name,b'bad')
            with self.assertRaises(ValueError, msg=name):
                members(stream.getvalue())
        stream=io.BytesIO()
        with zipfile.ZipFile(stream,'w') as archive:
            archive.writestr('foo/bar.lua',b'bad')
        # Windows ZipInfo normalizes backslashes while creating the fixture;
        # patch both raw directory names to model an actual hostile archive.
        with self.assertRaises(ValueError):
            members(stream.getvalue().replace(b'foo/bar.lua',b'foo\\bar.lua'))
        stream=io.BytesIO()
        with zipfile.ZipFile(stream,'w') as archive:
            archive.writestr('Addon/one.lua',b'a')
            archive.writestr('addon/ONE.lua',b'b')
        with self.assertRaises(ValueError):
            members(stream.getvalue())

    def test_copy_fixture_without_writing_reference(self):
        source=ROOT/'reference/config/2026-10-03-initial/Account/_template_/SavedVariables'
        prior={p.name:sha(p) for p in source.iterdir() if p.is_file()}
        output(ROOT/'scratch').mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(dir=ROOT/'scratch') as temp:
            target=fixture_copy(source,Path(temp)/'copy')
            (target/'ConsolePort_Forever.lua').write_text('simulation only')
        self.assertEqual(prior,{p.name:sha(p) for p in source.iterdir() if p.is_file()})


if __name__=='__main__':
    unittest.main()
