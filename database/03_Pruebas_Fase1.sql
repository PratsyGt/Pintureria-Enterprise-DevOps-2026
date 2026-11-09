USE PintureriaDB;
GO

PRINT '=== ROLES ===';
EXEC dbo.sp_Rol_Listar;
GO
PRINT '=== USUARIOS / ROLES ===';
SELECT * FROM dbo.vw_UsuariosRoles;
GO
PRINT '=== CUATRO MANTENIMIENTOS ===';
EXEC dbo.sp_Cliente_Listar;
EXEC dbo.sp_Proveedor_Listar;
EXEC dbo.sp_Categoria_Listar;
EXEC dbo.sp_Marca_Listar;
GO
PRINT '=== OBJETOS DE APOYO ===';
SELECT * FROM dbo.vw_ProductosCatalogo;
SELECT * FROM dbo.vw_InventarioActual;
GO
PRINT '=== TABLAS Y LLAVES ===';
SELECT t.name AS Tabla, c.name AS ColumnaPK
FROM sys.tables t
JOIN sys.indexes i ON t.object_id=i.object_id AND i.is_primary_key=1
JOIN sys.index_columns ic ON i.object_id=ic.object_id AND i.index_id=ic.index_id
JOIN sys.columns c ON ic.object_id=c.object_id AND ic.column_id=c.column_id
ORDER BY t.name;
GO
PRINT 'Pruebas basicas completadas.';
GO
