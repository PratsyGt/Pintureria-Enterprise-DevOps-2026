from functools import wraps
from django.shortcuts import redirect
from django.contrib import messages


def login_required_custom(view_func):
    @wraps(view_func)
    def wrapper(request,*args,**kwargs):
        if not request.session.get('usuario_id'):
            return redirect('login')
        from core.permissions import user_permissions
        user_permissions(request)
        if not request.session.get('usuario_id'):
            return redirect('login')
        return view_func(request,*args,**kwargs)
    return wrapper


def roles_required(*roles):
    def decorator(view_func):
        @wraps(view_func)
        def wrapper(request, *args, **kwargs):
            if not request.session.get('usuario_id'):
                return redirect('login')
            from core.permissions import user_permissions
            user_permissions(request)
            if not request.session.get('usuario_id'):
                return redirect('login')
            from core.db import execute_query
            user = execute_query('SELECT u.Activo,r.Nombre AS Rol FROM dbo.Usuario u JOIN dbo.Rol r ON r.RolID=u.RolID WHERE u.UsuarioID=%s', [request.session['usuario_id']], one=True)
            if not user or not user['Activo']:
                request.session.flush()
                return redirect('login')
            if user['Rol'] not in roles:
                messages.error(request, 'No tiene permiso para acceder a esta opción.')
                return redirect('dashboard')
            return view_func(request, *args, **kwargs)
        return wrapper
    return decorator
