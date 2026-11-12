#!/usr/bin/env bash
# Uso: bash ejecutar_consulta.sh <etapa> <archivo_sql> <archivo_resultado>
set -euo pipefail
ETAPA="$1"; SQL="$2"; SALIDA="$3"
QUERY=$(cat "$SQL")
if [ -n "${4:-}" ]; then
  QUERY=$(awk -v n="$4" 'BEGIN{RS=";"} NR==n' "$SQL")
fi
WG="wg-entregas-gr01-user4"
DB="entregas_db_gr01_user4"

ID=$(aws athena start-query-execution \
  --work-group "$WG" \
  --query-execution-context Database="$DB" \
  --query-string "$QUERY" \
  --query 'QueryExecutionId' --output text)
echo "ID de ejecucion: $ID"

while true; do
  ESTADO=$(aws athena get-query-execution --query-execution-id "$ID" \
    --query 'QueryExecution.Status.State' --output text)
  case "$ESTADO" in
    SUCCEEDED) break ;;
    FAILED|CANCELLED)
      aws athena get-query-execution --query-execution-id "$ID" \
        --query 'QueryExecution.Status.StateChangeReason' --output text
      exit 1 ;;
  esac
  sleep 2
done

UBIC=$(aws athena get-query-execution --query-execution-id "$ID" \
  --query 'QueryExecution.ResultConfiguration.OutputLocation' --output text)
aws s3 cp "$UBIC" - | sed 's/"//g' > "$SALIDA"
cat "$SALIDA"

REG="evidencias/ejecuciones_athena.csv"
[ -f "$REG" ] || echo "etapa,archivo_sql,id_ejecucion,archivo_resultado" > "$REG"
echo "$ETAPA,$SQL,$ID,$SALIDA" >> "$REG"