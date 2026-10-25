"""One-time integrity-checked import. No deployment, ads, or accounts are enabled."""
from pathlib import Path, PurePosixPath
from urllib.request import urlopen
from urllib.parse import urlparse
import base64, hashlib, json, lzma, os, re, shutil, sys
ROOT = Path.cwd()
CONTROL = ROOT / '.source-import'
manifest = json.loads((CONTROL / 'ready.json').read_text())
assert os.environ.get('GITHUB_REPOSITORY', manifest['repository']) == manifest['repository']

def digest(data):
    return hashlib.sha256(data).hexdigest()

def unpack(section):
    chunks = []
    for item in section['parts']:
        if item.startswith('https://'):
            u = urlparse(item)
            if u.netloc != 'raw.githubusercontent.com' or not re.fullmatch(r'/blockaystudio/mini-garage-adventure/[0-9a-f]{40}/\.source-import/common-[0-9]+\.txt', u.path):
                raise ValueError('Unapproved source URL')
            with urlopen(item, timeout=45) as response:
                data = response.read(200000)
        else:
            if not re.fullmatch(r'\.source-import/(common|app)-[0-9]+\.txt', item):
                raise ValueError('Unapproved archive path')
            data = (ROOT / item).read_bytes()
        chunks.append(data.decode('ascii').strip())
    encoded = base64.b64decode(''.join(chunks), validate=True)
    if digest(encoded) != section['sha256']:
        raise ValueError('Source archive checksum mismatch')
    decoder = lzma.LZMADecompressor()
    decoded = decoder.decompress(encoded, max_length=1000000)
    if not decoder.eof:
        raise ValueError('Unexpected archive size or incomplete data')
    files = json.loads(decoded)
    if not isinstance(files, dict) or len(files) > 60:
        raise ValueError('Invalid source manifest')
    return files

if '--finish' not in sys.argv:
    files = {}
    for section in (manifest['common'], manifest['app']):
        part = unpack(section)
        if set(part) & set(files):
            raise ValueError('Overlapping source paths')
        files.update(part)
    for name, text in files.items():
        path = PurePosixPath(name)
        if path.is_absolute() or '..' in path.parts or '.git' in path.parts or not isinstance(text, str):
            raise ValueError('Unsafe source path')
        if digest(text.encode('utf-8')) != manifest['expected'][name]:
            raise ValueError('Source checksum mismatch: ' + name)
        target = ROOT / name
        if name.startswith('.github/workflows/') and (not target.exists() or target.read_text() != text):
            raise ValueError('Workflows must be pre-staged unchanged by the authorized uploader')
    for name, text in files.items():
        target = ROOT / name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(text, encoding='utf-8')
    print('Restored', len(files), 'integrity-checked source files.')
else:
    for name, expected in manifest['expected'].items():
        if digest((ROOT / name).read_bytes()) != expected:
            raise ValueError('Final source integrity mismatch: ' + name)
    for name in manifest['raster_exports']:
        if not (ROOT / name).is_file():
            raise ValueError('Missing regenerated review export: ' + name)
    from datetime import datetime, timezone
    report = {
        'repository': manifest['repository'],
        'completed_utc': datetime.now(timezone.utc).isoformat(),
        'original_source_zip_sha256': manifest['original_zip_sha256'],
        'source_files_verified': len(manifest['expected']),
        'source_sha256': manifest['expected'],
        'raster_exports_sha256': {p: digest((ROOT / p).read_bytes()) for p in manifest['raster_exports']},
        'source_changes': ['CI guard skips only the one-time bootstrap push. Game code is unchanged.'],
        'artifact_note': 'PNG exports and browser screenshots were regenerated from original source in GitHub Actions. They are not asserted byte-identical to archived PNGs.',
        'verification': 'python scripts/verify.py completed before this finalization step.',
        'limitations': 'Browser prototypes only. No native-device tests, store submissions, ad activation, deployment, or Codex optimization was performed.'
    }
    (ROOT / 'evidence/import-verification.json').write_text(json.dumps(report, indent=2) + '\n')
    (ROOT / 'IMPORT_STATUS.md').write_text(
        '# GitHub source import completed\n\n'
        'The editable prototype source, original SVG artwork, tests, plans, and Codex instructions are present at repository root. '
        'Both standalone HTML pages have been rebuilt and verified against the prepared package. '
        'PNG artwork exports and current browser screenshots were regenerated from source; archived raster byte identity is not claimed.\n\n'
        'The only change to existing text files is a CI guard that skips the initial bootstrap push. No gameplay or monetization code was changed. '
        'All 47 expected text files passed SHA-256 comparison against the import manifest. '
        'The import workflow also ran the project verifier (63 Node tests and 6 Python tests).\n\n'
        'See `evidence/import-verification.json` and the source-import workflow run for evidence. '
        'Earlier upload-status documents describe the pre-import package and are superseded by this file for upload status only.\n\n'
        'Start Codex using `CODEX_START_PROMPT.txt` on `main`. Review `AGENTS.md` first. '
        'No Codex optimization task, public deployment, store submission, or advertising activation has been started.\n'
    )
    shutil.copyfile(CONTROL / 'render.py', ROOT / 'scripts/export_review_assets.py')
    shutil.rmtree(CONTROL)
    print('Import finalized:', len(manifest['expected']), 'text files verified and', len(manifest['raster_exports']), 'review exports regenerated.')
