/* ============================================================
   PROYECTO FINAL - BASES DE DATOS II - FASE 1
   Sistema comercial para pinturas, barnices y productos relacionados
   Motor: Microsoft SQL Server 2022 Express
   Base de datos: PintureriaDB
   ============================================================ */

USE master;
GO

IF DB_ID('PintureriaDB') IS NULL
BEGIN
    CREATE DATABASE PintureriaDB;
END;
GO

USE PintureriaDB;
GO

/* ============================================================
   1. SEGURIDAD
   ============================================================ */
IF OBJECT_ID('dbo.Rol', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Rol(
        RolID           INT IDENTITY(1,1) PRIMARY KEY,
        Nombre          VARCHAR(30) NOT NULL UNIQUE,
        Descripcion     VARCHAR(150) NULL,
        Activo          BIT NOT NULL CONSTRAINT DF_Rol_Activo DEFAULT(1),
        FechaCreacion   DATETIME2(0) NOT NULL CONSTRAINT DF_Rol_Fecha DEFAULT(SYSDATETIME())
    );
END;
GO

IF OBJECT_ID('dbo.Usuario', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Usuario(
        UsuarioID       INT IDENTITY(1,1) PRIMARY KEY,
        RolID           INT NOT NULL,
        NombreUsuario   VARCHAR(50) NOT NULL UNIQUE,
        PasswordHash    VARCHAR(255) NOT NULL,
        Nombres         VARCHAR(80) NOT NULL,
        Apellidos       VARCHAR(80) NOT NULL,
        Correo          VARCHAR(120) NULL,
        Activo          BIT NOT NULL CONSTRAINT DF_Usuario_Activo DEFAULT(1),
        FechaCreacion   DATETIME2(0) NOT NULL CONSTRAINT DF_Usuario_Fecha DEFAULT(SYSDATETIME()),
        UltimoAcceso    DATETIME2(0) NULL,
        CONSTRAINT FK_Usuario_Rol FOREIGN KEY (RolID) REFERENCES dbo.Rol(RolID)
    );
END;
GO

/* ============================================================
   2. TABLAS FUERTES / CATALOGOS PRINCIPALES
   ============================================================ */
IF OBJECT_ID('dbo.Cliente', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Cliente(
        ClienteID       INT IDENTITY(1,1) PRIMARY KEY,
        TipoCliente     VARCHAR(15) NOT NULL,
        NIT             VARCHAR(20) NULL,
        Nombre          VARCHAR(150) NOT NULL,
        Telefono        VARCHAR(30) NULL,
        Correo          VARCHAR(120) NULL,
        Direccion       VARCHAR(250) NULL,
        Activo          BIT NOT NULL CONSTRAINT DF_Cliente_Activo DEFAULT(1),
        FechaCreacion   DATETIME2(0) NOT NULL CONSTRAINT DF_Cliente_Fecha DEFAULT(SYSDATETIME()),
        CONSTRAINT CK_Cliente_Tipo CHECK (TipoCliente IN ('PARTICULAR','EMPRESA'))
    );
END;
GO

IF OBJECT_ID('dbo.Proveedor', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Proveedor(
        ProveedorID     INT IDENTITY(1,1) PRIMARY KEY,
        NIT             VARCHAR(20) NULL,
        Nombre          VARCHAR(150) NOT NULL,
        Contacto        VARCHAR(120) NULL,
        Telefono        VARCHAR(30) NULL,
        Correo          VARCHAR(120) NULL,
        Direccion       VARCHAR(250) NULL,
        Activo          BIT NOT NULL CONSTRAINT DF_Proveedor_Activo DEFAULT(1),
        FechaCreacion   DATETIME2(0) NOT NULL CONSTRAINT DF_Proveedor_Fecha DEFAULT(SYSDATETIME())
    );
END;
GO

IF OBJECT_ID('dbo.Categoria', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Categoria(
        CategoriaID     INT IDENTITY(1,1) PRIMARY KEY,
        Nombre          VARCHAR(80) NOT NULL UNIQUE,
        TipoControl     VARCHAR(20) NOT NULL,
        ManejaLote      BIT NOT NULL CONSTRAINT DF_Categoria_Lote DEFAULT(0),
        Descripcion     VARCHAR(200) NULL,
        Activo          BIT NOT NULL CONSTRAINT DF_Categoria_Activo DEFAULT(1),
        CONSTRAINT CK_Categoria_Tipo CHECK (TipoControl IN ('ACCESORIO','SOLVENTE','PINTURA','BARNIZ','OTRO'))
    );
END;
GO

IF OBJECT_ID('dbo.Marca', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Marca(
        MarcaID         INT IDENTITY(1,1) PRIMARY KEY,
        Nombre          VARCHAR(100) NOT NULL UNIQUE,
        Descripcion     VARCHAR(200) NULL,
        Activo          BIT NOT NULL CONSTRAINT DF_Marca_Activo DEFAULT(1)
    );
END;
GO

IF OBJECT_ID('dbo.UnidadMedida', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.UnidadMedida(
        UnidadMedidaID  INT IDENTITY(1,1) PRIMARY KEY,
        Nombre          VARCHAR(50) NOT NULL UNIQUE,
        Simbolo         VARCHAR(15) NOT NULL,
        Activo          BIT NOT NULL CONSTRAINT DF_Unidad_Activo DEFAULT(1)
    );
END;
GO

IF OBJECT_ID('dbo.Presentacion', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Presentacion(
        PresentacionID  INT IDENTITY(1,1) PRIMARY KEY,
        UnidadMedidaID  INT NOT NULL,
        Nombre          VARCHAR(50) NOT NULL UNIQUE,
        FactorGalon     DECIMAL(10,5) NULL,
        Activo          BIT NOT NULL CONSTRAINT DF_Presentacion_Activo DEFAULT(1),
        CONSTRAINT FK_Presentacion_Unidad FOREIGN KEY (UnidadMedidaID) REFERENCES dbo.UnidadMedida(UnidadMedidaID)
    );
END;
GO

IF OBJECT_ID('dbo.ColorProducto', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.ColorProducto(
        ColorID         INT IDENTITY(1,1) PRIMARY KEY,
        Nombre          VARCHAR(80) NOT NULL UNIQUE,
        CodigoHex       CHAR(7) NULL,
        Activo          BIT NOT NULL CONSTRAINT DF_Color_Activo DEFAULT(1)
    );
END;
GO

IF OBJECT_ID('dbo.Ubicacion', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Ubicacion(
        UbicacionID     INT IDENTITY(1,1) PRIMARY KEY,
        Codigo          VARCHAR(30) NOT NULL UNIQUE,
        Bodega          VARCHAR(80) NOT NULL,
        Pasillo         VARCHAR(30) NULL,
        Estante         VARCHAR(30) NULL,
        Nivel           VARCHAR(30) NULL,
        Descripcion     VARCHAR(180) NULL,
        Activo          BIT NOT NULL CONSTRAINT DF_Ubicacion_Activo DEFAULT(1)
    );
END;
GO

/* ============================================================
   3. PRODUCTOS Y VARIANTES
   ============================================================ */
IF OBJECT_ID('dbo.Producto', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Producto(
        ProductoID      INT IDENTITY(1,1) PRIMARY KEY,
        CategoriaID     INT NOT NULL,
        MarcaID         INT NOT NULL,
        CodigoBase      VARCHAR(40) NOT NULL UNIQUE,
        Nombre          VARCHAR(150) NOT NULL,
        Descripcion     VARCHAR(300) NULL,
        ManejaColor     BIT NOT NULL CONSTRAINT DF_Producto_Color DEFAULT(0),
        ManejaLote      BIT NOT NULL CONSTRAINT DF_Producto_Lote DEFAULT(0),
        Activo          BIT NOT NULL CONSTRAINT DF_Producto_Activo DEFAULT(1),
        CONSTRAINT FK_Producto_Categoria FOREIGN KEY (CategoriaID) REFERENCES dbo.Categoria(CategoriaID),
        CONSTRAINT FK_Producto_Marca FOREIGN KEY (MarcaID) REFERENCES dbo.Marca(MarcaID)
    );
END;
GO

IF OBJECT_ID('dbo.ProductoVariante', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.ProductoVariante(
        VarianteID      INT IDENTITY(1,1) PRIMARY KEY,
        ProductoID      INT NOT NULL,
        PresentacionID  INT NOT NULL,
        ColorID         INT NULL,
        SKU             VARCHAR(60) NOT NULL UNIQUE,
        PrecioVenta     DECIMAL(12,2) NOT NULL,
        StockMinimo     DECIMAL(12,3) NOT NULL CONSTRAINT DF_Variante_StockMin DEFAULT(0),
        Activo          BIT NOT NULL CONSTRAINT DF_Variante_Activo DEFAULT(1),
        CONSTRAINT CK_Variante_Precio CHECK (PrecioVenta >= 0),
        CONSTRAINT CK_Variante_StockMin CHECK (StockMinimo >= 0),
        CONSTRAINT FK_Variante_Producto FOREIGN KEY (ProductoID) REFERENCES dbo.Producto(ProductoID),
        CONSTRAINT FK_Variante_Presentacion FOREIGN KEY (PresentacionID) REFERENCES dbo.Presentacion(PresentacionID),
        CONSTRAINT FK_Variante_Color FOREIGN KEY (ColorID) REFERENCES dbo.ColorProducto(ColorID)
    );
END;
GO

/* ============================================================
   4. COMPRAS Y RECEPCIONES PARCIALES
   ============================================================ */
IF OBJECT_ID('dbo.OrdenCompra', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.OrdenCompra(
        OrdenCompraID   INT IDENTITY(1,1) PRIMARY KEY,
        ProveedorID     INT NOT NULL,
        UsuarioID       INT NOT NULL,
        FechaOrden      DATETIME2(0) NOT NULL CONSTRAINT DF_OC_Fecha DEFAULT(SYSDATETIME()),
        Estado          VARCHAR(20) NOT NULL CONSTRAINT DF_OC_Estado DEFAULT('PENDIENTE'),
        Observaciones   VARCHAR(300) NULL,
        CONSTRAINT CK_OC_Estado CHECK (Estado IN ('PENDIENTE','PARCIAL','COMPLETA','CANCELADA')),
        CONSTRAINT FK_OC_Proveedor FOREIGN KEY (ProveedorID) REFERENCES dbo.Proveedor(ProveedorID),
        CONSTRAINT FK_OC_Usuario FOREIGN KEY (UsuarioID) REFERENCES dbo.Usuario(UsuarioID)
    );
END;
GO

IF OBJECT_ID('dbo.OrdenCompraDetalle', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.OrdenCompraDetalle(
        OrdenCompraDetalleID INT IDENTITY(1,1) PRIMARY KEY,
        OrdenCompraID        INT NOT NULL,
        VarianteID           INT NOT NULL,
        CantidadSolicitada   DECIMAL(12,3) NOT NULL,
        CantidadRecibida     DECIMAL(12,3) NOT NULL CONSTRAINT DF_OCD_Recibida DEFAULT(0),
        CostoUnitario        DECIMAL(12,2) NOT NULL,
        CONSTRAINT CK_OCD_Cantidades CHECK (CantidadSolicitada > 0 AND CantidadRecibida >= 0 AND CantidadRecibida <= CantidadSolicitada),
        CONSTRAINT CK_OCD_Costo CHECK (CostoUnitario >= 0),
        CONSTRAINT FK_OCD_OC FOREIGN KEY (OrdenCompraID) REFERENCES dbo.OrdenCompra(OrdenCompraID),
        CONSTRAINT FK_OCD_Variante FOREIGN KEY (VarianteID) REFERENCES dbo.ProductoVariante(VarianteID)
    );
END;
GO

IF OBJECT_ID('dbo.RecepcionCompra', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.RecepcionCompra(
        RecepcionCompraID INT IDENTITY(1,1) PRIMARY KEY,
        OrdenCompraID     INT NOT NULL,
        UsuarioID         INT NOT NULL,
        FechaRecepcion    DATETIME2(0) NOT NULL CONSTRAINT DF_RC_Fecha DEFAULT(SYSDATETIME()),
        DocumentoProveedor VARCHAR(60) NULL,
        Observaciones     VARCHAR(300) NULL,
        CONSTRAINT FK_RC_OC FOREIGN KEY (OrdenCompraID) REFERENCES dbo.OrdenCompra(OrdenCompraID),
        CONSTRAINT FK_RC_Usuario FOREIGN KEY (UsuarioID) REFERENCES dbo.Usuario(UsuarioID)
    );
END;
GO

IF OBJECT_ID('dbo.RecepcionCompraDetalle', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.RecepcionCompraDetalle(
        RecepcionCompraDetalleID INT IDENTITY(1,1) PRIMARY KEY,
        RecepcionCompraID        INT NOT NULL,
        OrdenCompraDetalleID     INT NOT NULL,
        UbicacionID              INT NOT NULL,
        CodigoLote               VARCHAR(60) NULL,
        CantidadRecibida         DECIMAL(12,3) NOT NULL,
        CostoUnitario            DECIMAL(12,2) NOT NULL,
        CONSTRAINT CK_RCD_Cantidad CHECK (CantidadRecibida > 0),
        CONSTRAINT CK_RCD_Costo CHECK (CostoUnitario >= 0),
        CONSTRAINT FK_RCD_RC FOREIGN KEY (RecepcionCompraID) REFERENCES dbo.RecepcionCompra(RecepcionCompraID),
        CONSTRAINT FK_RCD_OCD FOREIGN KEY (OrdenCompraDetalleID) REFERENCES dbo.OrdenCompraDetalle(OrdenCompraDetalleID),
        CONSTRAINT FK_RCD_Ubicacion FOREIGN KEY (UbicacionID) REFERENCES dbo.Ubicacion(UbicacionID)
    );
END;
GO

/* ============================================================
   5. INVENTARIO Y PEPS
   ============================================================ */
IF OBJECT_ID('dbo.LoteInventario', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.LoteInventario(
        LoteID              BIGINT IDENTITY(1,1) PRIMARY KEY,
        VarianteID          INT NOT NULL,
        UbicacionID         INT NOT NULL,
        RecepcionCompraDetalleID INT NULL,
        CodigoLote          VARCHAR(60) NULL,
        FechaIngreso        DATETIME2(0) NOT NULL CONSTRAINT DF_Lote_Fecha DEFAULT(SYSDATETIME()),
        CostoUnitario       DECIMAL(12,2) NOT NULL,
        CantidadInicial     DECIMAL(12,3) NOT NULL,
        CantidadDisponible  DECIMAL(12,3) NOT NULL,
        FechaVencimiento    DATE NULL,
        Activo              BIT NOT NULL CONSTRAINT DF_Lote_Activo DEFAULT(1),
        CONSTRAINT CK_Lote_Cantidades CHECK (CantidadInicial > 0 AND CantidadDisponible >= 0 AND CantidadDisponible <= CantidadInicial),
        CONSTRAINT CK_Lote_Costo CHECK (CostoUnitario >= 0),
        CONSTRAINT FK_Lote_Variante FOREIGN KEY (VarianteID) REFERENCES dbo.ProductoVariante(VarianteID),
        CONSTRAINT FK_Lote_Ubicacion FOREIGN KEY (UbicacionID) REFERENCES dbo.Ubicacion(UbicacionID),
        CONSTRAINT FK_Lote_RecepcionDetalle FOREIGN KEY (RecepcionCompraDetalleID) REFERENCES dbo.RecepcionCompraDetalle(RecepcionCompraDetalleID)
    );
END;
GO

IF OBJECT_ID('dbo.MovimientoInventario', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.MovimientoInventario(
        MovimientoID       BIGINT IDENTITY(1,1) PRIMARY KEY,
        LoteID             BIGINT NOT NULL,
        UsuarioID          INT NOT NULL,
        TipoMovimiento     VARCHAR(20) NOT NULL,
        Cantidad           DECIMAL(12,3) NOT NULL,
        CostoUnitario      DECIMAL(12,2) NULL,
        ReferenciaTipo     VARCHAR(30) NULL,
        ReferenciaID       BIGINT NULL,
        FechaMovimiento    DATETIME2(0) NOT NULL CONSTRAINT DF_MovInv_Fecha DEFAULT(SYSDATETIME()),
        Observaciones      VARCHAR(250) NULL,
        CONSTRAINT CK_MovInv_Tipo CHECK (TipoMovimiento IN ('ENTRADA','SALIDA','DEVOLUCION','AJUSTE_ENTRADA','AJUSTE_SALIDA')),
        CONSTRAINT CK_MovInv_Cantidad CHECK (Cantidad > 0),
        CONSTRAINT FK_MovInv_Lote FOREIGN KEY (LoteID) REFERENCES dbo.LoteInventario(LoteID),
        CONSTRAINT FK_MovInv_Usuario FOREIGN KEY (UsuarioID) REFERENCES dbo.Usuario(UsuarioID)
    );
END;
GO

/* ============================================================
   6. COTIZACION, FACTURACION Y PAGOS
   ============================================================ */
IF OBJECT_ID('dbo.Cotizacion', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Cotizacion(
        CotizacionID    BIGINT IDENTITY(1,1) PRIMARY KEY,
        ClienteID       INT NOT NULL,
        UsuarioID       INT NOT NULL,
        FechaCotizacion DATETIME2(0) NOT NULL CONSTRAINT DF_Cot_Fecha DEFAULT(SYSDATETIME()),
        VigenciaHasta   DATE NULL,
        Estado          VARCHAR(20) NOT NULL CONSTRAINT DF_Cot_Estado DEFAULT('PENDIENTE'),
        Observaciones   VARCHAR(300) NULL,
        Total           DECIMAL(12,2) NOT NULL CONSTRAINT DF_Cot_Total DEFAULT(0),
        CONSTRAINT CK_Cot_Estado CHECK (Estado IN ('PENDIENTE','CONFIRMADA','FACTURADA','VENCIDA','CANCELADA')),
        CONSTRAINT CK_Cot_Total CHECK (Total >= 0),
        CONSTRAINT FK_Cot_Cliente FOREIGN KEY (ClienteID) REFERENCES dbo.Cliente(ClienteID),
        CONSTRAINT FK_Cot_Usuario FOREIGN KEY (UsuarioID) REFERENCES dbo.Usuario(UsuarioID)
    );
END;
GO

IF OBJECT_ID('dbo.CotizacionDetalle', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.CotizacionDetalle(
        CotizacionDetalleID BIGINT IDENTITY(1,1) PRIMARY KEY,
        CotizacionID        BIGINT NOT NULL,
        VarianteID          INT NOT NULL,
        Cantidad            DECIMAL(12,3) NOT NULL,
        PrecioUnitario      DECIMAL(12,2) NOT NULL,
        Descuento           DECIMAL(12,2) NOT NULL CONSTRAINT DF_CotD_Desc DEFAULT(0),
        CONSTRAINT CK_CotD_Cantidad CHECK (Cantidad > 0),
        CONSTRAINT CK_CotD_Precio CHECK (PrecioUnitario >= 0 AND Descuento >= 0),
        CONSTRAINT FK_CotD_Cot FOREIGN KEY (CotizacionID) REFERENCES dbo.Cotizacion(CotizacionID),
        CONSTRAINT FK_CotD_Variante FOREIGN KEY (VarianteID) REFERENCES dbo.ProductoVariante(VarianteID)
    );
END;
GO

IF OBJECT_ID('dbo.Factura', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Factura(
        FacturaID        BIGINT IDENTITY(1,1) PRIMARY KEY,
        NumeroFactura    VARCHAR(40) NOT NULL UNIQUE,
        ClienteID        INT NOT NULL,
        UsuarioID        INT NOT NULL,
        CotizacionID     BIGINT NULL,
        FechaFactura     DATETIME2(0) NOT NULL CONSTRAINT DF_Fact_Fecha DEFAULT(SYSDATETIME()),
        Estado           VARCHAR(15) NOT NULL CONSTRAINT DF_Fact_Estado DEFAULT('EMITIDA'),
        Subtotal         DECIMAL(12,2) NOT NULL,
        Descuento        DECIMAL(12,2) NOT NULL CONSTRAINT DF_Fact_Desc DEFAULT(0),
        Total            DECIMAL(12,2) NOT NULL,
        AnuladaPorID     INT NULL,
        FechaAnulacion   DATETIME2(0) NULL,
        MotivoAnulacion  VARCHAR(250) NULL,
        CONSTRAINT CK_Fact_Estado CHECK (Estado IN ('EMITIDA','ANULADA')),
        CONSTRAINT CK_Fact_Montos CHECK (Subtotal >= 0 AND Descuento >= 0 AND Total >= 0),
        CONSTRAINT FK_Fact_Cliente FOREIGN KEY (ClienteID) REFERENCES dbo.Cliente(ClienteID),
        CONSTRAINT FK_Fact_Usuario FOREIGN KEY (UsuarioID) REFERENCES dbo.Usuario(UsuarioID),
        CONSTRAINT FK_Fact_Cot FOREIGN KEY (CotizacionID) REFERENCES dbo.Cotizacion(CotizacionID),
        CONSTRAINT FK_Fact_AnuladaPor FOREIGN KEY (AnuladaPorID) REFERENCES dbo.Usuario(UsuarioID)
    );
END;
GO

IF OBJECT_ID('dbo.FacturaDetalle', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.FacturaDetalle(
        FacturaDetalleID BIGINT IDENTITY(1,1) PRIMARY KEY,
        FacturaID        BIGINT NOT NULL,
        VarianteID       INT NOT NULL,
        Cantidad         DECIMAL(12,3) NOT NULL,
        PrecioUnitario   DECIMAL(12,2) NOT NULL,
        Descuento        DECIMAL(12,2) NOT NULL CONSTRAINT DF_FactD_Desc DEFAULT(0),
        CONSTRAINT CK_FactD_Cantidad CHECK (Cantidad > 0),
        CONSTRAINT CK_FactD_Precio CHECK (PrecioUnitario >= 0 AND Descuento >= 0),
        CONSTRAINT FK_FactD_Fact FOREIGN KEY (FacturaID) REFERENCES dbo.Factura(FacturaID),
        CONSTRAINT FK_FactD_Variante FOREIGN KEY (VarianteID) REFERENCES dbo.ProductoVariante(VarianteID)
    );
END;
GO

IF OBJECT_ID('dbo.SalidaLoteFactura', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.SalidaLoteFactura(
        SalidaLoteID      BIGINT IDENTITY(1,1) PRIMARY KEY,
        FacturaDetalleID  BIGINT NOT NULL,
        LoteID            BIGINT NOT NULL,
        Cantidad          DECIMAL(12,3) NOT NULL,
        CostoUnitario     DECIMAL(12,2) NOT NULL,
        CONSTRAINT CK_SalidaLote_Cantidad CHECK (Cantidad > 0),
        CONSTRAINT FK_SalidaLote_FactD FOREIGN KEY (FacturaDetalleID) REFERENCES dbo.FacturaDetalle(FacturaDetalleID),
        CONSTRAINT FK_SalidaLote_Lote FOREIGN KEY (LoteID) REFERENCES dbo.LoteInventario(LoteID)
    );
END;
GO

IF OBJECT_ID('dbo.MedioPago', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.MedioPago(
        MedioPagoID     INT IDENTITY(1,1) PRIMARY KEY,
        Nombre          VARCHAR(40) NOT NULL UNIQUE,
        Activo          BIT NOT NULL CONSTRAINT DF_MedioPago_Activo DEFAULT(1)
    );
END;
GO

IF OBJECT_ID('dbo.PagoFactura', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.PagoFactura(
        PagoFacturaID   BIGINT IDENTITY(1,1) PRIMARY KEY,
        FacturaID       BIGINT NOT NULL,
        MedioPagoID     INT NOT NULL,
        UsuarioID       INT NOT NULL,
        Monto           DECIMAL(12,2) NOT NULL,
        Referencia      VARCHAR(100) NULL,
        FechaPago       DATETIME2(0) NOT NULL CONSTRAINT DF_Pago_Fecha DEFAULT(SYSDATETIME()),
        CONSTRAINT CK_Pago_Monto CHECK (Monto > 0),
        CONSTRAINT FK_Pago_Fact FOREIGN KEY (FacturaID) REFERENCES dbo.Factura(FacturaID),
        CONSTRAINT FK_Pago_Medio FOREIGN KEY (MedioPagoID) REFERENCES dbo.MedioPago(MedioPagoID),
        CONSTRAINT FK_Pago_Usuario FOREIGN KEY (UsuarioID) REFERENCES dbo.Usuario(UsuarioID)
    );
END;
GO

/* ============================================================
   7. DEVOLUCIONES
   ============================================================ */
IF OBJECT_ID('dbo.DevolucionVenta', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.DevolucionVenta(
        DevolucionID    BIGINT IDENTITY(1,1) PRIMARY KEY,
        FacturaID       BIGINT NOT NULL,
        UsuarioID       INT NOT NULL,
        FechaDevolucion DATETIME2(0) NOT NULL CONSTRAINT DF_Dev_Fecha DEFAULT(SYSDATETIME()),
        Motivo          VARCHAR(250) NOT NULL,
        TotalDevuelto   DECIMAL(12,2) NOT NULL CONSTRAINT DF_Dev_Total DEFAULT(0),
        CONSTRAINT CK_Dev_Total CHECK (TotalDevuelto >= 0),
        CONSTRAINT FK_Dev_Fact FOREIGN KEY (FacturaID) REFERENCES dbo.Factura(FacturaID),
        CONSTRAINT FK_Dev_Usuario FOREIGN KEY (UsuarioID) REFERENCES dbo.Usuario(UsuarioID)
    );
END;
GO

IF OBJECT_ID('dbo.DevolucionVentaDetalle', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.DevolucionVentaDetalle(
        DevolucionDetalleID BIGINT IDENTITY(1,1) PRIMARY KEY,
        DevolucionID        BIGINT NOT NULL,
        FacturaDetalleID    BIGINT NOT NULL,
        Cantidad            DECIMAL(12,3) NOT NULL,
        Monto               DECIMAL(12,2) NOT NULL,
        CONSTRAINT CK_DevD_Cantidad CHECK (Cantidad > 0),
        CONSTRAINT CK_DevD_Monto CHECK (Monto >= 0),
        CONSTRAINT FK_DevD_Dev FOREIGN KEY (DevolucionID) REFERENCES dbo.DevolucionVenta(DevolucionID),
        CONSTRAINT FK_DevD_FactD FOREIGN KEY (FacturaDetalleID) REFERENCES dbo.FacturaDetalle(FacturaDetalleID)
    );
END;
GO

/* ============================================================
   8. AUDITORIA
   ============================================================ */
IF OBJECT_ID('dbo.AuditoriaOperacion', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.AuditoriaOperacion(
        AuditoriaID     BIGINT IDENTITY(1,1) PRIMARY KEY,
        UsuarioID       INT NULL,
        TablaAfectada   VARCHAR(80) NOT NULL,
        LlaveRegistro   VARCHAR(100) NOT NULL,
        Operacion       VARCHAR(15) NOT NULL,
        FechaOperacion  DATETIME2(0) NOT NULL CONSTRAINT DF_Aud_Fecha DEFAULT(SYSDATETIME()),
        DatosAntes      NVARCHAR(MAX) NULL,
        DatosDespues    NVARCHAR(MAX) NULL,
        CONSTRAINT CK_Aud_Operacion CHECK (Operacion IN ('INSERT','UPDATE','DELETE','ANULAR')),
        CONSTRAINT FK_Aud_Usuario FOREIGN KEY (UsuarioID) REFERENCES dbo.Usuario(UsuarioID)
    );
END;
GO

/* ============================================================
   9. INDICES
   ============================================================ */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_LoteInventario_PEPS' AND object_id = OBJECT_ID('dbo.LoteInventario'))
    CREATE INDEX IX_LoteInventario_PEPS ON dbo.LoteInventario(VarianteID, FechaIngreso, LoteID) INCLUDE(CantidadDisponible, CostoUnitario, UbicacionID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Factura_Fecha' AND object_id = OBJECT_ID('dbo.Factura'))
    CREATE INDEX IX_Factura_Fecha ON dbo.Factura(FechaFactura, Estado);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_MovimientoInventario_Fecha' AND object_id = OBJECT_ID('dbo.MovimientoInventario'))
    CREATE INDEX IX_MovimientoInventario_Fecha ON dbo.MovimientoInventario(FechaMovimiento, TipoMovimiento);
GO

/* ============================================================
   10. DATOS BASE
   ============================================================ */
IF NOT EXISTS (SELECT 1 FROM dbo.Rol WHERE Nombre='DIGITADOR')
    INSERT dbo.Rol(Nombre,Descripcion) VALUES ('DIGITADOR','Alimenta y mantiene informacion del sistema');
IF NOT EXISTS (SELECT 1 FROM dbo.Rol WHERE Nombre='CAJERO')
    INSERT dbo.Rol(Nombre,Descripcion) VALUES ('CAJERO','Encargado del cobro y medios de pago');
IF NOT EXISTS (SELECT 1 FROM dbo.Rol WHERE Nombre='GERENTE')
    INSERT dbo.Rol(Nombre,Descripcion) VALUES ('GERENTE','Administra usuarios y consulta reportes');
GO

IF NOT EXISTS (SELECT 1 FROM dbo.UnidadMedida WHERE Nombre='Unidad')
    INSERT dbo.UnidadMedida(Nombre,Simbolo) VALUES ('Unidad','u');
IF NOT EXISTS (SELECT 1 FROM dbo.UnidadMedida WHERE Nombre='Galon')
    INSERT dbo.UnidadMedida(Nombre,Simbolo) VALUES ('Galon','gal');
IF NOT EXISTS (SELECT 1 FROM dbo.UnidadMedida WHERE Nombre='Cubeta')
    INSERT dbo.UnidadMedida(Nombre,Simbolo) VALUES ('Cubeta','cub');
GO

DECLARE @UnidadID INT=(SELECT UnidadMedidaID FROM dbo.UnidadMedida WHERE Nombre='Unidad');
DECLARE @GalonID INT=(SELECT UnidadMedidaID FROM dbo.UnidadMedida WHERE Nombre='Galon');
DECLARE @CubetaID INT=(SELECT UnidadMedidaID FROM dbo.UnidadMedida WHERE Nombre='Cubeta');

IF NOT EXISTS (SELECT 1 FROM dbo.Presentacion WHERE Nombre='Unidad')
    INSERT dbo.Presentacion(UnidadMedidaID,Nombre,FactorGalon) VALUES (@UnidadID,'Unidad',NULL);
IF NOT EXISTS (SELECT 1 FROM dbo.Presentacion WHERE Nombre='1/32 galon')
    INSERT dbo.Presentacion(UnidadMedidaID,Nombre,FactorGalon) VALUES (@GalonID,'1/32 galon',0.03125);
IF NOT EXISTS (SELECT 1 FROM dbo.Presentacion WHERE Nombre='1/16 galon')
    INSERT dbo.Presentacion(UnidadMedidaID,Nombre,FactorGalon) VALUES (@GalonID,'1/16 galon',0.06250);
IF NOT EXISTS (SELECT 1 FROM dbo.Presentacion WHERE Nombre='1/8 galon')
    INSERT dbo.Presentacion(UnidadMedidaID,Nombre,FactorGalon) VALUES (@GalonID,'1/8 galon',0.12500);
IF NOT EXISTS (SELECT 1 FROM dbo.Presentacion WHERE Nombre='1/4 galon')
    INSERT dbo.Presentacion(UnidadMedidaID,Nombre,FactorGalon) VALUES (@GalonID,'1/4 galon',0.25000);
IF NOT EXISTS (SELECT 1 FROM dbo.Presentacion WHERE Nombre='1/2 galon')
    INSERT dbo.Presentacion(UnidadMedidaID,Nombre,FactorGalon) VALUES (@GalonID,'1/2 galon',0.50000);
IF NOT EXISTS (SELECT 1 FROM dbo.Presentacion WHERE Nombre='1 galon')
    INSERT dbo.Presentacion(UnidadMedidaID,Nombre,FactorGalon) VALUES (@GalonID,'1 galon',1.00000);
IF NOT EXISTS (SELECT 1 FROM dbo.Presentacion WHERE Nombre='1 cubeta')
    INSERT dbo.Presentacion(UnidadMedidaID,Nombre,FactorGalon) VALUES (@CubetaID,'1 cubeta',NULL);
GO

IF NOT EXISTS (SELECT 1 FROM dbo.MedioPago WHERE Nombre='EFECTIVO') INSERT dbo.MedioPago(Nombre) VALUES ('EFECTIVO');
IF NOT EXISTS (SELECT 1 FROM dbo.MedioPago WHERE Nombre='CHEQUE') INSERT dbo.MedioPago(Nombre) VALUES ('CHEQUE');
IF NOT EXISTS (SELECT 1 FROM dbo.MedioPago WHERE Nombre='TARJETA') INSERT dbo.MedioPago(Nombre) VALUES ('TARJETA');
GO

/* ============================================================
   11. VISTAS
   ============================================================ */
CREATE OR ALTER VIEW dbo.vw_UsuariosRoles
AS
SELECT u.UsuarioID, u.NombreUsuario, u.Nombres, u.Apellidos, u.Correo,
       u.Activo, u.FechaCreacion, u.UltimoAcceso,
       r.RolID, r.Nombre AS Rol
FROM dbo.Usuario u
INNER JOIN dbo.Rol r ON r.RolID=u.RolID;
GO

CREATE OR ALTER VIEW dbo.vw_ProductosCatalogo
AS
SELECT p.ProductoID, p.CodigoBase, p.Nombre AS Producto, c.Nombre AS Categoria,
       m.Nombre AS Marca, pv.VarianteID, pv.SKU, pr.Nombre AS Presentacion,
       cp.Nombre AS Color, pv.PrecioVenta, pv.StockMinimo, pv.Activo
FROM dbo.Producto p
INNER JOIN dbo.Categoria c ON c.CategoriaID=p.CategoriaID
INNER JOIN dbo.Marca m ON m.MarcaID=p.MarcaID
INNER JOIN dbo.ProductoVariante pv ON pv.ProductoID=p.ProductoID
INNER JOIN dbo.Presentacion pr ON pr.PresentacionID=pv.PresentacionID
LEFT JOIN dbo.ColorProducto cp ON cp.ColorID=pv.ColorID;
GO

CREATE OR ALTER VIEW dbo.vw_InventarioActual
AS
SELECT pv.VarianteID, pv.SKU, p.Nombre AS Producto, pr.Nombre AS Presentacion,
       cp.Nombre AS Color, SUM(li.CantidadDisponible) AS StockActual,
       pv.StockMinimo
FROM dbo.ProductoVariante pv
INNER JOIN dbo.Producto p ON p.ProductoID=pv.ProductoID
INNER JOIN dbo.Presentacion pr ON pr.PresentacionID=pv.PresentacionID
LEFT JOIN dbo.ColorProducto cp ON cp.ColorID=pv.ColorID
LEFT JOIN dbo.LoteInventario li ON li.VarianteID=pv.VarianteID AND li.Activo=1
GROUP BY pv.VarianteID,pv.SKU,p.Nombre,pr.Nombre,cp.Nombre,pv.StockMinimo;
GO

/* ============================================================
   12. FUNCION
   ============================================================ */
CREATE OR ALTER FUNCTION dbo.fn_StockVariante(@VarianteID INT)
RETURNS DECIMAL(12,3)
AS
BEGIN
    DECLARE @Stock DECIMAL(12,3);
    SELECT @Stock = ISNULL(SUM(CantidadDisponible),0)
    FROM dbo.LoteInventario
    WHERE VarianteID=@VarianteID AND Activo=1;
    RETURN ISNULL(@Stock,0);
END;
GO

/* ============================================================
   13. PROCEDIMIENTOS - SEGURIDAD
   La aplicacion genera/valida el hash PBKDF2; la BD nunca guarda
   la contraseña en texto plano.
   ============================================================ */
CREATE OR ALTER PROCEDURE dbo.sp_Rol_Listar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT RolID,Nombre,Descripcion,Activo FROM dbo.Rol WHERE Activo=1 ORDER BY Nombre;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_UsuarioObtenerPorNombre
    @NombreUsuario VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP(1) u.UsuarioID,u.NombreUsuario,u.PasswordHash,u.Nombres,u.Apellidos,u.Correo,
           u.Activo,r.RolID,r.Nombre AS Rol
    FROM dbo.Usuario u
    INNER JOIN dbo.Rol r ON r.RolID=u.RolID
    WHERE u.NombreUsuario=@NombreUsuario;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_UsuarioRegistrarAcceso
    @UsuarioID INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.Usuario SET UltimoAcceso=SYSDATETIME() WHERE UsuarioID=@UsuarioID;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Usuario_Listar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT UsuarioID,NombreUsuario,Nombres,Apellidos,Correo,RolID,Rol,Activo,FechaCreacion,UltimoAcceso
    FROM dbo.vw_UsuariosRoles
    ORDER BY NombreUsuario;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Usuario_Obtener
    @UsuarioID INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT u.UsuarioID,u.NombreUsuario,u.Nombres,u.Apellidos,u.Correo,u.RolID,u.Activo,r.Nombre AS Rol
    FROM dbo.Usuario u INNER JOIN dbo.Rol r ON r.RolID=u.RolID
    WHERE u.UsuarioID=@UsuarioID;
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
    IF @UsuarioID IS NULL OR @UsuarioID=0
    BEGIN
        IF @PasswordHash IS NULL THROW 50001,'La contraseña es obligatoria para un usuario nuevo.',1;
        INSERT dbo.Usuario(RolID,NombreUsuario,PasswordHash,Nombres,Apellidos,Correo,Activo)
        VALUES(@RolID,@NombreUsuario,@PasswordHash,@Nombres,@Apellidos,NULLIF(@Correo,''),@Activo);
        SELECT CAST(SCOPE_IDENTITY() AS INT) AS UsuarioID;
    END
    ELSE
    BEGIN
        UPDATE dbo.Usuario
        SET RolID=@RolID,NombreUsuario=@NombreUsuario,Nombres=@Nombres,Apellidos=@Apellidos,
            Correo=NULLIF(@Correo,''),Activo=@Activo,
            PasswordHash=CASE WHEN @PasswordHash IS NULL OR @PasswordHash='' THEN PasswordHash ELSE @PasswordHash END
        WHERE UsuarioID=@UsuarioID;
        SELECT @UsuarioID AS UsuarioID;
    END
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Usuario_CambiarEstado
    @UsuarioID INT,
    @Activo BIT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.Usuario SET Activo=@Activo WHERE UsuarioID=@UsuarioID;
END;
GO

/* ============================================================
   14. PROCEDIMIENTOS - MANTENIMIENTOS DE TABLAS FUERTES
   ============================================================ */
CREATE OR ALTER PROCEDURE dbo.sp_Cliente_Listar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ClienteID,TipoCliente,NIT,Nombre,Telefono,Correo,Direccion,Activo,FechaCreacion
    FROM dbo.Cliente ORDER BY Nombre;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Cliente_Obtener @ClienteID INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ClienteID,TipoCliente,NIT,Nombre,Telefono,Correo,Direccion,Activo
    FROM dbo.Cliente WHERE ClienteID=@ClienteID;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Cliente_Guardar
    @ClienteID INT=NULL,@TipoCliente VARCHAR(15),@NIT VARCHAR(20)=NULL,@Nombre VARCHAR(150),
    @Telefono VARCHAR(30)=NULL,@Correo VARCHAR(120)=NULL,@Direccion VARCHAR(250)=NULL,@Activo BIT=1
AS
BEGIN
    SET NOCOUNT ON;
    IF @ClienteID IS NULL OR @ClienteID=0
    BEGIN
        INSERT dbo.Cliente(TipoCliente,NIT,Nombre,Telefono,Correo,Direccion,Activo)
        VALUES(@TipoCliente,NULLIF(@NIT,''),@Nombre,NULLIF(@Telefono,''),NULLIF(@Correo,''),NULLIF(@Direccion,''),@Activo);
        SELECT CAST(SCOPE_IDENTITY() AS INT) AS ClienteID;
    END
    ELSE
    BEGIN
        UPDATE dbo.Cliente SET TipoCliente=@TipoCliente,NIT=NULLIF(@NIT,''),Nombre=@Nombre,
            Telefono=NULLIF(@Telefono,''),Correo=NULLIF(@Correo,''),Direccion=NULLIF(@Direccion,''),Activo=@Activo
        WHERE ClienteID=@ClienteID;
        SELECT @ClienteID AS ClienteID;
    END
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Cliente_CambiarEstado @ClienteID INT,@Activo BIT
AS
BEGIN SET NOCOUNT ON; UPDATE dbo.Cliente SET Activo=@Activo WHERE ClienteID=@ClienteID; END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Proveedor_Listar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ProveedorID,NIT,Nombre,Contacto,Telefono,Correo,Direccion,Activo,FechaCreacion
    FROM dbo.Proveedor ORDER BY Nombre;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Proveedor_Obtener @ProveedorID INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ProveedorID,NIT,Nombre,Contacto,Telefono,Correo,Direccion,Activo
    FROM dbo.Proveedor WHERE ProveedorID=@ProveedorID;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Proveedor_Guardar
    @ProveedorID INT=NULL,@NIT VARCHAR(20)=NULL,@Nombre VARCHAR(150),@Contacto VARCHAR(120)=NULL,
    @Telefono VARCHAR(30)=NULL,@Correo VARCHAR(120)=NULL,@Direccion VARCHAR(250)=NULL,@Activo BIT=1
AS
BEGIN
    SET NOCOUNT ON;
    IF @ProveedorID IS NULL OR @ProveedorID=0
    BEGIN
        INSERT dbo.Proveedor(NIT,Nombre,Contacto,Telefono,Correo,Direccion,Activo)
        VALUES(NULLIF(@NIT,''),@Nombre,NULLIF(@Contacto,''),NULLIF(@Telefono,''),NULLIF(@Correo,''),NULLIF(@Direccion,''),@Activo);
        SELECT CAST(SCOPE_IDENTITY() AS INT) AS ProveedorID;
    END
    ELSE
    BEGIN
        UPDATE dbo.Proveedor SET NIT=NULLIF(@NIT,''),Nombre=@Nombre,Contacto=NULLIF(@Contacto,''),
            Telefono=NULLIF(@Telefono,''),Correo=NULLIF(@Correo,''),Direccion=NULLIF(@Direccion,''),Activo=@Activo
        WHERE ProveedorID=@ProveedorID;
        SELECT @ProveedorID AS ProveedorID;
    END
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Proveedor_CambiarEstado @ProveedorID INT,@Activo BIT
AS
BEGIN SET NOCOUNT ON; UPDATE dbo.Proveedor SET Activo=@Activo WHERE ProveedorID=@ProveedorID; END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Categoria_Listar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CategoriaID,Nombre,TipoControl,ManejaLote,Descripcion,Activo FROM dbo.Categoria ORDER BY Nombre;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Categoria_Obtener @CategoriaID INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CategoriaID,Nombre,TipoControl,ManejaLote,Descripcion,Activo FROM dbo.Categoria WHERE CategoriaID=@CategoriaID;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Categoria_Guardar
    @CategoriaID INT=NULL,@Nombre VARCHAR(80),@TipoControl VARCHAR(20),@ManejaLote BIT=0,
    @Descripcion VARCHAR(200)=NULL,@Activo BIT=1
AS
BEGIN
    SET NOCOUNT ON;
    IF @CategoriaID IS NULL OR @CategoriaID=0
    BEGIN
        INSERT dbo.Categoria(Nombre,TipoControl,ManejaLote,Descripcion,Activo)
        VALUES(@Nombre,@TipoControl,@ManejaLote,NULLIF(@Descripcion,''),@Activo);
        SELECT CAST(SCOPE_IDENTITY() AS INT) AS CategoriaID;
    END
    ELSE
    BEGIN
        UPDATE dbo.Categoria SET Nombre=@Nombre,TipoControl=@TipoControl,ManejaLote=@ManejaLote,
            Descripcion=NULLIF(@Descripcion,''),Activo=@Activo WHERE CategoriaID=@CategoriaID;
        SELECT @CategoriaID AS CategoriaID;
    END
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Categoria_CambiarEstado @CategoriaID INT,@Activo BIT
AS
BEGIN SET NOCOUNT ON; UPDATE dbo.Categoria SET Activo=@Activo WHERE CategoriaID=@CategoriaID; END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Marca_Listar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT MarcaID,Nombre,Descripcion,Activo FROM dbo.Marca ORDER BY Nombre;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Marca_Obtener @MarcaID INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT MarcaID,Nombre,Descripcion,Activo FROM dbo.Marca WHERE MarcaID=@MarcaID;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Marca_Guardar
    @MarcaID INT=NULL,@Nombre VARCHAR(100),@Descripcion VARCHAR(200)=NULL,@Activo BIT=1
AS
BEGIN
    SET NOCOUNT ON;
    IF @MarcaID IS NULL OR @MarcaID=0
    BEGIN
        INSERT dbo.Marca(Nombre,Descripcion,Activo) VALUES(@Nombre,NULLIF(@Descripcion,''),@Activo);
        SELECT CAST(SCOPE_IDENTITY() AS INT) AS MarcaID;
    END
    ELSE
    BEGIN
        UPDATE dbo.Marca SET Nombre=@Nombre,Descripcion=NULLIF(@Descripcion,''),Activo=@Activo WHERE MarcaID=@MarcaID;
        SELECT @MarcaID AS MarcaID;
    END
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Marca_CambiarEstado @MarcaID INT,@Activo BIT
AS
BEGIN SET NOCOUNT ON; UPDATE dbo.Marca SET Activo=@Activo WHERE MarcaID=@MarcaID; END;
GO

/* ============================================================
   15. DASHBOARD
   ============================================================ */
CREATE OR ALTER PROCEDURE dbo.sp_DashboardResumen
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
      (SELECT COUNT(*) FROM dbo.Cliente WHERE Activo=1) AS Clientes,
      (SELECT COUNT(*) FROM dbo.Proveedor WHERE Activo=1) AS Proveedores,
      (SELECT COUNT(*) FROM dbo.Categoria WHERE Activo=1) AS Categorias,
      (SELECT COUNT(*) FROM dbo.Marca WHERE Activo=1) AS Marcas,
      (SELECT COUNT(*) FROM dbo.Usuario WHERE Activo=1) AS Usuarios,
      (SELECT COUNT(*) FROM dbo.Producto WHERE Activo=1) AS Productos;
END;
GO

PRINT 'PintureriaDB - Fase 1 instalada correctamente.';
GO
