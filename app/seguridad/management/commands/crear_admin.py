from django.core.management.base import BaseCommand, CommandError
from django.contrib.auth.hashers import make_password
from django.db import connection
from getpass import getpass

class Command(BaseCommand):
    help='Crea o actualiza un usuario GERENTE inicial para la demostracion.'

    def add_arguments(self, parser):
        parser.add_argument('--usuario', default='admin')
        parser.add_argument('--clave', default=None)
        parser.add_argument('--actualizar', action='store_true', help='Permitir restablecer una cuenta existente')
        parser.add_argument('--nombre', default='Administrador')
        parser.add_argument('--apellido', default='Sistema')
        parser.add_argument('--correo', default='admin@local.test')

    def handle(self,*args,**o):
        clave=o['clave'] or getpass('Contraseña (mínimo 12 caracteres): ')
        if len(clave)<12: raise CommandError('Use al menos 12 caracteres.')
        with connection.cursor() as c:
            c.execute("SELECT RolID FROM dbo.Rol WHERE Nombre='GERENTE'")
            row=c.fetchone()
            if not row:
                raise CommandError('No existe el rol GERENTE. Ejecute primero 01_PintureriaDB_Fase1.sql')
            rol=row[0]
            c.execute('SELECT UsuarioID FROM dbo.Usuario WHERE NombreUsuario=%s',[o['usuario']])
            user=c.fetchone()
            ph=make_password(clave)
            if user:
                if not o['actualizar']: raise CommandError('La cuenta existe. Use --actualizar explícitamente para restablecerla.')
                c.execute('EXEC dbo.sp_Usuario_Guardar @UsuarioID=%s,@RolID=%s,@NombreUsuario=%s,@PasswordHash=%s,@Nombres=%s,@Apellidos=%s,@Correo=%s,@Activo=%s',
                          [user[0],rol,o['usuario'],ph,o['nombre'],o['apellido'],o['correo'],1])
                accion='actualizado'
            else:
                c.execute('EXEC dbo.sp_Usuario_Guardar @UsuarioID=%s,@RolID=%s,@NombreUsuario=%s,@PasswordHash=%s,@Nombres=%s,@Apellidos=%s,@Correo=%s,@Activo=%s',
                          [None,rol,o['usuario'],ph,o['nombre'],o['apellido'],o['correo'],1])
                accion='creado'
        self.stdout.write(self.style.SUCCESS(f"Usuario GERENTE '{o['usuario']}' {accion}."))
        self.stdout.write('Credenciales de demo: use el usuario y clave indicados en el comando; cambielos despues de la demostracion.')
