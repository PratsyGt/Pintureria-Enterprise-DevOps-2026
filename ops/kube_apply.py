"""Render and apply to an explicitly selected context. Bootstrap runs separately from rollouts."""
import argparse
import re
import subprocess
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('stage',choices=['bootstrap','release'])
parser.add_argument('--context',required=True)
parser.add_argument('--image',required=True)
parser.add_argument('--host',required=True)
args = parser.parse_args()
if not re.fullmatch(r'[a-z0-9][a-z0-9.:/@_-]+',args.image) or not re.fullmatch(r'[a-z0-9][a-z0-9.-]+',args.host):
    parser.error('Imagen o dominio inválido')
root = Path(__file__).resolve().parents[1] / 'k8s'
kubectl = ['kubectl','--context',args.context,'-n','pintureria-redes']
for filename in (['db','init'] if args.stage=='bootstrap' else ['config','web','ingress']):
    content = (root/(filename+'.yaml')).read_text().replace('__IMAGE__',args.image).replace('__HOST__',args.host)
    subprocess.run(kubectl+['apply','-f','-'],input=content.encode(),check=True)
if args.stage=='bootstrap':
    subprocess.run(kubectl+['wait','--for=condition=complete','job/inicializar-sql','--timeout=600s'],check=True)
else:
    subprocess.run(kubectl+['rollout','status','deployment/web','--timeout=360s'],check=True)
