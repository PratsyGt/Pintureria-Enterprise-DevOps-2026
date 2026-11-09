"""Generate the team's local Compose env once, outside Git."""
import os
import secrets
from pathlib import Path

path = Path(__file__).resolve().parents[1] / '.env.docker'
if path.exists():
    raise SystemExit('Ya existe .env.docker. Se conserva.')
with os.fdopen(os.open(path, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600), 'w') as f:
    for key in ('SECRET_KEY','DB_PASSWORD','MSSQL_SA_PASSWORD'):
        f.write(f'{key}=Aa1!{secrets.token_hex(32)}\n')
    f.write('WEB_PORT=8000\n')
print('Se creó .env.docker localmente.')
