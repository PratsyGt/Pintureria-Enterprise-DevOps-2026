from django.shortcuts import render,redirect
from django.contrib import messages
from django.db import DatabaseError, IntegrityError, transaction
from django.views.decorators.http import require_POST
from core.decorators import roles_required
from .forms import LoginForm,UsuarioForm
from . import services
from django.middleware.csrf import rotate_token
from core.permissions import MODULES
from django.core.cache import cache
from django.utils.crypto import salted_hmac
import hashlib


def login_view(request):
    if request.session.get('usuario_id'):
        return redirect('dashboard')
    form=LoginForm(request.POST or None)
    if request.method=='POST' and form.is_valid():
        key='login:'+hashlib.sha256((request.META.get('REMOTE_ADDR','')+form.cleaned_data['usuario'].casefold()).encode()).hexdigest()
        attempts=cache.get(key,0)
        if attempts>=8:
            form.add_error(None,'Demasiados intentos. Espere 5 minutos.')
            return render(request,'seguridad/login.html',{'form':form},status=429)
        try:
            user=services.autenticar(form.cleaned_data['usuario'],form.cleaned_data['clave'])
        except DatabaseError as exc:
            messages.error(request,f'No fue posible conectar con la base de datos: Revise los datos y la conexión; consulte el registro del servidor.')
            user=None
        if user:
            cache.delete(key)
            request.session.flush()
            rotate_token(request)
            request.session['auth_fingerprint']=salted_hmac('pintureria.session',user['PasswordHash']).hexdigest()
            request.session['usuario_id']=user['UsuarioID']
            request.session['username']=user['NombreUsuario']
            request.session['rol']=user['Rol']
            request.session['nombre_completo']=f"{user['Nombres']} {user['Apellidos']}"
            return redirect('dashboard')
        cache.set(key,attempts+1,300)
        messages.error(request,'Usuario o contraseña incorrectos, o usuario inactivo.')
    return render(request,'seguridad/login.html',{'form':form})


@require_POST
def logout_view(request):
    request.session.flush()
    return redirect('login')

@roles_required('GERENTE')
def usuarios_list(request):
    from core.pagination import page_query
    usuarios,pagination=page_query(request,'SELECT * FROM dbo.vw_UsuariosRoles',['UsuarioID','NombreUsuario','Nombres','Apellidos','Correo','Rol','Activo'],'UsuarioID',state_column='Activo',states=[('1','Activo'),('0','Inactivo')])
    return render(request,'seguridad/usuarios_list.html',{'usuarios':usuarios,'pagination':pagination,'roles':services.listar_roles()})

@roles_required('GERENTE')
def usuario_nuevo(request):
    roles=services.listar_roles()
    form=UsuarioForm(request.POST or None,roles=roles)
    if request.method=='POST' and form.is_valid():
        try:
            with transaction.atomic():
                uid = services.guardar_usuario({**form.cleaned_data,'usuario_id':None,'activo':True})
                services.guardar_permisos(uid, request.POST)
            messages.success(request,'Usuario creado correctamente.')
            return redirect('usuarios_list')
        except (DatabaseError,IntegrityError) as exc:
            messages.error(request,f'No se pudo guardar el usuario: Revise los datos y la conexión; consulte el registro del servidor.')
    return render(request,'seguridad/usuario_form.html',{'form':form,'titulo':'Nuevo usuario','modulos':[(key,label,False,False) for key,label in MODULES]})

@roles_required('GERENTE')
def usuario_editar(request,usuario_id):
    roles=services.listar_roles()
    user=services.obtener_usuario(usuario_id)
    if not user:
        messages.error(request,'Usuario no encontrado.')
        return redirect('usuarios_list')
    initial={'usuario_id':user['UsuarioID'],'nombre_usuario':user['NombreUsuario'],'nombres':user['Nombres'],
             'apellidos':user['Apellidos'],'correo':user['Correo'],'rol_id':user['RolID'],'activo':user['Activo']}
    form=UsuarioForm(request.POST or None,initial=initial,roles=roles,editing=True)
    if request.method=='POST' and form.is_valid() and usuario_id==request.session['usuario_id'] and int(form.cleaned_data['rol_id'])!=user['RolID']:
        form.add_error('rol_id','No puede cambiar su propio rol durante esta sesión.')
    if request.method=='POST' and form.is_valid():
        try:
            with transaction.atomic():
                uid = services.guardar_usuario({**form.cleaned_data,'usuario_id':usuario_id,'activo':user['Activo']})
                services.guardar_permisos(uid, request.POST)
            messages.success(request,'Usuario actualizado correctamente.')
            return redirect('usuarios_list')
        except (DatabaseError,IntegrityError) as exc:
            messages.error(request,f'No se pudo actualizar el usuario: Revise los datos y la conexión; consulte el registro del servidor.')
    return render(request,'seguridad/usuario_form.html',{'form':form,'titulo':'Editar usuario','modulos':services.permisos_form(usuario_id)})

@roles_required('GERENTE')
@require_POST
def usuario_estado(request,usuario_id,activo):
    if usuario_id == request.session['usuario_id'] and not activo:
        messages.error(request, 'No puede desactivar su propia cuenta.')
        return redirect('usuarios_list')
    if activo not in (0,1):
        from django.http import Http404
        raise Http404
    services.cambiar_estado(usuario_id,bool(activo))
    messages.success(request,'Estado del usuario actualizado.')
    return redirect('usuarios_list')
