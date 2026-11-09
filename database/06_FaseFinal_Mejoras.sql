-- Actualización incremental. Copia de seguridad previa; ejecutar después de 05.
USE PintureriaDB;
GO

ALTER TABLE dbo.UsuarioPermiso DROP CONSTRAINT CK_UsuarioPermiso_Modulo;
ALTER TABLE dbo.UsuarioPermiso WITH CHECK ADD CONSTRAINT CK_UsuarioPermiso_Modulo CHECK (Modulo IN ('clientes','proveedores','categorias','marcas','productos','cotizaciones','facturas','compras','inventario','reportes','anulaciones','presentaciones','colores','ubicaciones','variantes','unidades','devoluciones'));
GO

CREATE OR ALTER PROCEDURE dbo.sp_Cliente_Guardar
    @ClienteID INT=NULL,@TipoCliente VARCHAR(15),@NIT VARCHAR(20)=NULL,@Nombre VARCHAR(150),
    @Telefono VARCHAR(30)=NULL,@Correo VARCHAR(120)=NULL,@Direccion VARCHAR(250)=NULL,@Activo BIT=1
AS
BEGIN
    SET NOCOUNT ON;
    IF @ClienteID IS NULL OR @ClienteID=0 SET @Activo=1;
    IF @ClienteID IS NULL OR @ClienteID=0
    BEGIN
        INSERT dbo.Cliente(TipoCliente,NIT,Nombre,Telefono,Correo,Direccion,Activo)
        VALUES(@TipoCliente,NULLIF(@NIT,''),@Nombre,NULLIF(@Telefono,''),NULLIF(@Correo,''),NULLIF(@Direccion,''),@Activo);
        SELECT CAST(SCOPE_IDENTITY() AS INT) AS ClienteID;
    END
    ELSE
    BEGIN
        IF NOT EXISTS(SELECT 1 FROM dbo.Cliente WHERE ClienteID=@ClienteID) THROW 51100,'Registro no encontrado.',1;
        UPDATE dbo.Cliente SET TipoCliente=@TipoCliente,NIT=NULLIF(@NIT,''),Nombre=@Nombre,
            Telefono=NULLIF(@Telefono,''),Correo=NULLIF(@Correo,''),Direccion=NULLIF(@Direccion,''),Activo=@Activo
        WHERE ClienteID=@ClienteID;
        SELECT @ClienteID AS ClienteID;
    END
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Cliente_Listar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ClienteID,TipoCliente,NIT,Nombre,Telefono,Correo,Direccion,Activo,FechaCreacion
    FROM dbo.Cliente ORDER BY ClienteID ASC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Proveedor_Guardar
    @ProveedorID INT=NULL,@NIT VARCHAR(20)=NULL,@Nombre VARCHAR(150),@Contacto VARCHAR(120)=NULL,
    @Telefono VARCHAR(30)=NULL,@Correo VARCHAR(120)=NULL,@Direccion VARCHAR(250)=NULL,@Activo BIT=1
AS
BEGIN
    SET NOCOUNT ON;
    IF @ProveedorID IS NULL OR @ProveedorID=0 SET @Activo=1;
    IF @ProveedorID IS NULL OR @ProveedorID=0
    BEGIN
        INSERT dbo.Proveedor(NIT,Nombre,Contacto,Telefono,Correo,Direccion,Activo)
        VALUES(NULLIF(@NIT,''),@Nombre,NULLIF(@Contacto,''),NULLIF(@Telefono,''),NULLIF(@Correo,''),NULLIF(@Direccion,''),@Activo);
        SELECT CAST(SCOPE_IDENTITY() AS INT) AS ProveedorID;
    END
    ELSE
    BEGIN
        IF NOT EXISTS(SELECT 1 FROM dbo.Proveedor WHERE ProveedorID=@ProveedorID) THROW 51100,'Registro no encontrado.',1;
        UPDATE dbo.Proveedor SET NIT=NULLIF(@NIT,''),Nombre=@Nombre,Contacto=NULLIF(@Contacto,''),
            Telefono=NULLIF(@Telefono,''),Correo=NULLIF(@Correo,''),Direccion=NULLIF(@Direccion,''),Activo=@Activo
        WHERE ProveedorID=@ProveedorID;
        SELECT @ProveedorID AS ProveedorID;
    END
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Proveedor_Listar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ProveedorID,NIT,Nombre,Contacto,Telefono,Correo,Direccion,Activo,FechaCreacion
    FROM dbo.Proveedor ORDER BY ProveedorID ASC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Categoria_Guardar
    @CategoriaID INT=NULL,@Nombre VARCHAR(80),@TipoControl VARCHAR(20),@ManejaLote BIT=0,
    @Descripcion VARCHAR(200)=NULL,@Activo BIT=1
