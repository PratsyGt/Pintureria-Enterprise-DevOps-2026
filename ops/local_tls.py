"""Install a short-lived certificate for the isolated local HTTPS demonstration."""
import argparse
from datetime import datetime, timedelta, timezone
import base64
import json
from pathlib import Path
import subprocess

from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.x509.oid import NameOID, ExtendedKeyUsageOID

parser=argparse.ArgumentParser()
parser.add_argument('--context', required=True)
parser.add_argument('--host', default='pos.redes.test')
args=parser.parse_args()
now=datetime.now(timezone.utc)
def certificate(subject,key,issuer,issuer_key,ca=False):
    builder=(x509.CertificateBuilder().subject_name(subject).issuer_name(issuer)
        .public_key(key.public_key()).serial_number(x509.random_serial_number())
        .not_valid_before(now-timedelta(minutes=5)).not_valid_after(now+timedelta(days=7))
        .add_extension(x509.BasicConstraints(ca=ca,path_length=0 if ca else None),critical=True))
    if not ca:
        builder=builder.add_extension(x509.SubjectAlternativeName([x509.DNSName(args.host)]),False)
        builder=builder.add_extension(x509.ExtendedKeyUsage([ExtendedKeyUsageOID.SERVER_AUTH]),False)
    return builder.sign(issuer_key,hashes.SHA256()).public_bytes(serialization.Encoding.PEM)

name=lambda text:x509.Name([x509.NameAttribute(NameOID.COMMON_NAME,text)])
ca_key=rsa.generate_private_key(public_exponent=65537,key_size=2048)
leaf_key=rsa.generate_private_key(public_exponent=65537,key_size=2048)
issuer=name('Pintureria Redes QA local')
ca=certificate(issuer,ca_key,issuer,ca_key,True)
cert=certificate(name(args.host),leaf_key,issuer,ca_key)
key=leaf_key.private_bytes(serialization.Encoding.PEM,serialization.PrivateFormat.PKCS8,serialization.NoEncryption())
obj={'apiVersion':'v1','kind':'Secret','type':'kubernetes.io/tls',
     'metadata':{'name':'pos-tls','namespace':'pintureria-redes'},
     'data':{k:base64.b64encode(v).decode() for k,v in [('tls.crt',cert),('tls.key',key)]}}
subprocess.run(['kubectl','--context',args.context,'create','-f','-'],input=json.dumps(obj).encode(),check=True)
out=Path(__file__).resolve().parents[1]/'tmp'
out.mkdir(exist_ok=True)
(out/'redes-local-ca.pem').write_bytes(ca)
print('CA pública para la prueba en tmp/redes-local-ca.pem')
