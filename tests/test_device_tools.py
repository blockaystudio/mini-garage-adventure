#!/usr/bin/env python3
"""Regressions for device-tool safety, without inventing device execution."""
from contextlib import redirect_stdout
import io
import json
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest import mock
import zipfile

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'scripts'))
import android_smoke
import native_save_audit

FIXTURES = ROOT / 'tests/fixtures'
ACTUAL_SAVE = FIXTURES / 'native-schema3-actual-godot.json'


def envelope(payload, schema=3):
    """Synthetic adversarial variants, distinct from the actual Godot fixture."""
    checksum = hashlib.sha256(native_save_audit.canonical_payload(payload).encode()).hexdigest()
    return json.dumps({'schema': schema, 'payload': payload, 'checksum': checksum},
                      separators=(',', ':'), allow_nan=False).encode()


def collect(output, raw, name='fixture'):
    device = android_smoke.Device('NOT-AN-ADB-EXECUTABLE', None, output)
    with mock.patch.object(device, 'shell', return_value='files/garage-save.json'), \
            mock.patch.object(device, 'run', return_value=raw):
        return device.save_copy(name)


class SaveEvidenceTests(unittest.TestCase):
    """Actual collector method; mocked transport is never device evidence."""
    def test_actual_store_schema3_bytes_checksum_and_owned_equipment(self):
        raw = ACTUAL_SAVE.read_bytes()
        with tempfile.TemporaryDirectory() as temporary:
            result = collect(Path(temporary), raw)
            self.assertEqual((Path(temporary) / result['file']).read_bytes(), raw)
        self.assertEqual(result['status'], 'copied')
        self.assertEqual(result['validation']['status'], 'valid')
        self.assertEqual(result['validation']['checksum'], 'verified')
        self.assertEqual(result['payload']['gp'], 315)
        self.assertEqual(result['payload']['build']['tires'], 'mud')
        self.assertEqual(result['payload']['equipped']['tires'], 'mud')
        self.assertIn('mud', result['payload']['owned'])
        self.assertEqual(result['payload']['best']['meadow'], 7.29166666666665)
        self.assertEqual(result['sha256'], hashlib.sha256(raw).hexdigest())

    def test_actual_godot_canonical_numeric_vectors(self):
        cases = json.loads((FIXTURES / 'native-canonical-actual-godot.json').read_text())
        for case in cases:
            with self.subTest(number=case['payload']['numeric_probe']):
                self.assertEqual(native_save_audit.canonical_payload(case['payload']), case['canonical'])

    def test_canonical_checksum_ignores_equivalent_numeric_spelling(self):
        raw = ACTUAL_SAVE.read_bytes()
        for altered in (raw.replace(b'"gp":315', b'"gp":315.00000000000000001'),
                        raw.replace(b'"yaw":0.0000001', b'"yaw":1e-7'),
                        json.dumps(json.loads(raw), indent=2).encode()):
            with self.subTest(raw=altered[:30]):
                result = native_save_audit.validate_save_bytes(altered)
                self.assertEqual(result['status'], 'valid', result)

    def test_raw_numeric_token_checksum_is_not_accepted(self):
        record = json.loads(ACTUAL_SAVE.read_bytes())
        canonical = native_save_audit.canonical_payload(record['payload'])
        wrong = canonical.replace('"gp":315.0', '"gp":315.00000000000000001')
        self.assertNotEqual(wrong, canonical)
        record['checksum'] = hashlib.sha256(wrong.encode()).hexdigest()
        result = native_save_audit.validate_save_bytes(json.dumps(record).encode())
        self.assertEqual(result['status'], 'invalid')
        self.assertEqual(result['checksum'], 'mismatch')

    def test_python_scientific_checksum_is_not_accepted_as_godot(self):
        record = json.loads(ACTUAL_SAVE.read_bytes())
        wrong = native_save_audit.canonical_payload(record['payload']).replace('"yaw":0.0000001', '"yaw":1e-07')
        record['checksum'] = hashlib.sha256(wrong.encode()).hexdigest()
        result = native_save_audit.validate_save_bytes(json.dumps(record).encode())
        self.assertEqual(result['status'], 'invalid')

    def test_corrupt_and_malformed_bytes_are_retained_before_validation(self):
        records = [b'not-json\xff', b'null', b'[]', b'{"schema":3,"payload":',
                   b'{"schema":3,"schema":2}', b'{"schema":3,"payload":null}',
                   b'{"schema":3,"payload":{"version":3},"checksum":"wrong"}',
                   b'x' * (native_save_audit.MAX_BYTES + 1)]
        with tempfile.TemporaryDirectory() as temporary:
            for index, raw in enumerate(records):
                with self.subTest(case=index):
                    result = collect(Path(temporary), raw, str(index))
                    self.assertEqual(result['status'], 'copied')
                    self.assertEqual(result['validation']['status'], 'invalid')
                    self.assertEqual((Path(temporary) / result['file']).read_bytes(), raw)
                    self.assertNotIn('payload', result)

    def test_raw_copy_survives_unexpected_audit_failure(self):
        raw = ACTUAL_SAVE.read_bytes()
        with tempfile.TemporaryDirectory() as temporary:
            with mock.patch.object(android_smoke, 'validate_save_bytes', side_effect=OSError('synthetic auditor failure')):
                with self.assertRaises(OSError):
                    collect(Path(temporary), raw)
            self.assertEqual((Path(temporary) / 'fixture-save.json').read_bytes(), raw)

    def test_legacy_envelopes_are_classified_without_migrating(self):
        profile = json.loads(ACTUAL_SAVE.read_bytes())['payload']
        profile['version'] = 2
        records = [envelope(profile, 2), b'{"version":1,"vehicle":"buggy","completed":[]}']
        with tempfile.TemporaryDirectory() as temporary:
            for index, raw in enumerate(records):
                result = collect(Path(temporary), raw, str(index))
                self.assertEqual(result['validation']['status'], 'legacy')
                self.assertEqual((Path(temporary) / result['file']).read_bytes(), raw)
                with self.assertRaises(android_smoke.Blocked):
                    android_smoke.require_current_save(result)

    def test_future_root_or_payload_version_keeps_exact_unsupported_bytes(self):
        records = [b'{"schema":4,"payload":{"version":4,"unknown":"leave intact"}}',
                   b'{"schema":3,"payload":{"version":4,"unknown":"leave intact"}}',
                   b'{"version":10000000000,"unknown":[1,2,3]}',
                   b'{"schema":4,"payload":["future representation",1,2]}']
        with tempfile.TemporaryDirectory() as temporary:
            for index, raw in enumerate(records):
                result = collect(Path(temporary), raw, str(index))
                self.assertEqual(result['validation']['status'], 'unsupported_future')
                self.assertEqual((Path(temporary) / result['file']).read_bytes(), raw)
                self.assertNotIn('payload', result)
                with self.assertRaises(android_smoke.Blocked):
                    android_smoke.require_current_save(result)

    def test_version_disagreement_and_checksum_tamper_are_invalid(self):
        record = json.loads(ACTUAL_SAVE.read_bytes())
        record['schema'] = 2
        self.assertEqual(native_save_audit.validate_save_bytes(json.dumps(record).encode())['status'], 'invalid')
        record = json.loads(ACTUAL_SAVE.read_bytes())
        record['payload']['gp'] += 1
        result = native_save_audit.validate_save_bytes(json.dumps(record).encode())
        self.assertEqual(result['status'], 'invalid')
        self.assertEqual(result['checksum'], 'mismatch')

    def test_signed_wallet_and_inventory_invariant_failures_are_not_device_passes(self):
        base = json.loads(ACTUAL_SAVE.read_bytes())['payload']
        variants = []
        for amount in (-1, 1.5, True, 1000000001, '315'):
            p = json.loads(json.dumps(base)); p['gp'] = amount; variants.append(p)
        for change in (
                lambda p: p['owned'].append('unknown_upgrade'),
                lambda p: p['owned'].append('mud'),
                lambda p: p['owned'].remove('mud'),
                lambda p: p['equipped'].update(tires='road'),
                lambda p: p['equipped'].update(engine='mud'),
                lambda p: p['build'].update(vehicle='unknown'),
                lambda p: p.update(stars=['meadow:completion', 'meadow:completion']),
                lambda p: p['economy'].update(next_run=0),
                lambda p: p['explore'].update(region='unknown')):
            p = json.loads(json.dumps(base)); change(p); variants.append(p)
        for profile in variants:
            result = native_save_audit.validate_save_bytes(envelope(profile))
            self.assertEqual(result['checksum'], 'verified')
            self.assertEqual(result['status'], 'invalid', profile)
            with self.assertRaises(android_smoke.Blocked):
                android_smoke.require_current_save({'status': 'copied', 'validation': result})

    def test_nonfinite_and_bad_types_do_not_escape_as_valid(self):
        for raw in (b'{"schema":NaN}', b'{"schema":3,"payload":{"version":3,"gp":Infinity}}'):
            self.assertEqual(native_save_audit.validate_save_bytes(raw)['status'], 'invalid')
        base = json.loads(ACTUAL_SAVE.read_bytes())['payload']
        for key in ('owned', 'owned_vehicles', 'stars', 'claims', 'regions', 'explore', 'economy', 'build', 'settings', 'custom', 'best'):
            value = dict(base, **{key: None})
            self.assertEqual(native_save_audit.validate_save_bytes(envelope(value))['status'], 'invalid', key)

    def test_non_native_utf16_encoding_is_not_accepted(self):
        raw = ACTUAL_SAVE.read_text().encode('utf-16')
        with tempfile.TemporaryDirectory() as temporary:
            result = collect(Path(temporary), raw)
            self.assertEqual(result['validation']['status'], 'invalid')
            self.assertEqual((Path(temporary) / result['file']).read_bytes(), raw)

    def test_ambiguous_or_escaping_package_paths_are_not_read(self):
        for path in ('files/../garage-save.json', '/other/garage-save.json',
                     'files/one/garage-save.json\nfiles/two/garage-save.json'):
            with tempfile.TemporaryDirectory() as temporary:
                device = android_smoke.Device('NOT-AN-ADB-EXECUTABLE', None, Path(temporary))
                with mock.patch.object(device, 'shell', return_value=path), mock.patch.object(device, 'run') as read:
                    result = device.save_copy('fixture')
                    self.assertEqual(result['status'], 'not_found')
                    read.assert_not_called()

    def test_valid_copy_only_passes_current_save_gate(self):
        with tempfile.TemporaryDirectory() as temporary:
            evidence = collect(Path(temporary), ACTUAL_SAVE.read_bytes())
            android_smoke.require_current_save(evidence)
        with self.assertRaises(android_smoke.Blocked):
            android_smoke.require_current_save({'status': 'not_found'})

    def _capture_cli(self, raw):
        with tempfile.TemporaryDirectory() as temporary:
            output = Path(temporary)
            def run(device, *args, **_kwargs):
                return 'files/garage-save.json' if args[0] == 'shell' else raw
            with mock.patch.object(sys, 'argv', ['android_smoke.py', 'capture', '--adb', sys.executable, '--output', str(output)]), \
                    mock.patch.object(android_smoke.Device, 'choose', return_value={'model': 'synthetic fixture, not a device'}), \
                    mock.patch.object(android_smoke.Device, 'verify_installed_debug'), \
                    mock.patch.object(android_smoke.Device, 'snapshot'), \
                    mock.patch.object(android_smoke.Device, 'performance_snapshot'), \
                    mock.patch.object(android_smoke.Device, 'run', run), redirect_stdout(io.StringIO()):
                code = android_smoke.main()
            report = json.loads((output / 'report.json').read_text())
            saved = (output / 'manual-scene-save.json').read_bytes()
            return code, report, saved

    def test_capture_cli_continues_for_real_schema3_fixture(self):
        code, report, saved = self._capture_cli(ACTUAL_SAVE.read_bytes())
        self.assertEqual(code, 0)
        self.assertEqual(report['status'], 'observed_pending_review')
        self.assertEqual(report['native_save']['validation']['status'], 'valid')
        self.assertEqual(saved, ACTUAL_SAVE.read_bytes())

    def test_capture_cli_blocks_invalid_save_acceptance_but_retains_forensics(self):
        raw = b'{"truncated'
        code, report, saved = self._capture_cli(raw)
        self.assertEqual(code, 2)
        self.assertEqual(report['status'], 'blocked')
        self.assertEqual(report['native_save']['validation']['status'], 'invalid')
        self.assertEqual(saved, raw)

    def test_capture_cli_blocks_legacy_and_future_without_erasing_evidence(self):
        legacy = json.loads(ACTUAL_SAVE.read_bytes())['payload']; legacy['version'] = 2
        for raw, status in ((envelope(legacy, 2), 'legacy'),
                            (b'{"schema":4,"payload":{"version":4}}', 'unsupported_future')):
            code, report, saved = self._capture_cli(raw)
            self.assertEqual(code, 2)
            self.assertEqual(report['status'], 'blocked')
            self.assertEqual(report['native_save']['validation']['status'], status)
            self.assertEqual(saved, raw)

    def test_unrelated_release_or_permissioned_apks_cannot_be_installed(self):
        baseline = [
            {'tag': 'manifest', 'attributes': {'package': android_smoke.PACKAGE}},
            {'tag': 'application', 'attributes': {'debuggable': True, 'allowBackup': False}},
            {'tag': 'uses-sdk', 'attributes': {'minSdkVersion': 24, 'targetSdkVersion': 36}},
        ]
        variants = []
        for tag, key, value in (('manifest', 'package', 'unrelated.private.app'),
                                ('application', 'debuggable', False), ('application', 'allowBackup', True)):
            rows = json.loads(json.dumps(baseline))
            next(row for row in rows if row['tag'] == tag)['attributes'][key] = value
            variants.append(rows)
        variants.append(baseline + [{'tag': 'uses-permission', 'attributes': {'name': 'android.permission.INTERNET'}}])
        with tempfile.TemporaryDirectory() as temporary:
            apk = Path(temporary) / 'synthetic-manifest.apk'
            with zipfile.ZipFile(apk, 'w') as archive:
                archive.writestr('AndroidManifest.xml', b'Synthetic parser fixture; not an Android build')
                archive.writestr('assets/licenses/GODOT_LICENSE.txt', b'fixture')
            for rows in variants:
                with mock.patch.object(android_smoke, 'manifest_elements', return_value=rows):
                    with self.assertRaises(android_smoke.Blocked):
                        android_smoke.apk_details(apk)