AS
BEGIN
    SET NOCOUNT ON;
    IF @CategoriaID IS NULL OR @CategoriaID=0 SET @Activo=1;
    IF @CategoriaID IS NULL OR @CategoriaID=0
    BEGIN
        INSERT dbo.Categoria(Nombre,TipoControl,ManejaLote,Descripcion,Activo)
        VALUES(@Nombre,@TipoControl,@ManejaLote,NULLIF(@Descripcion,''),@Activo);
        SELECT CAST(SCOPE_IDENTITY() AS INT) AS CategoriaID;
    END
    ELSE
    BEGIN
        IF NOT EXISTS(SELECT 1 FROM dbo.Categoria WHERE CategoriaID=@CategoriaID) THROW 51100,'Registro no encontrado.',1;
        UPDATE dbo.Categoria SET Nombre=@Nombre,TipoControl=@TipoControl,ManejaLote=@ManejaLote,
            Descripcion=NULLIF(@Descripcion,''),Activo=@Activo WHERE CategoriaID=@CategoriaID;
        SELECT @CategoriaID AS CategoriaID;
    END
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Categoria_Listar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CategoriaID,Nombre,TipoControl,ManejaLote,Descripcion,Activo FROM dbo.Categoria ORDER BY CategoriaID ASC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Marca_Guardar
    @MarcaID INT=NULL,@Nombre VARCHAR(100),@Descripcion VARCHAR(200)=NULL,@Activo BIT=1
AS
BEGIN
    SET NOCOUNT ON;
    IF @MarcaID IS NULL OR @MarcaID=0 SET @Activo=1;
    IF @MarcaID IS NULL OR @MarcaID=0
    BEGIN
        INSERT dbo.Marca(Nombre,Descripcion,Activo) VALUES(@Nombre,NULLIF(@Descripcion,''),@Activo);
        SELECT CAST(SCOPE_IDENTITY() AS INT) AS MarcaID;
    END
    ELSE
    BEGIN
        IF NOT EXISTS(SELECT 1 FROM dbo.Marca WHERE MarcaID=@MarcaID) THROW 51100,'Registro no encontrado.',1;
        UPDATE dbo.Marca SET Nombre=@Nombre,Descripcion=NULLIF(@Descripcion,''),Activo=@Activo WHERE MarcaID=@MarcaID;
        SELECT @MarcaID AS MarcaID;
    END
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Marca_Listar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT MarcaID,Nombre,Descripcion,Activo FROM dbo.Marca ORDER BY MarcaID ASC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Usuario_Guardar
    @UsuarioID INT = NULL,
    @RolID INT,
    @NombreUsuario VARCHAR(50),
    @PasswordHash VARCHAR(255) = NULL,
    @Nombres VARCHAR(80),
    @Apellidos VARCHAR(80),
    @Correo VARCHAR(120) = NULL,
    @Activo BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    IF @UsuarioID IS NULL OR @UsuarioID=0 SET @Activo=1;
    IF @UsuarioID IS NULL OR @UsuarioID=0
    BEGIN
        IF @PasswordHash IS NULL THROW 50001,'La contraseña es obligatoria para un usuario nuevo.',1;
        INSERT dbo.Usuario(RolID,NombreUsuario,PasswordHash,Nombres,Apellidos,Correo,Activo)
        VALUES(@RolID,@NombreUsuario,@PasswordHash,@Nombres,@Apellidos,NULLIF(@Correo,''),@Activo);
        SELECT CAST(SCOPE_IDENTITY() AS INT) AS UsuarioID;
    END
    ELSE
    BEGIN
        IF NOT EXISTS(SELECT 1 FROM dbo.Usuario WHERE UsuarioID=@UsuarioID) THROW 51100,'Registro no encontrado.',1;
        UPDATE dbo.Usuario
        SET RolID=@RolID,NombreUsuario=@NombreUsuario,Nombres=@Nombres,Apellidos=@Apellidos,
            Correo=NULLIF(@Correo,''),Activo=@Activo,
            PasswordHash=CASE WHEN @PasswordHash IS NULL OR @PasswordHash='' THEN PasswordHash ELSE @PasswordHash END
        WHERE UsuarioID=@UsuarioID;
        SELECT @UsuarioID AS UsuarioID;
    END
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Usuario_Listar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT UsuarioID,NombreUsuario,Nombres,Apellidos,Correo,RolID,Rol,Activo,FechaCreacion,UltimoAcceso
    FROM dbo.vw_UsuariosRoles
    ORDER BY UsuarioID ASC;
END;
GO

CREATE OR ALTER TRIGGER dbo.tr_Cliente_AltaActiva ON dbo.Cliente AFTER INSERT AS
BEGIN
 SET NOCOUNT ON;
 UPDATE t SET Activo=1 FROM dbo.Cliente t JOIN inserted i ON i.ClienteID=t.ClienteID WHERE t.Activo=0;
