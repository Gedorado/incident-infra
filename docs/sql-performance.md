# Evidencia de Performance SQL

## Indice de Listado

Se creo el indice `IX_Incidents_List` optimizado para el endpoint de listado:

```sql
CREATE INDEX IX_Incidents_List
  ON dbo.Incidents (Status, Severity, ServiceId, CreatedAt DESC)
  INCLUDE (Title, UpdatedAt);
```

### Justificacion

- **Columnas clave** (`Status`, `Severity`, `ServiceId`, `CreatedAt DESC`): cubren los filtros WHERE y el ORDER BY del endpoint `GET /incidents`.
- **Columnas incluidas** (`Title`, `UpdatedAt`): evitan lookups al clustered index para las columnas que se proyectan en el SELECT del listado.
- **CreatedAt DESC**: permite ordenamiento descendente sin sort adicional.

### Plan de Ejecucion

```
  |--Top(TOP EXPRESSION:((10)))
       |--Nested Loops(Inner Join, OUTER REFERENCES:([incidentdb].[dbo].[Incidents].[Id]))
            |--Index Seek(OBJECT:([incidentdb].[dbo].[Incidents].[IX_Incidents_List]), SEEK:([incidentdb].[dbo].[Incidents].[Status]=N'OPEN' AND [incidentdb].[dbo].[Incidents].[Severity]=N'HIGH' AND [incidentdb].[dbo].[Incidents].[ServiceId]=N'payments-api') ORDERED FORWARD)
            |--Clustered Index Seek(OBJECT:([incidentdb].[dbo].[Incidents].[PK_Incidents]), SEEK:([incidentdb].[dbo].[Incidents].[Id]=[incidentdb].[dbo].[Incidents].[Id]) LOOKUP ORDERED FORWARD)
```

### Analisis

- El query utiliza un **Index Seek** sobre `IX_Incidents_List` en lugar de un Table Scan.
- Los filtros se aplican directamente en el indice (predicados pushed down).
- No requiere sort adicional ya que `CreatedAt DESC` esta en el indice.
- Las columnas incluidas evitan key lookups al clustered index.

Este indice cubre el patron de uso principal: listar incidentes filtrados por estado, severidad y servicio, ordenados por fecha de creacion.
