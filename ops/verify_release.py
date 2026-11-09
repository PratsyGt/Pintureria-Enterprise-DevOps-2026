"""TLS, SQL readiness and the actual deployed revision must all agree."""
import argparse
import json
import time
import urllib.request
from urllib.error import URLError

parser = argparse.ArgumentParser()
parser.add_argument('url')
parser.add_argument('revision')
args = parser.parse_args()
if not args.url.startswith('https://'):
    parser.error('Se requiere la URL pública HTTPS')
for _ in range(60):
    try:
        with urllib.request.urlopen(args.url.rstrip('/')+'/health/ready/',timeout=8) as response:
            data = json.load(response)
            if data.get('status')=='ok' and data.get('revision')==args.revision:
                print('HTTPS, revisión y SQL verificados:', args.revision)
                break
    except (URLError, ValueError, TimeoutError):
        pass
    time.sleep(5)
else:
    raise SystemExit('La revisión esperada no alcanzó readiness antes del plazo.')
