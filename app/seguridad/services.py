from django.contrib.auth.hashers import check_password, make_password
from . import repositories as repo
from core.permissions import MODULES, DEFAULTS


def autenticar(username,clave):
    user=repo.obtener_por_username(username)
    if not user or not user['Activo']:
        return None
    if not check_password(clave,user['PasswordHash']):
        return None
    repo.registrar_acceso(user['UsuarioID'])
    return user

def listar_roles(): return repo.listar_roles()
def listar_usuarios(): return repo.listar_usuarios()
def obtener_usuario(uid): return repo.obtener_usuario(uid)

def guardar_usuario(data):
    password_hash=make_password(data['clave']) if data.get('clave') else None
    return repo.guardar_usuario(data,password_hash)['UsuarioID']

def cambiar_estado(uid,activo): repo.cambiar_estado(uid,activo)


def permisos_form(uid):
    user = repo.obtener_usuario(uid)
    stored = {row['Modulo']: row for row in repo.listar_permisos(uid)}
    defaults = DEFAULTS.get(user['Rol'], {})
    output = []
    for key, label in MODULES:
        row = stored.get(key)
        view, edit = defaults.get(key, (False,False))
        output.append((key,label,bool(row['PuedeVer']) if row else view,bool(row['PuedeEditar']) if row else edit))
    return output

def guardar_permisos(uid, data):
    if not data.get('personalizar_permisos'):
        repo.guardar_permisos(uid,[])
        return
    entries = []
    for key, label in MODULES:
        editar = 'editar_' + key in data
        ver = ('ver_' + key in data) or editar
        entries.append((key,ver,editar))
    repo.guardar_permisos(uid,entries)
