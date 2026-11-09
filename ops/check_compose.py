"""Verify the local Compose service, bind mount and database persistence. Run on dev only."""
import argparse
import json
import subprocess
import time
import uuid
import urllib.request
from pathlib import Path

parser=argparse.ArgumentParser()
parser.add_argument('--port',type=int,default=8000)
args=parser.parse_args()
root=Path(__file__).resolve().parents[1]
cli=['docker','compose','--env-file','.env.docker','-f','compose.dev.yml']
def compose(*args):
    return subprocess.check_output(cli+list(args),cwd=root,text=True).strip()

def get(path):
    with urllib.request.urlopen(f'http://127.0.0.1:{args.port}'+path,timeout=8) as reply:
        return reply.read()

assert json.loads(get('/health/ready/'))['status']=='ok'
token=uuid.uuid4().hex
probe=root/'app'/'static'/('redes-'+token+'.txt')
try:
    probe.write_text(token)
    assert get('/static/'+probe.name).decode()==token
    probe.write_text(token+'-edit')
    assert get('/static/'+probe.name).decode()==token+'-edit'
finally:
    probe.unlink(missing_ok=True)
print('Cambio de estático visible sin rebuild.',flush=True)
def child():
    return compose('exec','-T','web','python','-c',
        "from pathlib import Path; print(Path('/proc/1/task/1/children').read_text().strip())")
before=child()
(root/'app'/'core'/'health.py').touch()
for _ in range(25):
    time.sleep(1)
    after=child()
    if after and after!=before: break
else: raise RuntimeError('No se detectó la recarga de Django')
print('Django recargó el proceso hijo.',flush=True)
def sql(query):
    return compose('exec','-T','db','bash','-c',
        'export SQLCMDPASSWORD="$MSSQL_SA_PASSWORD"; exec /opt/mssql-tools18/bin/sqlcmd -C -b -S localhost -U sa -d PintureriaDB -h -1 -W -Q "$1"','sql',query)
name='RedesQA_'+token
sql(f"EXEC sys.sp_addextendedproperty @name='{name}', @value='{token}'")
compose('restart','db')
for _ in range(90):
    time.sleep(2)
    try:
        if json.loads(get('/health/ready/'))['status']=='ok':break
    except OSError:pass
else: raise RuntimeError('SQL no volvió a readiness')
assert token in sql(f"SELECT value FROM sys.extended_properties WHERE name='{name}'")
sql(f"EXEC sys.sp_dropextendedproperty @name='{name}'")
print('Prueba de persistencia aprobada tras reiniciar SQL.',flush=True)
