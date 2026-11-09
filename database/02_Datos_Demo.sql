USE PintureriaDB;
GO

/* Datos de demostracion para la defensa de Fase 1. Ejecutar después de 01_PintureriaDB_Fase1.sql. */

IF NOT EXISTS (SELECT 1 FROM dbo.Categoria WHERE Nombre='Accesorios')
    INSERT dbo.Categoria(Nombre,TipoControl,ManejaLote,Descripcion) VALUES ('Accesorios','ACCESORIO',0,'Brochas, rodillos, bandejas, espatulas y otros.');
IF NOT EXISTS (SELECT 1 FROM dbo.Categoria WHERE Nombre='Solventes')
    INSERT dbo.Categoria(Nombre,TipoControl,ManejaLote,Descripcion) VALUES ('Solventes','SOLVENTE',1,'Aguarras y solventes de limpieza.');
IF NOT EXISTS (SELECT 1 FROM dbo.Categoria WHERE Nombre='Pinturas')
    INSERT dbo.Categoria(Nombre,TipoControl,ManejaLote,Descripcion) VALUES ('Pinturas','PINTURA',1,'Pinturas a base de agua y aceite.');
IF NOT EXISTS (SELECT 1 FROM dbo.Categoria WHERE Nombre='Barnices')
    INSERT dbo.Categoria(Nombre,TipoControl,ManejaLote,Descripcion) VALUES ('Barnices','BARNIZ',1,'Barnices sinteticos y acrilicos.');
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Marca WHERE Nombre='ColorMax') INSERT dbo.Marca(Nombre,Descripcion) VALUES ('ColorMax','Marca demostrativa');
IF NOT EXISTS (SELECT 1 FROM dbo.Marca WHERE Nombre='Pinturas GT') INSERT dbo.Marca(Nombre,Descripcion) VALUES ('Pinturas GT','Marca demostrativa');
IF NOT EXISTS (SELECT 1 FROM dbo.Marca WHERE Nombre='ProTools') INSERT dbo.Marca(Nombre,Descripcion) VALUES ('ProTools','Accesorios para pintura');
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Cliente WHERE Nombre='Consumidor Final')
    INSERT dbo.Cliente(TipoCliente,NIT,Nombre,Telefono,Correo,Direccion) VALUES ('PARTICULAR','CF','Consumidor Final',NULL,NULL,'Quetzaltenango');
IF NOT EXISTS (SELECT 1 FROM dbo.Cliente WHERE NIT='1234567-8')
    INSERT dbo.Cliente(TipoCliente,NIT,Nombre,Telefono,Correo,Direccion) VALUES ('EMPRESA','1234567-8','Constructora Los Altos','5555-1001','compras@losaltos.test','Quetzaltenango');
IF NOT EXISTS (SELECT 1 FROM dbo.Cliente WHERE NIT='9876543-2')
    INSERT dbo.Cliente(TipoCliente,NIT,Nombre,Telefono,Correo,Direccion) VALUES ('PARTICULAR','9876543-2','Carlos Mendez','5555-2002','carlos@example.test','San Juan Ostuncalco');
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Proveedor WHERE NIT='1111111-1')
    INSERT dbo.Proveedor(NIT,Nombre,Contacto,Telefono,Correo,Direccion) VALUES ('1111111-1','Distribuidora Nacional de Pinturas','Ana Lopez','2222-1000','ventas@dnp.test','Guatemala');
IF NOT EXISTS (SELECT 1 FROM dbo.Proveedor WHERE NIT='2222222-2')
    INSERT dbo.Proveedor(NIT,Nombre,Contacto,Telefono,Correo,Direccion) VALUES ('2222222-2','Suministros del Occidente','Mario Perez','7766-3000','pedidos@occidente.test','Quetzaltenango');
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Ubicacion WHERE Codigo='B1-P1-E1-N1')
    INSERT dbo.Ubicacion(Codigo,Bodega,Pasillo,Estante,Nivel,Descripcion) VALUES ('B1-P1-E1-N1','Bodega principal','P1','E1','N1','Primera posicion PEPS');
GO

PRINT 'Datos de demostracion cargados.';
GO
