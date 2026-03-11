#!/usr/bin/env bash
set -euo pipefail

SQL_HOST="sqlserver"
SQL_PORT="1433"
SQL_USER="sa"
SQL_PASSWORD="${SQL_SA_PASSWORD}"
SQL_DB_NAME="${SQL_DB_NAME:-incidentdb}"
INIT_FILE="/work/sql/init.sql"

if [[ ! -f "$INIT_FILE" ]]; then
  echo "No se encontro $INIT_FILE"
  exit 1
fi

echo "Esperando conectividad hacia SQL Server..."
for i in {1..60}; do
  if /opt/mssql-tools18/bin/sqlcmd -S "${SQL_HOST},${SQL_PORT}" -U "$SQL_USER" -P "$SQL_PASSWORD" -No -Q "SELECT 1" >/dev/null 2>&1; then
    echo "SQL Server disponible. Ejecutando inicializacion..."
    break
  fi
  echo "Intento $i/60, SQL Server aun no responde..."
  sleep 2
done

/opt/mssql-tools18/bin/sqlcmd -S "${SQL_HOST},${SQL_PORT}" -U "$SQL_USER" -P "$SQL_PASSWORD" -No -v DB_NAME="$SQL_DB_NAME" -i "$INIT_FILE"

echo "Inicializacion completada."
