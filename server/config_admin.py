#!/usr/bin/env python3
"""Offline signing CLI. Keep private keys OUTSIDE the project and public web root.
Dependencies: Python 3.10+ and cryptography. Does not deploy or enable advertising.
"""
import argparse,base64,hashlib,json,os,tempfile,time
from pathlib import Path
from cryptography.hazmat.primitives import hashes,serialization
from cryptography.hazmat.primitives.asymmetric import rsa,padding
APPS=('pocket-pet-village','mini-garage-adventure','wonder-lab-adventures')
def write_json(path,data):
    path=Path(path);path.parent.mkdir(parents=True,exist_ok=True)
    with tempfile.NamedTemporaryFile('w',dir=path.parent,delete=False,encoding='utf-8') as f:
        json.dump(data,f,indent=2);f.write('\n');temp=f.name
    os.replace(temp,path)
def disabled_config(revision=1):
    now=int(time.time())
    return {'schema_version':1,'revision':revision,'issued_at':now,'expires_at':now+86400,'kill_switch':True,'apps':{app:{platform:{'enabled':False,'reviewed_build':None,'rollout_percent':0,'daily_cap':0,'min_install_days':7,'min_active_days':3,'min_session_minutes':5,'min_minutes_between':15} for platform in ('ios','android')}for app in APPS}}
def validate(c):
    if not isinstance(c,dict) or c.get('schema_version')!=1:raise ValueError('schema_version must be 1')
    if type(c.get('revision')) is not int or c['revision']<1:raise ValueError('Positive integer revision required')
    if type(c.get('kill_switch')) is not bool:raise ValueError('Explicit boolean kill_switch required')
    if any(type(c.get(k)) is not int for k in ('issued_at','expires_at')):raise ValueError('Integer UTC timestamps required')
    if c['expires_at']<=c['issued_at'] or c['expires_at']-c['issued_at']>86400:raise ValueError('Policy validity must be between 1 second and 24 hours')
    if c['issued_at']>time.time()+60 or c['expires_at']<=time.time():raise ValueError('Configuration is not currently valid')
    if set(c.get('apps',{}))!=set(APPS):raise ValueError('Exactly the three known app IDs required')
    for app,platforms in c['apps'].items():
        if set(platforms)!= {'ios','android'}:raise ValueError('Both platform settings are required')
        for platform,p in platforms.items():
            if type(p.get('enabled')) is not bool:raise ValueError('enabled must be a boolean')
            # This build is a policy scaffold with no approved adapters. Fail closed at signer as well.
            if p['enabled']:raise ValueError('No advertising adapter is approved in Build 01. An enabled policy cannot be signed by this release tool.')
            if p.get('rollout_percent')!=0 or p.get('daily_cap')!=0:raise ValueError('Build 01 requires zero rollout and zero impressions')
    return c
def init_keys(private_path,public_path):
    private_path=Path(private_path);public_path=Path(public_path)
    if private_path.exists() or public_path.exists():raise ValueError('Refusing to overwrite existing key material')
    key=rsa.generate_private_key(public_exponent=65537,key_size=3072)
    private_path.parent.mkdir(parents=True,exist_ok=True);public_path.parent.mkdir(parents=True,exist_ok=True)
    with os.fdopen(os.open(private_path,os.O_WRONLY|os.O_CREAT|os.O_EXCL,0o600),'wb') as f:
        f.write(key.private_bytes(serialization.Encoding.PEM,serialization.PrivateFormat.PKCS8,serialization.NoEncryption()))
    public_path.write_bytes(key.public_key().public_bytes(serialization.Encoding.PEM,serialization.PublicFormat.SubjectPublicKeyInfo))
    print('Keypair created. Never distribute or serve the private key.')
def sign(config_path,key_path,output):
    c=validate(json.loads(Path(config_path).read_text()))
    key=serialization.load_pem_private_key(Path(key_path).read_bytes(),password=None)
    if not isinstance(key,rsa.RSAPrivateKey) or key.key_size<3072:raise ValueError('RSA-3072 or stronger private key required')
    payload=json.dumps(c,separators=(',',':'),sort_keys=True).encode()
    sig=key.sign(payload,padding.PKCS1v15(),hashes.SHA256())
    env={'algorithm':'RS256','payload_b64':base64.b64encode(payload).decode(),'signature_b64':base64.b64encode(sig).decode()}
    write_json(output,env)
    print(f'Signed disabled policy revision {c["revision"]}; payload SHA256 {hashlib.sha256(payload).hexdigest()}')
    return env
def main():
    p=argparse.ArgumentParser(description=__doc__);s=p.add_subparsers(dest='command',required=True)
    k=s.add_parser('init-keys');k.add_argument('--private',required=True);k.add_argument('--public',required=True)
    c=s.add_parser('new-disabled');c.add_argument('--output',required=True);c.add_argument('--revision',type=int,default=1)
    t=s.add_parser('sign');t.add_argument('--config',required=True);t.add_argument('--private',required=True);t.add_argument('--output',required=True)
    a=p.parse_args()
    try:
        if a.command=='init-keys':init_keys(a.private,a.public)
        elif a.command=='new-disabled':write_json(a.output,disabled_config(a.revision))
        elif a.command=='sign':sign(a.config,a.private,a.output)
    except (OSError,ValueError,TypeError,KeyError) as e:p.exit(1,f'Error: {e}\n')
if __name__=='__main__':main()
