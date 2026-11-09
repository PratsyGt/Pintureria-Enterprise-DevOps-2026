USE PintureriaDB;
GO
-- Relación exacta entre cada devolución y la salida PEPS original.
IF OBJECT_ID('dbo.DevolucionLote','U') IS NULL
CREATE TABLE dbo.DevolucionLote(
 DevolucionDetalleID BIGINT NOT NULL REFERENCES dbo.DevolucionVentaDetalle(DevolucionDetalleID),
 SalidaLoteID BIGINT NOT NULL REFERENCES dbo.SalidaLoteFactura(SalidaLoteID),
 Cantidad DECIMAL(12,3) NOT NULL CHECK(Cantidad>0),
 PRIMARY KEY(DevolucionDetalleID,SalidaLoteID)
);
GO
IF OBJECT_ID('dbo.FacturaAnulacion','U') IS NULL
CREATE TABLE dbo.FacturaAnulacion(
 FacturaID BIGINT PRIMARY KEY REFERENCES dbo.Factura(FacturaID),
 SubtotalOriginal DECIMAL(12,2) NOT NULL,
 DescuentoOriginal DECIMAL(12,2) NOT NULL,
 TotalOriginal DECIMAL(12,2) NOT NULL,
 UsuarioID INT NOT NULL REFERENCES dbo.Usuario(UsuarioID),
 Fecha DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
 Motivo VARCHAR(250) NOT NULL
);
GO
CREATE OR ALTER PROCEDURE dbo.sp_Devolucion_Registrar
 @FacturaID BIGINT,@FacturaDetalleID BIGINT,@Cantidad DECIMAL(12,3),@UsuarioID INT,@Motivo VARCHAR(250)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.sp_Autorizar @UsuarioID,'devoluciones',1;
 IF @Cantidad IS NULL OR @Cantidad<=0 OR NULLIF(LTRIM(RTRIM(@Motivo)),'') IS NULL THROW 51200,'Cantidad y motivo obligatorios.',1;
 BEGIN TRY
 BEGIN TRAN;
 IF NOT EXISTS(SELECT 1 FROM dbo.Factura WITH(UPDLOCK,HOLDLOCK) WHERE FacturaID=@FacturaID AND Estado='EMITIDA') THROW 51201,'La factura no está vigente.',1;
 DECLARE @Vendida DECIMAL(12,3),@Devuelta DECIMAL(12,3),@Monto DECIMAL(12,2),@Dev BIGINT,@DD BIGINT;
 SELECT @Vendida=Cantidad,@Monto=ROUND(Cantidad*PrecioUnitario,2)-Descuento FROM dbo.FacturaDetalle WHERE FacturaID=@FacturaID AND FacturaDetalleID=@FacturaDetalleID;
 SELECT @Devuelta=COALESCE(SUM(Cantidad),0) FROM dbo.DevolucionVentaDetalle WHERE FacturaDetalleID=@FacturaDetalleID;
 IF @Vendida IS NULL OR @Cantidad>@Vendida-@Devuelta THROW 51202,'La devolución supera el saldo vendido.',1;
 IF EXISTS(SELECT 1 FROM dbo.DevolucionVentaDetalle d WHERE d.FacturaDetalleID=@FacturaDetalleID AND d.Cantidad<>(SELECT COALESCE(SUM(Cantidad),0) FROM dbo.DevolucionLote x WHERE x.DevolucionDetalleID=d.DevolucionDetalleID)) THROW 51203,'Hay devoluciones históricas sin lote conciliado.',1;
 -- La última devolución absorbe el redondeo para no superar el importe original.
 SET @Monto=CASE WHEN @Cantidad=@Vendida-@Devuelta THEN @Monto-(SELECT COALESCE(SUM(Monto),0) FROM dbo.DevolucionVentaDetalle WHERE FacturaDetalleID=@FacturaDetalleID) ELSE ROUND(@Monto*@Cantidad/@Vendida,2) END;
 INSERT dbo.DevolucionVenta(FacturaID,UsuarioID,Motivo,TotalDevuelto) VALUES(@FacturaID,@UsuarioID,@Motivo,@Monto); SET @Dev=SCOPE_IDENTITY();
 INSERT dbo.DevolucionVentaDetalle(DevolucionID,FacturaDetalleID,Cantidad,Monto) VALUES(@Dev,@FacturaDetalleID,@Cantidad,@Monto); SET @DD=SCOPE_IDENTITY();
 DECLARE @Salida BIGINT,@Lote BIGINT,@Saldo DECIMAL(12,3),@Tomar DECIMAL(12,3),@Costo DECIMAL(12,2);
 DECLARE lotes CURSOR LOCAL FAST_FORWARD FOR
 SELECT s.SalidaLoteID,s.LoteID,s.Cantidad-COALESCE((SELECT SUM(x.Cantidad) FROM dbo.DevolucionLote x WHERE x.SalidaLoteID=s.SalidaLoteID),0),s.CostoUnitario
 FROM dbo.SalidaLoteFactura s WHERE s.FacturaDetalleID=@FacturaDetalleID ORDER BY s.SalidaLoteID;
 OPEN lotes; FETCH NEXT FROM lotes INTO @Salida,@Lote,@Saldo,@Costo;
 WHILE @@FETCH_STATUS=0 AND @Cantidad>0
 BEGIN
  SET @Tomar=CASE WHEN @Saldo<@Cantidad THEN @Saldo ELSE @Cantidad END;
  IF @Tomar>0
  BEGIN
   UPDATE dbo.LoteInventario WITH(UPDLOCK) SET CantidadDisponible=CantidadDisponible+@Tomar,Activo=1 WHERE LoteID=@Lote;
   INSERT dbo.DevolucionLote VALUES(@DD,@Salida,@Tomar);
   INSERT dbo.MovimientoInventario(LoteID,UsuarioID,TipoMovimiento,Cantidad,CostoUnitario,ReferenciaTipo,ReferenciaID,Observaciones) VALUES(@Lote,@UsuarioID,'DEVOLUCION',@Tomar,@Costo,'DEVOLUCION',@Dev,@Motivo);
   SET @Cantidad=@Cantidad-@Tomar;
  END;
  FETCH NEXT FROM lotes INTO @Salida,@Lote,@Saldo,@Costo;
 END;
 CLOSE lotes; DEALLOCATE lotes;
 IF @Cantidad>0 THROW 51204,'No existen salidas originales suficientes.',1;
 INSERT dbo.AuditoriaOperacion(UsuarioID,TablaAfectada,LlaveRegistro,Operacion,DatosDespues) SELECT @UsuarioID,'DevolucionVenta',CAST(@Dev AS VARCHAR(100)),'INSERT',(SELECT * FROM dbo.DevolucionVenta WHERE DevolucionID=@Dev FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 COMMIT; SELECT @Dev AS DevolucionID;
 END TRY BEGIN CATCH
 IF CURSOR_STATUS('local','lotes')>=0 CLOSE lotes;
 IF CURSOR_STATUS('local','lotes')>=-1 DEALLOCATE lotes;
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW;
 END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_Factura_Anular
 @NumeroFactura VARCHAR(40),@UsuarioID INT,@Motivo VARCHAR(250)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.sp_Autorizar @UsuarioID,'anulaciones',1;
 IF NULLIF(LTRIM(RTRIM(@Motivo)),'') IS NULL THROW 51210,'Indique el motivo de anulación.',1;
 BEGIN TRY
 BEGIN TRAN;
 DECLARE @ID BIGINT,@Estado VARCHAR(15),@Antes NVARCHAR(MAX);
 SELECT @ID=FacturaID,@Estado=Estado FROM dbo.Factura WITH(UPDLOCK,HOLDLOCK) WHERE NumeroFactura=@NumeroFactura;
 IF @ID IS NULL THROW 51211,'Factura no encontrada.',1;
 IF @Estado<>'EMITIDA' THROW 51212,'La factura ya está anulada.',1;
 IF EXISTS(SELECT 1 FROM dbo.DevolucionVentaDetalle d JOIN dbo.FacturaDetalle f ON f.FacturaDetalleID=d.FacturaDetalleID WHERE f.FacturaID=@ID AND d.Cantidad<>(SELECT COALESCE(SUM(x.Cantidad),0) FROM dbo.DevolucionLote x WHERE x.DevolucionDetalleID=d.DevolucionDetalleID)) THROW 51213,'Conciliar devoluciones históricas sin trazabilidad de lote antes de anular.',1;
 IF EXISTS(SELECT 1 FROM dbo.FacturaDetalle d WHERE d.FacturaID=@ID AND d.Cantidad<>(SELECT COALESCE(SUM(Cantidad),0) FROM dbo.SalidaLoteFactura s WHERE s.FacturaDetalleID=d.FacturaDetalleID)) THROW 51214,'Las salidas de la factura no coinciden con el detalle; concilie inventario.',1;
 SET @Antes=(SELECT * FROM dbo.Factura WHERE FacturaID=@ID FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 INSERT dbo.FacturaAnulacion(FacturaID,SubtotalOriginal,DescuentoOriginal,TotalOriginal,UsuarioID,Motivo)
 SELECT FacturaID,Subtotal,Descuento,Total,@UsuarioID,@Motivo FROM dbo.Factura WHERE FacturaID=@ID;
 DECLARE @Restituir TABLE(LoteID BIGINT PRIMARY KEY,Cantidad DECIMAL(12,3),Costo DECIMAL(12,2));
 INSERT @Restituir
 SELECT s.LoteID,SUM(s.Cantidad-COALESCE(x.Cantidad,0)),MAX(s.CostoUnitario)
 FROM dbo.SalidaLoteFactura s JOIN dbo.FacturaDetalle d ON d.FacturaDetalleID=s.FacturaDetalleID
 OUTER APPLY(SELECT SUM(Cantidad) AS Cantidad FROM dbo.DevolucionLote WHERE SalidaLoteID=s.SalidaLoteID) x
 WHERE d.FacturaID=@ID GROUP BY s.LoteID;
 IF EXISTS(SELECT 1 FROM @Restituir WHERE Cantidad<0) THROW 51215,'Devoluciones inconsistentes.',1;
 UPDATE l WITH(UPDLOCK) SET CantidadDisponible=l.CantidadDisponible+r.Cantidad,Activo=1 FROM dbo.LoteInventario l JOIN @Restituir r ON r.LoteID=l.LoteID WHERE r.Cantidad>0;
 INSERT dbo.MovimientoInventario(LoteID,UsuarioID,TipoMovimiento,Cantidad,CostoUnitario,ReferenciaTipo,ReferenciaID,Observaciones)
 SELECT LoteID,@UsuarioID,'DEVOLUCION',Cantidad,Costo,'ANULACION',@ID,@Motivo FROM @Restituir WHERE Cantidad>0;
 UPDATE dbo.Factura SET Estado='ANULADA',Subtotal=0,Descuento=0,Total=0,AnuladaPorID=@UsuarioID,FechaAnulacion=SYSDATETIME(),MotivoAnulacion=@Motivo WHERE FacturaID=@ID;
 INSERT dbo.AuditoriaOperacion(UsuarioID,TablaAfectada,LlaveRegistro,Operacion,DatosAntes,DatosDespues)
 SELECT @UsuarioID,'Factura',CAST(@ID AS VARCHAR(100)),'ANULAR',@Antes,(SELECT * FROM dbo.Factura WHERE FacturaID=@ID FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 COMMIT; SELECT @ID AS FacturaID;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_Cotizacion_Confirmar @CotizacionID BIGINT,@UsuarioID INT AS
BEGIN
 SET NOCOUNT ON;
 EXEC dbo.sp_Autorizar @UsuarioID,'cotizaciones',1;
 UPDATE dbo.Cotizacion SET Estado='CONFIRMADA' OUTPUT inserted.CotizacionID WHERE CotizacionID=@CotizacionID AND Estado='PENDIENTE' AND (VigenciaHasta IS NULL OR VigenciaHasta>=CAST(SYSDATETIME() AS DATE));
END;
GO
-- Filtrar antes de agregar evita multiplicar totales al unir pagos y detalles.
CREATE OR ALTER PROCEDURE dbo.sp_Reporte_Ventas @Desde DATE,@Hasta DATE AS
BEGIN
 SET NOCOUNT ON;
 SELECT COALESCE((SELECT SUM(Total) FROM dbo.Factura WHERE Estado='EMITIDA' AND CAST(FechaFactura AS DATE) BETWEEN @Desde AND @Hasta),0) AS TotalFacturado,
 COALESCE(SUM(CASE WHEN UPPER(m.Nombre)='EFECTIVO' THEN p.Monto ELSE 0 END),0) AS Efectivo,
 COALESCE(SUM(CASE WHEN UPPER(m.Nombre)='CHEQUE' THEN p.Monto ELSE 0 END),0) AS Cheque,
 COALESCE(SUM(CASE WHEN UPPER(m.Nombre)='TARJETA' THEN p.Monto ELSE 0 END),0) AS Tarjeta,
 COALESCE(SUM(CASE WHEN UPPER(m.Nombre) NOT IN ('EFECTIVO','CHEQUE','TARJETA') THEN p.Monto ELSE 0 END),0) AS Otros
 FROM dbo.PagoFactura p JOIN dbo.Factura f ON f.FacturaID=p.FacturaID JOIN dbo.MedioPago m ON m.MedioPagoID=p.MedioPagoID
 WHERE f.Estado='EMITIDA' AND CAST(f.FechaFactura AS DATE) BETWEEN @Desde AND @Hasta;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_Reporte_Productos @Desde DATE,@Hasta DATE,@Orden VARCHAR(12) AS
BEGIN
 SET NOCOUNT ON;
 -- Mantener presentación y variante: no se suman cubetas con galones como si fueran iguales.
 WITH ventas AS(
 SELECT d.VarianteID,SUM(d.Cantidad) AS Cantidad,SUM(ROUND(d.Cantidad*d.PrecioUnitario,2)-d.Descuento) AS Ingresos
 FROM dbo.FacturaDetalle d JOIN dbo.Factura f ON f.FacturaID=d.FacturaID
 WHERE f.Estado='EMITIDA' AND CAST(f.FechaFactura AS DATE) BETWEEN @Desde AND @Hasta GROUP BY d.VarianteID)
 SELECT v.VarianteID,v.SKU,v.Producto,v.Presentacion,v.Color,COALESCE(s.Cantidad,0) AS Cantidad,COALESCE(s.Ingresos,0) AS Ingresos
 FROM dbo.vw_ProductosCatalogo v LEFT JOIN ventas s ON s.VarianteID=v.VarianteID
 ORDER BY CASE WHEN @Orden='ingresos' THEN COALESCE(s.Ingresos,0) END DESC,
 CASE WHEN @Orden='cantidad' THEN COALESCE(s.Cantidad,0) END DESC,
 CASE WHEN @Orden='menos' THEN COALESCE(s.Cantidad,0) END ASC,v.VarianteID ASC;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_Reporte_Inventario AS
BEGIN
 SET NOCOUNT ON;
 SELECT v.VarianteID,v.SKU,v.Producto,v.Presentacion,v.Color,l.LoteID,l.FechaIngreso,u.Bodega,u.Codigo AS Ubicacion,
 COALESCE(l.CantidadDisponible,0) AS Existencias,l.CostoUnitario,v.StockMinimo
 FROM dbo.vw_ProductosCatalogo v LEFT JOIN dbo.LoteInventario l ON l.VarianteID=v.VarianteID AND l.Activo=1 AND l.CantidadDisponible>0
 LEFT JOIN dbo.Ubicacion u ON u.UbicacionID=l.UbicacionID ORDER BY v.VarianteID,l.FechaIngreso,l.LoteID;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_Reporte_SinStock AS
BEGIN
 SET NOCOUNT ON;
 SELECT i.VarianteID,i.SKU,i.Producto,i.Presentacion,i.Color,COALESCE(i.StockActual,0) AS Existencias,i.StockMinimo
 FROM dbo.vw_InventarioActual i JOIN dbo.vw_ProductosCatalogo v ON v.VarianteID=i.VarianteID
 WHERE COALESCE(i.StockActual,0)=0 AND v.DisponibleVenta=1 ORDER BY i.VarianteID;
END;
GO
