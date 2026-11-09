-- Ejecutar una vez sobre PintureriaDB, después de los scripts anteriores.
IF OBJECT_ID('dbo.UsuarioPermiso', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.UsuarioPermiso (
        UsuarioID INT NOT NULL,
        Modulo VARCHAR(30) NOT NULL,
        PuedeVer BIT NOT NULL CONSTRAINT DF_UsuarioPermiso_Ver DEFAULT(0),
        PuedeEditar BIT NOT NULL CONSTRAINT DF_UsuarioPermiso_Editar DEFAULT(0),
        CONSTRAINT PK_UsuarioPermiso PRIMARY KEY (UsuarioID, Modulo),
        CONSTRAINT FK_UsuarioPermiso_Usuario FOREIGN KEY (UsuarioID)
            REFERENCES dbo.Usuario(UsuarioID) ON DELETE CASCADE,
        CONSTRAINT CK_UsuarioPermiso_Modulo CHECK (Modulo IN
            ('clientes','proveedores','categorias','marcas','productos',
             'cotizaciones','facturas','compras','inventario')),
        CONSTRAINT CK_UsuarioPermiso_Edicion CHECK (PuedeEditar = 0 OR PuedeVer = 1)
    );
END;
GO
