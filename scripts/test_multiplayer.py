#!/usr/bin/env python3
"""Real local Godot ENet server + independent native-process client acceptance.

Only isolated temporary TEST profiles. Does not deploy a service or import solo
saves. Impairment is application-level real-message scheduling, not kernel netem.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import socket
import subprocess
import sys
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]
NATIVE = ROOT / 'native'


def run_case(engine: str, label: str, clients: int, latency: int, jitter: int,
             loss: float, duration: float, destination: Path, rejoin=True, rounds=1, storage_fault=False):
    source_before={str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted((NATIVE/'scripts/net').glob('*.gd'))+[NATIVE/'scripts/drive3d/vehicle_sim.gd']}
    case = destination / label
    case.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='garage-net-test-') as temporary:
        tmp = Path(temporary)
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as probe:
            probe.bind(('127.0.0.1', 0))
            port = probe.getsockname()[1]
        base_env = dict(os.environ, XDG_DATA_HOME=str(tmp/'data'),
                        XDG_CONFIG_HOME=str(tmp/'config'), XDG_CACHE_HOME=str(tmp/'cache'))
        ready = tmp/'ready.json'
        config = dict(port=port, ready=str(ready), store=str(tmp/'online-test-profiles.json'),
                      output=str(case/'server.json'), players=clients,
                      duration=duration+2, countdown=0.7, latency_ms=latency,
                      jitter_ms=jitter, loss=loss, storage_fault=storage_fault,
                      fault_after_seconds=1.0,fault_duration_seconds=7.0,
                      race_timeout_seconds=5.0 if storage_fault else 120.0)
        server_config = tmp/'server-config.json'
        server_config.write_text(json.dumps(config))
        processes, handles = [], []
        try:
            def launch(script, configuration, logname):
                log = (case/logname).open('w')
                handles.append(log)
                process = subprocess.Popen([engine,'--headless','--path',str(NATIVE),
                    '--script',script,'--',str(configuration)],cwd=ROOT,env=base_env,
                    stdout=log,stderr=subprocess.STDOUT)
                processes.append(process)
                return process
            server = launch('server/session_server.gd',server_config,'server.log')
            deadline = time.monotonic()+10
            while not ready.exists():
                if server.poll() is not None or time.monotonic()>deadline:
                    raise RuntimeError('Dedicated server did not become ready; inspect server.log')
                time.sleep(.05)
            invitation = json.loads(ready.read_text())['invite']
            for index in range(clients):
                cfg = dict(port=port,invite=invitation,profile=f'qa-driver-{index+1}',
                    throttle=1.0-index*.10,output=str(case/f'client-{index+1}.json'),
                    duration=duration,latency_ms=latency,jitter_ms=jitter,loss=loss,
                    attack=index==0,rejoin=rejoin and index==0,rounds=rounds,storage_fault=storage_fault)
                path = tmp/f'client-{index+1}-config.json'
                path.write_text(json.dumps(cfg))
                launch('tests/net_client.gd',path,f'client-{index+1}.log')
            for process in processes[1:]:
                process.wait(timeout=duration+15)
            server.wait(timeout=8)
            for handle in handles: handle.flush()
            reports = [json.loads((case/f'client-{i+1}.json').read_text()) for i in range(clients)]
            authority = json.loads((case/'server.json').read_text())
            failures=[]
            def require(value,message):
                if not value: failures.append(message)
            require(len({p.pid for p in processes})==clients+1,'Processes must be independent')
            require(all(hashlib.sha256((ROOT/p).read_bytes()).hexdigest()==h for p,h in source_before.items()),'Runtime source unchanged throughout this actual process test')
            require(all(p.returncode==0 for p in processes),'Every process exits successfully')
            expected={f'qa-driver-{i+1}' for i in range(clients)}
            results=authority['snapshot'].get('race',{}).get('results',[])
            require(len(results)==clients,'Every real client has one server-validated finish')
            require({p['profile'] for p in results}==expected,'Results contain each player once')
            require(sorted(p['gp'] for p in results)==[100]*(clients-1)+[125], 'Finish and winner rewards exact')
            require(authority['diagnostics']['rejected_packets']>=1,'Illegal position/GP/finish payload rejected')
            for report in reports:
                require(set(report['saw_profiles'])==expected,f"{report['profile']} sees every remote player")
                for profile in expected:
                    samples=report['position_samples'].get(profile,[])
                    require(samples and max(float(p['z']) for p in samples)-min(float(p['z']) for p in samples)>10,
                            f"{report['profile']} observes real movement for {profile}")
                client_results=report['latest_snapshot'].get('race',{}).get('results',[])
                require(client_results==results,f"{report['profile']} agrees on authoritative result order/rewards")
                require(report['snapshot_samples']>5,f"{report['profile']} receives actual snapshots")
            require(len(authority.get('completed_races',{}))==rounds,'Server finalizes exact requested number of rounds')
            for profile, bank in authority['banked_profiles'].items():
                require(len(bank['claims'])==rounds,f'{profile} has exactly one persisted award per legitimate round')
                require(bank['gp']>=100*rounds and bank['gp']<=125*rounds,f'{profile} has no forged or duplicate GP')
            if rounds>1:
                for report in reports:
                    require(report['completed_races']==authority['completed_races'],f"{report['profile']} agrees on both immutable round records")
            if storage_fault:
                before=next((row for row in authority.get('storage_fault_events',[]) if row['event']=='before_storage_recovery'),{})
                require(before.get('pending_validated_finishes')==clients,'Every validated finish remains pending beyond failed storage')
                require(before.get('race_elapsed',0)>5 and before.get('phase')=='saving_results','Pending finishes survive the ordinary race timeout')
                require(all(v==0 for v in before.get('banked_gp',{}).values()),'No reward is banked before storage recovery')
                for report in reports:
                    require(report.get('saw_pending_reward') and report.get('pending_balance_honest') and report.get('pending_messages'),f"{report['profile']} receives explicit unbanked pending-save state")
            if rejoin:
                require(reports[0]['did_rejoin'],'First/leader client actually disconnects and rejoins')
                require('Connected as' in reports[0]['status'],'Rejoin authenticated successfully')
            for log in case.glob('*.log'):
                require('SCRIPT ERROR:' not in log.read_text() and '\nERROR:' not in log.read_text(),f'{log.name} has no engine errors')
            summary={'label':label,'status':'pass' if not failures else 'fail',
                'server_pid':server.pid,'client_pids':[p.pid for p in processes[1:]],
                'clients':clients,'latency_ms_per_direction':latency,'jitter_ms':jitter,'loss_fraction':loss,
                'impairment':'Application-level scheduling/drop on actual ENet input/snapshot messages; control handshake reliable; not OS netem',
                'source_files_sha256':source_before,'race_results':results,'server_diagnostics':authority['diagnostics'],
                'client_diagnostics':[r['diagnostics'] for r in reports], 'failures':failures,
                'scope':'Linux native headless separate processes on local UDP; no physical devices/browser/production service'}
            (case/'summary.json').write_text(json.dumps(summary,indent=2)+'\n')
            print(label,summary['status'],json.dumps(failures),flush=True)
            return summary
        finally:
            for process in processes:
                if process.poll() is None:
                    process.terminate()
                    try:process.wait(timeout=3)
                    except subprocess.TimeoutExpired:process.kill();process.wait()
            for handle in handles:handle.close()


def run_auth_case(engine: str, destination: Path):
    case=destination/'authentication'
    case.mkdir(parents=True,exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='garage-net-auth-') as temporary:
        tmp=Path(temporary)
        with socket.socket(socket.AF_INET,socket.SOCK_DGRAM) as probe:
            probe.bind(('127.0.0.1',0));port=probe.getsockname()[1]
        env=dict(os.environ,XDG_DATA_HOME=str(tmp/'data'),XDG_CONFIG_HOME=str(tmp/'config'),XDG_CACHE_HOME=str(tmp/'cache'))
        ready=tmp/'ready.json'
        config=tmp/'server.json'
        config.write_text(json.dumps(dict(port=port,ready=str(ready),store=str(tmp/'test-profiles.json'),output=str(case/'server.json'),players=2,duration=5)))
        with (case/'server.log').open('w') as server_log,(case/'client.log').open('w') as client_log:
            server=subprocess.Popen([engine,'--headless','--path',str(NATIVE),'--script','server/session_server.gd','--',str(config)],env=env,stdout=server_log,stderr=subprocess.STDOUT)
            client=None
            try:
                until=time.monotonic()+8
                while not ready.exists():
                    if server.poll() is not None or time.monotonic()>until:raise RuntimeError('Auth test server did not start')
                    time.sleep(.05)
                invitation=json.loads(ready.read_text())['invite']
                cc=tmp/'client.json';cc.write_text(json.dumps(dict(port=port,invite=invitation,output=str(case/'client.json'))))
                client=subprocess.Popen([engine,'--headless','--path',str(NATIVE),'--script','tests/net_auth_client.gd','--',str(cc)],env=env,stdout=client_log,stderr=subprocess.STDOUT)
                client.wait(timeout=12);server.wait(timeout=8)
                server_log.flush();client_log.flush()
                result=json.loads((case/'client.json').read_text())
                authority=json.loads((case/'server.json').read_text())
                checks=[result[k] for k in ('invalid_invite_rejected','valid_join_after_rejection','forged_rejoin_rejected','authenticated_rejoin')]
                failures=[]
                if not all(checks) or client.returncode or server.returncode:failures.append('Actual invitation/rejoin handshake failed')
                if set(authority['banked_profiles'])!={'qa-auth'} or authority['banked_profiles']['qa-auth']['gp']!=0:failures.append('Rejected authentication modified profile/wallet')
                for log in case.glob('*.log'):
                    if 'SCRIPT ERROR:' in log.read_text() or '\nERROR:' in log.read_text():failures.append(log.name+' engine error')
                report=dict(status='pass' if not failures else 'fail',server_pid=server.pid,client_pid=client.pid,checks=result,failures=failures)
                (case/'summary.json').write_text(json.dumps(report,indent=2)+'\n')
                print('authentication',report['status'],failures,flush=True)
                return report
            finally:
                for p in (client,server):
                    if p is not None and p.poll() is None:
                        p.terminate()
                        try:p.wait(timeout=3)
                        except subprocess.TimeoutExpired:p.kill();p.wait()


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output',type=Path,default=ROOT/'evidence/3d-development/multiplayer')
    parser.add_argument('--matrix',action='store_true')
    parser.add_argument('--storage-fault',action='store_true',help='real server storage failure across validated finishes and timeout, then recovery')
    parser.add_argument('--auth',action='store_true',help='actual invalid-invite and forged-rejoin handshake tests')
    parser.add_argument('--repeat',action='store_true',help='two real clients finish two consecutive races in the same room')
    parser.add_argument('--duration',type=float,default=10)
    parser.add_argument('--godot',default=os.environ.get('GODOT_BIN') or shutil.which('godot'))
    args=parser.parse_args()
    if not args.godot:parser.error('Godot4.6.3 required')
    args.output=args.output.resolve()
    if args.auth:
        return 0 if run_auth_case(args.godot,args.output)['status']=='pass' else 1
    cases=[('two-clients',2,0,0,0.0),('four-clients',4,0,0,0.0)]
    if args.matrix:
        cases += [(f'network-{ms}ms',4,ms,ms//5,loss) for ms,loss in [(50,.01),(100,.02),(150,.03),(250,.05)]]
    if args.storage_fault:
        summaries=[run_case(args.godot,'two-clients-storage-fault',2,0,0,0.0,max(args.duration,12),args.output,storage_fault=True)]
    else:
        summaries=[run_case(args.godot,*case,args.duration,args.output) for case in cases] if not args.repeat else [run_case(args.godot,'two-consecutive-races',2,0,0,0.0,max(args.duration,15),args.output,rounds=2)]
    cpu='unknown'
    if Path('/proc/cpuinfo').exists():
        cpu=next((line.split(':',1)[1].strip() for line in Path('/proc/cpuinfo').read_text().splitlines() if line.startswith('model name')),'unknown')
    result={'host_cpu':cpu,'logical_cpus':os.cpu_count(),'cases':summaries,'all_passed':all(s['status']=='pass' for s in summaries),
            'engine':subprocess.check_output([args.godot,'--version'],text=True).strip(),
            'source_sha256':{str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted((NATIVE/'scripts/net').glob('*.gd'))}}
    (args.output/'results.json').write_text(json.dumps(result,indent=2)+'\n')
    return 0 if result['all_passed'] else 1
if __name__=='__main__':
    try:sys.exit(main())
    except (RuntimeError,OSError,subprocess.SubprocessError,ValueError) as error:
        print('NETWORK TEST FAILED:',error,file=sys.stderr);sys.exit(1)
