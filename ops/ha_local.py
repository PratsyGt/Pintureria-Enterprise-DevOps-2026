"""Exercise only the project's local cluster through its TLS ingress. Requires a port forward."""
import argparse
import http.client
import json
import socket
import ssl
import subprocess
import threading
import time
from pathlib import Path

parser=argparse.ArgumentParser()
parser.add_argument('--image',required=True)
parser.add_argument('--revision',required=True)
parser.add_argument('--port',type=int,default=8443)
args=parser.parse_args()
root=Path(__file__).resolve().parents[1]
ca=ssl.create_default_context(cafile=str(root/'tmp/redes-local-ca.pem'))
host='pos.redes.test'
cli=['kubectl','--context','docker-desktop','--namespace','pintureria-redes']
def kubectl(*command):
    return subprocess.check_output(cli+list(command),text=True).strip()

def read(path):
    conn=http.client.HTTPSConnection(host,timeout=5,context=ca)
    with socket.create_connection(('127.0.0.1',args.port),timeout=5) as sock:
        conn.sock=ca.wrap_socket(sock,server_hostname=host)
        try:
            conn.request('GET',path,headers={'Host':host})
            res=conn.getresponse()
            data=res.read()
            if res.status!=200:
                raise RuntimeError(f'{path}: HTTP {res.status}')
            return data
        finally:
            conn.close()

def pods():
    data=json.loads(kubectl('get','pods','-l','app=pos-web','-o','json'))
    return [p['metadata']['name'] for p in data['items'] if not p['metadata'].get('deletionTimestamp')]

before=json.loads(read('/health/ready/'))
for path in ['/seguridad/login/','/static/css/site.css','/static/css/motion.css',
             '/static/js/workspace.js','/static/img/menu-ribbon.svg']:
    assert read(path)
original=pods()
assert len(original)==2
failures=[]
revisions=set()
samples=[]
done=threading.Event()
def sample():
    while not done.is_set():
        try:
            response=json.loads(read('/health/ready/'))
            assert response['status']=='ok'
            revisions.add(response['revision'])
        except Exception as error:
            failures.append(str(error))
        samples.append(time.monotonic())
        done.wait(.25)

thread=threading.Thread(target=sample)
thread.start()
try:
    kubectl('delete','pod',original[0],'--wait=false')
    for i in range(90):
        time.sleep(1)
        current=pods()
        if original[0] not in current and len(current)==2:
            kubectl('wait','--for=condition=Ready','pod/'+next(p for p in current if p not in original),'--timeout=90s')
            break
    else:raise RuntimeError('No apareció el pod de reemplazo')
    replacement=pods()
    kubectl('set','image','deployment/web','web='+args.image)
    kubectl('rollout','status','deployment/web','--timeout=300s')
    after=json.loads(read('/health/ready/'))
    assert after['revision']==args.revision
    time.sleep(2)
finally:
    done.set()
    thread.join()
result={'cluster':'docker-desktop','namespace':'pintureria-redes','tlsHost':host,
        'peerVerified':True,'before':before,'after':after,'originalPods':original,
        'afterDeletion':replacement,'afterRollout':pods(),'samples':len(samples),
        'seconds':round(samples[-1]-samples[0],2),'sampleErrors':failures,
        'revisionsSeen':sorted(revisions)}
print(json.dumps(result,indent=2))
(root/'tmp/ha-redes.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
raise SystemExit(bool(failures))
