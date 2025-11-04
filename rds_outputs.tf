output "rds_cluster_endpoint" {
  description = "El endpoint de conexión (escritura) del cluster Aurora."
  value       = aws_rds_cluster.aurora.endpoint
}

output "rds_cluster_reader_endpoint" {
  description = "El endpoint de solo lectura del cluster Aurora."
  value       = aws_rds_cluster.aurora.reader_endpoint
}

output "db_secret_arn" {
  description = "El ARN del secreto en Secrets Manager."
  value       = aws_secretsmanager_secret.db.arn
}