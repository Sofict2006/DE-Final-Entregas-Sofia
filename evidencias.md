# Respuestas

## 1. ¿Por qué se pudo consultar el tercer día sin registrar una partición nueva?

La tabla `entregas` usa partition projection. En lugar de leer particiones registradas en Glue, Athena calcula los valores de `fecha` durante la consulta a partir de las propiedades de la tabla definidas en Terraform: `projection.fecha.type = date`, formato `yyyy-MM-dd`, intervalo de 1 día y rango `2026-10-01,2026-10-03`. La plantilla `storage.location.template` (`s3://<bucket>/entregas/fecha=${fecha}/`) le indica dónde buscar cada fecha.

Como el 2026-10-03 ya estaba dentro del rango desde el despliegue inicial, bastó con subir el archivo al prefijo `entregas/fecha=2026-10-03/`. En la siguiente consulta, Athena lo encontró. No se ejecutaron crawlers, `MSCK REPAIR TABLE` ni `ALTER TABLE ADD PARTITION`, y `terraform plan` mostró "No changes". La evidencia está en `resultados/final/verificacion_tercer_dia.csv` (6 registros), `resultados/final/verificacion_total_registros.csv` (18 registros) y en las ejecuciones con etapa `final` de `evidencias/ejecuciones_athena.csv`.

## 2. ¿Qué pasaría con un archivo del 4 de octubre y qué se debería modificar?

Con la configuración actual, el rango de proyección termina en `2026-10-03`, así que Athena nunca genera la fecha `2026-10-04`. El archivo quedaría en S3, pero sería ignorado. Una consulta con `WHERE fecha = '2026-10-04'` devolvería cero filas, sin error, y el total seguiría en 18.

Para incluirlo habría que ampliar la propiedad `projection.fecha.range` en `infraestructura/principal.tf`, por ejemplo a `2026-10-01,2026-10-04`, o usar un rango relativo como `2026-10-01,NOW`, y luego ejecutar `terraform apply`. Tampoco en ese caso habría que registrar particiones, porque solo cambia la regla de proyección.