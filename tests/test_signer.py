import base64,importlib.util,json,tempfile,unittest,stat,time
from pathlib import Path
from cryptography.hazmat.primitives import hashes,serialization
from cryptography.hazmat.primitives.asymmetric import padding
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('config_admin',ROOT/'server/config_admin.py');admin=importlib.util.module_from_spec(spec);spec.loader.exec_module(admin)
class SigningTests(unittest.TestCase):
    def test_disabled_default_valid(self):self.assertTrue(admin.validate(admin.disabled_config())['kill_switch'])
    def test_enabled_policy_rejected(self):
        c=admin.disabled_config();c['apps']['pocket-pet-village']['android']['enabled']=True
        with self.assertRaises(ValueError):admin.validate(c)
    def test_rollout_rejected_in_build01(self):
        c=admin.disabled_config();c['apps']['pocket-pet-village']['android']['rollout_percent']=5
        with self.assertRaises(ValueError):admin.validate(c)
    def test_expired_rejected(self):
        c=admin.disabled_config();c['issued_at']=int(time.time())-100;c['expires_at']=int(time.time())-1
        with self.assertRaises(ValueError):admin.validate(c)
    def test_missing_app_rejected(self):
        c=admin.disabled_config();del c['apps']['wonder-lab-adventures']
        with self.assertRaises(ValueError):admin.validate(c)
    def test_signatures_and_key_permissions(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d);private=root/'private.pem';public=root/'public.pem';cfg=root/'config.json';output=root/'signed.json'
            admin.init_keys(private,public);admin.write_json(cfg,admin.disabled_config());env=admin.sign(cfg,private,output)
            pub=serialization.load_pem_public_key(public.read_bytes());pub.verify(base64.b64decode(env['signature_b64']),base64.b64decode(env['payload_b64']),padding.PKCS1v15(),hashes.SHA256())
            self.assertEqual(stat.S_IMODE(private.stat().st_mode),0o600)
            self.assertEqual(json.loads(output.read_text())['algorithm'],'RS256')
            self.assertNotIn('PRIVATE KEY',output.read_text())
            with self.assertRaises(ValueError):admin.init_keys(private,public)
if __name__=='__main__':unittest.main(verbosity=2)
