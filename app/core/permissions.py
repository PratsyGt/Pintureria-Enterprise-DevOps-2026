from functools import wraps
from inspect import signature
from django.contrib import messages
from django.shortcuts import redirect
from core.db import execute_query

MODULES = [
    ('clientes', 'Clientes'), ('proveedores', 'Proveedores'),
    ('categorias', 'Categorías'), ('marcas', 'Marcas'),
    ('productos', 'Productos'), ('cotizaciones', 'Cotizaciones'),
    ('facturas', 'Facturación'), ('compras', 'Compras'),
    ('inventario', 'Inventario'), ('reportes','Reportes'), ('anulaciones','Anulaciones'),
    ('presentaciones','Presentaciones'), ('colores','Colores'), ('ubicaciones','Ubicaciones'), ('variantes','Variantes'), ('unidades','Unidades'), ('devoluciones','Devoluciones'),
]
DEFAULTS = {
    'DIGITADOR': {name: (True, True) for name, _ in MODULES if name not in ('facturas','reportes','anulaciones','devoluciones')},
    'CAJERO': {'facturas': (True, True)},
}

def user_permissions(request):
    if hasattr(request,'_permission_cache'):
        return request._permission_cache
    uid = request.session.get('usuario_id')
    if not uid:
        return {}
    user = execute_query('SELECT u.Activo,u.PasswordHash,r.Nombre AS Rol FROM dbo.Usuario u JOIN dbo.Rol r ON r.RolID=u.RolID AND r.Activo=1 WHERE u.UsuarioID=%s', [uid], one=True)
    if not user or not user['Activo']:
        request.session.flush()
        return {}
    from django.utils.crypto import salted_hmac, constant_time_compare
    fingerprint=salted_hmac('pintureria.session',user['PasswordHash']).hexdigest()
    if not constant_time_compare(request.session.get('auth_fingerprint',''),fingerprint):
        request.session.flush()
        return {}
    request.session['rol'] = user['Rol']
    if user['Rol'] == 'GERENTE':
        request._permission_cache={name: {'ver': True, 'editar': True} for name, _ in MODULES}
        return request._permission_cache
    rows = execute_query('SELECT Modulo,PuedeVer,PuedeEditar FROM dbo.UsuarioPermiso WHERE UsuarioID=%s', [uid])
    result = {}
    for name, _ in MODULES:
        defaults = DEFAULTS.get(user['Rol'], {}).get(name, (False, False))
        row = next((x for x in rows if x['Modulo'] == name), None)
        result[name] = {'ver': bool(row['PuedeVer']) if row else defaults[0], 'editar': bool(row['PuedeEditar']) if row else defaults[1]}
    request._permission_cache=result
    return result

def permission_required(module, action='ver'):
    def decorate(view):
        @wraps(view)
        def wrapped(request, *args, **kwargs):
            if not request.session.get('usuario_id'):
                return redirect('login')
            target = signature(view).bind(request, *args, **kwargs).arguments.get('tipo', module) if module == 'catalogo' else module
            if not user_permissions(request).get(target, {}).get(action):
                messages.error(request, 'No tiene permiso para realizar esta operación.')
                return redirect('dashboard')
            return view(request, *args, **kwargs)
        return wrapped
    return decorate
