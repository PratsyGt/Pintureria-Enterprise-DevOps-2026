from core.db import execute_query, execute_non_query

def obtener_por_username(username):
    return execute_query('EXEC dbo.sp_UsuarioObtenerPorNombre @NombreUsuario=%s',[username],one=True)

def registrar_acceso(usuario_id):
    execute_non_query('EXEC dbo.sp_UsuarioRegistrarAcceso @UsuarioID=%s',[usuario_id])

def listar_roles():
    return execute_query('EXEC dbo.sp_Rol_Listar')

def listar_usuarios():
    return sorted(execute_query('EXEC dbo.sp_Usuario_Listar'),key=lambda r:r['UsuarioID'])

def obtener_usuario(usuario_id):
    return execute_query('EXEC dbo.sp_Usuario_Obtener @UsuarioID=%s',[usuario_id],one=True)

def guardar_usuario(data,password_hash):
    params=[data.get('usuario_id') or None,int(data['rol_id']),data['nombre_usuario'],password_hash,
            data['nombres'],data['apellidos'],data.get('correo') or None,1 if data.get('activo') else 0]
    return execute_query('EXEC dbo.sp_Usuario_Guardar @UsuarioID=%s,@RolID=%s,@NombreUsuario=%s,@PasswordHash=%s,@Nombres=%s,@Apellidos=%s,@Correo=%s,@Activo=%s',params,one=True)

def cambiar_estado(usuario_id,activo):
    execute_non_query('EXEC dbo.sp_Usuario_CambiarEstado @UsuarioID=%s,@Activo=%s',[usuario_id,1 if activo else 0])


def listar_permisos(usuario_id):
    return execute_query('SELECT Modulo,PuedeVer,PuedeEditar FROM dbo.UsuarioPermiso WHERE UsuarioID=%s', [usuario_id])

def guardar_permisos(usuario_id, permisos):
    from django.db import transaction
    with transaction.atomic():
        execute_non_query('DELETE FROM dbo.UsuarioPermiso WHERE UsuarioID=%s', [usuario_id])
        for modulo, ver, editar in permisos:
            execute_non_query('INSERT dbo.UsuarioPermiso(UsuarioID,Modulo,PuedeVer,PuedeEditar) VALUES(%s,%s,%s,%s)', [usuario_id, modulo, int(ver), int(editar)])