END;
GO

CREATE OR ALTER TRIGGER dbo.tr_Proveedor_AltaActiva ON dbo.Proveedor AFTER INSERT AS
BEGIN
 SET NOCOUNT ON;
 UPDATE t SET Activo=1 FROM dbo.Proveedor t JOIN inserted i ON i.ProveedorID=t.ProveedorID WHERE t.Activo=0;
END;
GO

CREATE OR ALTER TRIGGER dbo.tr_Categoria_AltaActiva ON dbo.Categoria AFTER INSERT AS
BEGIN
 SET NOCOUNT ON;
 UPDATE t SET Activo=1 FROM dbo.Categoria t JOIN inserted i ON i.CategoriaID=t.CategoriaID WHERE t.Activo=0;
END;
GO

CREATE OR ALTER TRIGGER dbo.tr_Marca_AltaActiva ON dbo.Marca AFTER INSERT AS
BEGIN
 SET NOCOUNT ON;
 UPDATE t SET Activo=1 FROM dbo.Marca t JOIN inserted i ON i.MarcaID=t.MarcaID WHERE t.Activo=0;
END;
GO

CREATE OR ALTER TRIGGER dbo.tr_Usuario_AltaActiva ON dbo.Usuario AFTER INSERT AS
BEGIN
 SET NOCOUNT ON;
 UPDATE t SET Activo=1 FROM dbo.Usuario t JOIN inserted i ON i.UsuarioID=t.UsuarioID WHERE t.Activo=0;
END;
GO

CREATE OR ALTER TRIGGER dbo.tr_Producto_AltaActiva ON dbo.Producto AFTER INSERT AS
BEGIN
 SET NOCOUNT ON;
 UPDATE t SET Activo=1 FROM dbo.Producto t JOIN inserted i ON i.ProductoID=t.ProductoID WHERE t.Activo=0;
END;
GO

CREATE OR ALTER TRIGGER dbo.tr_ProductoVariante_AltaActiva ON dbo.ProductoVariante AFTER INSERT AS
BEGIN
 SET NOCOUNT ON;
 UPDATE t SET Activo=1 FROM dbo.ProductoVariante t JOIN inserted i ON i.VarianteID=t.VarianteID WHERE t.Activo=0;
END;
GO

CREATE OR ALTER TRIGGER dbo.tr_Presentacion_AltaActiva ON dbo.Presentacion AFTER INSERT AS
BEGIN
 SET NOCOUNT ON;
 UPDATE t SET Activo=1 FROM dbo.Presentacion t JOIN inserted i ON i.PresentacionID=t.PresentacionID WHERE t.Activo=0;
END;
GO

CREATE OR ALTER TRIGGER dbo.tr_ColorProducto_AltaActiva ON dbo.ColorProducto AFTER INSERT AS
BEGIN
 SET NOCOUNT ON;
 UPDATE t SET Activo=1 FROM dbo.ColorProducto t JOIN inserted i ON i.ColorID=t.ColorID WHERE t.Activo=0;
END;
GO

CREATE OR ALTER TRIGGER dbo.tr_Ubicacion_AltaActiva ON dbo.Ubicacion AFTER INSERT AS
BEGIN
 SET NOCOUNT ON;
 UPDATE t SET Activo=1 FROM dbo.Ubicacion t JOIN inserted i ON i.UbicacionID=t.UbicacionID WHERE t.Activo=0;
END;
GO

CREATE OR ALTER TRIGGER dbo.tr_UnidadMedida_AltaActiva ON dbo.UnidadMedida AFTER INSERT AS
BEGIN
 SET NOCOUNT ON;
 UPDATE t SET Activo=1 FROM dbo.UnidadMedida t JOIN inserted i ON i.UnidadMedidaID=t.UnidadMedidaID WHERE t.Activo=0;
END;
GO

CREATE OR ALTER VIEW dbo.vw_ProductosCatalogo
AS
SELECT p.ProductoID, p.CodigoBase, p.Nombre AS Producto, c.Nombre AS Categoria,
       m.Nombre AS Marca, pv.VarianteID, pv.SKU, pr.Nombre AS Presentacion,
       cp.Nombre AS Color, pv.PrecioVenta, pv.StockMinimo, pv.Activo,
       CAST(CASE WHEN p.Activo=1 AND pv.Activo=1 AND c.Activo=1 AND m.Activo=1 AND pr.Activo=1 AND (cp.ColorID IS NULL OR cp.Activo=1) THEN 1 ELSE 0 END AS BIT) AS DisponibleVenta
FROM dbo.Producto p
INNER JOIN dbo.Categoria c ON c.CategoriaID=p.CategoriaID
INNER JOIN dbo.Marca m ON m.MarcaID=p.MarcaID
INNER JOIN dbo.ProductoVariante pv ON pv.ProductoID=p.ProductoID
INNER JOIN dbo.Presentacion pr ON pr.PresentacionID=pv.PresentacionID
LEFT JOIN dbo.ColorProducto cp ON cp.ColorID=pv.ColorID;
GO

