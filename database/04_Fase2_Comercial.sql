/* FASE 2 - Cotizaciones, facturación transaccional PEPS, pagos y compras.
   Ejecutar después de 01_PintureriaDB_Fase1.sql y 02_Datos_Demo.sql. */
USE PintureriaDB;
GO
BEGIN
 IF NOT EXISTS(SELECT 1 FROM dbo.MedioPago WHERE Nombre='Efectivo') INSERT dbo.MedioPago(Nombre) VALUES('Efectivo');
 IF NOT EXISTS(SELECT 1 FROM dbo.MedioPago WHERE Nombre='Tarjeta') INSERT dbo.MedioPago(Nombre) VALUES('Tarjeta');
 IF NOT EXISTS(SELECT 1 FROM dbo.MedioPago WHERE Nombre='Transferencia') INSERT dbo.MedioPago(Nombre) VALUES('Transferencia');
 IF NOT EXISTS(SELECT 1 FROM dbo.MedioPago WHERE Nombre='Cheque') INSERT dbo.MedioPago(Nombre) VALUES('Cheque');
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_Cotizacion_Crear
 @ClienteID INT, @UsuarioID INT, @DetalleJSON NVARCHAR(MAX), @VigenciaHasta DATE=NULL, @Observaciones VARCHAR(300)=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF ISJSON(@DetalleJSON)<>1 THROW 51001,'El detalle de la cotización debe ser JSON válido.',1;
 IF NOT EXISTS(SELECT 1 FROM OPENJSON(@DetalleJSON) WITH(VarianteID INT '$.varianteId', Cantidad DECIMAL(12,3) '$.cantidad') WHERE VarianteID IS NOT NULL AND Cantidad>0)
   THROW 51002,'Agregue al menos un producto con cantidad válida.',1;
 BEGIN TRY BEGIN TRAN;
 DECLARE @CotizacionID BIGINT;
 INSERT dbo.Cotizacion(ClienteID,UsuarioID,VigenciaHasta,Observaciones) VALUES(@ClienteID,@UsuarioID,@VigenciaHasta,@Observaciones);
 SET @CotizacionID=SCOPE_IDENTITY();
 INSERT dbo.CotizacionDetalle(CotizacionID,VarianteID,Cantidad,PrecioUnitario,Descuento)
 SELECT @CotizacionID,j.VarianteID,j.Cantidad,v.PrecioVenta,COALESCE(j.Descuento,0)
 FROM OPENJSON(@DetalleJSON) WITH(VarianteID INT '$.varianteId',Cantidad DECIMAL(12,3) '$.cantidad',Descuento DECIMAL(12,2) '$.descuento') j
 JOIN dbo.ProductoVariante v ON v.VarianteID=j.VarianteID AND v.Activo=1
 WHERE j.Cantidad>0;
 IF @@ROWCOUNT=0 OR (SELECT COUNT(*) FROM dbo.CotizacionDetalle WHERE CotizacionID=@CotizacionID)<>(SELECT COUNT(*) FROM OPENJSON(@DetalleJSON)) THROW 51003,'Todas las líneas deben tener variantes activas y cantidades válidas.',1;
 IF EXISTS(SELECT 1 FROM dbo.CotizacionDetalle WHERE CotizacionID=@CotizacionID AND (Descuento<0 OR Descuento>Cantidad*PrecioUnitario)) THROW 51004,'Descuento de cotización inválido.',1;
 UPDATE dbo.Cotizacion SET Total=(SELECT SUM(Cantidad*PrecioUnitario-Descuento) FROM dbo.CotizacionDetalle WHERE CotizacionID=@CotizacionID) WHERE CotizacionID=@CotizacionID;
 COMMIT; SELECT @CotizacionID AS CotizacionID;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_Factura_Emitir
 @ClienteID INT, @UsuarioID INT, @DetalleJSON NVARCHAR(MAX), @PagosJSON NVARCHAR(MAX), @CotizacionID BIGINT=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF ISJSON(@DetalleJSON)<>1 OR ISJSON(@PagosJSON)<>1 THROW 51010,'Detalle y pagos deben ser JSON válidos.',1;
 BEGIN TRY BEGIN TRAN;
 IF @CotizacionID IS NOT NULL
 BEGIN
   IF NOT EXISTS(SELECT 1 FROM dbo.Cotizacion WITH(UPDLOCK,HOLDLOCK) WHERE CotizacionID=@CotizacionID AND ClienteID=@ClienteID AND Estado='CONFIRMADA') THROW 51011,'La cotización no existe, no corresponde al cliente o ya fue facturada.',1;
 END;
 DECLARE @D TABLE(VarianteID INT PRIMARY KEY,Cantidad DECIMAL(12,3),Precio DECIMAL(12,2),Descuento DECIMAL(12,2));
 IF @CotizacionID IS NOT NULL
   INSERT @D SELECT VarianteID,SUM(Cantidad),MAX(PrecioUnitario),SUM(Descuento) FROM dbo.CotizacionDetalle WHERE CotizacionID=@CotizacionID GROUP BY VarianteID;
 ELSE
   INSERT @D SELECT j.VarianteID,j.Cantidad,v.PrecioVenta,COALESCE(j.Descuento,0)
   FROM OPENJSON(@DetalleJSON) WITH(VarianteID INT '$.varianteId',Cantidad DECIMAL(12,3) '$.cantidad',Descuento DECIMAL(12,2) '$.descuento') j
   JOIN dbo.ProductoVariante v ON v.VarianteID=j.VarianteID AND v.Activo=1;
 IF @CotizacionID IS NULL AND (SELECT COUNT(*) FROM OPENJSON(@DetalleJSON))<>(SELECT COUNT(*) FROM @D) THROW 51012,'Hay productos duplicados, inactivos o inválidos en la factura.',1;
 IF NOT EXISTS(SELECT 1 FROM @D) OR EXISTS(SELECT 1 FROM @D WHERE Cantidad<=0 OR Precio<0 OR Descuento<0 OR Descuento>Cantidad*Precio) THROW 51013,'Detalle de factura inválido.',1;
 IF EXISTS(SELECT 1 FROM @D d WHERE (SELECT COALESCE(SUM(CantidadDisponible),0) FROM dbo.LoteInventario WITH(UPDLOCK,HOLDLOCK) WHERE VarianteID=d.VarianteID AND Activo=1)<d.Cantidad) THROW 51014,'Existencias insuficientes para uno o más productos.',1;
 DECLARE @Subtotal DECIMAL(12,2),@Descuento DECIMAL(12,2),@Total DECIMAL(12,2),@FacturaID BIGINT,@Numero VARCHAR(40);
 SELECT @Subtotal=SUM(Cantidad*Precio),@Descuento=SUM(Descuento),@Total=SUM(Cantidad*Precio-Descuento) FROM @D;
 IF NOT EXISTS(SELECT 1 FROM OPENJSON(@PagosJSON)) OR EXISTS(SELECT 1 FROM OPENJSON(@PagosJSON) WITH(MedioPagoID INT '$.medioPagoId',Monto DECIMAL(12,2) '$.monto') p LEFT JOIN dbo.MedioPago m ON m.MedioPagoID=p.MedioPagoID AND m.Activo=1 WHERE p.Monto IS NULL OR p.Monto<=0 OR m.MedioPagoID IS NULL) THROW 51018,'Los pagos deben tener importes positivos y medios activos.',1;
 IF ABS(COALESCE((SELECT SUM(Monto) FROM OPENJSON(@PagosJSON) WITH(Monto DECIMAL(12,2) '$.monto')),0)-@Total)>0.01 THROW 51015,'La suma de los pagos debe ser igual al total de la factura.',1;
 SET @Numero=CONCAT('FAC-',FORMAT(SYSDATETIME(),'yyyyMMddHHmmss'),'-',RIGHT(CONVERT(VARCHAR(10),ABS(CHECKSUM(NEWID()))),4));
 INSERT dbo.Factura(NumeroFactura,ClienteID,UsuarioID,CotizacionID,Subtotal,Descuento,Total) VALUES(@Numero,@ClienteID,@UsuarioID,@CotizacionID,@Subtotal,@Descuento,@Total);
 SET @FacturaID=SCOPE_IDENTITY();
 DECLARE @FD TABLE(FacturaDetalleID BIGINT,VarianteID INT,Cantidad DECIMAL(12,3));
 INSERT dbo.FacturaDetalle(FacturaID,VarianteID,Cantidad,PrecioUnitario,Descuento)
 OUTPUT inserted.FacturaDetalleID,inserted.VarianteID,inserted.Cantidad INTO @FD
 SELECT @FacturaID,VarianteID,Cantidad,Precio,Descuento FROM @D;
 DECLARE @vid INT,@need DECIMAL(12,3),@fdid BIGINT,@lote BIGINT,@avail DECIMAL(12,3),@take DECIMAL(12,3),@cost DECIMAL(12,2);
 DECLARE c CURSOR LOCAL FAST_FORWARD FOR SELECT VarianteID,Cantidad,FacturaDetalleID FROM @FD;
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
 COMMIT; SELECT @FacturaID AS FacturaID,@Numero AS NumeroFactura,@Total AS Total;
 END TRY BEGIN CATCH IF CURSOR_STATUS('local','lots')>=-1 BEGIN TRY CLOSE lots; DEALLOCATE lots; END TRY BEGIN CATCH END CATCH; IF CURSOR_STATUS('local','c')>=-1 BEGIN TRY CLOSE c; DEALLOCATE c; END TRY BEGIN CATCH END CATCH; IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_OrdenCompra_Crear
 @ProveedorID INT,@UsuarioID INT,@DetalleJSON NVARCHAR(MAX),@Observaciones VARCHAR(300)=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF ISJSON(@DetalleJSON)<>1 THROW 51020,'El detalle debe ser JSON válido.',1;
 BEGIN TRY BEGIN TRAN; DECLARE @id INT;
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
 IF ISJSON(@DetalleJSON)<>1 THROW 51030,'El detalle de recepción debe ser JSON válido.',1;
 BEGIN TRY BEGIN TRAN;
 IF NOT EXISTS(SELECT 1 FROM dbo.OrdenCompra WITH(UPDLOCK,HOLDLOCK) WHERE OrdenCompraID=@OrdenCompraID AND Estado IN ('PENDIENTE','PARCIAL')) THROW 51031,'La orden no está pendiente de recepción.',1;
 DECLARE @r INT; INSERT dbo.RecepcionCompra(OrdenCompraID,UsuarioID,DocumentoProveedor,Observaciones) VALUES(@OrdenCompraID,@UsuarioID,@DocumentoProveedor,@Observaciones); SET @r=SCOPE_IDENTITY();
 DECLARE @x TABLE(OrdenCompraDetalleID INT,Cantidad DECIMAL(12,3),UbicacionID INT,CodigoLote VARCHAR(60),Costo DECIMAL(12,2));
 INSERT @x SELECT OrdenCompraDetalleID,Cantidad,UbicacionID,CodigoLote,Costo FROM OPENJSON(@DetalleJSON) WITH(OrdenCompraDetalleID INT '$.ordenCompraDetalleId',Cantidad DECIMAL(12,3) '$.cantidad',UbicacionID INT '$.ubicacionId',CodigoLote VARCHAR(60) '$.codigoLote',Costo DECIMAL(12,2) '$.costo');
 IF NOT EXISTS(SELECT 1 FROM @x) OR (SELECT COUNT(*) FROM @x)<>(SELECT COUNT(*) FROM OPENJSON(@DetalleJSON)) OR EXISTS(SELECT 1 FROM @x WHERE Costo IS NULL OR Costo<0) THROW 51032,'No se indicaron cantidades/costos válidos.',1;
 IF EXISTS(SELECT 1 FROM @x GROUP BY OrdenCompraDetalleID HAVING COUNT(*)>1) THROW 51034,'No repita detalles de orden en la recepción.',1;
 IF EXISTS(SELECT 1 FROM @x x LEFT JOIN dbo.OrdenCompraDetalle d ON d.OrdenCompraDetalleID=x.OrdenCompraDetalleID AND d.OrdenCompraID=@OrdenCompraID WHERE d.OrdenCompraDetalleID IS NULL OR x.Cantidad<=0 OR NOT EXISTS(SELECT 1 FROM dbo.Ubicacion u WHERE u.UbicacionID=x.UbicacionID AND u.Activo=1)) OR EXISTS(SELECT 1 FROM @x x JOIN dbo.OrdenCompraDetalle d ON d.OrdenCompraDetalleID=x.OrdenCompraDetalleID GROUP BY x.OrdenCompraDetalleID,d.CantidadSolicitada,d.CantidadRecibida HAVING SUM(x.Cantidad)>d.CantidadSolicitada-d.CantidadRecibida) THROW 51033,'Cantidad, ubicación o detalle de orden inválido.',1;
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
CREATE OR ALTER VIEW dbo.vw_FacturasImpresion AS
SELECT f.FacturaID,f.NumeroFactura,f.FechaFactura,f.Estado,f.Subtotal,f.Descuento,f.Total,c.Nombre AS Cliente,c.NIT,c.Direccion,c.Telefono,
 d.FacturaDetalleID,d.Cantidad,d.PrecioUnitario,d.Descuento AS DescuentoLinea,
 p.Nombre AS Producto,v.SKU,pr.Nombre AS Presentacion,co.Nombre AS Color
FROM dbo.Factura f JOIN dbo.Cliente c ON c.ClienteID=f.ClienteID JOIN dbo.FacturaDetalle d ON d.FacturaID=f.FacturaID
JOIN dbo.ProductoVariante v ON v.VarianteID=d.VarianteID JOIN dbo.Producto p ON p.ProductoID=v.ProductoID
JOIN dbo.Presentacion pr ON pr.PresentacionID=v.PresentacionID LEFT JOIN dbo.ColorProducto co ON co.ColorID=v.ColorID;
GO
