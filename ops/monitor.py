"""Sample an actual endpoint during a rollout or pod removal; returns nonzero on any failure."""
import argparse
import json
import time
import urllib.request

parser = argparse.ArgumentParser()
parser.add_argument('url')
parser.add_argument('--seconds',type=int,default=60)
args = parser.parse_args()
end = time.monotonic()+args.seconds
failures = samples = 0
while time.monotonic()<end:
    samples += 1
    try:
        with urllib.request.urlopen(args.url.rstrip('/')+'/health/ready/',timeout=3) as r:
            assert r.status == 200 and json.load(r)['status']=='ok'
    except Exception as e:
        failures += 1
        print(time.strftime('%FT%T'),type(e).__name__,flush=True)
    time.sleep(.25)
print(f'Muestras: {samples}; fallos: {failures}',flush=True)
raise SystemExit(bool(failures))
