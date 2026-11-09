"""Create first-install Kubernetes secrets from a private Compose env, without printing them."""
import argparse
import json
import subprocess
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('--context', required=True)
parser.add_argument('--env-file', required=True, type=Path)
args = parser.parse_args()
values = dict(line.split('=',1) for line in args.env_file.read_text().splitlines()
              if line.strip() and not line.startswith('#'))
for name, keys in [('sql-admin',['MSSQL_SA_PASSWORD']),('pos-secret',['SECRET_KEY','DB_PASSWORD'])]:
    resource = {'apiVersion':'v1','kind':'Secret','metadata':{'name':name,'namespace':'pintureria-redes'},
                'stringData':{key:values[key] for key in keys}}
    subprocess.run(['kubectl','--context',args.context,'create','-f','-'],
                   input=json.dumps(resource).encode(),check=True)
