# incident-infra

Infraestructura local para la prueba técnica de incidentes.

Este repo levanta con Docker Compose:

- SQL Server
- MongoDB
- Mock Service Catalog
- incident-api
- incident-web

## Estructura esperada

```text
/workspace
  /incident-api
  /incident-web
  /incident-infra
```

## Archivos incluidos

```text
incident-infra/
  docker-compose.yml
  .env.example
  README.md
  /sql
    init.sql
  /scripts
    init-db.sh
  /mock-service-catalog
    Dockerfile
    package.json
    /src
      server.js
```

## Requisitos

- Docker Desktop
- Docker Compose
- Los repos `incident-api` e `incident-web` deben existir al mismo nivel que este repo.
- Ambos deben tener `Dockerfile` funcional.

## Variables de entorno

Copia el archivo de ejemplo:

```bash
cp .env.example .env
```

Variables:

- `SQL_SA_PASSWORD`: password del usuario `sa`
- `SQL_DB_NAME`: nombre de la base SQL Server
- `MONGO_DB_NAME`: nombre de la base en MongoDB

## Cómo levantar

Desde la carpeta `incident-infra`:

```bash
docker compose up --build
```

## Servicios y puertos

- API: `http://localhost:3000`
- Web: `http://localhost:5173`
- Service Catalog Mock: `http://localhost:3001`
- SQL Server: `localhost:1433`
- MongoDB: `localhost:27017`

## Qué hace cada servicio

### sqlserver

Levanta SQL Server 2022 con volumen persistente.

### sqlserver-init

Espera a que SQL Server esté sano y luego ejecuta `sql/init.sql` de forma automática.

### mongo

Levanta MongoDB para eventos y auditoría.

### service-catalog-mock

Simula el servicio externo requerido por la prueba.

Endpoints:

- `GET /health`
- `GET /services/payments-api`
- `GET /services/orders-api`
- `GET /services/webhooks-api`

Cualquier otro `serviceId` devuelve `404`.

### incident-api

Se construye desde `../incident-api`.

Variables que este compose le inyecta:

- `PORT=3000`
- `SQL_HOST=sqlserver`
- `SQL_PORT=1433`
- `SQL_USER=sa`
- `SQL_PASSWORD=<valor de .env>`
- `SQL_DB_NAME=<valor de .env>`
- `MONGO_URI=mongodb://mongo:27017/<db>`
- `MONGO_DB_NAME=<valor de .env>`
- `SERVICE_CATALOG_BASE_URL=http://service-catalog-mock:3001`

### incident-web

Se construye desde `../incident-web`.

Este compose le pasa el build arg:

- `VITE_API_URL=http://localhost:3000`

Si tu frontend usa otro mecanismo para variables, ajusta el `Dockerfile` o el servicio en compose.

## SQL incluido

`sql/init.sql` crea:

- Base de datos `incidentdb` o la que definas en `.env`
- Tabla `dbo.Incidents`
- Constraints para `Severity` y `Status`
- Índice `IX_Incidents_List`
- 4 incidentes seed

## Modelo SQL usado

Tabla:

- `Id UNIQUEIDENTIFIER`
- `Title NVARCHAR(200)`
- `Description NVARCHAR(MAX)`
- `Severity NVARCHAR(20)`
- `Status NVARCHAR(20)`
- `ServiceId NVARCHAR(100)`
- `CreatedAt DATETIME2(3)`
- `UpdatedAt DATETIME2(3)`

Estados permitidos:

- `OPEN`
- `IN_PROGRESS`
- `RESOLVED`

Severidades permitidas:

- `LOW`
- `MEDIUM`
- `HIGH`
- `CRITICAL`

## Cómo probar rápido

### 1. Probar mock

```bash
curl http://localhost:3001/health
curl http://localhost:3001/services/payments-api
curl http://localhost:3001/services/unknown-api
```

### 2. Verificar SQL Server

Cuando levante todo, revisa logs:

```bash
docker compose logs -f sqlserver-init
```

Debe terminar con un mensaje similar a `Inicializacion completada`.

### 3. Verificar API

```bash
curl http://localhost:3000/health
```

Ese endpoint es recomendado para tu backend, aunque depende de tu implementación.

## Decisiones tomadas

- SQL Server separado de la inicialización, para que `init.sql` sea repetible.
- Índice orientado al listado con filtros y orden por fecha.
- Mock externo en contenedor propio, así el backend no depende de servicios reales.
- Variables explícitas, para que NestJS las lea con `@nestjs/config`.

## Tradeoffs

- `incident-web` usa `VITE_API_URL` en build time. Si luego quieres cambiar URL sin reconstruir, conviene usar un `nginx.conf` con runtime config.
- El `sqlserver-init` usa la misma imagen de SQL Server para tener `sqlcmd` disponible. Es simple, aunque no es la imagen más liviana.
- El seed SQL facilita demo y pruebas, pero en producción se quitaría.

## CI Pipelines

Ambos repos tienen GitHub Actions CI configurado en `.github/workflows/ci.yml`:

- **incident-api**: lint, build y test en cada push/PR a `main`.
- **incident-web**: lint, build y test en cada push/PR a `main`.

Ambos pipelines usan Node.js 20 con cache de npm.

## Performance SQL

El indice `IX_Incidents_List` esta optimizado para el endpoint principal de listado.
Se documento la evidencia del plan de ejecucion en [`docs/sql-performance.md`](docs/sql-performance.md).

## Pendientes opcionales

- Agregar Redis
- Agregar healthcheck en NestJS
- Agregar perfiles `dev` y `test` en Compose

## Siguiente paso recomendado

Haz que `incident-api` en NestJS lea exactamente estas variables y conecte a:

- SQL Server con TypeORM
- MongoDB con Mongoose
- Mock con `HttpModule`
