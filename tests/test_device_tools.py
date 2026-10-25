#!/usr/bin/env python3
"""Regressions for device-tool safety, without inventing device execution."""
from contextlib import redirect_stdout
import io
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'scripts'))
import android_smoke


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
