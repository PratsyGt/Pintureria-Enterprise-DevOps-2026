/* Ejecutar SOLO en base de desarrollo después de 07.
   Cada escenario crea datos identificados por GUID y los revierte.
   IDENTITY/SEQUENCE pueden dejar huecos, lo cual es normal.
   No ejecutar con otra transacción abierta. No utiliza datos comerciales existentes. */
USE PintureriaDB;
GO
CREATE PROCEDURE #PruebaPintureria @Caso VARCHAR(30) AS
BEGIN
 SET NOCOUNT ON;
 IF @@TRANCOUNT<>0 THROW 51900,'Ejecute sin una transacción externa.',1;
 DECLARE @Tag VARCHAR(36)=CONVERT(VARCHAR(36),NEWID()),@U INT,@C INT,@P INT,@Cat INT,@M INT,@Prod INT,@V INT,@Ub INT,@OC INT,@F BIGINT,@FD BIGINT,@N VARCHAR(40),@D NVARCHAR(MAX),@Pagos NVARCHAR(MAX),@Old BIGINT,@New BIGINT,@Cot BIGINT;
 DECLARE @Expected INT=CASE @Caso WHEN 'stock' THEN 51014 WHEN 'pagos' THEN 51015 WHEN 'exceso_recepcion' THEN 51033 WHEN 'doble_anulacion' THEN 51212 WHEN 'exceso_devolucion' THEN 51202 WHEN 'doble_cotizacion' THEN 51011 END;
 BEGIN TRY
 BEGIN TRAN;
 INSERT dbo.Usuario(RolID,NombreUsuario,PasswordHash,Nombres,Apellidos) SELECT RolID,@Tag,'!integration-test-unusable','Prueba','Temporal' FROM dbo.Rol WHERE Nombre='GERENTE'; SET @U=SCOPE_IDENTITY();
 INSERT dbo.Cliente(TipoCliente,Nombre,Activo) VALUES('PARTICULAR',@Tag,0); SET @C=SCOPE_IDENTITY();
 IF NOT EXISTS(SELECT 1 FROM dbo.Cliente WHERE ClienteID=@C AND Activo=1) THROW 51901,'Alta activa falló.',1;
 INSERT dbo.Proveedor(Nombre) VALUES(@Tag); SET @P=SCOPE_IDENTITY();
 INSERT dbo.Categoria(Nombre,TipoControl,ManejaLote) VALUES(@Tag,'PINTURA',1); SET @Cat=SCOPE_IDENTITY();
 INSERT dbo.Marca(Nombre) VALUES(@Tag); SET @M=SCOPE_IDENTITY();
 INSERT dbo.Producto(CategoriaID,MarcaID,CodigoBase,Nombre,ManejaLote) VALUES(@Cat,@M,@Tag,@Tag,1); SET @Prod=SCOPE_IDENTITY();
 INSERT dbo.ProductoVariante(ProductoID,PresentacionID,SKU,PrecioVenta) SELECT @Prod,MIN(PresentacionID),@Tag,10 FROM dbo.Presentacion; SET @V=SCOPE_IDENTITY();
 INSERT dbo.Ubicacion(Codigo,Bodega) VALUES(LEFT(@Tag,30),'Prueba temporal'); SET @Ub=SCOPE_IDENTITY();
 SET @D=CONCAT('[{"varianteId":',@V,',"cantidad":100,"costo":5}]');
 EXEC dbo.sp_OrdenCompra_Crear @P,@U,@D;
 SELECT @OC=OrdenCompraID FROM dbo.OrdenCompra WHERE ProveedorID=@P;
 DECLARE @OD INT=(SELECT OrdenCompraDetalleID FROM dbo.OrdenCompraDetalle WHERE OrdenCompraID=@OC);
 SET @D=CONCAT('[{"ordenCompraDetalleId":',@OD,',"cantidad":75,"ubicacionId":',@Ub,',"costo":5}]');
 EXEC dbo.sp_Compra_Recibir @OC,@U,@D;
 IF NOT EXISTS(SELECT 1 FROM dbo.OrdenCompra WHERE OrdenCompraID=@OC AND Estado='PARCIAL') THROW 51902,'Recepción parcial falló.',1;
 SELECT @Old=MIN(LoteID) FROM dbo.LoteInventario WHERE VarianteID=@V;
 SET @D=CONCAT('[{"ordenCompraDetalleId":',@OD,',"cantidad":',CASE WHEN @Caso='exceso_recepcion' THEN 26 ELSE 25 END,',"ubicacionId":',@Ub,',"costo":6}]');
 EXEC dbo.sp_Compra_Recibir @OC,@U,@D;
 SELECT @New=MAX(LoteID) FROM dbo.LoteInventario WHERE VarianteID=@V;
 IF NOT EXISTS(SELECT 1 FROM dbo.OrdenCompra WHERE OrdenCompraID=@OC AND Estado='COMPLETA') THROW 51903,'Recepción completa falló.',1;
 SET @D=CONCAT('[{"varianteId":',@V,',"cantidad":',CASE WHEN @Caso='stock' THEN 101 ELSE 80 END,',"descuento":0}]');
 DECLARE @E INT=(SELECT MedioPagoID FROM dbo.MedioPago WHERE Nombre='EFECTIVO'),@T INT=(SELECT MedioPagoID FROM dbo.MedioPago WHERE Nombre='TARJETA');
 SET @Pagos=CONCAT('[{"medioPagoId":',@E,',"monto":400},{"medioPagoId":',@T,',"monto":',CASE WHEN @Caso='pagos' THEN '399.99' ELSE '400.00' END,'}]');
 IF @Caso='doble_cotizacion'
 BEGIN
  EXEC dbo.sp_Cotizacion_Crear @C,@U,@D;
  SELECT @Cot=CotizacionID FROM dbo.Cotizacion WHERE ClienteID=@C;
  EXEC dbo.sp_Cotizacion_Confirmar @Cot,@U;
 END;
 EXEC dbo.sp_Factura_Emitir @C,@U,@D,@Pagos,@Cot;
 SELECT @F=FacturaID,@N=NumeroFactura FROM dbo.Factura WHERE ClienteID=@C;
 IF @Caso='doble_cotizacion' EXEC dbo.sp_Factura_Emitir @C,@U,@D,@Pagos,@Cot;
 IF (SELECT CantidadDisponible FROM dbo.LoteInventario WHERE LoteID=@Old)<>0 OR (SELECT CantidadDisponible FROM dbo.LoteInventario WHERE LoteID=@New)<>20 THROW 51904,'PEPS falló.',1;
 SELECT @FD=FacturaDetalleID FROM dbo.FacturaDetalle WHERE FacturaID=@F;
 DECLARE @Qty DECIMAL(12,3)=CASE WHEN @Caso='exceso_devolucion' THEN 81 ELSE 10 END;
 EXEC dbo.sp_Devolucion_Registrar @F,@FD,@Qty,@U,'Prueba devolución';
 EXEC dbo.sp_Factura_Anular @N,@U,'Prueba anulación';
 IF (SELECT SUM(CantidadDisponible) FROM dbo.LoteInventario WHERE VarianteID=@V)<>100 THROW 51905,'Restitución duplicada o incompleta.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Factura WHERE FacturaID=@F AND Total=0 AND Estado='ANULADA') THROW 51906,'Anulación no dejó monto cero.',1;
 IF (SELECT SUM(Monto) FROM dbo.PagoFactura WHERE FacturaID=@F)<>800 THROW 51907,'Se perdió el historial de pagos.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.FacturaAnulacion WHERE FacturaID=@F AND TotalOriginal=800) THROW 51908,'Falta auditoría del monto original.',1;
 IF @Caso='doble_anulacion' EXEC dbo.sp_Factura_Anular @N,@U,'Segundo intento';
 IF @Expected IS NOT NULL THROW 51909,'La operación inválida fue aceptada.',1;
 ROLLBACK;
 PRINT CONCAT('OK: ',@Caso,' (datos revertidos)');
 END TRY
 BEGIN CATCH
  DECLARE @Error INT=ERROR_NUMBER();
  IF @@TRANCOUNT>0 ROLLBACK;
  IF @Error<>COALESCE(@Expected,0) THROW;
  IF EXISTS(SELECT 1 FROM dbo.Cliente WHERE Nombre=@Tag) THROW 51910,'La transacción no revirtió los datos.',1;
  PRINT CONCAT('OK: ',@Caso,' rechazado y revertido (',@Error,')');
 END CATCH;
END;
GO
EXEC #PruebaPintureria 'completo';
EXEC #PruebaPintureria 'stock';
EXEC #PruebaPintureria 'pagos';
EXEC #PruebaPintureria 'exceso_recepcion';
EXEC #PruebaPintureria 'exceso_devolucion';
EXEC #PruebaPintureria 'doble_anulacion';
EXEC #PruebaPintureria 'doble_cotizacion';
GO
DROP PROCEDURE #PruebaPintureria;
GO
