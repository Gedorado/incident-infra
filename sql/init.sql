:setvar DB_NAME "incidentdb"

IF DB_ID('$(DB_NAME)') IS NULL
BEGIN
  PRINT 'Creando base de datos $(DB_NAME)';
  DECLARE @createDbSql NVARCHAR(MAX) = N'CREATE DATABASE [' + '$(DB_NAME)' + N']';
  EXEC(@createDbSql);
END
ELSE
BEGIN
  PRINT 'La base de datos $(DB_NAME) ya existe';
END
GO

USE [$(DB_NAME)];
GO

IF OBJECT_ID('dbo.Incidents', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.Incidents (
    Id UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_Incidents PRIMARY KEY,
    Title NVARCHAR(200) NOT NULL,
    Description NVARCHAR(MAX) NOT NULL,
    Severity NVARCHAR(20) NOT NULL,
    Status NVARCHAR(20) NOT NULL,
    ServiceId NVARCHAR(100) NOT NULL,
    CreatedAt DATETIME2(3) NOT NULL CONSTRAINT DF_Incidents_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2(3) NOT NULL CONSTRAINT DF_Incidents_UpdatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT CK_Incidents_Severity CHECK (Severity IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    CONSTRAINT CK_Incidents_Status CHECK (Status IN ('OPEN', 'IN_PROGRESS', 'RESOLVED'))
  );
END
GO

IF NOT EXISTS (
  SELECT 1
  FROM sys.indexes
  WHERE name = 'IX_Incidents_List'
    AND object_id = OBJECT_ID('dbo.Incidents')
)
BEGIN
  CREATE INDEX IX_Incidents_List
    ON dbo.Incidents (Status, Severity, ServiceId, CreatedAt DESC)
    INCLUDE (Title, UpdatedAt);
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Incidents)
BEGIN
  INSERT INTO dbo.Incidents (Id, Title, Description, Severity, Status, ServiceId, CreatedAt, UpdatedAt)
  VALUES
    ('F8F0D9B7-0F2A-4387-B5A5-6DFF4C0A0101', 'Pago falla al confirmar', 'Error 500 intermitente al confirmar el pago.', 'HIGH', 'OPEN', 'payments-api', DATEADD(HOUR, -6, SYSUTCDATETIME()), DATEADD(HOUR, -6, SYSUTCDATETIME())),
    ('F8F0D9B7-0F2A-4387-B5A5-6DFF4C0A0102', 'Orden no actualiza estado', 'Las ordenes quedan en processing por mas tiempo del esperado.', 'MEDIUM', 'IN_PROGRESS', 'orders-api', DATEADD(HOUR, -4, SYSUTCDATETIME()), DATEADD(HOUR, -2, SYSUTCDATETIME())),
    ('F8F0D9B7-0F2A-4387-B5A5-6DFF4C0A0103', 'Latencia alta en checkout', 'Tiempo de respuesta elevado en el flujo de checkout.', 'CRITICAL', 'OPEN', 'payments-api', DATEADD(HOUR, -2, SYSUTCDATETIME()), DATEADD(HOUR, -90, SYSUTCDATETIME())),
    ('F8F0D9B7-0F2A-4387-B5A5-6DFF4C0A0104', 'Webhook duplicado', 'Se reciben eventos duplicados desde proveedor externo.', 'LOW', 'RESOLVED', 'webhooks-api', DATEADD(DAY, -1, SYSUTCDATETIME()), DATEADD(HOUR, -12, SYSUTCDATETIME()));
END
GO

SELECT DB_NAME() AS CurrentDatabase;
SELECT COUNT(*) AS IncidentCount FROM dbo.Incidents;
GO
