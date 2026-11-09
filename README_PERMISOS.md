# Permisos de usuario

1. Ejecuta `database/05_Permisos_Usuarios.sql` sobre la base de datos existente, después de los scripts anteriores.
2. Inicia la aplicación e ingresa como GERENTE.
3. En Usuarios, crea o edita un usuario y selecciona Consultar o Crear y modificar en cada módulo.
4. Prueba los permisos cerrando sesión e ingresando con ese usuario.

El gerente mantiene acceso completo. Los permisos se revisan en SQL Server en cada petición, no solo al mostrar los enlaces. La edición implica permiso de consulta. Las cuentas desactivadas se bloquean al solicitar una página protegida. Los perfiles originales siguen existiendo.

Nota: no se incluye una base de datos de ejemplo; debes ejecutar los scripts indicados. La modificación se comprobó sintácticamente, pero las operaciones con SQL Server requieren pruebas en tu equipo.
