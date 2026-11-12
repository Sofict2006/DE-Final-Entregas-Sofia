# Punto 1 - Consultas en Athena con partition projection

Arquitectura: CSV locales → S3 (`entregas/`) → tabla externa en Glue Data Catalog con partition projection → Athena → S3 (`resultados-athena/`). El enunciado original está en `ENUNCIADO.md`.

## Prerrequisitos
- Terraform >= 1.5 (usado: 1.16) y proveedor hashicorp/aws >= 5.0.
- AWS CLI v2 configurado con credenciales (`aws configure`). Usuario usado: `de-gr01-user-4`.
- Región: `us-east-1`.
- Bash (probado en Ubuntu sobre WSL2).

## Configuración
Las variables están en `infraestructura/variables.tf`:

| Variable | Valor por defecto |
| --- | --- |
| region | us-east-1 |
| nombre_bucket | de-gr01-user-4-entregas-20261112 |
| nombre_base_datos | entregas_db_gr01_user4 |
| nombre_tabla | entregas |
| nombre_workgroup | wg-entregas-gr01-user4 |

Si el nombre del bucket no está disponible, cambie `nombre_bucket`.

## 1. Despliegue
```bash
cd infraestructura
terraform init
terraform validate
terraform plan
terraform apply -auto-approve -no-color 2>&1 | tee ../evidencias/aplicacion_terraform.txt
terraform output -json > ../evidencias/outputs.json
cd ..
```
Se crean 7 recursos: el bucket privado, el bloqueo de acceso público, los prefijos `entregas/` y `resultados-athena/`, la base de Glue, la tabla `entregas` (5 columnas, partición `fecha` string y proyección diaria `yyyy-MM-dd` de 2026-10-01 a 2026-10-03) y el workgroup de Athena.

## 2. Etapa inicial: días 1 y 2
Los archivos se cargan uno por uno, sin carga recursiva:
```bash
aws s3 cp "data/entregas/fecha=2026-10-01/entregas.csv" "s3://<bucket>/entregas/fecha=2026-10-01/entregas.csv"
aws s3 cp "data/entregas/fecha=2026-10-02/entregas.csv" "s3://<bucket>/entregas/fecha=2026-10-02/entregas.csv"
```
Las consultas se ejecutan con `ejecutar_consulta.sh`. El script lanza la consulta en el workgroup, espera a que termine, descarga el CSV de resultados y registra la ejecución en `evidencias/ejecuciones_athena.csv`:
```bash
bash ejecutar_consulta.sh inicial consultas/conteo_total.sql resultados/inicial/conteo_total.csv
bash ejecutar_consulta.sh inicial consultas/intentos_por_fecha_estado.sql resultados/inicial/intentos_por_fecha_estado.csv
bash ejecutar_consulta.sh inicial consultas/porcentaje_exito_por_fecha_ciudad.sql resultados/inicial/porcentaje_exito_por_fecha_ciudad.csv
bash ejecutar_consulta.sh inicial consultas/duracion_promedio_2026-10-02.sql resultados/inicial/duracion_promedio_2026-10-02.csv
```
Resultado: 12 registros. Los resultados coinciden con `resultados_esperados/*_inicial.csv` y `duracion_promedio_2026-10-02.csv` (verificado con `diff`).

## 3. Etapa final: día 3 (solo se sube el archivo y se consulta)
```bash
aws s3 cp "data/entregas/fecha=2026-10-03/entregas.csv" "s3://<bucket>/entregas/fecha=2026-10-03/entregas.csv"
```
No se ejecutaron crawlers, `MSCK REPAIR TABLE` ni `ALTER TABLE ADD PARTITION`, ni se modificó la tabla. Después de la carga, `terraform plan` devolvió "No changes".
```bash
bash ejecutar_consulta.sh final consultas/verificacion_tercer_dia.sql resultados/final/verificacion_tercer_dia.csv 1
bash ejecutar_consulta.sh final consultas/verificacion_tercer_dia.sql resultados/final/verificacion_tercer_dia_conteo_estado.csv 2
bash ejecutar_consulta.sh final consultas/verificacion_tercer_dia.sql resultados/final/verificacion_total_registros.csv 3
bash ejecutar_consulta.sh final consultas/intentos_por_fecha_estado.sql resultados/final/intentos_por_fecha_estado.csv
bash ejecutar_consulta.sh final consultas/porcentaje_exito_por_fecha_ciudad.sql resultados/final/porcentaje_exito_por_fecha_ciudad.csv
```
El cuarto parámetro indica qué sentencia de `verificacion_tercer_dia.sql` se ejecuta, porque Athena ejecuta una sentencia por vez. Resultado: 6 registros del 2026-10-03, conteos por estado correctos y 18 registros en total. Los resultados coinciden con `resultados_esperados/*_final.csv`.

## 4. Limpieza
Con las evidencias ya guardadas:
```bash
aws s3 rm s3://<bucket> --recursive
cd infraestructura
terraform destroy -auto-approve -no-color 2>&1 | tee ../evidencias/eliminacion_terraform.txt
```
Resultado: 5 recursos destruidos. Los 2 objetos de prefijo ya habían sido eliminados al vaciar el bucket, así que Terraform los retiró del estado al refrescarlo. Se verificó con la CLI que el bucket, la base de Glue y el workgroup ya no existen.