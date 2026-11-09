from core.permissions import user_permissions
from .navigation import navigation

def usuario_actual(request):
    permisos=user_permissions(request) if request.session.get('usuario_id') else {}
    groups,section=navigation(request,permisos)
    return {'usuario_sesion':{'id':request.session.get('usuario_id'),'username':request.session.get('username'),'rol':request.session.get('rol'),'nombre':request.session.get('nombre_completo')},'permisos':permisos,'navigation':groups,'section_name':section}
