import argparse
import json
from pack_format import read_pack

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--pack', required=True)
    parser.add_argument('--sha256', required=True)
    parser.add_argument('--require-complete', action='store_true')
    args = parser.parse_args()
    manifest, rows = read_pack(args.pack, args.sha256, args.require_complete)
    print(json.dumps({'verifiedFiles': len(rows), 'addonFolders': len(manifest['addonFolders']),
        'assemblyComplete': manifest['assemblyComplete'], 'sourceCommit': manifest['sourceCommit'],
        'localPersonalUseOnly': True, 'RetailAcceptance': 'Pending'}, indent=2))