class NativeSaveDifferentialTests(unittest.TestCase):
    """Pinned native reader oracle, independent of Python checksum generation."""
    def test_generated_fixture_and_numeric_spellings_match_actual_native_reader(self):
        engine = os.environ.get('GODOT_BIN') or shutil.which('godot') or shutil.which('godot4')
        if not engine:
            self.skipTest('Pinned Godot unavailable; static actual-Store fixtures still tested, native differential not run.')
        with tempfile.TemporaryDirectory(prefix='garage-collector-oracle-') as temporary:
            path = Path(temporary)
            environment = dict(os.environ, XDG_DATA_HOME=str(path / 'data'), XDG_CONFIG_HOME=str(path / 'config'), XDG_CACHE_HOME=str(path / 'cache'))
            version = subprocess.check_output([engine, '--version'], env=environment, text=True).strip()
            self.assertEqual(version, '4.6.3.stable.official.7d41c59c4')
            generator = path / 'generate.gd'; generator.write_bytes((FIXTURES / 'generate_native_save.gd.txt').read_bytes())
            generated = subprocess.run([engine, '--headless', '--path', str(ROOT / 'native'), '--script', str(generator), '--', str(path)], env=environment, capture_output=True, text=True, timeout=30)
            self.assertEqual(generated.returncode, 0, generated.stdout + generated.stderr)
            actual = (path / 'actual-schema3.json').read_bytes()
            self.assertEqual(native_save_audit.validate_save_bytes(actual)['status'], 'valid')
            record = json.loads(actual)
            canonical = native_save_audit.canonical_payload(record['payload'])
            wrong = dict(record, checksum=hashlib.sha256(canonical.replace('"gp":315.0', '"gp":315.00000000000000001').encode()).hexdigest())
            variants = [actual, actual.replace(b'"gp":315', b'"gp":315.00000000000000001'),
                        actual.replace(b'"yaw":0.0000001', b'"yaw":1e-7'), json.dumps(wrong).encode(),
                        actual.replace(b'"gp":315', b'"gp":316')]
            files = []
            for index, raw in enumerate(variants):
                file = path / f'case-{index}.json'; file.write_bytes(raw); files.append(str(file))
            (path / 'cases.json').write_text(json.dumps(files))
            oracle = path / 'oracle.gd'
            oracle.write_text('''extends SceneTree
const Store = preload("res://scripts/save_store.gd")
func _initialize() -> void:
 var args := OS.get_cmdline_user_args()
 var files: Array = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
 var results: Array = []
 for file in files:
  results.append(Store.new()._read_record(file).status)
 var out = FileAccess.open(args[1],FileAccess.WRITE)
 out.store_string(JSON.stringify(results))
 out.close()
 quit()
''')
            run = subprocess.run([engine, '--headless', '--path', str(ROOT / 'native'), '--script', str(oracle), '--', str(path / 'cases.json'), str(path / 'result.json')], env=environment, capture_output=True, text=True, timeout=30)
            self.assertEqual(run.returncode, 0, run.stdout + run.stderr)
            results = json.loads((path / 'result.json').read_text())
            self.assertEqual(results, ['ok', 'ok', 'ok', 'invalid', 'invalid'])
            for raw, native in zip(variants, results):
                self.assertEqual(native_save_audit.validate_save_bytes(raw)['status'] == 'valid', native == 'ok')