IF OBJECT_ID('dbo.FacturaSecuencia','SO') IS NULL
 EXEC('CREATE SEQUENCE dbo.FacturaSecuencia AS BIGINT START WITH 1 INCREMENT BY 1');
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='UX_Factura_Cotizacion' AND object_id=OBJECT_ID('dbo.Factura'))
BEGIN
 IF EXISTS(SELECT CotizacionID FROM dbo.Factura WHERE CotizacionID IS NOT NULL GROUP BY CotizacionID HAVING COUNT(*)>1)
  THROW 51101,'Existen cotizaciones facturadas más de una vez. Conciliar antes de actualizar.',1;
 CREATE UNIQUE INDEX UX_Factura_Cotizacion ON dbo.Factura(CotizacionID) WHERE CotizacionID IS NOT NULL;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_Autorizar @UsuarioID INT,@Modulo VARCHAR(30),@Editar BIT=1 AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @Rol VARCHAR(30),@Ver BIT,@Edit BIT;
 SELECT @Rol=r.Nombre FROM dbo.Usuario u JOIN dbo.Rol r ON r.RolID=u.RolID AND r.Activo=1 WHERE u.UsuarioID=@UsuarioID AND u.Activo=1;
 IF @Rol IS NULL THROW 51102,'Usuario no autorizado.',1;
 IF @Rol='GERENTE' RETURN;
 SELECT @Ver=PuedeVer,@Edit=PuedeEditar FROM dbo.UsuarioPermiso WHERE UsuarioID=@UsuarioID AND Modulo=@Modulo;
 IF @Ver IS NULL
 BEGIN
  SET @Edit=CASE WHEN @Rol='CAJERO' AND @Modulo='facturas' THEN 1 WHEN @Rol='DIGITADOR' AND @Modulo IN ('clientes','proveedores','categorias','marcas','productos','cotizaciones','compras','inventario','presentaciones','colores','ubicaciones','variantes','unidades') THEN 1 ELSE 0 END;
  SET @Ver=@Edit;
 END;
 IF (@Editar=1 AND @Edit=0) OR (@Editar=0 AND @Ver=0) THROW 51103,'Permiso insuficiente.',1;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Cotizacion_Crear
 @ClienteID INT, @UsuarioID INT, @DetalleJSON NVARCHAR(MAX), @VigenciaHasta DATE=NULL, @Observaciones VARCHAR(300)=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.sp_Autorizar @UsuarioID,'cotizaciones',1;
 IF ISJSON(@DetalleJSON)<>1 THROW 51001,'El detalle de la cotización debe ser JSON válido.',1;
 IF NOT EXISTS(SELECT 1 FROM OPENJSON(@DetalleJSON) WITH(VarianteID INT '$.varianteId', Cantidad DECIMAL(12,3) '$.cantidad') WHERE VarianteID IS NOT NULL AND Cantidad>0)
   THROW 51002,'Agregue al menos un producto con cantidad válida.',1;
 BEGIN TRY BEGIN TRAN;
 IF NOT EXISTS(SELECT 1 FROM dbo.Cliente WITH(HOLDLOCK) WHERE ClienteID=@ClienteID AND Activo=1) THROW 51104,'Cliente inactivo o inexistente.',1;
 IF @VigenciaHasta<CAST(SYSDATETIME() AS DATE) THROW 51105,'La vigencia no puede estar en el pasado.',1;
 IF EXISTS(SELECT varianteId FROM OPENJSON(@DetalleJSON) WITH(varianteId INT) GROUP BY varianteId HAVING COUNT(*)>1) THROW 51106,'No repita productos.',1;
 DECLARE @CotizacionID BIGINT;
 INSERT dbo.Cotizacion(ClienteID,UsuarioID,VigenciaHasta,Observaciones) VALUES(@ClienteID,@UsuarioID,@VigenciaHasta,@Observaciones);
 SET @CotizacionID=SCOPE_IDENTITY();
 INSERT dbo.CotizacionDetalle(CotizacionID,VarianteID,Cantidad,PrecioUnitario,Descuento)
 SELECT @CotizacionID,j.VarianteID,j.Cantidad,v.PrecioVenta,COALESCE(j.Descuento,0)
 FROM OPENJSON(@DetalleJSON) WITH(VarianteID INT '$.varianteId',Cantidad DECIMAL(12,3) '$.cantidad',Descuento DECIMAL(12,2) '$.descuento') j
 JOIN dbo.vw_ProductosCatalogo v ON v.VarianteID=j.VarianteID AND v.DisponibleVenta=1
 WHERE j.Cantidad>0;
 IF @@ROWCOUNT=0 OR (SELECT COUNT(*) FROM dbo.CotizacionDetalle WHERE CotizacionID=@CotizacionID)<>(SELECT COUNT(*) FROM OPENJSON(@DetalleJSON)) THROW 51003,'Todas las líneas deben tener variantes activas y cantidades válidas.',1;
 IF EXISTS(SELECT 1 FROM dbo.CotizacionDetalle WHERE CotizacionID=@CotizacionID AND (Descuento<0 OR Descuento>Cantidad*PrecioUnitario)) THROW 51004,'Descuento de cotización inválido.',1;
 UPDATE dbo.Cotizacion SET Total=(SELECT SUM(ROUND(Cantidad*PrecioUnitario,2)-Descuento) FROM dbo.CotizacionDetalle WHERE CotizacionID=@CotizacionID) WHERE CotizacionID=@CotizacionID;
 COMMIT; SELECT @CotizacionID AS CotizacionID;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Factura_Emitir
 @ClienteID INT, @UsuarioID INT, @DetalleJSON NVARCHAR(MAX), @PagosJSON NVARCHAR(MAX), @CotizacionID BIGINT=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.sp_Autorizar @UsuarioID,'facturas',1;
 IF ISJSON(@DetalleJSON)<>1 OR ISJSON(@PagosJSON)<>1 THROW 51010,'Detalle y pagos deben ser JSON válidos.',1;
 BEGIN TRY BEGIN TRAN;
 IF NOT EXISTS(SELECT 1 FROM dbo.Cliente WITH(HOLDLOCK) WHERE ClienteID=@ClienteID AND Activo=1) THROW 51104,'Cliente inactivo o inexistente.',1;
 IF @CotizacionID IS NOT NULL
 BEGIN
   IF NOT EXISTS(SELECT 1 FROM dbo.Cotizacion WITH(UPDLOCK,HOLDLOCK) WHERE CotizacionID=@CotizacionID AND ClienteID=@ClienteID AND Estado='CONFIRMADA' AND (VigenciaHasta IS NULL OR VigenciaHasta>=CAST(SYSDATETIME() AS DATE))) THROW 51011,'La cotización no existe, no corresponde al cliente o ya fue facturada.',1;
 END;
 DECLARE @D TABLE(VarianteID INT PRIMARY KEY,Cantidad DECIMAL(12,3),Precio DECIMAL(12,2),Descuento DECIMAL(12,2));
 IF @CotizacionID IS NOT NULL
   INSERT @D SELECT VarianteID,SUM(Cantidad),MAX(PrecioUnitario),SUM(Descuento) FROM dbo.CotizacionDetalle WHERE CotizacionID=@CotizacionID GROUP BY VarianteID;
 ELSE
   INSERT @D SELECT j.VarianteID,j.Cantidad,v.PrecioVenta,COALESCE(j.Descuento,0)
   FROM OPENJSON(@DetalleJSON) WITH(VarianteID INT '$.varianteId',Cantidad DECIMAL(12,3) '$.cantidad',Descuento DECIMAL(12,2) '$.descuento') j
   JOIN dbo.vw_ProductosCatalogo v ON v.VarianteID=j.VarianteID AND v.DisponibleVenta=1;
 IF @CotizacionID IS NULL AND (SELECT COUNT(*) FROM OPENJSON(@DetalleJSON))<>(SELECT COUNT(*) FROM @D) THROW 51012,'Hay productos duplicados, inactivos o inválidos en la factura.',1;
 IF NOT EXISTS(SELECT 1 FROM @D) OR EXISTS(SELECT 1 FROM @D WHERE Cantidad IS NULL OR Precio IS NULL OR Descuento IS NULL OR Cantidad<=0 OR Precio<0 OR Descuento<0 OR Descuento>Cantidad*Precio) THROW 51013,'Detalle de factura inválido.',1;
 IF EXISTS(SELECT 1 FROM @D d WHERE (SELECT COALESCE(SUM(CantidadDisponible),0) FROM dbo.LoteInventario WITH(UPDLOCK,HOLDLOCK) WHERE VarianteID=d.VarianteID AND Activo=1)<d.Cantidad) THROW 51014,'Existencias insuficientes para uno o más productos.',1;
 IF EXISTS(SELECT 1 FROM @D d LEFT JOIN dbo.vw_ProductosCatalogo v ON v.VarianteID=d.VarianteID AND v.DisponibleVenta=1 WHERE v.VarianteID IS NULL) THROW 51107,'Producto inactivo.',1;
 DECLARE @Subtotal DECIMAL(12,2),@Descuento DECIMAL(12,2),@Total DECIMAL(12,2),@FacturaID BIGINT,@Numero VARCHAR(40);
 SELECT @Subtotal=SUM(ROUND(Cantidad*Precio,2)),@Descuento=SUM(Descuento),@Total=SUM(ROUND(Cantidad*Precio,2)-Descuento) FROM @D;
 IF NOT EXISTS(SELECT 1 FROM OPENJSON(@PagosJSON)) OR EXISTS(SELECT 1 FROM OPENJSON(@PagosJSON) WITH(MedioPagoID INT '$.medioPagoId',Monto DECIMAL(12,2) '$.monto') p LEFT JOIN dbo.MedioPago m ON m.MedioPagoID=p.MedioPagoID AND m.Activo=1 WHERE p.Monto IS NULL OR p.Monto<=0 OR m.MedioPagoID IS NULL) THROW 51018,'Los pagos deben tener importes positivos y medios activos.',1;
 IF ABS(COALESCE((SELECT SUM(Monto) FROM OPENJSON(@PagosJSON) WITH(Monto DECIMAL(12,2) '$.monto')),0)-@Total)<>0 THROW 51015,'La suma de los pagos debe ser igual al total de la factura.',1;
 SET @Numero=CONCAT('P26-',NEXT VALUE FOR dbo.FacturaSecuencia);
 INSERT dbo.Factura(NumeroFactura,ClienteID,UsuarioID,CotizacionID,Subtotal,Descuento,Total) VALUES(@Numero,@ClienteID,@UsuarioID,@CotizacionID,@Subtotal,@Descuento,@Total);
 SET @FacturaID=SCOPE_IDENTITY();
 DECLARE @FD TABLE(FacturaDetalleID BIGINT,VarianteID INT,Cantidad DECIMAL(12,3));
 INSERT dbo.FacturaDetalle(FacturaID,VarianteID,Cantidad,PrecioUnitario,Descuento)
 OUTPUT inserted.FacturaDetalleID,inserted.VarianteID,inserted.Cantidad INTO @FD
 SELECT @FacturaID,VarianteID,Cantidad,Precio,Descuento FROM @D;
 DECLARE @vid INT,@need DECIMAL(12,3),@fdid BIGINT,@lote BIGINT,@avail DECIMAL(12,3),@take DECIMAL(12,3),@cost DECIMAL(12,2);
 DECLARE c CURSOR LOCAL FAST_FORWARD FOR SELECT VarianteID,Cantidad,FacturaDetalleID FROM @FD ORDER BY VarianteID;
 OPEN c; FETCH NEXT FROM c INTO @vid,@need,@fdid;
 WHILE @@FETCH_STATUS=0
 BEGIN
  DECLARE lots CURSOR LOCAL FAST_FORWARD FOR SELECT LoteID,CantidadDisponible,CostoUnitario FROM dbo.LoteInventario WITH(UPDLOCK,ROWLOCK) WHERE VarianteID=@vid AND Activo=1 AND CantidadDisponible>0 ORDER BY FechaIngreso,LoteID;
  OPEN lots; FETCH NEXT FROM lots INTO @lote,@avail,@cost;
  WHILE @need>0 AND @@FETCH_STATUS=0
  BEGIN
   SET @take=IIF(@avail<@need,@avail,@need);
   UPDATE dbo.LoteInventario SET CantidadDisponible=CantidadDisponible-@take WHERE LoteID=@lote;
   INSERT dbo.SalidaLoteFactura(FacturaDetalleID,LoteID,Cantidad,CostoUnitario) VALUES(@fdid,@lote,@take,@cost);
   INSERT dbo.MovimientoInventario(LoteID,UsuarioID,TipoMovimiento,Cantidad,CostoUnitario,ReferenciaTipo,ReferenciaID) VALUES(@lote,@UsuarioID,'SALIDA',@take,@cost,'FACTURA',@FacturaID);
   SET @need=@need-@take; FETCH NEXT FROM lots INTO @lote,@avail,@cost;
  END
  CLOSE lots; DEALLOCATE lots;
  IF @need>0 THROW 51019,'No se pudo descontar el total de unidades del inventario. La factura se revierte.',1;
  FETCH NEXT FROM c INTO @vid,@need,@fdid;
 END
 CLOSE c; DEALLOCATE c;
 INSERT dbo.PagoFactura(FacturaID,MedioPagoID,UsuarioID,Monto,Referencia)
 SELECT @FacturaID,MedioPagoID,@UsuarioID,Monto,Referencia FROM OPENJSON(@PagosJSON) WITH(MedioPagoID INT '$.medioPagoId',Monto DECIMAL(12,2) '$.monto',Referencia VARCHAR(100) '$.referencia');
 IF EXISTS(SELECT 1 FROM dbo.PagoFactura p LEFT JOIN dbo.MedioPago m ON m.MedioPagoID=p.MedioPagoID AND m.Activo=1 WHERE p.FacturaID=@FacturaID AND m.MedioPagoID IS NULL) THROW 51016,'Medio de pago inválido o inactivo.',1;
 IF @CotizacionID IS NOT NULL UPDATE dbo.Cotizacion SET Estado='FACTURADA' WHERE CotizacionID=@CotizacionID;
 INSERT dbo.AuditoriaOperacion(UsuarioID,TablaAfectada,LlaveRegistro,Operacion,DatosDespues) SELECT @UsuarioID,'Factura',CAST(@FacturaID AS VARCHAR(100)),'INSERT',(SELECT * FROM dbo.Factura WHERE FacturaID=@FacturaID FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 COMMIT; SELECT @FacturaID AS FacturaID,@Numero AS NumeroFactura,@Total AS Total;
 END TRY BEGIN CATCH IF CURSOR_STATUS('local','lots')>=-1 BEGIN TRY CLOSE lots; DEALLOCATE lots; END TRY BEGIN CATCH END CATCH; IF CURSOR_STATUS('local','c')>=-1 BEGIN TRY CLOSE c; DEALLOCATE c; END TRY BEGIN CATCH END CATCH; IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_OrdenCompra_Crear
 @ProveedorID INT,@UsuarioID INT,@DetalleJSON NVARCHAR(MAX),@Observaciones VARCHAR(300)=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.sp_Autorizar @UsuarioID,'compras',1;
 IF ISJSON(@DetalleJSON)<>1 THROW 51020,'El detalle debe ser JSON válido.',1;
 BEGIN TRY BEGIN TRAN;
 IF NOT EXISTS(SELECT 1 FROM dbo.Proveedor WITH(HOLDLOCK) WHERE ProveedorID=@ProveedorID AND Activo=1) THROW 51108,'Proveedor inactivo.',1;
 IF EXISTS(SELECT 1 FROM OPENJSON(@DetalleJSON) WITH(VarianteID INT '$.varianteId') j LEFT JOIN dbo.vw_ProductosCatalogo v ON v.VarianteID=j.VarianteID AND v.DisponibleVenta=1 WHERE v.VarianteID IS NULL) THROW 51109,'Producto inactivo.',1;
 IF EXISTS(SELECT VarianteID FROM OPENJSON(@DetalleJSON) WITH(VarianteID INT '$.varianteId') GROUP BY VarianteID HAVING COUNT(*)>1) THROW 51110,'No repita productos.',1;
 DECLARE @id INT;
 INSERT dbo.OrdenCompra(ProveedorID,UsuarioID,Observaciones) VALUES(@ProveedorID,@UsuarioID,@Observaciones); SET @id=SCOPE_IDENTITY();
 INSERT dbo.OrdenCompraDetalle(OrdenCompraID,VarianteID,CantidadSolicitada,CostoUnitario)
 SELECT @id,VarianteID,Cantidad,Costo FROM OPENJSON(@DetalleJSON) WITH(VarianteID INT '$.varianteId',Cantidad DECIMAL(12,3) '$.cantidad',Costo DECIMAL(12,2) '$.costo') WHERE Cantidad>0 AND Costo>=0;
 IF @@ROWCOUNT=0 OR (SELECT COUNT(*) FROM dbo.OrdenCompraDetalle WHERE OrdenCompraID=@id)<>(SELECT COUNT(*) FROM OPENJSON(@DetalleJSON)) THROW 51021,'Todas las líneas de compra deben tener cantidades y costos válidos.',1;
 COMMIT; SELECT @id AS OrdenCompraID;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Compra_Recibir
 @OrdenCompraID INT,@UsuarioID INT,@DetalleJSON NVARCHAR(MAX),@DocumentoProveedor VARCHAR(60)=NULL,@Observaciones VARCHAR(300)=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.sp_Autorizar @UsuarioID,'compras',1;
 IF ISJSON(@DetalleJSON)<>1 THROW 51030,'El detalle de recepción debe ser JSON válido.',1;
 BEGIN TRY BEGIN TRAN;
 IF NOT EXISTS(SELECT 1 FROM dbo.OrdenCompra WITH(UPDLOCK,HOLDLOCK) WHERE OrdenCompraID=@OrdenCompraID AND Estado IN ('PENDIENTE','PARCIAL')) THROW 51031,'La orden no está pendiente de recepción.',1;
 DECLARE @r INT; INSERT dbo.RecepcionCompra(OrdenCompraID,UsuarioID,DocumentoProveedor,Observaciones) VALUES(@OrdenCompraID,@UsuarioID,@DocumentoProveedor,@Observaciones); SET @r=SCOPE_IDENTITY();
 DECLARE @x TABLE(OrdenCompraDetalleID INT,Cantidad DECIMAL(12,3),UbicacionID INT,CodigoLote VARCHAR(60),Costo DECIMAL(12,2));
 INSERT @x SELECT OrdenCompraDetalleID,Cantidad,UbicacionID,CodigoLote,Costo FROM OPENJSON(@DetalleJSON) WITH(OrdenCompraDetalleID INT '$.ordenCompraDetalleId',Cantidad DECIMAL(12,3) '$.cantidad',UbicacionID INT '$.ubicacionId',CodigoLote VARCHAR(60) '$.codigoLote',Costo DECIMAL(12,2) '$.costo');
 IF NOT EXISTS(SELECT 1 FROM @x) OR (SELECT COUNT(*) FROM @x)<>(SELECT COUNT(*) FROM OPENJSON(@DetalleJSON)) OR EXISTS(SELECT 1 FROM @x WHERE Costo IS NULL OR Costo<0) THROW 51032,'No se indicaron cantidades/costos válidos.',1;
 IF EXISTS(SELECT 1 FROM @x GROUP BY OrdenCompraDetalleID HAVING COUNT(*)>1) THROW 51034,'No repita detalles de orden en la recepción.',1;
 IF EXISTS(SELECT 1 FROM @x x LEFT JOIN dbo.OrdenCompraDetalle d ON d.OrdenCompraDetalleID=x.OrdenCompraDetalleID AND d.OrdenCompraID=@OrdenCompraID WHERE d.OrdenCompraDetalleID IS NULL OR x.Cantidad IS NULL OR x.Cantidad<=0 OR NOT EXISTS(SELECT 1 FROM dbo.Ubicacion u WHERE u.UbicacionID=x.UbicacionID AND u.Activo=1)) OR EXISTS(SELECT 1 FROM @x x JOIN dbo.OrdenCompraDetalle d ON d.OrdenCompraDetalleID=x.OrdenCompraDetalleID GROUP BY x.OrdenCompraDetalleID,d.CantidadSolicitada,d.CantidadRecibida HAVING SUM(x.Cantidad)>d.CantidadSolicitada-d.CantidadRecibida) THROW 51033,'Cantidad, ubicación o detalle de orden inválido.',1;
 INSERT dbo.RecepcionCompraDetalle(RecepcionCompraID,OrdenCompraDetalleID,UbicacionID,CodigoLote,CantidadRecibida,CostoUnitario) SELECT @r,OrdenCompraDetalleID,UbicacionID,CodigoLote,Cantidad,Costo FROM @x;
 DECLARE @det INT,@qty DECIMAL(12,3),@ub INT,@cod VARCHAR(60),@cost DECIMAL(12,2),@var INT,@rd BIGINT,@lote BIGINT;
 DECLARE rc CURSOR LOCAL FAST_FORWARD FOR SELECT x.OrdenCompraDetalleID,x.Cantidad,x.UbicacionID,x.CodigoLote,x.Costo,d.VarianteID FROM @x x JOIN dbo.OrdenCompraDetalle d ON d.OrdenCompraDetalleID=x.OrdenCompraDetalleID;
 OPEN rc; FETCH NEXT FROM rc INTO @det,@qty,@ub,@cod,@cost,@var;
 WHILE @@FETCH_STATUS=0 BEGIN
  SELECT @rd=RecepcionCompraDetalleID FROM dbo.RecepcionCompraDetalle WHERE RecepcionCompraID=@r AND OrdenCompraDetalleID=@det;
  INSERT dbo.LoteInventario(VarianteID,UbicacionID,RecepcionCompraDetalleID,CodigoLote,CostoUnitario,CantidadInicial,CantidadDisponible) VALUES(@var,@ub,@rd,@cod,@cost,@qty,@qty); SET @lote=SCOPE_IDENTITY();
  INSERT dbo.MovimientoInventario(LoteID,UsuarioID,TipoMovimiento,Cantidad,CostoUnitario,ReferenciaTipo,ReferenciaID) VALUES(@lote,@UsuarioID,'ENTRADA',@qty,@cost,'RECEPCION',@r);
  UPDATE dbo.OrdenCompraDetalle SET CantidadRecibida=CantidadRecibida+@qty WHERE OrdenCompraDetalleID=@det;
  FETCH NEXT FROM rc INTO @det,@qty,@ub,@cod,@cost,@var;
 END
 CLOSE rc; DEALLOCATE rc;
 UPDATE dbo.OrdenCompra SET Estado=CASE WHEN NOT EXISTS(SELECT 1 FROM dbo.OrdenCompraDetalle WHERE OrdenCompraID=@OrdenCompraID AND CantidadRecibida<CantidadSolicitada) THEN 'COMPLETA' ELSE 'PARCIAL' END WHERE OrdenCompraID=@OrdenCompraID;
 COMMIT; SELECT @r AS RecepcionCompraID;
 END TRY BEGIN CATCH IF CURSOR_STATUS('local','rc')>=-1 BEGIN TRY CLOSE rc; DEALLOCATE rc; END TRY BEGIN CATCH END CATCH; IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH
END;
GO
