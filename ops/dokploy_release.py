"""Publish the compose specification by digest; Dokploy retains environment secrets and UI domains."""
import json
import os
import re
import urllib.request
from pathlib import Path

image = os.environ['RELEASE_IMAGE']
if not re.fullmatch(r'[a-z0-9][a-z0-9./_-]+@sha256:[a-f0-9]{64}',image):
    raise SystemExit('Se requiere un digest de Registry.')
endpoint = os.environ['DOKPLOY_URL'].rstrip('/')
if not endpoint.startswith('https://'):
    raise SystemExit('DOKPLOY_URL requiere HTTPS.')
compose_id = os.environ['DOKPLOY_COMPOSE_ID']
template = Path('compose.dokploy.yml').read_text()
spec = template.replace('${APP_IMAGE:?Configure APP_IMAGE}',image)
if spec == template:
    raise RuntimeError('Falta el marcador de imagen en el Compose.')

def call(method, data):
    request = urllib.request.Request(endpoint+'/api/compose.'+method,
        data=json.dumps({'composeId':compose_id, **data}).encode(), method='POST',
        headers={'Content-Type':'application/json','x-api-key':os.environ['DOKPLOY_TOKEN']})
    with urllib.request.urlopen(request,timeout=60) as reply:
        print(method, reply.status)

call('update',{'sourceType':'raw','composeFile':spec})
call('deploy',{})