class DeviceToolTests(unittest.TestCase):
    def test_transport_identifier_is_redacted_on_subprocess_timeout(self):
        serial = 'SYNTHETIC-TRANSPORT-NOT-A-REAL-DEVICE'

        def choose(device):
            device.serial = serial
            return {'model': 'synthetic test fixture'}

        # Exercise the actual outer exception/report path: TimeoutExpired carries
        # the full command, including -s. This fixture is not a device test.
        with tempfile.TemporaryDirectory() as temporary:
            output = Path(temporary) / 'capture'
            command = ['android_smoke.py', 'capture', '--adb', sys.executable,
                       '--output', str(output)]
            timeout = subprocess.TimeoutExpired(['adb', '-s', serial, 'shell'], 30)
            stdout = io.StringIO()
            with mock.patch.object(sys, 'argv', command), \
                    mock.patch.object(android_smoke.Device, 'choose', choose), \
                    mock.patch.object(android_smoke.Device, 'verify_installed_debug', side_effect=timeout), \
                    redirect_stdout(stdout):
                code = android_smoke.main()
            report = (output / 'report.json').read_text()
            self.assertEqual(code, 2)
            self.assertEqual(json.loads(report)['status'], 'blocked')
            self.assertNotIn(serial, report)
            self.assertNotIn(serial, stdout.getvalue())
            self.assertIn('[transport]', report)


if __name__ == '__main__':
    unittest.main()
