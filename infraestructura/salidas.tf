output "bucket" {
  value = aws_s3_bucket.datos.bucket
}

output "base_datos" {
  value = aws_glue_catalog_database.db.name
}

output "tabla" {
  value = aws_glue_catalog_table.entregas.name
}

output "workgroup" {
  value = aws_athena_workgroup.wg.name
}

output "ubicacion_resultados" {
  value = "s3://${aws_s3_bucket.datos.bucket}/resultados-athena/"
}